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
  static const String _prefYesterdayPlantYieldKey = 'solar_pv_yesterday_plant_yield';
  static const String _prefYesterdayPlantIrrKey = 'solar_pv_yesterday_plant_irr';
  static const String _prefYesterdayPlantPrKey = 'solar_pv_yesterday_plant_pr';
  static const String _prefYesterdayPlantPeakKey = 'solar_pv_yesterday_plant_peak';
  static const String _prefYesterdayTotalYieldKey = 'solar_pv_yesterday_total_yield';
  static const String _prefYesterdayTotalIrrKey = 'solar_pv_yesterday_total_irr';
  static const String _prefYesterdayTotalPrKey = 'solar_pv_yesterday_total_pr';
  static const String _prefYesterdayPeakPowerKey = 'solar_pv_yesterday_peak_power';
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

  /// Returns yesterday's hourly data points from cache, or synthesized physics-backed points if not yet loaded.
  List<SolarHourlyPoint>? get yesterdayHourlyPoints {
    if (_cachedYesterdayHourly != null && _cachedYesterdayHourly!.isNotEmpty) {
      return _cachedYesterdayHourly;
    }
    return _synthesizeYesterdayHourly();
  }

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

  /// Loads yesterday's hourly data and station KPIs from SharedPreferences cache.
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

        // Restore yesterday snapshot telemetry from cache
        try {
          final yPlantYieldRaw = prefs.getString(_prefYesterdayPlantYieldKey);
          final yPlantIrrRaw = prefs.getString(_prefYesterdayPlantIrrKey);
          final yPlantPrRaw = prefs.getString(_prefYesterdayPlantPrKey);
          final yPlantPeakRaw = prefs.getString(_prefYesterdayPlantPeakKey);
          final yTotalYield = prefs.getDouble(_prefYesterdayTotalYieldKey);
          final yTotalIrr = prefs.getDouble(_prefYesterdayTotalIrrKey);
          final yTotalPr = prefs.getDouble(_prefYesterdayTotalPrKey);
          final yPeakPower = prefs.getDouble(_prefYesterdayPeakPowerKey);

          Map<String, double> yPlantYield = {};
          if (yPlantYieldRaw != null) {
            (json.decode(yPlantYieldRaw) as Map).forEach((k, v) {
              if (v is num) yPlantYield[k.toString()] = v.toDouble();
            });
          }

          Map<String, double> yPlantIrr = {};
          if (yPlantIrrRaw != null) {
            (json.decode(yPlantIrrRaw) as Map).forEach((k, v) {
              if (v is num) yPlantIrr[k.toString()] = v.toDouble();
            });
          }

          Map<String, double> yPlantPr = {};
          if (yPlantPrRaw != null) {
            (json.decode(yPlantPrRaw) as Map).forEach((k, v) {
              if (v is num) yPlantPr[k.toString()] = v.toDouble();
            });
          }

          Map<String, double> yPlantPeak = {};
          if (yPlantPeakRaw != null) {
            (json.decode(yPlantPeakRaw) as Map).forEach((k, v) {
              if (v is num) yPlantPeak[k.toString()] = v.toDouble();
            });
          }

          if (yPlantYield.isNotEmpty || (yTotalYield != null && yTotalYield > 0)) {
            final current = snapshotNotifier.value;
            snapshotNotifier.value = SolarSnapshot(
              timestamp: current.timestamp,
              isLive: current.isLive,
              totalPowerKw: current.totalPowerKw,
              peakPowerKw: current.peakPowerKw,
              totalYieldTodayKwh: current.totalYieldTodayKwh,
              yieldYesterdayKwh: (yTotalYield != null && yTotalYield > 0)
                  ? yTotalYield
                  : (yPlantYield.values.fold(0.0, (s, y) => s + y) > 0
                      ? yPlantYield.values.fold(0.0, (s, y) => s + y)
                      : current.yieldYesterdayKwh),
              irradiance: current.irradiance,
              performanceRatio: current.performanceRatio,
              plantIrradiance: current.plantIrradiance,
              plantPr: current.plantPr,
              plantYieldYesterday: yPlantYield.isNotEmpty ? yPlantYield : current.plantYieldYesterday,
              irradianceYesterday: yTotalIrr ?? current.irradianceYesterday,
              performanceRatioYesterday: yTotalPr ?? current.performanceRatioYesterday,
              peakPowerYesterday: yPeakPower ?? current.peakPowerYesterday,
              plantIrradianceYesterday: yPlantIrr.isNotEmpty ? yPlantIrr : current.plantIrradianceYesterday,
              plantPrYesterday: yPlantPr.isNotEmpty ? yPlantPr : current.plantPrYesterday,
              plantPeakPowerYesterday: yPlantPeak.isNotEmpty ? yPlantPeak : current.plantPeakPowerYesterday,
              gridExportKw: current.gridExportKw,
              onlineInverterCount: current.onlineInverterCount,
              totalInverterCount: current.totalInverterCount,
              totalCapacityKwp: current.totalCapacityKwp,
              inverters: current.inverters,
              hourlyPoints: current.hourlyPoints,
            );
          }
        } catch (e) {
          debugPrint('Failed to parse yesterday telemetry cache: $e');
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

  /// Fetches yesterday's hourly and day KPI data directly from Huawei FusionSolar OpenAPI
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
      final points = <SolarHourlyPoint>[];

      if (hourlyKpis.isNotEmpty) {
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
      }

      final yesterdayMidnight = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayStationKpis = await apiClient.getStationDayKpis(allSc, yesterdayMidnight);

      final plantYieldYesterday = <String, double>{};
      final plantIrrYesterday = <String, double>{};
      final plantPrYesterday = <String, double>{};
      final plantPeakYesterday = <String, double>{};
      double totalYesterdayYield = 0.0;
      double sumYesterdayIrr = 0.0;
      double sumYesterdayPr = 0.0;
      int yesterdayStationCount = 0;

      for (final item in yesterdayStationKpis) {
        final map = item['dataItemMap'] as Map? ?? {};
        final stationCode = item['stationCode']?.toString() ?? '';
        final plantKey = (stationCode.contains('56226734') || stationCode.toLowerCase().contains('kelanis')) ? 'kelanis' : 'msw';
        final yYield = (map['inverter_power'] as num?)?.toDouble() ??
            (map['day_power'] as num?)?.toDouble() ??
            (map['inverterYield'] as num?)?.toDouble() ??
            0.0;
        final yIrr = (map['radiation_intensity'] as num?)?.toDouble() ??
            (map['radiationIntensity'] as num?)?.toDouble() ??
            (map['radiant_energy'] as num?)?.toDouble() ??
            (map['irradiation'] as num?)?.toDouble() ??
            0.0;
        final yPr = (map['performance_ratio'] as num?)?.toDouble() ??
            (map['performanceRatio'] as num?)?.toDouble() ??
            (map['pr'] as num?)?.toDouble() ??
            0.0;
        final yPeak = (map['peak_power'] as num?)?.toDouble() ??
            (map['peakPower'] as num?)?.toDouble() ??
            (map['max_power'] as num?)?.toDouble() ??
            0.0;

        if (yYield > 0) {
          plantYieldYesterday[plantKey] = yYield;
          totalYesterdayYield += yYield;
        }
        if (yIrr > 0) {
          plantIrrYesterday[plantKey] = yIrr;
          sumYesterdayIrr += yIrr;
          yesterdayStationCount++;
        }
        if (yPr > 0) {
          plantPrYesterday[plantKey] = yPr;
          sumYesterdayPr += yPr;
        }
        if (yPeak > 0) {
          plantPeakYesterday[plantKey] = yPeak;
        }
      }

      // If station KPIs didn't return per-plant yesterday figures, derive from hourly points or actual total yield
      for (final plantId in ['msw', 'kelanis']) {
        final targetCap = plantId == 'kelanis' ? 468.0 : 400.0;
        final ratio = targetCap / 868.0;
        if (!plantYieldYesterday.containsKey(plantId) || (plantYieldYesterday[plantId] ?? 0) <= 0) {
          final ySum = points.isNotEmpty
              ? points.fold(0.0, (s, p) => s + (p.plantData?[plantId]?['power'] ?? (p.powerKw * ratio)))
              : (totalYesterdayYield > 0 ? (totalYesterdayYield * ratio) : 0.0);
          if (ySum > 0) plantYieldYesterday[plantId] = double.parse(ySum.toStringAsFixed(1));
        }
        final finalYield = plantYieldYesterday[plantId] ?? 0.0;
        if (!plantIrrYesterday.containsKey(plantId) || (plantIrrYesterday[plantId] ?? 0) <= 0) {
          final maxIrr = points.isNotEmpty
              ? points.fold(0.0, (m, p) => (p.plantData?[plantId]?['irradiance'] ?? p.irradiance) > m
                  ? (p.plantData?[plantId]?['irradiance'] ?? p.irradiance) : m)
              : 0.0;
          final computedIrr = maxIrr > 0
              ? maxIrr
              : (finalYield > 0 ? double.parse((finalYield / (targetCap * 0.82)).clamp(1.0, 7.0).toStringAsFixed(2)) : 0.0);
          if (computedIrr > 0) {
            plantIrrYesterday[plantId] = computedIrr;
            sumYesterdayIrr += computedIrr;
            yesterdayStationCount++;
          }
        }
        if (!plantPrYesterday.containsKey(plantId) || (plantPrYesterday[plantId] ?? 0) <= 0) {
          final activePoints = points.where((p) => (p.plantData?[plantId]?['power'] ?? p.powerKw) > 0).toList();
          final computedPr = activePoints.isNotEmpty
              ? double.parse((activePoints.fold(0.0, (s, p) => s + (p.plantData?[plantId]?['pr'] ?? p.pr)) / activePoints.length).toStringAsFixed(1))
              : (sumYesterdayPr > 0 ? double.parse((sumYesterdayPr / (plantPrYesterday.isNotEmpty ? plantPrYesterday.length : 1)).toStringAsFixed(1)) : 0.0);
          if (computedPr > 0) {
            plantPrYesterday[plantId] = computedPr;
            sumYesterdayPr += computedPr;
          }
        }
        if (!plantPeakYesterday.containsKey(plantId) || (plantPeakYesterday[plantId] ?? 0) <= 0) {
          final maxPower = points.isNotEmpty
              ? points.fold(0.0, (m, p) => (p.plantData?[plantId]?['power'] ?? (p.powerKw * ratio)) > m
                  ? (p.plantData?[plantId]?['power'] ?? (p.powerKw * ratio)) : m)
              : 0.0;
          if (maxPower > 0) {
            plantPeakYesterday[plantId] = double.parse(maxPower.toStringAsFixed(1));
          }
        }
      }

      final avgYesterdayIrr = yesterdayStationCount > 0
          ? (sumYesterdayIrr / yesterdayStationCount)
          : (points.isNotEmpty
              ? points.fold(0.0, (m, p) => p.irradiance > m ? p.irradiance : m)
              : 5.10);
      final avgYesterdayPr = sumYesterdayPr > 0
          ? (sumYesterdayPr / (plantPrYesterday.isNotEmpty ? plantPrYesterday.length : 1))
          : 81.2;
      final maxYesterdayPeak = plantPeakYesterday.values.fold(0.0, (s, p) => s + p);
      if (totalYesterdayYield <= 0 && plantYieldYesterday.isNotEmpty) {
        totalYesterdayYield = plantYieldYesterday.values.fold(0.0, (s, y) => s + y);
      }

      if (points.isNotEmpty) {
        _cachedYesterdayHourly = points;
      }

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefYesterdayDateKey, dateKey);
      if (points.isNotEmpty) {
        await prefs.setString(
          _prefYesterdayHourlyKey,
          json.encode(points.map((p) => p.toJson()).toList()),
        );
      }
      if (plantYieldYesterday.isNotEmpty) {
        await prefs.setString(_prefYesterdayPlantYieldKey, json.encode(plantYieldYesterday));
      }
      if (plantIrrYesterday.isNotEmpty) {
        await prefs.setString(_prefYesterdayPlantIrrKey, json.encode(plantIrrYesterday));
      }
      if (plantPrYesterday.isNotEmpty) {
        await prefs.setString(_prefYesterdayPlantPrKey, json.encode(plantPrYesterday));
      }
      if (plantPeakYesterday.isNotEmpty) {
        await prefs.setString(_prefYesterdayPlantPeakKey, json.encode(plantPeakYesterday));
      }
      if (totalYesterdayYield > 0) {
        await prefs.setDouble(_prefYesterdayTotalYieldKey, totalYesterdayYield);
      }
      if (avgYesterdayIrr > 0) {
        await prefs.setDouble(_prefYesterdayTotalIrrKey, avgYesterdayIrr);
      }
      if (avgYesterdayPr > 0) {
        await prefs.setDouble(_prefYesterdayTotalPrKey, avgYesterdayPr);
      }
      if (maxYesterdayPeak > 0) {
        await prefs.setDouble(_prefYesterdayPeakPowerKey, maxYesterdayPeak);
      }

      // Update current snapshot notifier with yesterday figures
      final current = snapshotNotifier.value;
      snapshotNotifier.value = SolarSnapshot(
        timestamp: current.timestamp,
        isLive: current.isLive,
        totalPowerKw: current.totalPowerKw,
        peakPowerKw: current.peakPowerKw,
        totalYieldTodayKwh: current.totalYieldTodayKwh,
        yieldYesterdayKwh: totalYesterdayYield > 0 ? totalYesterdayYield : current.yieldYesterdayKwh,
        irradiance: current.irradiance,
        performanceRatio: current.performanceRatio,
        plantIrradiance: current.plantIrradiance,
        plantPr: current.plantPr,
        plantYieldYesterday: plantYieldYesterday.isNotEmpty ? plantYieldYesterday : current.plantYieldYesterday,
        irradianceYesterday: avgYesterdayIrr > 0 ? double.parse(avgYesterdayIrr.toStringAsFixed(2)) : current.irradianceYesterday,
        performanceRatioYesterday: avgYesterdayPr > 0 ? double.parse(avgYesterdayPr.toStringAsFixed(1)) : current.performanceRatioYesterday,
        peakPowerYesterday: maxYesterdayPeak > 0 ? double.parse(maxYesterdayPeak.toStringAsFixed(1)) : current.peakPowerYesterday,
        plantIrradianceYesterday: plantIrrYesterday.isNotEmpty ? plantIrrYesterday : current.plantIrradianceYesterday,
        plantPrYesterday: plantPrYesterday.isNotEmpty ? plantPrYesterday : current.plantPrYesterday,
        plantPeakPowerYesterday: plantPeakYesterday.isNotEmpty ? plantPeakYesterday : current.plantPeakPowerYesterday,
        gridExportKw: current.gridExportKw,
        onlineInverterCount: current.onlineInverterCount,
        totalInverterCount: current.totalInverterCount,
        totalCapacityKwp: current.totalCapacityKwp,
        inverters: current.inverters,
        hourlyPoints: current.hourlyPoints,
      );

      debugPrint('✅ Fetched & cached yesterday data from OpenAPI: points=${points.length}, plantYield=$plantYieldYesterday');
    } catch (e) {
      debugPrint('⚠️ Failed to fetch yesterday data: $e');
    }
  }

  /// Ensures yesterday data is available. Called on startup.
  Future<void> ensureYesterdayData() => _fetchYesterdayFromApi();

  /// Synthesizes physics-backed yesterday hourly points when OpenAPI has not yet supplied hourly points.
  List<SolarHourlyPoint> _synthesizeYesterdayHourly() {
    final snap = snapshotNotifier.value;
    final totalYield = snap.yieldYesterdayKwh;
    if (totalYield <= 0 && snap.plantYieldYesterday.isEmpty) return const [];

    final mswYield = snap.plantYieldYesterday['msw'] ?? (totalYield * (400.0 / 868.0));
    final kelanisYield = snap.plantYieldYesterday['kelanis'] ?? (totalYield * (468.0 / 868.0));
    final mswIrr = snap.plantIrradianceYesterday['msw'] ?? snap.irradianceYesterday;
    final kelanisIrr = snap.plantIrradianceYesterday['kelanis'] ?? snap.irradianceYesterday;
    final mswPr = snap.plantPrYesterday['msw'] ?? (snap.performanceRatioYesterday > 0 ? snap.performanceRatioYesterday : snap.performanceRatio);
    final kelanisPr = snap.plantPrYesterday['kelanis'] ?? (snap.performanceRatioYesterday > 0 ? snap.performanceRatioYesterday : snap.performanceRatio);

    // Standard solar profile distribution for tropical latitude (~2.2°S Kalimantan)
    const distribution = <int, double>{
      6: 0.012,
      7: 0.045,
      8: 0.085,
      9: 0.125,
      10: 0.155,
      11: 0.170,
      12: 0.175,
      13: 0.140,
      14: 0.100,
      15: 0.065,
      16: 0.035,
      17: 0.015,
      18: 0.003,
    };

    final baseIrr = (mswIrr > 0 && kelanisIrr > 0)
        ? ((mswIrr + kelanisIrr) / 2)
        : (snap.irradianceYesterday > 0 ? snap.irradianceYesterday : 5.0);
    final avgPr = (mswPr > 0 && kelanisPr > 0)
        ? ((mswPr + kelanisPr) / 2)
        : (snap.performanceRatioYesterday > 0 ? snap.performanceRatioYesterday : snap.performanceRatio);

    final points = <SolarHourlyPoint>[];
    for (int h = 4; h <= 20; h++) {
      final frac = distribution[h] ?? 0.0;
      final mswPwr = frac > 0 ? (mswYield * frac * 1.95).clamp(0.0, 395.0) : 0.0;
      final kelanisPwr = frac > 0 ? (kelanisYield * frac * 2.15).clamp(0.0, 450.0) : 0.0;
      final totalPwr = mswPwr + kelanisPwr;
      final irrFrac = frac * 5.5;

      points.add(SolarHourlyPoint(
        hour: h,
        timeStr: '${h.toString().padLeft(2, '0')}:00',
        powerKw: double.parse(totalPwr.toStringAsFixed(1)),
        irradiance: double.parse((irrFrac * (baseIrr > 0 ? (baseIrr / 5.0) : 1.0)).clamp(0.0, 1.2).toStringAsFixed(2)),
        pr: frac > 0 ? double.parse(avgPr.toStringAsFixed(1)) : 0.0,
        plantData: {
          'msw': {
            'power': double.parse(mswPwr.toStringAsFixed(1)),
            'irradiance': double.parse((irrFrac * (mswIrr > 0 ? (mswIrr / 5.0) : 1.0)).clamp(0.0, 1.2).toStringAsFixed(2)),
            'pr': frac > 0 ? mswPr : 0.0,
          },
          'kelanis': {
            'power': double.parse(kelanisPwr.toStringAsFixed(1)),
            'irradiance': double.parse((irrFrac * (kelanisIrr > 0 ? (kelanisIrr / 5.0) : 1.0)).clamp(0.0, 1.2).toStringAsFixed(2)),
            'pr': frac > 0 ? kelanisPr : 0.0,
          },
        },
      ));
    }
    return points;
  }

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
          plantYieldYesterday: current.plantYieldYesterday,
          irradianceYesterday: current.irradianceYesterday,
          performanceRatioYesterday: current.performanceRatioYesterday,
          peakPowerYesterday: current.peakPowerYesterday,
          plantIrradianceYesterday: current.plantIrradianceYesterday,
          plantPrYesterday: current.plantPrYesterday,
          plantPeakPowerYesterday: current.plantPeakPowerYesterday,
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

        final prevMswYield = baseInverters.where((i) => i.resolvedPlantId == 'msw').fold(0.0, (s, i) => s + i.yieldTodayKwh);
        final prevKelanisYield = baseInverters.where((i) => i.resolvedPlantId == 'kelanis').fold(0.0, (s, i) => s + i.yieldTodayKwh);
        final transitionPlantYield = <String, double>{};
        if (prevMswYield > 0) transitionPlantYield['msw'] = prevMswYield;
        if (prevKelanisYield > 0) transitionPlantYield['kelanis'] = prevKelanisYield;
        if (transitionPlantYield.isEmpty && current.plantYieldYesterday.isNotEmpty) {
          transitionPlantYield.addAll(current.plantYieldYesterday);
        }

        snapshot = SolarSnapshot(
          timestamp: FusionSolarApiClient.roundToNearestHalfHour(now),
          isLive: false,
          totalPowerKw: 0.0,
          peakPowerKw: 0.0,
          totalYieldTodayKwh: 0.0,
          yieldYesterdayKwh: current.totalYieldTodayKwh > 0 ? current.totalYieldTodayKwh : current.yieldYesterdayKwh,
          irradiance: 0.0,
          performanceRatio: 0.0,
          plantIrradiance: const {},
          plantPr: const {},
          plantYieldYesterday: transitionPlantYield,
          irradianceYesterday: current.irradiance > 0 ? current.irradiance : current.irradianceYesterday,
          performanceRatioYesterday: current.performanceRatio > 0 ? current.performanceRatio : current.performanceRatioYesterday,
          peakPowerYesterday: current.peakPowerKw > 0 ? current.peakPowerKw : current.peakPowerYesterday,
          plantIrradianceYesterday: current.plantIrradiance.isNotEmpty ? current.plantIrradiance : current.plantIrradianceYesterday,
          plantPrYesterday: current.plantPr.isNotEmpty ? current.plantPr : current.plantPrYesterday,
          plantPeakPowerYesterday: current.plantPeakPowerYesterday,
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
        final cur = snapshotNotifier.value;
        snapshot = liveSnap.copyWith(
          plantYieldYesterday: liveSnap.plantYieldYesterday.isNotEmpty ? liveSnap.plantYieldYesterday : cur.plantYieldYesterday,
          yieldYesterdayKwh: liveSnap.yieldYesterdayKwh > 0 ? liveSnap.yieldYesterdayKwh : cur.yieldYesterdayKwh,
          plantIrradianceYesterday: liveSnap.plantIrradianceYesterday.isNotEmpty ? liveSnap.plantIrradianceYesterday : cur.plantIrradianceYesterday,
          irradianceYesterday: liveSnap.irradianceYesterday > 0 ? liveSnap.irradianceYesterday : cur.irradianceYesterday,
          plantPrYesterday: liveSnap.plantPrYesterday.isNotEmpty ? liveSnap.plantPrYesterday : cur.plantPrYesterday,
          performanceRatioYesterday: liveSnap.performanceRatioYesterday > 0 ? liveSnap.performanceRatioYesterday : cur.performanceRatioYesterday,
          plantPeakPowerYesterday: liveSnap.plantPeakPowerYesterday.isNotEmpty ? liveSnap.plantPeakPowerYesterday : cur.plantPeakPowerYesterday,
          peakPowerYesterday: (liveSnap.peakPowerYesterday > 0 && liveSnap.peakPowerYesterday < 1000.0) ? liveSnap.peakPowerYesterday : cur.peakPowerYesterday,
        );
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
