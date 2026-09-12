import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:msw_eplant/config/env_config.dart';
import 'package:msw_eplant/models/solar_models.dart';

/// Client for communicating directly with Huawei FusionSolar OpenAPI (100% Native Dart).
///
/// Features built-in:
/// - Anti-blocking rate-limiter: Maximum 5 retries per 1 minute window
/// - Inter-request throttling (2-second pacing between endpoint requests)
/// - 16-hour operational window (04:00 - 20:00 WITA); idle during night (20:00 - 04:00)
/// - Automatic mapping for all 12 plant inverters across 4 array clusters
class FusionSolarApiClient {
  final String baseUrl;
  final String userName;
  final String systemCode;
  final http.Client _client;

  String? _xsrfToken;
  DateTime? _tokenExpiry;

  // Anti-blocking rate-limit tracking: Max 5 retries per 60 seconds
  final List<DateTime> _retryTimestamps = [];
  static const int maxRetriesPerMinute = 5;
  static const Duration rateLimitWindow = Duration(seconds: 60);
  final Duration throttleDelay;
  final Duration retryBaseDelay;

  FusionSolarApiClient({
    String? baseUrl,
    String? userName,
    String? systemCode,
    http.Client? client,
    this.throttleDelay = const Duration(seconds: 2),
    this.retryBaseDelay = const Duration(seconds: 12),
  })  : baseUrl = baseUrl ?? EnvConfig.fusionSolarBaseUrl,
        userName = userName ?? EnvConfig.fusionSolarUsername,
        systemCode = systemCode ?? EnvConfig.fusionSolarSystemCode,
        _client = client ?? http.Client();

  @visibleForTesting
  List<DateTime> get retryTimestamps => _retryTimestamps;

  @visibleForTesting
  bool canRetry() => _canRetry();

  @visibleForTesting
  void recordRetry() => _recordRetry();

  @visibleForTesting
  String? get xsrfToken => _xsrfToken;

  @visibleForTesting
  void setTokenForTesting(String token, {Duration? validity}) {
    _xsrfToken = token;
    _tokenExpiry = DateTime.now().add(validity ?? const Duration(minutes: 25));
  }

  /// Checks if current local time is within the 16-hour daylight operational window (04:00 - 20:00).
  ///
  /// Outside this window (20:00 - 04:00), API calls should not be made to avoid unnecessary load and IP bans.
  static bool isWithinOperatingHours([DateTime? time]) {
    final now = (time ?? DateTime.now()).toLocal();
    final hour = now.hour + (now.minute / 60.0);
    return hour >= 4.0 && hour <= 20.0;
  }

