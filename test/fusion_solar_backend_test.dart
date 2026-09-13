import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'helpers/test_solar_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FusionSolarApiClient Operational Rules Tests (16h Window)', () {
    test('isWithinOperatingHours accurately validates 16h daylight window (04:00 - 20:00 WITA)', () {
      // 04:00 morning -> within window
      final t4am = DateTime(2026, 6, 15, 4, 0);
      expect(FusionSolarApiClient.isWithinOperatingHours(t4am), isTrue);

      // 12:30 peak solar -> within window
      final tNoon = DateTime(2026, 6, 15, 12, 30);
      expect(FusionSolarApiClient.isWithinOperatingHours(tNoon), isTrue);

      // 20:00 evening boundary -> within window
      final t8pm = DateTime(2026, 6, 15, 20, 0);
      expect(FusionSolarApiClient.isWithinOperatingHours(t8pm), isTrue);

      // 20:01 night -> outside window
      final tNight1 = DateTime(2026, 6, 15, 20, 1);
      expect(FusionSolarApiClient.isWithinOperatingHours(tNight1), isFalse);

      // 03:59 early morning -> outside window
      final tNight2 = DateTime(2026, 6, 15, 3, 59);
      expect(FusionSolarApiClient.isWithinOperatingHours(tNight2), isFalse);

      // 23:00 midnight -> outside window
      final tMidnight = DateTime(2026, 6, 15, 23, 0);
      expect(FusionSolarApiClient.isWithinOperatingHours(tMidnight), isFalse);
    });

    test('fetchLatestSnapshot returns null outside operating hours (Night Standby) without API calls', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      final client = FusionSolarApiClient(
        client: mockClient,
        throttleDelay: Duration.zero,
      );
      final nightTime = DateTime(2026, 6, 15, 22, 0);

      final snapshot = await client.fetchLatestSnapshot(referenceDate: nightTime);
      expect(snapshot, isNull);
      expect(requestCount, equals(0)); // Zero API calls during night standby
    });
  });

  group('Anti-Blocking Rate Limiter & Throttling Tests', () {
    test('Rate limiter enforces max 5 retries in 60-second window', () {
      final client = FusionSolarApiClient(
        throttleDelay: Duration.zero,
        retryBaseDelay: Duration.zero,
      );

      expect(client.canRetry(), isTrue);

      // Record 4 retries -> still can retry
      for (int i = 0; i < 4; i++) {
        client.recordRetry();
      }
      expect(client.canRetry(), isTrue);

      // 5th retry -> budget full
      client.recordRetry();
      expect(client.canRetry(), isFalse);

      // Simulate expired retry (> 60 seconds ago)
      client.retryTimestamps.clear();
      client.retryTimestamps.add(DateTime.now().subtract(const Duration(seconds: 65)));
      client.retryTimestamps.add(DateTime.now().subtract(const Duration(seconds: 70)));
      expect(client.canRetry(), isTrue);
    });

    test('Client handles failCode 407 (rate limited) and aborts when retry budget exhausted', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'xsrf-token': 'test-token'},
          );
        }
        // Always return 407 rate limit
        return http.Response(
          jsonEncode({'success': false, 'failCode': 407, 'message': 'Rate limited'}),
          200,
        );
      });

      final client = FusionSolarApiClient(
        client: mockClient,
        throttleDelay: Duration.zero,
        retryBaseDelay: Duration.zero,
      );

      // Pre-fill retry budget so canRetry() returns false
      for (int i = 0; i < FusionSolarApiClient.maxRetriesPerMinute; i++) {
        client.recordRetry();
      }

      final stations = await client.getStationList();
      expect(stations, isEmpty);
      // Because budget was exhausted, it shouldn't repeatedly retry
      expect(callCount, lessThanOrEqualTo(2));
    });

    test('Client stops retry immediately after failCode 407 occurs 2x on /getDevList', () async {
      int devListCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'xsrf-token': 'test-token'},
          );
        }
        if (request.url.path.endsWith('/getDevList')) {
          devListCalls++;
          return http.Response(
            jsonEncode({'success': false, 'failCode': 407, 'message': 'Rate limited'}),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final client = FusionSolarApiClient(
        client: mockClient,
        throttleDelay: Duration.zero,
        retryBaseDelay: Duration.zero,
      );

      final inverters = await client.getInverters('ST_01');
      expect(inverters, isEmpty);
      // Exactly 2 attempts on /getDevList before stopping immediately
      expect(devListCalls, equals(2));
    });
  });

  group('12 Inverters across 4 Clusters & Hourly Clamping (Up to Current Hour)', () {
    test('generateTestSolarSnapshot produces hourly points strictly up to current hour (no future points)', () {
      // At 12:00 -> 04:00 to 12:00 inclusive = 9 points
      final snapNoon = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );
      expect(snapNoon.hourlyPoints.length, equals(9));
      expect(snapNoon.hourlyPoints.first.hour, equals(4));
      expect(snapNoon.hourlyPoints.first.timeStr, equals('04:00'));
      expect(snapNoon.hourlyPoints.last.hour, equals(12));
      expect(snapNoon.hourlyPoints.last.timeStr, equals('12:00'));

      // At 20:00 -> 04:00 to 20:00 inclusive = 17 points
      final snapEvening = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 20, 0),
      );
      expect(snapEvening.hourlyPoints.length, equals(17));
      expect(snapEvening.hourlyPoints.last.hour, equals(20));
      expect(snapEvening.hourlyPoints.last.timeStr, equals('20:00'));
    });

    test('All 12 inverters are mapped across 4 arrays with correct capacities summing to 868 kWp', () {
      final snap = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );

      expect(snap.inverters.length, equals(12));
      expect(snap.totalCapacityKwp, equals(868.0));

      final clusters = snap.clusters;
      expect(clusters.length, equals(4));

      final c165 = clusters.firstWhere((c) => c.id == '165kwp');
      expect(c165.inverters.length, equals(4));
      expect(c165.totalCapacityKwp, equals(165.0)); // 4x 41.25 kWp

      final c200 = clusters.firstWhere((c) => c.id == '200kwp');
      expect(c200.inverters.length, equals(2));
      expect(c200.totalCapacityKwp, equals(200.0)); // 2x 100 kWp

      final c468 = clusters.firstWhere((c) => c.id == '468kwp');
      expect(c468.inverters.length, equals(4));
      expect(c468.totalCapacityKwp, equals(468.0)); // 4x 117 kWp
      // All 468 kWp inverters have specificEnergy
      for (final inv in c468.inverters) {
        expect(inv.specificEnergy, isNotNull);
      }

      final c1520 = clusters.firstWhere((c) => c.id == '15_20kwp');
      expect(c1520.inverters.length, equals(2));
      expect(c1520.totalCapacityKwp, equals(35.0)); // 15 + 20 kWp
    });

    test('Plant separation isolates MSW (400 kWp, 8 inverters) and Kelanis (468 kWp, 4 inverters)', () {
      final snap = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );

      // MSW plant snapshot
      final msw = snap.mswSnapshot;
      expect(msw.totalCapacityKwp, equals(400.0));
      expect(msw.inverters.length, equals(8));
      expect(msw.clusters.length, equals(3)); // 165 kWp, 200 kWp, 15 & 20 kWp
      for (final inv in msw.inverters) {
        expect(inv.resolvedPlantId, equals('msw'));
      }

      // Kelanis plant snapshot
      final kelanis = snap.kelanisSnapshot;
      expect(kelanis.totalCapacityKwp, equals(468.0));
      expect(kelanis.inverters.length, equals(4));
      expect(kelanis.clusters.length, equals(1)); // 468 kWp Array
      for (final inv in kelanis.inverters) {
        expect(inv.resolvedPlantId, equals('kelanis'));
        expect(inv.specificEnergy, isNotNull);
      }
    });
  });

  group('Night Standby Bug Fix & Default Inventory Tests', () {
    test('SolarInverter.defaultInventory produces exactly 12 inverters in standby status', () {
      final inventory = SolarInverter.defaultInventory();
      expect(inventory.length, equals(12));
      for (final inv in inventory) {
        expect(inv.powerKw, equals(0.0));
        expect(inv.yieldTodayKwh, equals(0.0));
        expect(inv.status, equals(InverterStatus.standby));
        expect(inv.isNightStandby, isTrue);
      }
      expect(inventory.where((i) => i.plantId == 'msw').length, equals(8));
      expect(inventory.where((i) => i.plantId == 'kelanis').length, equals(4));
    });

    test('SolarSnapshot.emptyOrStandby has 12 standby inverters and 0 online count', () {
      final standby = SolarSnapshot.emptyOrStandby();
      expect(standby.totalInverterCount, equals(12));
      expect(standby.inverters.length, equals(12));
      expect(standby.onlineInverterCount, equals(0));
      expect(standby.totalCapacityKwp, equals(868.0));
    });

    test('SolarSnapshot.forPlant preserves yield and peak power when inverters list is empty', () {
      final snap = SolarSnapshot(
        timestamp: DateTime.now(),
        isLive: true,
        totalPowerKw: 0.0,
        peakPowerKw: 550.0,
        totalYieldTodayKwh: 3200.0,
        yieldYesterdayKwh: 3100.0,
        irradiance: 0.0,
        performanceRatio: 82.0,
        onlineInverterCount: 0,
        totalInverterCount: 12,
        totalCapacityKwp: 868.0,
        gridExportKw: 0.0,
        hourlyPoints: const [],
        inverters: const [], // empty inverters
      );

      final msw = snap.forPlant('msw');
      expect(msw.totalYieldTodayKwh, greaterThan(0.0));
      expect(msw.peakPowerKw, greaterThan(0.0));
      expect(msw.totalCapacityKwp, equals(400.0));

      final kelanis = snap.forPlant('kelanis');
      expect(kelanis.totalYieldTodayKwh, greaterThan(0.0));
      expect(kelanis.peakPowerKw, greaterThan(0.0));
      expect(kelanis.totalCapacityKwp, equals(468.0));
    });

    test('SolarSnapshot serialization preserves full time series and inverter data', () {
      final snap = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );

      final json = snap.toJson();
      expect(json['is_live'], isTrue);
      expect(json['total_power_kw'], isNotNull);
      expect((json['inverters'] as List).length, equals(12));
      expect((json['hourly_points'] as List).length, equals(9));

      final restored = SolarSnapshot.fromJson(json);
      expect(restored.totalInverterCount, equals(12));
      expect(restored.inverters.length, equals(12));
      expect(restored.hourlyPoints.length, equals(9));
      expect(restored.clusters.length, equals(4));
    });
  });

  group('WhatsApp Report Tests', () {
    test('formatWhatsAppReport formats isolated reports for MSW, Kelanis, and Combined', () {
      final snap = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );

      // Combined / Default (868 kWp)
      final reportCombined = FusionSolarService.formatWhatsAppReport(snap);
      expect(reportCombined, contains('MSW SOLAR PV TOTAL PRODUCTION REPORT (868 kWp)'));
      expect(reportCombined, contains('Total Energy Today:'));
      expect(reportCombined, contains('Auxiliary Load Offset:'));

      // MSW Isolated Report (400 kWp)
      final reportMsw = FusionSolarService.formatWhatsAppReport(snap, plantId: 'msw');
      expect(reportMsw, contains('MSW SOLAR PV PRODUCTION REPORT (400 kWp)'));
      expect(reportMsw, contains('*Inverters Online:* 8/8 Units'));

      // Kelanis Isolated Report (468 kWp)
      final reportKelanis = FusionSolarService.formatWhatsAppReport(snap, plantId: 'kelanis');
      expect(reportKelanis, contains('KELANIS SOLAR PV PRODUCTION REPORT (468 kWp)'));
      expect(reportKelanis, contains('*Inverters Online:* 4/4 Units'));
    });
  });

  group('Mocked FusionSolar OpenAPI Full Snapshot Integration Test', () {
    test('fetchLatestSnapshot successfully processes mock OpenAPI endpoints', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/login')) {
          return http.Response(
            jsonEncode({'data': 'success', 'failCode': 0}),
            200,
            headers: {'xsrf-token': 'mock-auth-token-12345'},
          );
        } else if (path.endsWith('/getStationList')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'list': [
                  {'stationCode': 'ST_01', 'stationName': 'MSW Solar Plant'}
                ]
              }
            }),
            200,
          );
        } else if (path.endsWith('/getDevList')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': '101',
                  'devName': 'INV PLTS 165 kWp 1',
                  'devTypeId': 1,
                  'model': 'SUN2000-40KTL-M3',
                  'softwareVersion': 'V100R001C20SPC134',
                  'esnCode': '6T2469039090',
                },
                {
                  'id': '102',
                  'devName': 'INV_PLTS_200_KWP_1',
                  'devTypeId': 1,
                  'model': 'SUN2000-100KTL-M1',
                  'softwareVersion': 'V500R023C00SPC156',
                  'esnCode': 'BN2541082492',
                },
                {
                  'id': '103',
                  'devName': 'Inverter(COM1-1)',
                  'devTypeId': 1,
                  'model': 'SUN2000-100KTL-M1',
                  'softwareVersion': 'V500R023C00SPC156',
                  'esnCode': '6T2149024369',
                },
                {
                  'id': '104',
                  'devName': 'INV PLTS 15 kWp',
                  'devTypeId': 1,
                  'model': 'SUN2000-20KTL-M2',
                  'softwareVersion': 'V100R001C00SPC161',
                  'esnCode': 'HV2140021380',
                },
              ]
            }),
            200,
          );
        } else if (path.endsWith('/getDevRealKpi')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'devId': '101',
                  'dataItemMap': {
                    'active_power': 120.5,
                    'day_cap': 450.0,
                    'temperature': 42.6,
                    'elec_freq': 49.98,
                    'ab_u': 391.7,
                    'bc_u': 391.4,
                    'ca_u': 388.6,
                    'a_i': 9.44,
                    'b_i': 9.44,
                    'c_i': 9.42,
                    'power_factor': 0.999,
                    'efficiency': 97.45,
                    'mppt_power': 6.44,
                    'total_cap': 93815.38,
                    'inverter_state': 0,
                  }
                },
                {'devId': '102', 'dataItemMap': {'active_power': 150.0, 'day_cap': 600.0, 'temperature': 44.1, 'elec_freq': 50.01}},
                {'devId': '103', 'dataItemMap': {'active_power': 90.0, 'day_cap': 380.0, 'temperature': 45.0, 'elec_freq': 50.00}},
                {'devId': '104', 'dataItemMap': {'active_power': 12.0, 'day_cap': 50.0, 'temperature': 41.2, 'elec_freq': 49.99}},
              ]
            }),
            200,
          );
        } else if (path.endsWith('/getDevKpiDay')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'devId': '101', 'dataItemMap': {'product_power': 450.0, 'perpower_ratio': 2.72}},
                {'devId': '102', 'dataItemMap': {'product_power': 600.0, 'perpower_ratio': 3.00}},
                {'devId': '103', 'dataItemMap': {'product_power': 380.0, 'perpower_ratio': 3.24}},
                {'devId': '104', 'dataItemMap': {'product_power': 50.0, 'perpower_ratio': 3.33}},
              ]
            }),
            200,
          );
        } else if (path.endsWith('/getKpiStationDay')) {
          final noonTime = DateTime(2026, 6, 15, 12, 0);
          final todayMidnight = DateTime(noonTime.year, noonTime.month, noonTime.day).millisecondsSinceEpoch;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'stationCode': 'ST_01',
                  'collectTime': todayMidnight,
                  'dataItemMap': {
                    'radiation_intensity': 4.85,
                    'inverter_power': 1480.0,
                    'performance_ratio': 82.5,
                    'reduction_total_co2': 0.792,
                    'reduction_total_coal': 0.667,
                    'reduction_total_tree': 1.081,
                  }
                }
              ]
            }),
            200,
          );
        } else if (path.endsWith('/getKpiStationHour')) {
          final noonTime = DateTime(2026, 6, 15, 12, 0);
          final list = <Map<String, dynamic>>[];
          for (int h = 4; h <= 12; h++) {
            final hDt = DateTime(noonTime.year, noonTime.month, noonTime.day, h, 0);
            list.add({
              'stationCode': 'ST_01',
              'collectTime': hDt.millisecondsSinceEpoch,
              'dataItemMap': {
                'radiation_intensity': 0.85,
                'inverter_power': 320.0,
                'performance_ratio': 81.5,
              },
            });
          }
          return http.Response(
            jsonEncode({'success': true, 'data': list}),
            200,
          );
        }

        return http.Response('{"success": true}', 200);
      });

      final client = FusionSolarApiClient(
        client: mockClient,
        throttleDelay: Duration.zero,
        retryBaseDelay: Duration.zero,
      );

      final noonTime = DateTime(2026, 6, 15, 12, 0);
      final snapshot = await client.fetchLatestSnapshot(referenceDate: noonTime);

      expect(snapshot, isNotNull);
      expect(snapshot!.isLive, isTrue);
      expect(snapshot.irradiance, equals(4.85));
      expect(snapshot.performanceRatio, equals(82.5));
      expect(snapshot.inverters.length, equals(4));
      expect(snapshot.totalPowerKw, equals(120.5 + 150.0 + 90.0 + 12.0));

      final firstInv = snapshot.inverters.first;
      expect(firstInv.name, equals('INV PLTS 165 kWp 1'));
      expect(firstInv.model, equals('SUN2000-40KTL-M3'));
      expect(firstInv.esnCode, equals('6T2469039090'));
      expect(firstInv.temperature, equals(42.6));
      expect(firstInv.gridFrequency, equals(49.98));
      expect(firstInv.lineVoltageAb, equals(391.7));
      expect(firstInv.efficiency, equals(97.45));
      expect(firstInv.powerFactor, equals(0.999));
      expect(firstInv.mpptPowerKw, equals(6.44));
      expect(firstInv.totalLifetimeKwh, equals(93815.38));
      expect(snapshot.hourlyPoints.length, equals(9)); // Clamped to 12:00
    });
  });

  group('Hourly Bucket Caching Tests', () {
    test('FusionSolarApiClient rounds snapshot timestamp to the round hour bucket', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(jsonEncode({'data': 'success', 'failCode': 0}), 200, headers: {'xsrf-token': 'token'});
        }
        if (request.url.path.endsWith('/getStationList')) {
          return http.Response(jsonEncode({'success': true, 'data': {'list': [{'stationCode': 'ST_01'}]}}), 200);
        }
        if (request.url.path.endsWith('/getDevList')) {
          return http.Response(jsonEncode({
            'success': true,
            'data': [
              {'id': '101', 'devName': 'INV 1', 'devTypeId': 1, 'model': 'SUN2000-40KTL-M3'}
            ]
          }), 200);
        }
        if (request.url.path.endsWith('/getDevRealKpi')) {
          return http.Response(jsonEncode({'success': true, 'data': [{'devId': '101', 'dataItemMap': {'active_power': 50.0}}]}), 200);
        }
        if (request.url.path.endsWith('/getDevKpiDay')) {
          return http.Response(jsonEncode({'success': true, 'data': [{'devId': '101', 'dataItemMap': {'product_power': 100.0}}]}), 200);
        }
        if (request.url.path.endsWith('/getKpiStationDay')) {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final client = FusionSolarApiClient(client: mockClient, throttleDelay: Duration.zero);
      final refDate = DateTime(2026, 6, 15, 15, 20); // 15:20 -> nearest half-hour is 15:30
      final snap = await client.fetchLatestSnapshot(referenceDate: refDate);
      expect(snap, isNotNull);
      // Timestamp must be bucketed to nearest half-hour: 15:30:00
      expect(snap!.timestamp.hour, equals(15));
      expect(snap.timestamp.minute, equals(30));
      expect(snap.timestamp.second, equals(0));

      // Test helper directly for various intervals
      expect(FusionSolarApiClient.roundToNearestHalfHour(DateTime(2026, 6, 15, 9, 10)), equals(DateTime(2026, 6, 15, 9, 0)));
      expect(FusionSolarApiClient.roundToNearestHalfHour(DateTime(2026, 6, 15, 9, 25)), equals(DateTime(2026, 6, 15, 9, 30)));
      expect(FusionSolarApiClient.roundToNearestHalfHour(DateTime(2026, 6, 15, 9, 40)), equals(DateTime(2026, 6, 15, 9, 30)));
      expect(FusionSolarApiClient.roundToNearestHalfHour(DateTime(2026, 6, 15, 9, 50)), equals(DateTime(2026, 6, 15, 10, 0)));
    });

    test('checkAndTriggerPeriodicSync reuses same 30-minute cached snapshot without triggering sync', () async {
      final service = FusionSolarService.instance;
      final snap1500 = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 15, 0),
      );
      service.snapshotNotifier.value = snap1500;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        FusionSolarService.prefLastSyncKey,
        DateTime(2026, 6, 15, 15, 0).millisecondsSinceEpoch,
      );

      // User opens app at 15:20 (same 30-minute bucket)
      await service.checkAndTriggerPeriodicSync(now: DateTime(2026, 6, 15, 15, 20));
      // Snapshot should remain preserved in cache
      expect(service.snapshotNotifier.value.timestamp.hour, equals(15));
    });
  });

  group('Distinct Plant Irradiance/PR & Morning Anti-Zero Yield Tests', () {
    test('MSW and Kelanis have strictly distinct irradiance, PR, and hourly curves in forPlant()', () {
      final snap = generateTestSolarSnapshot(
        date: DateTime(2026, 6, 15, 12, 0),
      );

      final msw = snap.forPlant('msw');
      final kelanis = snap.forPlant('kelanis');

      // Irradiance must never be identical between plants
      expect(msw.irradiance, isNot(equals(kelanis.irradiance)));
      expect(msw.irradiance, greaterThan(0.0));
      expect(kelanis.irradiance, greaterThan(0.0));

      // PR must never be identical between plants
      expect(msw.performanceRatio, isNot(equals(kelanis.performanceRatio)));
      expect(msw.performanceRatio, greaterThan(0.0));
      expect(kelanis.performanceRatio, greaterThan(0.0));

      // Hourly irradiance and PR curves must be distinct
      final mswH = msw.hourlyPoints.firstWhere((h) => h.hour == 12);
      final kelanisH = kelanis.hourlyPoints.firstWhere((h) => h.hour == 12);
      expect(mswH.irradiance, isNot(equals(kelanisH.irradiance)));
      expect(mswH.pr, isNot(equals(kelanisH.pr)));
    });

    test('Anti-zero morning yield fallback prevents zero display when inverters have active power', () {
      final morningSnap = SolarSnapshot(
        timestamp: DateTime(2026, 6, 15, 7, 30),
        isLive: true,
        totalPowerKw: 150.0,
        peakPowerKw: 720.0,
        totalYieldTodayKwh: 0.0, // Huawei cloud aggregation delay
        yieldYesterdayKwh: 2600.0,
        irradiance: 0.65,
        performanceRatio: 81.0,
        gridExportKw: 150.0,
        onlineInverterCount: 12,
        totalInverterCount: 12,
        totalCapacityKwp: 868.0,
        inverters: [
          SolarInverter(
            id: 'inv_1',
            name: 'INV 1',
            clusterId: '165kwp',
            plantId: 'msw',
            capacityKwp: 41.25,
            powerKw: 15.0,
            yieldTodayKwh: 0.0,
            status: InverterStatus.normal,
            isNightStandby: false,
          ),
          SolarInverter(
            id: 'inv_kel_1',
            name: 'Inverter(COM1-1)',
            clusterId: '468kwp',
            plantId: 'kelanis',
            capacityKwp: 117.0,
            powerKw: 45.0,
            yieldTodayKwh: 0.0,
            status: InverterStatus.normal,
            isNightStandby: false,
          ),
        ],
        hourlyPoints: [
          SolarHourlyPoint(hour: 6, timeStr: '06:00', powerKw: 40.0, irradiance: 0.2, pr: 80.0),
          SolarHourlyPoint(hour: 7, timeStr: '07:00', powerKw: 150.0, irradiance: 0.65, pr: 81.0),
        ],
      );

      // Effective yield on main snapshot must be positive
      expect(morningSnap.effectiveYieldTodayKwh, greaterThan(0.0));

      // forPlant must also have positive yield today
      final msw = morningSnap.forPlant('msw');
      expect(msw.totalYieldTodayKwh, greaterThan(0.0));

      final kelanis = morningSnap.forPlant('kelanis');
      expect(kelanis.totalYieldTodayKwh, greaterThan(0.0));
    });

    test('FusionSolarApiClient getDayKpi passes midnight timestamp required by Huawei OpenAPI', () async {
      int? capturedCollectTime;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(jsonEncode({'success': true}), 200, headers: {'xsrf-token': 'token'});
        }
        if (request.url.path.endsWith('/getDevKpiDay')) {
          final body = jsonDecode(request.body) as Map;
          capturedCollectTime = body['collectTime'] as int?;
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final client = FusionSolarApiClient(client: mockClient, throttleDelay: Duration.zero);
      final refDate = DateTime(2026, 6, 15, 7, 45, 30);
      await client.getDayKpi(['101'], refDate);

      final expectedMidnight = DateTime(2026, 6, 15, 0, 0, 0).millisecondsSinceEpoch;
      expect(capturedCollectTime, equals(expectedMidnight));
    });

    test('SolarSnapshot JSON serialization preserves plantIrradiance and plantPr', () {
      final snap = SolarSnapshot(
        timestamp: DateTime(2026, 6, 15, 12, 0),
        isLive: true,
        totalPowerKw: 500.0,
        peakPowerKw: 700.0,
        totalYieldTodayKwh: 1200.0,
        yieldYesterdayKwh: 2500.0,
        irradiance: 4.2,
        performanceRatio: 81.0,
        plantIrradiance: {'msw': 4.35, 'kelanis': 3.95},
        plantPr: {'msw': 82.5, 'kelanis': 79.2},
        gridExportKw: 500.0,
        onlineInverterCount: 12,
        totalInverterCount: 12,
        totalCapacityKwp: 868.0,
        inverters: const [],
        hourlyPoints: const [],
      );

      final json = snap.toJson();
      expect(json['plant_irradiance'], isA<Map>());
      expect(json['plant_irradiance']['msw'], equals(4.35));
      expect(json['plant_irradiance']['kelanis'], equals(3.95));
      expect(json['plant_pr']['msw'], equals(82.5));
      expect(json['plant_pr']['kelanis'], equals(79.2));

      final restored = SolarSnapshot.fromJson(json);
      expect(restored.plantIrradiance['msw'], equals(4.35));
      expect(restored.plantIrradiance['kelanis'], equals(3.95));
      expect(restored.plantPr['msw'], equals(82.5));
      expect(restored.plantPr['kelanis'], equals(79.2));

      // forPlant uses restored distinct values
      expect(restored.forPlant('msw').irradiance, equals(4.35));
      expect(restored.forPlant('kelanis').irradiance, equals(3.95));
      expect(restored.forPlant('msw').performanceRatio, equals(82.5));
      expect(restored.forPlant('kelanis').performanceRatio, equals(79.2));
    });

    test('fetchLatestSnapshot prioritizes live day_cap from getDevRealKpi and filters getDevKpiDay by collectTime', () async {
      final today = DateTime(2026, 6, 15, 10, 0);
      final todayCollectTime = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      final yesterdayCollectTime = DateTime(2026, 6, 14).millisecondsSinceEpoch;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(jsonEncode({'success': true}), 200, headers: {'xsrf-token': 'mock-token'});
        }
        if (request.url.path.endsWith('/getStationList')) {
          return http.Response(jsonEncode({
            'success': true,
            'data': {'list': [{'stationCode': 'NE=54218158', 'stationName': 'MSW 400'}]}
          }), 200);
        }
        if (request.url.path.endsWith('/getDevList')) {
          return http.Response(jsonEncode({
            'success': true,
            'data': [{'id': '101', 'devName': 'INV_PLTS_200_KWP_1', 'devTypeId': 1}]
          }), 200);
        }
        if (request.url.path.endsWith('/getDevRealKpi')) {
          return http.Response(jsonEncode({
            'success': true,
            'data': [{'devId': '101', 'dataItemMap': {'active_power': 65.0, 'day_cap': 384.5}}]
          }), 200);
        }
        if (request.url.path.endsWith('/getDevKpiDay')) {
          // Returns 2 records: yesterday (150.0) and today (340.0)
          return http.Response(jsonEncode({
            'success': true,
            'data': [
              {'devId': '101', 'collectTime': yesterdayCollectTime, 'dataItemMap': {'product_power': 150.0}},
              {'devId': '101', 'collectTime': todayCollectTime, 'dataItemMap': {'product_power': 340.0}},
            ]
          }), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final client = FusionSolarApiClient(client: mockClient, throttleDelay: Duration.zero);
      final snap = await client.fetchLatestSnapshot(referenceDate: today);
      expect(snap, isNotNull);
      // Inverter must have live day_cap (384.5 kWh), NOT the delayed 340.0 or overwritten 150.0
      expect(snap!.inverters.first.yieldTodayKwh, equals(384.5));
      expect(snap.totalYieldTodayKwh, equals(384.5));
    });
  });
}
