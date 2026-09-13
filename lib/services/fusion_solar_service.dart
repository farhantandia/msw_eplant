import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';

class FusionSolarService {
  static const String _prefLastSyncKey = 'solar_pv_last_sync_ms';
  static const String _prefValidSnapshotKey = 'solar_pv_last_valid_snapshot';
  static const String _prefYesterdayHourlyKey = 'solar_pv_yesterday_hourly';
  static const String _prefYesterdayDateKey = 'solar_pv_yesterday_date';
  static final FusionSolarService instance = FusionSolarService._internal();

  FusionSolarService._internal();

  static bool enableAutoSync = true;

  DatabaseReference? _solarLatestRef;
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

  /// Cached yesterday hourly points, loaded from SharedPreferences on startup.
  List<SolarHourlyPoint>? _cachedYesterdayHourly;

  /// Returns yesterday's hourly data points from cache.
  /// Returns null if data has not been fetched/cached yet.
  List<SolarHourlyPoint>? get yesterdayHourlyPoints => _cachedYesterdayHourly;

  /// Initializes listeners to Firebase RTDB `/solar_pv/latest`, restores local cache,
  /// fetches yesterday data, and starts auto-sync.
  void init({bool? autoSync}) {
    // 1. Immediately restore last valid snapshot from local SharedPreferences cache
    // This ensures data is available instantly (before async RTDB / API calls complete)
    _restoreSnapshotFromLocalCache();

    try {
      final rtdb = FirebaseDatabase.instance;
      _solarLatestRef = rtdb.ref('solar_pv/latest');

      // Attempt immediate cache restoration from Firebase RTDB
      _solarLatestRef?.once().then((event) {
        if (event.snapshot.value is Map) {
          try {
            final snap = SolarSnapshot.fromJson(event.snapshot.value as Map);
            // Only accept RTDB data if it has valid inverters (not stale empty data)
            if (snap.inverters.isNotEmpty) {
              snapshotNotifier.value = snap;
              debugPrint('✅ Restored actual solar snapshot from Firebase cache');
            }
          } catch (_) {}
        }
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

    // 2. Load yesterday's hourly data from cache
    _loadYesterdayCacheFromPrefs();

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

  /// Restores the last valid snapshot from SharedPreferences (synchronous-like via async init).
  void _restoreSnapshotFromLocalCache() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = prefs.getString(_prefValidSnapshotKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final jsonMap = json.decode(raw) as Map;
          final cached = SolarSnapshot.fromJson(jsonMap);
          // Only restore if it has meaningful data
          if (cached.inverters.isNotEmpty || cached.totalYieldTodayKwh > 0) {
            snapshotNotifier.value = cached;
            debugPrint('✅ Restored solar snapshot from local SharedPreferences cache');
          }
        } catch (e) {
          debugPrint('Failed to restore local snapshot cache: $e');
        }
      }
    }).catchError((_) {});
  }

  /// Loads yesterday's hourly data from SharedPreferences cache.
  void _loadYesterdayCacheFromPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final expectedDateKey = _formatDateKey(yesterday);
      final cachedDate = prefs.getString(_prefYesterdayDateKey);

