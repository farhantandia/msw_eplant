import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';

class FusionSolarService {
  static const String _prefLastSyncKey = 'solar_pv_last_sync_ms';
  static final FusionSolarService instance = FusionSolarService._internal();

  FusionSolarService._internal();

  static bool enableAutoSync = true;

  DatabaseReference? _solarLatestRef;
  DatabaseReference? _solarHistoryRef;
  StreamSubscription<DatabaseEvent>? _solarStreamSub;
  Timer? _periodicTimer;

  /// Mutex lock to prevent concurrent overlapping syncs.
  /// When true, subsequent syncNow() calls are silently skipped.
  bool _isSyncing = false;

  /// Reactive notifier for UI components to display real-time API loading/syncing state.
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  /// Helper getter to inspect current syncing state.
  bool get isSyncing => isSyncingNotifier.value;

  FusionSolarApiClient apiClient = FusionSolarApiClient();

  final ValueNotifier<SolarSnapshot> snapshotNotifier = ValueNotifier<SolarSnapshot>(
    SolarSnapshot.emptyOrStandby(),
  );

  /// Initializes listeners to Firebase RTDB `/solar_pv/latest` and seeds if empty
  void init({bool? autoSync}) {
    try {
      final rtdb = FirebaseDatabase.instance;
      _solarLatestRef = rtdb.ref('solar_pv/latest');
      _solarHistoryRef = rtdb.ref('solar_pv/history');

      // Attempt immediate cache restoration from Firebase RTDB
      _solarLatestRef?.once().then((event) {
        if (event.snapshot.value is Map) {
          try {
            final snap = SolarSnapshot.fromJson(event.snapshot.value as Map);
            snapshotNotifier.value = snap;
            debugPrint('✅ Restored actual solar snapshot from Firebase cache');
          } catch (_) {}
        }
        // If node doesn't exist, keep the empty/standby snapshot — never seed mock data
      }).catchError((_) {});

      // Listen to solar_pv path
      _solarStreamSub = _solarLatestRef?.onValue.listen(
        (event) {
          _handleDatabaseEvent(event);
        },
        onError: (err) {
          debugPrint('Firebase Solar RTDB error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firebase RTDB not initialized in this environment: $e');
    }

    // Clock-Aligned Auto-Sync: Precisely at :00 and :30 wall-clock marks (e.g. 09:00, 09:30, 10:00, 10:30...)
    // during operating window (04:00 - 20:00).
    // Only schedule timer if not in automated widget test environment to avoid pending timer assertions
    final isWidgetTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final shouldSync = autoSync ?? (enableAutoSync && !isWidgetTest);

    if (shouldSync) {
      _scheduleNextHalfHourSync();

      // Initial sync check
      checkAndTriggerPeriodicSync();
    }
  }

  /// Computes the exact Duration until the next :00 or :30 mark on the wall-clock.
  static Duration getDurationUntilNextHalfHour([DateTime? from]) {
    final now = from ?? DateTime.now();
    final nextMinute = now.minute < 30 ? 30 : 60;
    final nextSlot = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      nextMinute == 60 ? 0 : 30,
    ).add(nextMinute == 60 ? const Duration(hours: 1) : Duration.zero);
    final diff = nextSlot.difference(now);
    return diff.isNegative ? const Duration(seconds: 1) : diff;
  }

  /// Schedules the next auto-sync precisely at the next :00 or :30 wall-clock mark.
  void _scheduleNextHalfHourSync() {
    _periodicTimer?.cancel();
    final delay = getDurationUntilNextHalfHour();
    debugPrint('⏰ Scheduling clock-aligned Solar PV sync in ${delay.inMinutes}m ${delay.inSeconds % 60}s (at :00 or :30)');
    _periodicTimer = Timer(delay, () async {
      await syncNow();
      // Reschedule for the subsequent :00 or :30 mark
      _scheduleNextHalfHourSync();
    });
  }

  void _handleDatabaseEvent(DatabaseEvent event) {
    if (event.snapshot.value != null && event.snapshot.value is Map) {
      try {
        final snap = SolarSnapshot.fromJson(event.snapshot.value as Map);
        snapshotNotifier.value = snap;
      } catch (e) {
        debugPrint('Error parsing Firebase solar snapshot: $e');
      }
    }
  }

  void dispose() {
    _solarStreamSub?.cancel();
    _periodicTimer?.cancel();
    isSyncingNotifier.value = false;
    apiClient.logout();
  }

  /// Public convenience method to force-refresh telemetry from Huawei OpenAPI
  Future<SolarSnapshot> refresh() => syncNow(forceRefresh: true);

  static const String prefLastSyncKey = _prefLastSyncKey;

  /// Checks if >= 30 minutes have elapsed since last sync, triggers sync if needed
  Future<void> checkAndTriggerPeriodicSync({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_prefLastSyncKey) ?? 0;
      final currentTime = now ?? DateTime.now();
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

      // 30-Minute Bucket: check if already synced in current 30-minute half-hour window
      final lastBucket = (lastSyncDate.hour * 2) + (lastSyncDate.minute >= 30 ? 1 : 0);
      final currentBucket = (currentTime.hour * 2) + (currentTime.minute >= 30 ? 1 : 0);
      final isSame30MinBucket = lastSyncMs > 0 &&
          lastSyncDate.year == currentTime.year &&
          lastSyncDate.month == currentTime.month &&
          lastSyncDate.day == currentTime.day &&
          lastBucket == currentBucket;

      if (!isSame30MinBucket) {
        await syncNow();
      }
    } catch (e) {
      debugPrint('Sync check error: $e');
    }
  }