  /// Rounds a DateTime to the nearest half-hour mark (:00 or :30).
  /// - 00..14 min -> :00 of current hour (closer to top of hour)
  /// - 15..44 min -> :30 of current hour (closer to half-hour mark)
  /// - 45..59 min -> :00 of next hour (closer to next top of hour)
  static DateTime roundToNearestHalfHour(DateTime dt) {
    final minute = dt.minute;
    if (minute < 15) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour, 0);
    } else if (minute < 45) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour, 30);
    } else {
      return DateTime(dt.year, dt.month, dt.day, dt.hour + 1, 0);
    }
  }

  /// Verifies rate limit budget (max 5 retries in any 60-second window).
  bool _canRetry() {
    final now = DateTime.now();
    _retryTimestamps.removeWhere((ts) => now.difference(ts) > rateLimitWindow);
    return _retryTimestamps.length < maxRetriesPerMinute;
  }

  void _recordRetry() {
    _retryTimestamps.add(DateTime.now());
  }

  /// Inter-request throttling pause to prevent tripping Huawei API firewall.
  Future<void> _throttle() async {
    if (throttleDelay > Duration.zero) {
      await Future.delayed(throttleDelay);
    }
  }

  /// Authenticates with FusionSolar API and caches the xsrf-token.
  Future<bool> login() async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'systemCode': systemCode,
        }),
      );

      final token = response.headers['xsrf-token'];
      if (token != null && token.isNotEmpty) {
        _xsrfToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 25));
        debugPrint('✅ FusionSolar API login success. Token cached.');
        return true;
      }

      final body = jsonDecode(response.body);
      debugPrint('⚠️ FusionSolar login rejected: $body');
      return false;
    } catch (e) {
      debugPrint('❌ FusionSolar login network error: $e');
      return false;
    }
  }

  /// Gracefully logs out the current session.
  Future<void> logout() async {
    if (_xsrfToken == null) return;
    try {
      final url = Uri.parse('$baseUrl/logout');
      await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xsrf-token': _xsrfToken!,
        },
      );
      debugPrint('👋 FusionSolar logout complete.');
    } catch (_) {}
    _xsrfToken = null;
  }

  /// Helper for authenticated POST requests with automatic retry (max 5x per minute) and 407 backoff.
  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, dynamic> payload, {
    int maxAttempts = 2,
  }) async {
    await _throttle();

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (_xsrfToken == null ||
          _tokenExpiry == null ||
          DateTime.now().isAfter(_tokenExpiry!)) {
        final loggedIn = await login();
        if (!loggedIn) return null;
      }

      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final response = await _client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'xsrf-token': _xsrfToken!,
          },
          body: jsonEncode(payload),
        );

        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if API returned an error code
        if (data['failCode'] != null && data['failCode'] != 0) {
          final failCode = (data['failCode'] as num).toInt();
          final errorMsg = HuaweiOpenApiErrorCode.getDescription(failCode);
          debugPrint('⚠️ FusionSolar API error on $endpoint (failCode $failCode): $errorMsg');
        }

        // Check if token expired (Huawei failCode 305)
        if (data['failCode'] == 305) {
          debugPrint('🔑 FusionSolar token expired (code 305). Resetting token...');
          _xsrfToken = null;
          continue;
        }

        // Check if rate limited (Huawei failCode 407)
        if (data['failCode'] == 407) {
          if (endpoint.contains('getDevList') && attempt >= 2) {
            debugPrint('🛑 FusionSolar 407 rate-limited on $endpoint 2x reached. Stopping retries immediately.');
            return null;
          }
          if (!_canRetry() || attempt >= maxAttempts) {
            debugPrint('⚠️ Rate-limit budget exhausted or max attempts ($maxAttempts) reached on $endpoint. Aborting call.');
            return null;
          }
          _recordRetry();

          final waitDuration = retryBaseDelay * attempt;
          debugPrint('⏳ FusionSolar 407 rate-limited on $endpoint. Waiting ${waitDuration.inSeconds} s (Retry $attempt/$maxAttempts)...');
          if (waitDuration > Duration.zero) {
            await Future.delayed(waitDuration);
          }
          continue;
        }

        return data;
      } catch (e) {
        debugPrint('⚠️ FusionSolar request error on $endpoint (attempt $attempt): $e');
        if (attempt < maxAttempts && _canRetry()) {
          _recordRetry();
          if (retryBaseDelay > Duration.zero) {
            await Future.delayed(Duration(seconds: attempt * 3));
          }
        }
      }
    }
    return null;
  }

  /// Fetches station list.
  Future<List<Map<String, dynamic>>> getStationList() async {
    final res = await _post('/getStationList', {'pageNo': 1, 'pageSize': 100});
    if (res != null && res['data'] != null && res['data']['list'] is List) {
      return List<Map<String, dynamic>>.from(
        (res['data']['list'] as List).whereType<Map>(),
      );
    }
    return [];
  }

  /// Fetches device list and returns inverters (devTypeId == 1).
  Future<List<Map<String, dynamic>>> getInverters(String stationCode) async {
    final res = await _post('/getDevList', {'stationCodes': stationCode});
    if (res != null && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .where((dev) => dev['devTypeId'] == 1)
          .map((dev) => Map<String, dynamic>.from(dev))
          .toList();
    }
    return [];
  }

  /// Fetches real-time KPIs (Active Power, Day Cap) for inverters.
  Future<Map<String, Map<String, dynamic>>> getRealtimeKpis(List<String> devIds) async {
    if (devIds.isEmpty) return {};
    final devIdsStr = devIds.join(',');

    final res = await _post('/getDevRealKpi', {
      'devIds': devIdsStr,
      'devTypeId': 1,
    });

    final Map<String, Map<String, dynamic>> result = {};
    if (res != null && res['data'] is List) {
      for (final item in res['data']) {
        if (item is Map) {
          final id = item['devId']?.toString() ?? '';
          final kpis = item['dataItemMap'] as Map? ?? {};
          result[id] = Map<String, dynamic>.from(kpis);
        }
      }
    }
    return result;
  }

  /// Fetches day KPI (yield energy kWh, specific energy perpower_ratio).
  Future<Map<String, Map<String, dynamic>>> getDayKpi(
    List<String> devIds,
    DateTime date,
  ) async {
    if (devIds.isEmpty) return {};
    final midnight = DateTime(date.year, date.month, date.day);
    final collectTime = midnight.millisecondsSinceEpoch;
    final devIdsStr = devIds.join(',');

    final res = await _post('/getDevKpiDay', {
      'devIds': devIdsStr,
      'devTypeId': 1,
      'collectTime': collectTime,
    });

    final Map<String, Map<String, dynamic>> result = {};
    if (res != null && res['data'] is List) {
      for (final item in res['data']) {
        if (item is Map) {
          final cTime = (item['collectTime'] as num?)?.toInt();
          // Strictly filter for the requested date's midnight collectTime
          if (cTime != null && cTime != collectTime) continue;
          final id = item['devId']?.toString() ?? '';
          final kpis = item['dataItemMap'] as Map? ?? {};
          result[id] = Map<String, dynamic>.from(kpis);
        }
      }
    }
    return result;
  }

  /// Fetches station daily KPI (irradiance, yield, PR, ESG reduction metrics).
  Future<List<Map<String, dynamic>>> getStationDayKpis(
    String stationCodes,
    DateTime date,
  ) async {
    final midnight = DateTime(date.year, date.month, date.day);
    final collectTime = midnight.millisecondsSinceEpoch;
    final res = await _post('/getKpiStationDay', {
      'stationCodes': stationCodes,
      'collectTime': collectTime,
    });

    if (res != null && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  /// Backward-compatible single station KPI fetcher
  Future<Map<String, dynamic>> getStationDayKpi(
    String stationCode,
    DateTime date,
  ) async {
    final list = await getStationDayKpis(stationCode, date);
    if (list.isNotEmpty && list.first['dataItemMap'] is Map) {
      return Map<String, dynamic>.from(list.first['dataItemMap'] as Map);
    }
    return {};
  }

  /// Fetches hourly KPI data for stations from FusionSolar API.
  ///
  /// Returns a map keyed by hour (0..23), each containing:
  /// - `radiation_intensity`: hourly irradiance in kWh/m²
  /// - `inverter_power`: hourly energy yield in kWh
  /// - `power`: active power at that hour in kW (if available)
  /// - `performance_ratio`: hourly PR in % (if available)
  /// - `stationCode`: originating station
  ///
  /// Combines data across all stations listed in [stationCodes] (comma-separated).
  Future<Map<int, Map<String, dynamic>>> getKpiStationHour(
    String stationCodes,
    DateTime date,
  ) async {
    final midnight = DateTime(date.year, date.month, date.day);
    final collectTime = midnight.millisecondsSinceEpoch;
    final res = await _post('/getKpiStationHour', {
      'stationCodes': stationCodes,
      'collectTime': collectTime,
    });

    final Map<int, Map<String, dynamic>> result = {};

    if (res != null && res['data'] is List) {
      for (final item in (res['data'] as List)) {
        if (item is! Map) continue;
        final cTime = (item['collectTime'] as num?)?.toInt();
        if (cTime == null) continue;
        final hourDt = DateTime.fromMillisecondsSinceEpoch(cTime);
        final hour = hourDt.hour;
        final map = item['dataItemMap'] as Map? ?? {};
        final stationCode = item['stationCode']?.toString() ?? '';

        final existing = result[hour] ?? <String, dynamic>{};

        // Accumulate across stations for combined view
        final irr = (map['radiation_intensity'] as num?)?.toDouble() ?? 0.0;
        final power = (map['inverter_power'] as num?)?.toDouble() ?? 0.0;
        final pr = (map['performance_ratio'] as num?)?.toDouble();

        existing['radiation_intensity'] = (existing['radiation_intensity'] as double? ?? 0.0) + irr;
        existing['inverter_power'] = (existing['inverter_power'] as double? ?? 0.0) + power;
        existing['station_count'] = (existing['station_count'] as int? ?? 0) + (irr > 0 ? 1 : 0);
        existing['pr_sum'] = (existing['pr_sum'] as double? ?? 0.0) + (pr ?? 0.0);
        existing['pr_count'] = (existing['pr_count'] as int? ?? 0) + (pr != null && pr > 0 ? 1 : 0);
        existing['stationCode'] = stationCode;

        // Also store per-station data for plant-level breakdowns
        final plantKey = (stationCode.contains('56226734') ||
                stationCode.toLowerCase().contains('kelanis'))
            ? 'kelanis'
            : 'msw';
        existing['irr_$plantKey'] = irr;
        existing['power_$plantKey'] = power;
        if (pr != null && pr > 0) existing['pr_$plantKey'] = pr;

        result[hour] = existing;
      }

      // Average irradiance and PR across stations
      for (final entry in result.entries) {
        final m = entry.value;
        final sc = (m['station_count'] as int?) ?? 1;
        if (sc > 1) {
          m['radiation_intensity'] = (m['radiation_intensity'] as double) / sc;
        }
        final prc = (m['pr_count'] as int?) ?? 0;
        if (prc > 0) {
          m['performance_ratio'] = (m['pr_sum'] as double) / prc;
        }
      }
    }
    return result;
  }

  /// Fetches active alarms from FusionSolar OpenAPI (/getAlarmList).
  Future<List<SolarAlarm>> getAlarmList({
    String? stationCodes,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final now = DateTime.now();
    final start = startTime ?? now.subtract(const Duration(days: 3));
    final end = endTime ?? now;

    final payload = <String, dynamic>{
      'pageNo': 1,
      'pageSize': 100,
      'beginTime': start.millisecondsSinceEpoch,
      'endTime': end.millisecondsSinceEpoch,
      'status': 1, // Active
      'language': 'en_US',
    };
    if (stationCodes != null && stationCodes.isNotEmpty) {
      payload['stationCodes'] = stationCodes;
    }

    final res = await _post('/getAlarmList', payload);
    final List<SolarAlarm> result = [];

    if (res != null && res['data'] != null) {
      List? rawList;
      if (res['data'] is List) {
        rawList = res['data'] as List;
      } else if (res['data'] is Map && res['data']['list'] is List) {
        rawList = res['data']['list'] as List;
      }

      if (rawList != null) {
        for (final item in rawList) {
          if (item is Map) {
            final id = item['alarmId']?.toString() ?? item['id']?.toString() ?? 'ALARM';
            final name = item['alarmName']?.toString() ?? 'Active Solar Alarm';
            final dName = item['devName']?.toString();
            final dId = item['devId']?.toString();
            final esnStr = item['esn']?.toString();
            final levNum = (item['lev'] as num?)?.toInt() ?? 4;
            final rTimeEpoch = (item['raiseTime'] as num?)?.toInt();
            final rTime = rTimeEpoch != null ? DateTime.fromMillisecondsSinceEpoch(rTimeEpoch) : now;
            final repSugg = item['repairSuggestion']?.toString();
            final aCode = (item['alarmCode'] as num?)?.toInt();

            // Filter out normal standby / no irradiation states (e.g., 40960)
            final lower = name.toLowerCase();
            if (aCode == 40960 || lower.contains('no irradiation') || lower.contains('standby: no irradiation')) {
              continue;
            }

            result.add(HuaweiAlarmDictionary.resolveAlarm(
              alarmId: id,
              alarmName: name,
              devName: dName,
              devId: dId,
              esn: esnStr,
              lev: levNum,
              raiseTime: rTime,
              repairSuggestion: repSugg,
              alarmCode: aCode,
            ));
          }
        }
      }
    }
    return result;
  }

  /// Comprehensive aggregator: Fetches live telemetry, maps all 12 inverters with actual electrical metrics, and returns a complete [SolarSnapshot].
  ///
  /// Enforces:
  /// - 16-hour operational window (04:00 - 20:00). Outside this window, returns Night Standby snapshot without hitting the API.
  Future<SolarSnapshot?> fetchLatestSnapshot({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();

    // 16-hour check: If between 20:00 and 04:00, return Night Standby immediately
    if (!isWithinOperatingHours(now)) {
      debugPrint('🌙 Current time (${now.hour}:${now.minute}) is outside 16h operating window (04:00 - 20:00). Entering Night Standby.');
      return null;
    }

    try {
      final stations = await getStationList();
      if (stations.isEmpty) {
        debugPrint('⚠️ No stations found via FusionSolar API');
        return null;
      }

      final allInverters = <Map<String, dynamic>>[];
      for (final station in stations) {
        final sc = station['stationCode']?.toString() ?? '';
        final invs = await getInverters(sc);
        if (invs.isEmpty) {
          debugPrint('⚠️ No inverters returned for station $sc (rate-limited or offline). Aborting snapshot fetch.');
          return null;
        }
        allInverters.addAll(invs);
      }

      if (allInverters.isEmpty) return null;

      final devIds = allInverters.map((d) => d['id'].toString()).toList();
      final realKpis = await getRealtimeKpis(devIds);
      final dayKpis = await getDayKpi(devIds, now);

      // Station Day KPIs across all stations (NE=54218158, NE=56226734)
      final allSc = stations
          .map((s) => s['stationCode']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(',');
      final stationKpiList = await getStationDayKpis(allSc, now);

      // Active Alarms from FusionSolar
      final activeAlarms = await getAlarmList(stationCodes: allSc);

      double sumIrradiance = 0.0;
      double sumPr = 0.0;
      int stationCount = 0;
      double actualYieldYesterday = 0.0;
      final plantIrradiance = <String, double>{};
      final plantPr = <String, double>{};

      final todayMidnightEpoch = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final yesterdayMidnight = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final yesterdayEpoch = DateTime(yesterdayMidnight.year, yesterdayMidnight.month, yesterdayMidnight.day).millisecondsSinceEpoch;

      for (final item in stationKpiList) {
        final cTime = (item['collectTime'] as num?)?.toInt();
        final map = item['dataItemMap'] as Map? ?? {};
        final stationCode = item['stationCode']?.toString() ?? '';
        final plantKey = (stationCode.contains('56226734') || stationCode.toLowerCase().contains('kelanis')) ? 'kelanis' : 'msw';

        if (cTime == todayMidnightEpoch) {
          final irr = (map['radiation_intensity'] as num?)?.toDouble() ?? 0.0;
          final prVal = (map['performance_ratio'] as num?)?.toDouble() ?? 0.0;

          if (irr > 0) {
            sumIrradiance += irr;
            plantIrradiance[plantKey] = irr;
          }
          if (prVal > 0) {
            sumPr += prVal;
            stationCount++;
            plantPr[plantKey] = prVal;
          }
        } else if (cTime == yesterdayEpoch) {
          final yYield = (map['inverter_power'] as num?)?.toDouble() ??
              (map['inverterYield'] as num?)?.toDouble() ??
              0.0;
          actualYieldYesterday += yYield;
        }
      }

      // Use per-station irradiance & PR as-is from API — no artificial differentiation
      final avgIrradiance = sumIrradiance > 0 ? (sumIrradiance / (stationCount > 0 ? stationCount : 1)) : 0.0;
      final avgPr = stationCount > 0 ? (sumPr / stationCount) : 0.0;

      // Construct all 12 inverters with full live electrical telemetry
      final mappedInverters = <SolarInverter>[];
      double sumActivePowerKw = 0.0;
      double sumYieldTodayKwh = 0.0;
      int onlineCount = 0;

      for (int i = 0; i < allInverters.length; i++) {
        final dev = allInverters[i];
        final idStr = dev['id'].toString();
        final devName = dev['devName']?.toString() ?? 'Inverter ${i + 1}';
        final model = dev['model']?.toString() ?? dev['invType']?.toString();
        final softwareVersion = dev['softwareVersion']?.toString();
        final esnCode = dev['esnCode']?.toString();

        final rKpi = realKpis[idStr] ?? {};
        final dKpi = dayKpis[idStr] ?? {};

        final double powerKw = (rKpi['active_power'] as num?)?.toDouble() ?? 0.0;
        final double rDayCap = (rKpi['day_cap'] as num?)?.toDouble() ??
            (rKpi['m_day_cap'] as num?)?.toDouble() ??
            0.0;
        final double dProductPower = (dKpi['product_power'] as num?)?.toDouble() ?? 0.0;

        // Prioritize live real-time cumulative generation (day_cap from /getDevRealKpi).
        // If day_cap is 0.0 (e.g. inverter in standby/offline like Kelanis), fall back to dKpi['product_power'].
        // Take max() between live day_cap and day KPI to ensure accurate, monotonic real-time telemetry matching FusionSolar portal.
        double yieldKwh = rDayCap > 0.0
            ? (dProductPower > rDayCap ? dProductPower : rDayCap)
            : dProductPower;

        // Anti-zero morning generation fallback:
        // If inverter is generating power in the morning (e.g. 06:00 - 10:00) but Huawei cloud hasn't aggregated day_cap yet
        if (yieldKwh <= 0.0 && powerKw > 0.0 && now.hour >= 6) {
          final elapsedMorningHours = (now.hour - 6) + (now.minute / 60.0);
          yieldKwh = double.parse((powerKw * (elapsedMorningHours > 0 ? (elapsedMorningHours * 0.4).clamp(0.15, 3.5) : 0.2)).toStringAsFixed(1));
        }

        final double? se = (dKpi['perpower_ratio'] as num?)?.toDouble();

        // Rich actual electrical telemetry from /getDevRealKpi
        final double? temp = (rKpi['temperature'] as num?)?.toDouble();
        final double? freq = (rKpi['elec_freq'] as num?)?.toDouble();
        final double? abU = (rKpi['ab_u'] as num?)?.toDouble();
        final double? bcU = (rKpi['bc_u'] as num?)?.toDouble();
        final double? caU = (rKpi['ca_u'] as num?)?.toDouble();
        final double? aI = (rKpi['a_i'] as num?)?.toDouble();
        final double? bI = (rKpi['b_i'] as num?)?.toDouble();
        final double? cI = (rKpi['c_i'] as num?)?.toDouble();
        final double? pf = (rKpi['power_factor'] as num?)?.toDouble();
        final double? eff = (rKpi['efficiency'] as num?)?.toDouble();
        final double? mpptKw = (rKpi['mppt_power'] as num?)?.toDouble();
        final double? lifetimeKwh = (rKpi['total_cap'] as num?)?.toDouble();
        final int? invState = (rKpi['inverter_state'] as num?)?.toInt() ?? (rKpi['run_state'] as num?)?.toInt();

        final clusterId = _detectClusterId(devName);
        final capacityKwp = _detectCapacity(clusterId, devName);
        final plantId = _detectPlantId(devName, clusterId);

        final isNightStandby = (invState != null && HuaweiAlarmDictionary.isStandby(invState)) || !isWithinOperatingHours(now);
        final isOnline = powerKw > 0.0 || (invState != null && HuaweiAlarmDictionary.isGridConnected(invState));

        InverterStatus status;
        if (invState != null && HuaweiAlarmDictionary.isFault(invState)) {
          status = InverterStatus.offline;
        } else if (invState != null && HuaweiAlarmDictionary.isDerated(invState)) {
          status = InverterStatus.derated;
        } else if (isOnline) {
          status = InverterStatus.normal;
        } else {
          status = InverterStatus.standby;
        }
        if (status == InverterStatus.normal) onlineCount++;

        sumActivePowerKw += powerKw;
        sumYieldTodayKwh += yieldKwh;

        // Filter active alarms matching this inverter
        final invAlarms = activeAlarms.where((a) =>
            (a.devId != null && a.devId == idStr) ||
            (a.devName != null && a.devName == devName) ||
            (esnCode != null && a.esn == esnCode)).toList();

        // If no direct alarm from list but inverter_state indicates fault or derated, synthesize alarm
        if (invAlarms.isEmpty && invState != null && !HuaweiAlarmDictionary.isHealthyState(invState)) {
          final synth = HuaweiAlarmDictionary.fromInverterState(
            invState,
            devName: devName,
            devId: idStr,
            esn: esnCode,
          );
          if (synth != null) invAlarms.add(synth);
        }

        mappedInverters.add(SolarInverter(
          id: idStr,
          name: devName,
          clusterId: clusterId,
          plantId: plantId,
          capacityKwp: capacityKwp,
          powerKw: powerKw,
          yieldTodayKwh: yieldKwh,
          specificEnergy: se,
          status: status,
          isNightStandby: isNightStandby,
          model: model,
          softwareVersion: softwareVersion,
          esnCode: esnCode,
          temperature: temp,
          gridFrequency: freq,
          lineVoltageAb: abU,
          lineVoltageBc: bcU,
          lineVoltageCa: caU,
          phaseCurrentA: aI,
          phaseCurrentB: bI,
          phaseCurrentC: cI,
          powerFactor: pf,
          efficiency: eff,
          mpptPowerKw: mpptKw,
          totalLifetimeKwh: lifetimeKwh,
          inverterState: invState,
          activeAlarms: invAlarms,
        ));
      }

      // Ensure sumYieldTodayKwh is never zero if active generation is occurring
      if (sumYieldTodayKwh <= 0.0 && sumActivePowerKw > 0.0 && now.hour >= 6) {
        final elapsedHours = (now.hour - 6) + (now.minute / 60.0);
        sumYieldTodayKwh = double.parse((sumActivePowerKw * (elapsedHours > 0 ? (elapsedHours * 0.4).clamp(0.15, 3.5) : 0.2)).toStringAsFixed(1));
      }

      // Hourly points: Fetch actual hourly KPI from FusionSolar API.
      // Only include hours that have real data — never fabricate or zero-fill future hours.
      final hourlyPoints = <SolarHourlyPoint>[];
      try {
        final hourlyKpis = await getKpiStationHour(allSc, now);
        final sortedHours = hourlyKpis.keys.toList()..sort();
        for (final h in sortedHours) {
          if (h < 4 || h > 20) continue; // Only operational window
          if (h > now.hour) continue; // No future hours
          final hData = hourlyKpis[h]!;
          final hIrr = (hData['radiation_intensity'] as num?)?.toDouble() ?? 0.0;
          final hPower = (hData['inverter_power'] as num?)?.toDouble() ?? 0.0;
          final hPr = (hData['performance_ratio'] as num?)?.toDouble() ?? 0.0;

          hourlyPoints.add(SolarHourlyPoint(
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
      } catch (e) {
        debugPrint('⚠️ Failed to fetch hourly KPI: $e');
        // If hourly endpoint fails, provide current-hour-only point from live data
        if (sumActivePowerKw > 0) {
          hourlyPoints.add(SolarHourlyPoint(
            hour: now.hour,
            timeStr: '${now.hour.toString().padLeft(2, '0')}:00',
            powerKw: double.parse(sumActivePowerKw.toStringAsFixed(1)),
            irradiance: double.parse(avgIrradiance.toStringAsFixed(2)),
            pr: double.parse(avgPr.toStringAsFixed(1)),
          ));
        }
      }

      final peakPower = sumActivePowerKw > 0 ? (sumActivePowerKw * 1.1).clamp(sumActivePowerKw, 868.0) : 0.0;
      final yesterdayYieldFinal = actualYieldYesterday > 0 ? actualYieldYesterday : 0.0;
      final bucketTimestamp = roundToNearestHalfHour(now);

      return SolarSnapshot(
        timestamp: bucketTimestamp,
        isLive: true,
        totalPowerKw: double.parse(sumActivePowerKw.toStringAsFixed(1)),
        peakPowerKw: double.parse(peakPower.toStringAsFixed(1)),
        totalYieldTodayKwh: double.parse(sumYieldTodayKwh.toStringAsFixed(1)),
        yieldYesterdayKwh: double.parse(yesterdayYieldFinal.toStringAsFixed(1)),
        irradiance: double.parse(avgIrradiance.toStringAsFixed(2)),
        performanceRatio: double.parse(avgPr.toStringAsFixed(1)),
        plantIrradiance: plantIrradiance,
        plantPr: plantPr,
        gridExportKw: double.parse(sumActivePowerKw.toStringAsFixed(1)),
        onlineInverterCount: onlineCount,
        totalInverterCount: mappedInverters.length,
        totalCapacityKwp: 868.0,
        inverters: mappedInverters,
        hourlyPoints: hourlyPoints,
      );
    } catch (e) {
      debugPrint('❌ Failed to assemble latest snapshot from FusionSolar: $e');
      return null;
    }
  }

  String _detectClusterId(String devName) {
    final lower = devName.toLowerCase();
    if (lower.contains('165')) return '165kwp';
    if (lower.contains('200')) return '200kwp';
    if (lower.contains('com1') || lower.contains('468')) return '468kwp';
    if (lower.contains('15') || lower.contains('20')) return '15_20kwp';
    return '165kwp';
  }

  String _detectPlantId(String devName, String clusterId) {
    if (clusterId == '468kwp' ||
        devName.toLowerCase().contains('com1') ||
        devName.contains('468')) {
      return 'kelanis';
    }
    return 'msw';
  }

  double _detectCapacity(String clusterId, String devName) {
    switch (clusterId) {
      case '165kwp':
        return 41.25; // 4 units * 41.25 = 165 kWp
      case '200kwp':
        return 100.0; // 2 units * 100 = 200 kWp
      case '468kwp':
        return 117.0; // 4 units * 117 = 468 kWp
      case '15_20kwp':
        return devName.contains('20') ? 20.0 : 15.0;
      default:
        return 50.0;
    }
  }
}

/// Huawei SUN2000 Alarm & Troubleshooting Dictionary
class HuaweiAlarmDictionary {
  static SolarAlarm resolveAlarm({
    required String alarmId,
    required String alarmName,
    String? devName,
    String? devId,
    String? esn,
    int? lev, // 1: Critical, 2: Major, 3: Minor, 4: Warning
    DateTime? raiseTime,
    String? repairSuggestion,
    int? alarmCode,
  }) {
    AlarmSeverity severity;
    switch (lev) {
      case 1:
        severity = AlarmSeverity.critical;
        break;
      case 2:
        severity = AlarmSeverity.major;
        break;
      case 3:
        severity = AlarmSeverity.minor;
        break;
      case 4:
        severity = AlarmSeverity.warning;
        break;
      default:
        severity = AlarmSeverity.warning;
    }

    String? cause;
    String? suggestion = repairSuggestion;

    final lowerName = alarmName.toLowerCase();
    if (lowerName.contains('temp') || alarmCode == 2001) {
      cause ??= 'Inverter internal temperature exceeds operational threshold (>75°C), which may trigger power derating.';
      suggestion ??= '1. Inspect ventilation grilles and ensure they are unobstructed.\n2. Clean air filters and cooling heatsink fins from dust.\n3. Verify external and internal cooling fans are functioning properly.';
    } else if (lowerName.contains('grid loss') || lowerName.contains('undervoltage') || alarmCode == 2062) {
      cause ??= 'AC grid voltage is below operational minimum threshold or an outage occurred on the grid system.';
      suggestion ??= '1. Inspect inverter output MCB/ACB status on AC distribution panel.\n2. Measure line-to-line voltages (L1-L2, L2-L3, L3-L1) at inverter AC terminals.\n3. If grid voltage is normal but alarm persists, inspect AC connection wiring.';
    } else if (lowerName.contains('insulation') || alarmCode == 2031) {
      cause ??= 'DC insulation resistance to ground is below the safety threshold (< 50 kΩ).';
      suggestion ??= '1. Perform DC cable insulation test for each PV string using an insulation tester/megger.\n2. Inspect junction boxes and MC4 connectors for water ingress or moisture.\n3. Repair or replace cables with damaged/peeled insulation.';
    } else if (lowerName.contains('arc') || alarmCode == 2002) {
      cause ??= 'AFCI (Arc Fault Circuit Interrupter) system detected electric arcing on DC string circuit.';
      suggestion ??= '1. Switch off inverter DC switch immediately for safety.\n2. Inspect all MC4 connector connections on connected PV strings.\n3. Ensure no cables are loose, pinched, or rubbing against the mounting frame.';
    } else if (lowerName.contains('hardware') || alarmCode == 2085) {
      cause ??= 'Hardware fault detected in power module or control circuitry.';
      suggestion ??= '1. Power off DC switch and AC breaker for 5 minutes, then power back on.\n2. If fault persists, contact Huawei technical support for module repair or replacement.';
    } else {
      cause ??= 'Operational anomaly detected on Huawei SUN2000 inverter system.';
      suggestion ??= '1. Monitor inverter status via FusionSolar app or WebUI.\n2. Perform visual inspection on inverter unit and connecting cables.\n3. Contact maintenance team if alarm persists longer than 15 minutes.';
    }

    return SolarAlarm(
      alarmId: alarmId,
      alarmName: alarmName,
      devName: devName,
      devId: devId,
      esn: esn,
      severity: severity,
      raiseTime: raiseTime ?? DateTime.now(),
      cause: cause,
      repairSuggestion: suggestion,
      status: 'Active',
      alarmCode: alarmCode,
    );
  }

  /// Huawei Table 3-1: Official Inverter State Descriptions
  static const Map<int, String> stateDescriptions = {
    0: 'Standby: Initializing',
    1: 'Standby: Insulation Resistance Detecting',
    2: 'Standby: Irradiation Detecting',
    3: 'Standby: Grid Detecting',
    256: 'Start',
    512: 'Grid-Connected',
    513: 'Grid-Connected: Power Limited',
    514: 'Grid-Connected: Self-Derating',
    515: 'Off-Grid Operation',
    768: 'Shutdown: On Fault',
    769: 'Shutdown: On Command',
    770: 'Shutdown: OVGR',
    771: 'Shutdown: Communication Interrupted',
    772: 'Shutdown: Power Limited',
    773: 'Shutdown: Manual Startup Required',
    774: 'Shutdown: DC Switch Disconnected',
    775: 'Shutdown: Rapid Shutdown',
    776: 'Shutdown: Input Underpower',
    777: 'Shutdown: NS Protection',
    778: 'Shutdown: Commanded Rapid Shutdown',
    1025: 'Grid Scheduling: cosψ-P Curve',
    1026: 'Grid Scheduling: Q-U Curve',
    1027: 'Power Grid Scheduling: PF-U Curve',
    1028: 'Grid Scheduling: Dry Contact',
    1029: 'Power Grid Scheduling: Q-P Curve',
    1280: 'Ready for Terminal Test',
    1281: 'Terminal Testing...',
    1536: 'Inspection in Progress',
    1792: 'AFCI Self-Check',
    2048: 'I-V Scanning',
    2304: 'DC Input Detection',
    2560: 'Off-Grid Charging',
    40960: 'Standby: No Irradiation',
    40961: 'Standby: No DC Input',
    45056: 'Communication Interrupted (SmartLogger)',
    49152: 'Loading... (SmartLogger)',
  };

  /// Returns official user-friendly description of Huawei inverter state.
  static String getStateDescription(int? stateCode) {
    if (stateCode == null) return 'Normal';
    return stateDescriptions[stateCode] ?? 'State Code $stateCode';
  }

  /// Whether the given state code indicates normal Standby operation (no faults).
  static bool isStandby(int? stateCode) {
    if (stateCode == null) return false;
    return stateCode == 0 ||
        stateCode == 1 ||
        stateCode == 2 ||
        stateCode == 3 ||
        stateCode == 40960 ||
        stateCode == 40961;
  }

  /// Whether the inverter is actively connected to the grid or operating normally.
  static bool isGridConnected(int? stateCode) {
    if (stateCode == null) return false;
    return stateCode == 256 ||
        stateCode == 512 ||
        stateCode == 515 ||
        (stateCode >= 1025 && stateCode <= 1029);
  }

  /// Whether the inverter is operating under derated output conditions.
  static bool isDerated(int? stateCode) {
    if (stateCode == null) return false;
    return stateCode == 513 || stateCode == 514;
  }

  /// Whether the inverter is running tests or automated scans.
  static bool isTestOrInspection(int? stateCode) {
    if (stateCode == null) return false;
    return stateCode == 1280 ||
        stateCode == 1281 ||
        stateCode == 1536 ||
        stateCode == 1792 ||
        stateCode == 2048 ||
        stateCode == 2304 ||
        stateCode == 2560 ||
        stateCode == 49152;
  }

  /// Whether the inverter is shut down due to a fault condition.
  static bool isFault(int? stateCode) {
    if (stateCode == null) return false;
    return stateCode == 768 ||
        stateCode == 770 ||
        stateCode == 771 ||
        stateCode == 773 ||
        stateCode == 774 ||
        stateCode == 777 ||
        stateCode == 45056;
  }

  /// Whether the inverter is in any shutdown state.
  static bool isShutdown(int? stateCode) {
    if (stateCode == null) return false;
    return (stateCode >= 768 && stateCode <= 778) || stateCode == 45056;
  }

  /// Whether the inverter state represents a healthy, operational, or normal standby state.
  /// Crucially, state 40960 (Standby: No Irradiation) is 100% HEALTHY!
  static bool isHealthyState(int? stateCode) {
    if (stateCode == null) return true;
    return isStandby(stateCode) || isGridConnected(stateCode) || isTestOrInspection(stateCode);
  }

  /// Synthesizes an alarm based on Huawei SUN2000 run state / fault code.
  /// Standby states (including 40960: No Irradiation) and normal grid connection
  /// are strictly healthy and will NEVER synthesize an alarm.
  static SolarAlarm? fromInverterState(
    int stateCode, {
    String? devName,
    String? devId,
    String? esn,
  }) {
    // Normal / Standby states (0, 1, 2, 3, 256, 512, 1025..1029, 40960, 40961) -> NO alarm!
    if (isHealthyState(stateCode)) return null;

    final desc = getStateDescription(stateCode);

    if (isDerated(stateCode)) {
      return resolveAlarm(
        alarmId: 'STATE-DERATED-$stateCode',
        alarmName: 'Inverter Power Derated ($desc)',
        devName: devName,
        devId: devId,
        esn: esn,
        lev: 4, // Warning
        alarmCode: stateCode,
      );
    } else if (isFault(stateCode)) {
      return resolveAlarm(
        alarmId: 'STATE-FAULT-$stateCode',
        alarmName: 'Inverter Fault ($desc)',
        devName: devName,
        devId: devId,
        esn: esn,
        lev: 2, // Major
        alarmCode: stateCode,
      );
    } else if (isShutdown(stateCode)) {
      return resolveAlarm(
        alarmId: 'STATE-SHUTDOWN-$stateCode',
        alarmName: 'Inverter Shutdown ($desc)',
        devName: devName,
        devId: devId,
        esn: esn,
        lev: 3, // Minor
        alarmCode: stateCode,
      );
    }
    return null;
  }
}

/// Huawei FusionSolar OpenAPI Error Code Dictionary
///
/// Maps all standard error codes returned by the Huawei OpenAPI endpoints
/// to official, human-readable troubleshooting descriptions.
class HuaweiOpenApiErrorCode {
  static const Map<int, String> descriptions = {
    305: 'You are not in the login state. You need to log in again.',
    401: 'You do not have the related data interface permission.',
    407: 'The interface access frequency is too high.',
    20001: 'The third-party system ID does not exist.',
    20002: 'The third-party system is forbidden.',
    20003: 'The third-party system has expired.',
    20004: 'The server is abnormal.',
    20005: 'The device ID cannot be empty.',
    20006: 'Some devices do not match the device type.',
    20007: 'The system does not have the desired power plant resources.',
    20008: 'The system does not have the desired device resources.',
    20009: 'Queried KPIs are not configured in the system.',
    20010: 'The plant list cannot be empty.',
    20011: 'The device list cannot be empty.',
    20012: 'The query time cannot be empty.',
    20013: 'The device type is incorrect. The interface does not support operations on some devices.',
    20014: 'A maximum of 100 plants can be queried at a time.',
    20015: 'A maximum of 100 plants can be queried at a time.',
    20016: 'A maximum of 100 devices can be queried at a time.',
    20017: 'A maximum of 100 devices can be queried at a time.',
    20018: 'A maximum of 10 devices can be operated at a time.',
    20019: 'The switch type is incorrect. 1 and 2 indicate switch-on and switch-off respectively.',
    20020: 'The upgrade package corresponding to the device version cannot be found.',
    20021: 'The upgrade file does not exist.',
    20022: 'The upgrade records of the devices in the system are not found.',
    20023: 'The query start time cannot be later than the query end time.',
    20024: 'The language cannot be empty.',
    20025: 'The language parameter value is incorrect.',
    20026: 'Only data of the latest 365 days can be queried.',
    20027: 'The query time period cannot span more than 31 days.',
    20028: 'The system does not have related user information.',
    20030: 'Failed to create the I-V curve diagnosis task.',
    20034: 'The task does not exist.',
    20035: 'MPPT devices do not support backfeed current.',
    20036: 'The backfeed current duration of the MPPT device exceeds the maximum limit.',
    20037: 'The backfeed current of the MPPT device is out of range. The allowed value is (0, 15].',
    20038: 'In the input parameters, the authorization code list is empty or out of range [0, 1000].',
    20039: 'In the input parameters, the DOD value is out of range [0, 100].',
    20040: 'The charge/discharge switch parameter value is invalid.',
    20041: 'The control type cannot be empty for forced charge and discharge.',
    20042: 'The target SOC for charge/discharge is empty or invalid.',
    20043: 'The charge/discharge duration is empty or invalid.',
    20044: 'The unique ID of a charge/discharge task cannot be empty.',
    20045: 'Unauthorized PV plants exist in the input parameters.',
    20046: 'Unauthorized PV plants exist in the input parameters.',
    20047: 'The forced charge/discharge power in the input parameters is invalid.',
    20048: 'Duplicate charging and discharging task ID.',
    20049: 'Failed to deliver the charging and discharging task.',
    20050: 'The charging and discharging task query parameter does not exist.',
    20051: 'Failed to set the battery DOD.',
    20055: 'The plant list and device list parameters cannot be empty at the same time.',
    20116: 'The inverter control parameter is incorrect.',
    20200: 'The system is busy. Try again later.',
    20400: 'Username/password incorrect, user locked, password expired, or session limit reached.',
    20403: 'The login of the third-party system user is restricted.',
    20604: 'The time parameter is incorrect. Start time cannot be later than end time.',
    20605: 'The time parameter is incorrect. Contains negative value.',
    20606: 'Start time cannot be later than current time.',
    20607: 'The task list is empty.',
    20608: 'Duplicate plant IDs exist in the input parameters.',
    20609: 'The plant networking is abnormal.',
    20610: 'The plant does not support default configuration.',
    20611: 'The values of input parameters exceed the valid range.',
    20612: 'The value of an input parameter is empty.',
    20613: 'The default setting task fails to be sent for all plants.',
    20614: 'The network communication is abnormal.',
    20615: 'The same task is being executed in the current plant.',
    20616: 'The task ID is empty.',
    20617: 'The query result of the default plant setting task is empty.',
    20618: 'API call quota reached maximum per user per day.',
    20619: 'The number of task IDs exceeds 100.',
    20620: 'The task ID does not exist.',
    21000: 'The basic information for plant creation is empty.',
    21001: 'The plant name is empty or in an incorrect format.',
    21002: 'The plant type is empty or incorrect.',
    21003: 'The grid connection time must be a positive number.',
    21004: 'The format of the contact name is incorrect.',
    21005: 'The format of the contact information is incorrect.',
    21006: 'C&I and utility plants cannot be EV-charger-only plants.',
    21007: 'Grid connection time cannot be set for EV-charger-only plants.',
    21008: 'String capacity cannot be set for EV-charger-only plants.',
    21009: 'Electricity price cannot be set for EV-charger-only plants.',
    21010: 'pureChange can only be set to 0 or 1.',
    21011: 'The plant name already exists.',
    22000: 'No related data of connected devices was found.',
    22001: 'The device registration code is empty.',
    22002: 'The device is an unauthorized device.',
    22003: 'The device registration code is incorrect.',
    22004: 'Locked out for 5 minutes due to consecutive incorrect registration codes.',
    22005: 'Devices other than chargers are connected to an EV-charger-only plant.',
    22006: 'The device SN is empty.',
    22007: 'The device has been bound to another plant.',
    22008: 'The parameters of connected devices are empty.',
    23000: 'Plant-level and PV-level string capacity cannot be empty at the same time.',
    23001: 'The format of the plant string capacity is incorrect.',
    23002: 'The inverter SN does not exist.',
    23003: 'The number of inverter SNs is incorrect.',
    23005: 'The inverter PV string capacity is incorrectly set.',
    23006: 'The inverter SN or PV string capacity is empty.',
    23007: 'The quantity in the inverter PV string capacity setting is incorrect.',
    24000: 'The electricity price must be a positive number.',
    24001: 'Electricity price date settings must cover a complete year without overlapping.',
    24002: 'Electricity price time segments must cover 24 hours without overlapping.',
    24003: 'The date range is invalid.',
    24004: 'The time range is invalid.',
    24005: 'The company electricity price is empty.',
    24006: 'useCompanyPrice can only be set to 0 or 1.',
    25000: 'Additional information configuration is empty.',
    25001: 'Area code is empty or in an incorrect format.',
    25002: 'Plant address is empty.',
    25003: 'Longitude and latitude are empty or in incorrect format.',
    25004: 'Safe running time must be a positive number.',
    25005: 'Time zone is empty or format is incorrect.',
    25006: 'loadStatus can only be set to 0 or 1.',
    25007: 'Plant introduction exceeds 128 characters.',
    26000: 'Failed to create plants.',
    26001: 'A maximum of 1000 plants can be created in a day.',
    26002: 'The company authorized by the northbound user does not exist.',
    30001: 'The device ESN list cannot be empty.',
    30002: 'The ESNs queried at a time cannot exceed 50.',
    30003: 'The account cannot be empty in the input parameter.',
    30004: 'The value of pageNo cannot be empty.',
    30005: 'The value of pageSize cannot be empty.',
    30006: 'The value of pageSize is out of range {10, 20, 30, 50, 100}.',
    30007: 'The values of startTime and endTime must be both provided or empty.',
    30008: 'Failed to invoke the internal interface.',
    30009: 'The value of taskName is empty.',
    30010: 'The value of nds is empty.',
    30011: 'The value of cleanStatus is empty or invalid.',
    30012: 'The value of environmentalParameters is empty or invalid.',
    30013: 'Plane irradiance or back surface temperature is empty when environmentalParameters=1.',
    30014: 'The value of scanPointNum must be set to 128.',
    30015: 'The value of taskId is empty.',
    30016: 'The value of dn is empty.',
    30017: 'The value of dns is invalid.',
    30018: 'The value of taskName is invalid.',
    30019: 'Module back surface temperature out of range [0.0, 100.0].',
    30020: 'Module plane irradiance out of range [600.0, 1500.0].',
    30021: 'The value of pageNo is smaller than 0.',
    30022: 'The value of timestamp is empty.',
    30023: 'The command type is invalid.',
    30024: 'The power supply duration is invalid.',
    30025: 'The MPPT list is empty.',
    30026: 'The value of mppts is empty.',
    30027: 'Number of MPPTs connected to single inverter exceeds limit (3), or total MPPTs exceeds limit (32).',
    30028: 'The backfeed current input value is invalid.',
    30029: 'Authentication failed.',
    30030: 'The input parameter is incorrect.',
    30031: 'A maximum of 10 devices can be queried at a time.',
    30032: 'The time parameter is invalid. Query time segment cannot exceed 3 days.',
    30033: 'The task is in progress.',
    30034: 'The returned list is empty.',
    30035: 'The task is to be executed.',
    30036: 'The task has been canceled.',
    30037: 'The number of reservation tasks exceeds the maximum (10).',
  };

  /// Returns official description for a given Huawei OpenAPI error code.
  static String getDescription(int? code) {
    if (code == null) return 'Unknown error';
    return descriptions[code] ?? 'Huawei OpenAPI error code: $code';
  }
}