      if (cachedDate == expectedDateKey) {
        final raw = prefs.getString(_prefYesterdayHourlyKey);
        if (raw != null && raw.isNotEmpty) {
          try {
            final list = json.decode(raw) as List;
            _cachedYesterdayHourly = list
                .whereType<Map>()
                .map((m) => SolarHourlyPoint.fromJson(m))
                .toList();
            debugPrint('✅ Loaded ${_cachedYesterdayHourly!.length} yesterday hourly points from cache');
          } catch (e) {
            debugPrint('Failed to parse yesterday hourly cache: $e');
          }
        }
      } else {
        // Cache is stale or missing — fetch from API (skip in automated widget tests)
        final isWidgetTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
        if (!isWidgetTest) {
          _fetchYesterdayFromApi();
        }
      }
    }).catchError((_) {});
  }

  /// Fetches yesterday's hourly KPI data directly from Huawei FusionSolar OpenAPI
  /// and caches it to SharedPreferences.
  Future<void> _fetchYesterdayFromApi() async {
    final isWidgetTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isWidgetTest) return;

    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateKey = _formatDateKey(yesterday);

      // Get station codes from the API client (same as used in fetchLatestSnapshot)
      final stations = await apiClient.getStationList();
      if (stations.isEmpty) return;

      final allSc = stations
          .map((s) => s['stationCode']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(',');

      if (allSc.isEmpty) return;

      final hourlyKpis = await apiClient.getKpiStationHour(allSc, yesterday);
      if (hourlyKpis.isEmpty) return;

      final points = <SolarHourlyPoint>[];
      final sortedHours = hourlyKpis.keys.toList()..sort();
      for (final h in sortedHours) {
        if (h < 4 || h > 20) continue;
        final hData = hourlyKpis[h]!;
        final hIrr = (hData['radiation_intensity'] as num?)?.toDouble() ?? 0.0;
        final hPower = (hData['inverter_power'] as num?)?.toDouble() ?? 0.0;
        final hPr = (hData['performance_ratio'] as num?)?.toDouble() ?? 0.0;

        points.add(SolarHourlyPoint(
          hour: h,
          timeStr: '${h.toString().padLeft(2, '0')}:00',
          powerKw: double.parse(hPower.toStringAsFixed(1)),
          irradiance: double.parse(hIrr.toStringAsFixed(2)),
          pr: double.parse(hPr.toStringAsFixed(1)),
          plantData: {
            'msw': {
              'irradiance': (hData['irr_msw'] as num?)?.toDouble() ?? 0.0,
              'power': (hData['power_msw'] as num?)?.toDouble() ?? 0.0,
              'pr': (hData['pr_msw'] as num?)?.toDouble() ?? 0.0,
            },
            'kelanis': {
              'irradiance': (hData['irr_kelanis'] as num?)?.toDouble() ?? 0.0,
              'power': (hData['power_kelanis'] as num?)?.toDouble() ?? 0.0,
              'pr': (hData['pr_kelanis'] as num?)?.toDouble() ?? 0.0,
            },
          },
        ));
      }

      if (points.isNotEmpty) {
        _cachedYesterdayHourly = points;

        // Persist to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefYesterdayDateKey, dateKey);
        await prefs.setString(
          _prefYesterdayHourlyKey,
          json.encode(points.map((p) => p.toJson()).toList()),
        );
        debugPrint('✅ Fetched & cached ${points.length} yesterday hourly points from OpenAPI');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch yesterday hourly data: $e');
    }
  }

  /// Ensures yesterday data is available. Called on startup.
  Future<void> ensureYesterdayData() => _fetchYesterdayFromApi();

  static String _formatDateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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
        if (snap.inverters.isNotEmpty) {
          snapshotNotifier.value = snap;
        }
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
  /// 5. In night hours, preserves today's yield, peak, hourly profile and inverter data — only zeroes active power.
  /// 6. Pushes live snapshot to Firebase RTDB `/solar_pv/latest`.
  /// 7. Never falls back to mock data during daytime – always retains last known actual snapshot.
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

      // Determine if we're still on the same calendar day as the last valid snapshot
      final isSameDay = current.timestamp.year == now.year &&
          current.timestamp.month == now.month &&
          current.timestamp.day == now.day;

      // Get valid inverters: use current if available, otherwise fallback to default inventory
      final baseInverters = current.inverters.isNotEmpty
          ? current.inverters
          : SolarInverter.defaultInventory();

      if (isSameDay) {
        // ── Same day (20:00 - 23:59): Preserve all daytime data ──
        // Keep yield, peak, PR, hourlyPoints. Only zero active power.
        final standbyInverters = baseInverters.map((inv) {
          return SolarInverter(
            id: inv.id,
            name: inv.name,
            clusterId: inv.clusterId,
            plantId: inv.plantId,
            capacityKwp: inv.capacityKwp,
            powerKw: 0.0,
            yieldTodayKwh: inv.yieldTodayKwh, // Preserve today's yield
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
          peakPowerKw: current.peakPowerKw, // Preserve
          totalYieldTodayKwh: current.totalYieldTodayKwh, // Preserve
          yieldYesterdayKwh: current.yieldYesterdayKwh, // Preserve
          irradiance: 0.0,
          performanceRatio: current.performanceRatio, // Preserve
          plantIrradiance: current.plantIrradiance, // Preserve
          plantPr: current.plantPr, // Preserve
          gridExportKw: 0.0,
          onlineInverterCount: 0,
          totalInverterCount: standbyInverters.length,
          totalCapacityKwp: current.totalCapacityKwp > 0 ? current.totalCapacityKwp : 868.0,
          inverters: standbyInverters,
          hourlyPoints: current.hourlyPoints, // Preserve today's trend
        );
      } else {
        // ── New day (00:00 - 03:59): Reset for new day ──
        // Move today's yield to yesterday, start fresh
        final standbyInverters = baseInverters.map((inv) {
          return SolarInverter(
            id: inv.id,
            name: inv.name,
            clusterId: inv.clusterId,
            plantId: inv.plantId,
            capacityKwp: inv.capacityKwp,
            powerKw: 0.0,
            yieldTodayKwh: 0.0, // Reset for new day
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
          peakPowerKw: 0.0,
          totalYieldTodayKwh: 0.0,
          yieldYesterdayKwh: current.totalYieldTodayKwh, // Yesterday's yield
          irradiance: 0.0,
          performanceRatio: 0.0,
          plantIrradiance: const {},
          plantPr: const {},
          gridExportKw: 0.0,
          onlineInverterCount: 0,
          totalInverterCount: standbyInverters.length,
          totalCapacityKwp: current.totalCapacityKwp > 0 ? current.totalCapacityKwp : 868.0,
          inverters: standbyInverters,
          hourlyPoints: const [], // New day, no hourly data yet
        );
      }
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
        // Never fall back to mock data during daytime –
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

    // Push to Firebase RTDB (latest only, no history node)
    await _pushToFirebase(snapshot, now);

    // Save valid daytime snapshot to local cache
    if (snapshot.inverters.isNotEmpty) {
      _saveSnapshotToLocalCache(snapshot);
    }

    snapshotNotifier.value = snapshot;
    return snapshot;
  }

  /// Saves a valid snapshot to SharedPreferences for instant restoration on next app launch.
  void _saveSnapshotToLocalCache(SolarSnapshot snapshot) {
    SharedPreferences.getInstance().then((prefs) {
      try {
        prefs.setString(_prefValidSnapshotKey, json.encode(snapshot.toJson()));
      } catch (_) {}
    }).catchError((_) {});
  }

  /// Pushes latest snapshot to Firebase RTDB `/solar_pv/latest`.
  /// Includes guard: never overwrite with empty/zero data when valid data exists.
  Future<void> _pushToFirebase(SolarSnapshot snapshot, DateTime now) async {
    try {
      // Guard: don't push if inverters are empty (corrupted/initial state)
      if (snapshot.inverters.isEmpty) {
        debugPrint('⚠️ Skipping RTDB push: snapshot has no inverters');
        return;
      }

      // Guard: don't overwrite valid RTDB data with zero yield at night
      // (when we know daytime data was previously stored)
      if (snapshot.totalYieldTodayKwh <= 0.0 && !FusionSolarApiClient.isWithinOperatingHours(now)) {
        final current = snapshotNotifier.value;
        if (current.totalYieldTodayKwh > 0.0) {
          debugPrint('⚠️ Skipping RTDB push: would overwrite valid yield with 0 at night');
          return;
        }
      }

      // Write latest snapshot to solar_pv/latest
      if (_solarLatestRef != null) {
        try {
          await _solarLatestRef!.set(snapshot.toJson());
        } catch (e) {
          debugPrint('Firebase solarLatestRef push error: $e');
        }
      }
    } catch (e) {
      debugPrint('Firebase push error: $e');
    }
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