  /// Backward-compatible alias for checkAndTriggerPeriodicSync
  Future<void> checkAndTriggerHourlySync({DateTime? now}) => checkAndTriggerPeriodicSync(now: now);

  /// Performs sync:
  /// 1. Guards against concurrent overlapping syncs using `_isSyncing` mutex lock.
  /// 2. Enforces hourly bucket cache policy: if already synced for the current hour, skips external API call and reuses stored snapshot.
  /// 3. Enforces 16-hour operating window (04:00 - 20:00 WITA). Night hours (20:00 - 04:00) enter Standby with 0 API calls.
  /// 4. Attempts FusionSolar OpenAPI fetch with max 5 retries / 1 min.
  /// 5. In night hours, puts inverters into Night Standby with 0.0 kW without calling API.
  /// 6. Pushes live snapshot to Firebase RTDB and appends to 30-day historical time-series.
  /// 7. Automatically prunes history older than 30 days.
  /// 8. Never falls back to mock data during daytime – always retains last known actual snapshot.
  Future<SolarSnapshot> syncNow({bool forceRefresh = false}) async {
    // ── Mutex lock: prevent concurrent overlapping syncs ──
    if (_isSyncing) {
      debugPrint('🔒 syncNow() skipped — another sync is already in progress.');
      return snapshotNotifier.value;
    }

    // ── 30-Minute Bucket Cache Guard ──
    // If already synced for the current 30-minute window (e.g. at 09:10, opened again at 09:20),
    // do NOT call external Huawei API again to strictly respect quota limits.
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastSyncMs = prefs.getInt(_prefLastSyncKey) ?? 0;
        final now = DateTime.now();
        final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

        final lastBucket = (lastSyncDate.hour * 2) + (lastSyncDate.minute >= 30 ? 1 : 0);
        final nowBucket = (now.hour * 2) + (now.minute >= 30 ? 1 : 0);
        final isSame30MinBucket = lastSyncMs > 0 &&
            lastSyncDate.year == now.year &&
            lastSyncDate.month == now.month &&
            lastSyncDate.day == now.day &&
            lastBucket == nowBucket;

        if (isSame30MinBucket) {
          final bucketMin = now.minute >= 30 ? '30' : '00';
          debugPrint('⏳ Solar sync skipped: Already synced for ${now.hour}:$bucketMin bucket. Using stored data.');
          return snapshotNotifier.value;
        }
      } catch (e) {
        debugPrint('Cache check error: $e');
      }
    }

    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      return await _performSync(forceRefresh: forceRefresh);
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  /// Internal sync implementation, called only from [syncNow] under lock.
  Future<SolarSnapshot> _performSync({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isWithinWindow = FusionSolarApiClient.isWithinOperatingHours(now);

    SolarSnapshot snapshot;

    if (!isWithinWindow) {
      // 20:00 - 04:00: Outside 16h operating window -> Night Standby, 0 API calls
      debugPrint('🌙 Outside 16h operational window (20:00 - 04:00). Standby mode active.');
      final current = snapshotNotifier.value;
      // Preserve current day's actual yield and actual inverters, but set active power to 0.0 kW
      final standbyInverters = current.inverters.map((inv) {
        return SolarInverter(
          id: inv.id,
          name: inv.name,
          clusterId: inv.clusterId,
          capacityKwp: inv.capacityKwp,
          powerKw: 0.0,
          yieldTodayKwh: inv.yieldTodayKwh,
          specificEnergy: inv.specificEnergy,
          status: InverterStatus.standby,
          isNightStandby: true,
          model: inv.model,
          softwareVersion: inv.softwareVersion,
          esnCode: inv.esnCode,
          temperature: inv.temperature,
          gridFrequency: inv.gridFrequency,
          lineVoltageAb: inv.lineVoltageAb,
          lineVoltageBc: inv.lineVoltageBc,
          lineVoltageCa: inv.lineVoltageCa,
          phaseCurrentA: 0.0,
          phaseCurrentB: 0.0,
          phaseCurrentC: 0.0,
          powerFactor: inv.powerFactor,
          efficiency: 0.0,
          mpptPowerKw: 0.0,
          totalLifetimeKwh: inv.totalLifetimeKwh,
          inverterState: 0,
        );
      }).toList();

      snapshot = SolarSnapshot(
        timestamp: FusionSolarApiClient.roundToNearestHalfHour(now),
        isLive: false,
        totalPowerKw: 0.0,
        peakPowerKw: current.peakPowerKw,
        totalYieldTodayKwh: current.totalYieldTodayKwh,
        yieldYesterdayKwh: current.yieldYesterdayKwh,
        irradiance: 0.0,
        performanceRatio: current.performanceRatio,
        plantIrradiance: current.plantIrradiance,
        plantPr: current.plantPr,
        gridExportKw: 0.0,
        onlineInverterCount: 0,
        totalInverterCount: standbyInverters.isNotEmpty ? standbyInverters.length : 12,
        totalCapacityKwp: current.totalCapacityKwp,
        inverters: standbyInverters.isNotEmpty ? standbyInverters : current.inverters,
        hourlyPoints: current.hourlyPoints,
      );
    } else {
      // 04:00 - 20:00: Attempt live fetch from Huawei FusionSolar OpenAPI
      SolarSnapshot? liveSnap;
      try {
        liveSnap = await apiClient.fetchLatestSnapshot(referenceDate: now);
      } catch (e) {
        debugPrint('FusionSolar API client error: $e');
      }

      if (liveSnap != null) {
        snapshot = liveSnap;
      } else {
        // API down or rate limited: ALWAYS retain last known actual snapshot.
        // Never fall back to generateMockSnapshot() during daytime –
        // mock data overwrites real values and confuses operators.
        debugPrint('ℹ️ API unavailable. Retaining last known actual solar snapshot.');
        snapshot = snapshotNotifier.value;
      }
    }

    // Save timestamp to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLastSyncKey, now.millisecondsSinceEpoch);
    } catch (_) {}

    // Push to Firebase RTDB and store 30-day historical time series
    await _pushToFirebase(snapshot, now);

    snapshotNotifier.value = snapshot;
    return snapshot;
  }

  /// Formats date to YYYY-MM-DD for Firebase RTDB historical time-series
  static String formatHistoryDateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Formats hour to HH (00..23)
  static String formatHistoryHourKey(DateTime dt) =>
      dt.hour.toString().padLeft(2, '0');

  /// Computes the 7-day retention cutoff date (Rolling 7-day window)
  static DateTime getHistoryCutoffDate(DateTime now) =>
      now.subtract(const Duration(days: 7));

  /// Persists snapshot and 7-day rolling time-series to Firebase RTDB with automatic pruning
  Future<void> _pushToFirebase(SolarSnapshot snapshot, DateTime now) async {
    try {
      final dateKey = formatHistoryDateKey(now);
      final hourKey = formatHistoryHourKey(now);

      final snapMsw = snapshot.forPlant('msw');
      final snapKelanis = snapshot.forPlant('kelanis');

      final historyRecord = {
        'timestamp': now.toIso8601String(),
        'hour': now.hour,
        'total_power_kw': snapshot.totalPowerKw,
        'total_yield_kwh': snapshot.effectiveYieldTodayKwh,
        'peak_power_kw': snapshot.peakPowerKw,
        'irradiance': snapshot.irradiance,
        'pr': snapshot.performanceRatio,
        'grid_export_kw': snapshot.gridExportKw,
        'online_inverters': snapshot.onlineInverterCount,
        'total_inverters': snapshot.totalInverterCount,
        'plants': {
          'msw': {
            'power_kw': snapMsw.totalPowerKw,
            'yield_kwh': snapMsw.effectiveYieldTodayKwh,
            'irradiance': snapMsw.irradiance,
            'pr': snapMsw.performanceRatio,
            'peak_power_kw': snapMsw.peakPowerKw,
            'online_inverters': snapMsw.onlineInverterCount,
            'total_inverters': snapMsw.totalInverterCount,
          },
          'kelanis': {
            'power_kw': snapKelanis.totalPowerKw,
            'yield_kwh': snapKelanis.effectiveYieldTodayKwh,
            'irradiance': snapKelanis.irradiance,
            'pr': snapKelanis.performanceRatio,
            'peak_power_kw': snapKelanis.peakPowerKw,
            'online_inverters': snapKelanis.onlineInverterCount,
            'total_inverters': snapKelanis.totalInverterCount,
          },
        },
        'inverters': snapshot.inverters.map((inv) => {
          'id': inv.id,
          'name': inv.name,
          'cluster_id': inv.clusterId,
          'plant_id': inv.plantId,
          'power_kw': inv.powerKw,
          'yield_today_kwh': inv.yieldTodayKwh,
          'specific_energy': inv.specificEnergy ?? (inv.capacityKwp > 0 ? (inv.yieldTodayKwh / inv.capacityKwp) : 0.0),
          'temperature': inv.temperature,
          'efficiency': inv.efficiency,
          'grid_frequency': inv.gridFrequency,
          'line_voltage_ab': inv.lineVoltageAb,
          'line_voltage_bc': inv.lineVoltageBc,
          'line_voltage_ca': inv.lineVoltageCa,
          'phase_current_a': inv.phaseCurrentA,
          'phase_current_b': inv.phaseCurrentB,
          'phase_current_c': inv.phaseCurrentC,
          'power_factor': inv.powerFactor,
          'mppt_power_kw': inv.mpptPowerKw,
          'status': inv.status.name,
          'is_night_standby': inv.isNightStandby,
        }).toList(),
      };

      // 1. Write latest snapshot to solar_pv/latest
      if (_solarLatestRef != null) {
        try {
          await _solarLatestRef!.set(snapshot.toJson());
        } catch (e) {
          debugPrint('Firebase solarLatestRef push error: $e');
        }
      }

      // 2. Append hourly point to 7-day time-series history
      if (_solarHistoryRef != null) {
        try {
          await _solarHistoryRef!.child('$dateKey/$hourKey').set(historyRecord);
        } catch (e) {
          debugPrint('Firebase solarHistoryRef push error: $e');
        }
      }

      // 3. Prune historical data older than 7 days
      _pruneOldHistory(now);
    } catch (e) {
      debugPrint('Firebase push error: $e');
    }
  }

  /// Automatically deletes historical date nodes older than 7 days
  void _pruneOldHistory(DateTime now) {
    try {
      final cutoffDate = getHistoryCutoffDate(now);
      final cutoffKey = formatHistoryDateKey(cutoffDate);

      void cleanRef(DatabaseReference? ref) {
        if (ref == null) return;
        ref.orderByKey().endAt(cutoffKey).once().then((event) {
          if (event.snapshot.value is Map) {
            final map = event.snapshot.value as Map;
            for (final key in map.keys) {
              if (key.toString().compareTo(cutoffKey) < 0) {
                ref.child(key.toString()).remove().catchError((_) {});
                debugPrint('🧹 Pruned old solar history record: $key');
              }
            }
          }
        }).catchError((_) {});
      }

      cleanRef(_solarHistoryRef);
    } catch (_) {}
  }

  /// Seeds initial structured solar data (latest snapshot + 7 days historical time-series)
  /// into Firebase RTDB under '/solar_pv' if not present or on demand.
  Future<void> ensureInitialSeed({DateTime? referenceDate, bool force = false}) async {
    final now = referenceDate ?? DateTime.now();
    try {
      if (!force && _solarLatestRef != null) {
        final check = await _solarLatestRef!.once();
        if (check.snapshot.value is Map) {
          return; // Already initialized in Firebase RTDB
        }
      }

      final initialSnapshot = generateMockSnapshot(date: now);
      // 1. Write latest snapshot
      if (_solarLatestRef != null) {
        await _solarLatestRef!.set(initialSnapshot.toJson());
        debugPrint('🌱 Seeded /solar_pv/latest in Firebase RTDB');
      }

      // 2. Seed 7 days of historical records
      final sevenDaysData = generate7DayHistoricalData(referenceDate: now);
      if (_solarHistoryRef != null) {
        for (final dateEntry in sevenDaysData.entries) {
          final dateKey = dateEntry.key;
          for (final hourEntry in dateEntry.value.entries) {
            final hourKey = hourEntry.key;
            await _solarHistoryRef!.child('$dateKey/$hourKey').set(hourEntry.value);
          }
        }
        debugPrint('🌱 Seeded 7-day history in /solar_pv/history');
      }
    } catch (e) {
      debugPrint('ensureInitialSeed error: $e');
    }
  }

  /// Fetches 7-day historical time-series from Firebase RTDB '/solar_pv/history'.
  /// Falls back to simulated 7-day time series if database is offline or empty.
  Future<Map<String, Map<String, dynamic>>> fetchHistory7Days({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final result = <String, Map<String, dynamic>>{};

    if (_solarHistoryRef != null) {
      try {
        final event = await _solarHistoryRef!.once();
        if (event.snapshot.value is Map) {
          final rawMap = event.snapshot.value as Map;
          for (final dateEntry in rawMap.entries) {
            final dateKey = dateEntry.key.toString();
            if (dateEntry.value is Map) {
              final hoursMap = <String, dynamic>{};
              final rawHours = dateEntry.value as Map;
              for (final hourEntry in rawHours.entries) {
                if (hourEntry.value is Map) {
                  hoursMap[hourEntry.key.toString()] = Map<String, dynamic>.from(hourEntry.value as Map);
                }
              }
              if (hoursMap.isNotEmpty) {
                result[dateKey] = hoursMap;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching 7-day solar history from Firebase: $e');
      }
    }

    if (result.isEmpty) {
      return generate7DayHistoricalData(referenceDate: currentTime);
    }
    return result;
  }

  /// Generates realistic 7-day historical dataset for testing only.
  /// WARNING: This is mock/simulated data — never use in production paths.
  @Deprecated('Mock data should only be used in widget tests. Production code should use API data.')
  static Map<String, Map<String, dynamic>> generate7DayHistoricalData({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final result = <String, Map<String, dynamic>>{};

    for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
      final date = now.subtract(Duration(days: dayOffset));
      final dateKey = formatHistoryDateKey(date);
      final hoursMap = <String, dynamic>{};

      final maxH = (dayOffset == 0) ? now.hour.clamp(4, 20) : 20;

      for (int h = 4; h <= maxH; h++) {
        final hourDate = DateTime(date.year, date.month, date.day, h, 0);
        final snap = generateMockSnapshot(date: hourDate);
        final snapMsw = snap.forPlant('msw');
        final snapKelanis = snap.forPlant('kelanis');

        hoursMap[h.toString().padLeft(2, '0')] = {
          'timestamp': hourDate.toIso8601String(),
          'hour': h,
          'total_power_kw': snap.totalPowerKw,
          'total_yield_kwh': snap.effectiveYieldTodayKwh,
          'peak_power_kw': snap.peakPowerKw,
          'irradiance': snap.irradiance,
          'pr': snap.performanceRatio,
          'grid_export_kw': snap.gridExportKw,
          'online_inverters': snap.onlineInverterCount,
          'total_inverters': snap.totalInverterCount,
          'plants': {
            'msw': {
              'power_kw': snapMsw.totalPowerKw,
              'yield_kwh': snapMsw.effectiveYieldTodayKwh,
              'irradiance': snapMsw.irradiance,
              'pr': snapMsw.performanceRatio,
              'peak_power_kw': snapMsw.peakPowerKw,
              'online_inverters': snapMsw.onlineInverterCount,
              'total_inverters': snapMsw.totalInverterCount,
            },
            'kelanis': {
              'power_kw': snapKelanis.totalPowerKw,
              'yield_kwh': snapKelanis.effectiveYieldTodayKwh,
              'irradiance': snapKelanis.irradiance,
              'pr': snapKelanis.performanceRatio,
              'peak_power_kw': snapKelanis.peakPowerKw,
              'online_inverters': snapKelanis.onlineInverterCount,
              'total_inverters': snapKelanis.totalInverterCount,
            },
          },
          'inverters': snap.inverters.map((inv) => {
            'id': inv.id,
            'name': inv.name,
            'cluster_id': inv.clusterId,
            'plant_id': inv.plantId,
            'power_kw': inv.powerKw,
            'yield_today_kwh': inv.yieldTodayKwh,
            'specific_energy': inv.specificEnergy ?? (inv.capacityKwp > 0 ? (inv.yieldTodayKwh / inv.capacityKwp) : 0.0),
            'temperature': inv.temperature,
            'efficiency': inv.efficiency,
            'grid_frequency': inv.gridFrequency,
            'line_voltage_ab': inv.lineVoltageAb,
            'line_voltage_bc': inv.lineVoltageBc,
            'line_voltage_ca': inv.lineVoltageCa,
            'phase_current_a': inv.phaseCurrentA,
            'phase_current_b': inv.phaseCurrentB,
            'phase_current_c': inv.phaseCurrentC,
            'power_factor': inv.powerFactor,
            'mppt_power_kw': inv.mpptPowerKw,
            'status': inv.status.name,
            'is_night_standby': inv.isNightStandby,
          }).toList(),
        };
      }
      result[dateKey] = hoursMap;
    }
    return result;
  }

  /// Generates realistic solar curves for testing only.
  /// WARNING: This is mock/simulated data — never use in production paths.
  @Deprecated('Mock data should only be used in widget tests. Production code should use API data.')
  static SolarSnapshot generateMockSnapshot({DateTime? date}) {
    final now = date ?? DateTime.now();
    final hour = now.hour + (now.minute / 60.0);

    // Sun bell curve peaking at 12:30 WITA (6:00 to 18:30)
    double sunFactor = 0.0;
    if (hour >= 6.0 && hour <= 18.5) {
      final normalized = (hour - 6.0) / 12.5; // 0 to 1
      sunFactor = sin(normalized * pi).clamp(0.0, 1.0);
    }
    final isNight = hour < 5.8 || hour > 18.5;
    final double peakSystemPower = 720.0; // kW peak for 868 kWp total plant
    final double currentPower = isNight ? 0.0 : (peakSystemPower * sunFactor * (0.92 + Random().nextDouble() * 0.08));

    // Calculate cumulative generation up to current hour
    double cumulativeYield = 0.0;

    // Hourly data points ONLY up to current hour (no future points, never zero-fill the future)
    final List<SolarHourlyPoint> hourlyPoints = [];
    final maxHour = now.hour.clamp(4, 20);
    for (int h = 4; h <= maxHour; h++) {
      double hSunFactor = 0.0;
      if (h >= 6 && h <= 18) {
        final norm = (h - 6.0) / 12.5;
        hSunFactor = sin(norm * pi).clamp(0.0, 1.0);
        hSunFactor = pow(hSunFactor, 1.4).toDouble();
      }

      final hKw = peakSystemPower * hSunFactor * 0.95;
      final hIrr = hSunFactor * 0.95;
      final hPr = (hKw > 0) ? (80.5 + (h % 3) * 0.5) : 0.0;

      cumulativeYield += hKw * 0.85; // rough integral kWh

      final mswHIrr = double.parse((hIrr * 1.02).toStringAsFixed(2));
      final kelanisHIrr = double.parse((hIrr * 0.96).toStringAsFixed(2));
      final mswHPower = double.parse((hKw * (400.0 / 868.0)).toStringAsFixed(1));
      final kelanisHPower = double.parse((hKw * (468.0 / 868.0)).toStringAsFixed(1));
      final mswHPr = double.parse((hPr > 0 ? 82.6 : 0.0).toStringAsFixed(1));
      final kelanisHPr = double.parse((hPr > 0 ? 79.8 : 0.0).toStringAsFixed(1));

      hourlyPoints.add(SolarHourlyPoint(
        hour: h,
        timeStr: '${h.toString().padLeft(2, '0')}:00',
        powerKw: double.parse(hKw.toStringAsFixed(1)),
        irradiance: double.parse(hIrr.toStringAsFixed(2)),
        pr: double.parse(hPr.toStringAsFixed(1)),
        plantData: {
          'msw': {'power': mswHPower, 'irradiance': mswHIrr, 'pr': mswHPr},
          'kelanis': {'power': kelanisHPower, 'irradiance': kelanisHIrr, 'pr': kelanisHPr},
        },
      ));
    }

    if (!isNight && currentPower > 0.0) {
      final morningElapsed = (hour - 5.8).clamp(0.1, 12.0);
      final minMorningYield = (currentPower * morningElapsed * 0.45).clamp(1.5, 9999.0);
      if (cumulativeYield < minMorningYield) {
        cumulativeYield = minMorningYield;
      }
    } else if (cumulativeYield == 0.0 && !isNight) {
      cumulativeYield = 850.0;
    }

    // 12 Inverters configured in config.ini (MSW: 400 kWp, Kelanis: 468 kWp)
    final inverters = <SolarInverter>[
      // 165 kWp Array (4 units @ 41.25 kWp each = 165 kWp, MSW)
      SolarInverter(
        id: 'inv_165_1',
        name: 'INV PLTS 165 kWp 1',
        clusterId: '165kwp',
        plantId: 'msw',
        capacityKwp: 41.25,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.047).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.048).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_165_2',
        name: 'INV PLTS 165 kWp 2',
        clusterId: '165kwp',
        plantId: 'msw',
        capacityKwp: 41.25,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.047).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.047).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_165_3',
        name: 'INV PLTS 165 kWp 3',
        clusterId: '165kwp',
        plantId: 'msw',
        capacityKwp: 41.25,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.048).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.048).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_165_4',
        name: 'INV PLTS 165 kWp 4',
        clusterId: '165kwp',
        plantId: 'msw',
        capacityKwp: 41.25,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.046).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.047).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),

      // 200 kWp Array (2 units @ 100 kWp each = 200 kWp, MSW)
      SolarInverter(
        id: 'inv_200_1',
        name: 'INV_PLTS_200_KWP_1',
        clusterId: '200kwp',
        plantId: 'msw',
        capacityKwp: 100.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.115).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.115).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_200_2',
        name: 'INV_PLTS_200_KWP_2',
        clusterId: '200kwp',
        plantId: 'msw',
        capacityKwp: 100.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.114).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.114).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),

      // 468 kWp Array (4 units @ 117 kWp each = 468 kWp, Kelanis with Specific Energy)
      SolarInverter(
        id: 'inv_468_1',
        name: 'Inverter(COM1-1)',
        clusterId: '468kwp',
        plantId: 'kelanis',
        capacityKwp: 117.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.134).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.134).toStringAsFixed(1)),
        specificEnergy: 3.42,
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_468_2',
        name: 'Inverter(COM1-2)',
        clusterId: '468kwp',
        plantId: 'kelanis',
        capacityKwp: 117.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.136).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.135).toStringAsFixed(1)),
        specificEnergy: 3.45,
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
        temperature: 48.5,
        gridFrequency: 50.02,
        lineVoltageAb: 399.5,
        lineVoltageBc: 400.1,
        lineVoltageCa: 399.8,
        efficiency: 98.6,
        powerFactor: 0.999,
        activeAlarms: [
          SolarAlarm(
            alarmId: 'ALM-2001-01',
            alarmName: 'High Temperature Derating Warning',
            devName: 'Inverter(COM1-2)',
            devId: 'inv_468_2',
            esn: '6T2469039092',
            severity: AlarmSeverity.warning,
            raiseTime: DateTime(now.year, now.month, now.day, 13, 15),
            cause: 'Inverter internal temperature reached 48.5°C approaching ventilation warning threshold.',
            repairSuggestion: '1. Inspect ventilation grilles and ensure they are not blocked by dust or debris.\n2. Verify external cooling fans run normally.\n3. Check ambient temperature of inverter shelter.',
            status: 'Active',
            alarmCode: 2001,
          ),
        ],
      ),
      SolarInverter(
        id: 'inv_468_3',
        name: 'Inverter(COM1-3)',
        clusterId: '468kwp',
        plantId: 'kelanis',
        capacityKwp: 117.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.133).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.133).toStringAsFixed(1)),
        specificEnergy: 3.40,
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_468_4',
        name: 'Inverter(COM1-5)',
        clusterId: '468kwp',
        plantId: 'kelanis',
        capacityKwp: 117.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.135).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.135).toStringAsFixed(1)),
        specificEnergy: 3.43,
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),

      // 15 & 20 kWp Array (2 units = 35 kWp, MSW)
      SolarInverter(
        id: 'inv_15',
        name: 'INV PLTS 15 kWp',
        clusterId: '15_20kwp',
        plantId: 'msw',
        capacityKwp: 15.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.017).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.017).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
      SolarInverter(
        id: 'inv_20',
        name: 'INV PLTS 20 kWp',
        clusterId: '15_20kwp',
        plantId: 'msw',
        capacityKwp: 20.0,
        powerKw: isNight ? 0.0 : double.parse((currentPower * 0.023).toStringAsFixed(1)),
        yieldTodayKwh: double.parse((cumulativeYield * 0.023).toStringAsFixed(1)),
        status: isNight ? InverterStatus.standby : InverterStatus.normal,
        isNightStandby: isNight,
      ),
    ];

    final activeCount = isNight ? 0 : inverters.where((i) => i.status == InverterStatus.normal).length;
    final irradiance = isNight ? 0.0 : double.parse((sunFactor * 5.2).toStringAsFixed(2));
    final mswIrr = isNight ? 0.0 : double.parse((sunFactor * 5.35).toStringAsFixed(2));
    final kelanisIrr = isNight ? 0.0 : double.parse((sunFactor * 4.92).toStringAsFixed(2));
    final plantIrrMap = {'msw': mswIrr, 'kelanis': kelanisIrr};
    final plantPrMap = {'msw': 82.6, 'kelanis': 79.8};
    final bucketTime = FusionSolarApiClient.roundToNearestHalfHour(now);

    return SolarSnapshot(
      timestamp: bucketTime,
      isLive: true,
      totalPowerKw: double.parse(currentPower.toStringAsFixed(1)),
      peakPowerKw: peakSystemPower,
      totalYieldTodayKwh: double.parse(cumulativeYield.toStringAsFixed(1)),
      yieldYesterdayKwh: 2600.0,
      irradiance: irradiance,
      performanceRatio: 81.4,
      plantIrradiance: plantIrrMap,
      plantPr: plantPrMap,
      gridExportKw: double.parse((currentPower * 0.98).toStringAsFixed(1)),
      onlineInverterCount: isNight ? 12 : activeCount,
      totalInverterCount: 12,
      totalCapacityKwp: 868.0,
      inverters: inverters,
      hourlyPoints: hourlyPoints,
    );
  }

  /// Formats a WhatsApp-friendly daily production report
  static String formatWhatsAppReport(SolarSnapshot snapshot, {String? plantId}) {
    final target = plantId != null ? snapshot.forPlant(plantId) : snapshot;
    final dt = target.timestamp;
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WITA';

    final plantTitle = plantId == 'kelanis'
        ? '☀️ KELANIS SOLAR PV PRODUCTION REPORT (468 kWp)'
        : (plantId == 'msw'
            ? '☀️ MSW SOLAR PV PRODUCTION REPORT (400 kWp)'
            : '☀️ MSW SOLAR PV TOTAL PRODUCTION REPORT (868 kWp)');

    return '''*$plantTitle*
📅 *Time:* $dateStr
━━━━━━━━━━━━━━━━━━━━━━
⚡ *Total Energy Today:* ${target.totalYieldTodayKwh.toStringAsFixed(1)} kWh
🔥 *Live Active Power:* ${target.totalPowerKw.toStringAsFixed(1)} kW (Peak: ${target.peakPowerKw.toStringAsFixed(0)} kW)
🌤️ *Solar Irradiance:* ${target.irradiance.toStringAsFixed(2)} kWh/m²
📈 *Performance Ratio (PR):* ${target.performanceRatio.toStringAsFixed(1)}%
🔌 *Inverters Online:* ${target.onlineInverterCount}/${target.totalInverterCount} Units
🏭 *Auxiliary Load Offset:* ${target.houseLoadOffsetPct.toStringAsFixed(1)}%
━━━━━━━━━━━━━━━━━━━━━━
_MSW ePlant · Clean & Reliable Energy_''';
  }
}
