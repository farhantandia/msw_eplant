import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';

void main() {
  group('Huawei SUN2000 Table 3-1 Inverter State Mapping Tests', () {
    test('State 40960 is recognized as Standby: No Irradiation and Healthy', () {
      expect(
        HuaweiAlarmDictionary.getStateDescription(40960),
        equals('Standby: No Irradiation'),
      );
      expect(HuaweiAlarmDictionary.isStandby(40960), isTrue);
      expect(HuaweiAlarmDictionary.isHealthyState(40960), isTrue);
      expect(HuaweiAlarmDictionary.isFault(40960), isFalse);
      expect(HuaweiAlarmDictionary.isDerated(40960), isFalse);

      // Crucial test: state 40960 must NOT synthesize an alarm!
      final synthAlarm = HuaweiAlarmDictionary.fromInverterState(
        40960,
        devName: 'Kelanis Inverter 01',
        devId: 'INV01',
      );
      expect(synthAlarm, isNull);
    });

    test('All normal standby states produce NO synthetic alarms', () {
      final standbyCodes = [0, 1, 2, 3, 40960, 40961];
      for (final code in standbyCodes) {
        expect(HuaweiAlarmDictionary.isStandby(code), isTrue, reason: 'Code $code should be standby');
        expect(HuaweiAlarmDictionary.isHealthyState(code), isTrue, reason: 'Code $code should be healthy');
        expect(
          HuaweiAlarmDictionary.fromInverterState(code),
          isNull,
          reason: 'Code $code must not generate an alarm',
        );
      }
    });

    test('All grid-connected states produce NO synthetic alarms', () {
      final gridCodes = [256, 512, 515, 1025, 1026, 1027, 1028, 1029];
      for (final code in gridCodes) {
        expect(HuaweiAlarmDictionary.isGridConnected(code), isTrue, reason: 'Code $code should be grid connected');
        expect(HuaweiAlarmDictionary.isHealthyState(code), isTrue, reason: 'Code $code should be healthy');
        expect(
          HuaweiAlarmDictionary.fromInverterState(code),
          isNull,
          reason: 'Code $code must not generate an alarm',
        );
      }
    });

    test('Derated states produce Warning alarms', () {
      final deratedCodes = [513, 514];
      for (final code in deratedCodes) {
        expect(HuaweiAlarmDictionary.isDerated(code), isTrue);
        expect(HuaweiAlarmDictionary.isHealthyState(code), isFalse);

        final alarm = HuaweiAlarmDictionary.fromInverterState(code, devName: 'Inv-Test');
        expect(alarm, isNotNull);
        expect(alarm!.severity, equals(AlarmSeverity.warning));
        expect(alarm.alarmId, contains('STATE-DERATED-$code'));
      }
    });

    test('Fault states produce Major fault alarms', () {
      final faultCodes = [768, 770, 771, 773, 774, 45056];
      for (final code in faultCodes) {
        expect(HuaweiAlarmDictionary.isFault(code), isTrue);
        expect(HuaweiAlarmDictionary.isHealthyState(code), isFalse);

        final alarm = HuaweiAlarmDictionary.fromInverterState(code, devName: 'Inv-Fault');
        expect(alarm, isNotNull);
        expect(alarm!.severity, equals(AlarmSeverity.major));
        expect(alarm.alarmId, contains('STATE-FAULT-$code'));
      }
    });

    test('All Table 3-1 descriptions are mapped', () {
      expect(HuaweiAlarmDictionary.getStateDescription(0), equals('Standby: Initializing'));
      expect(HuaweiAlarmDictionary.getStateDescription(512), equals('Grid-Connected'));
      expect(HuaweiAlarmDictionary.getStateDescription(768), equals('Shutdown: On Fault'));
      expect(HuaweiAlarmDictionary.getStateDescription(1025), equals('Grid Scheduling: cosψ-P Curve'));
      expect(HuaweiAlarmDictionary.getStateDescription(40960), equals('Standby: No Irradiation'));
      expect(HuaweiAlarmDictionary.getStateDescription(45056), equals('Communication Interrupted (SmartLogger)'));
    });
  });

  group('Huawei OpenAPI Error Code Dictionary Tests', () {
    test('Resolves standard API error codes to human-readable strings', () {
      expect(
        HuaweiOpenApiErrorCode.getDescription(20001),
        equals('The third-party system ID does not exist.'),
      );
      expect(
        HuaweiOpenApiErrorCode.getDescription(407),
        equals('The interface access frequency is too high.'),
      );
      expect(
        HuaweiOpenApiErrorCode.getDescription(305),
        equals('You are not in the login state. You need to log in again.'),
      );
      expect(
        HuaweiOpenApiErrorCode.getDescription(20010),
        equals('The plant list cannot be empty.'),
      );
      expect(
        HuaweiOpenApiErrorCode.getDescription(20200),
        equals('The system is busy. Try again later.'),
      );
    });

    test('Fallback for unknown error code', () {
      expect(
        HuaweiOpenApiErrorCode.getDescription(99999),
        equals('Huawei OpenAPI error code: 99999'),
      );
      expect(
        HuaweiOpenApiErrorCode.getDescription(null),
        equals('Unknown error'),
      );
    });
  });

  group('SolarInverter Model with Code 40960', () {
    test('Inverter in state 40960 has no alarms and standby status', () {
      final inv = SolarInverter(
        id: 'kelanis-inv-1',
        name: 'Kelanis Inverter 01',
        clusterId: 'kelanis',
        plantId: 'kelanis',
        capacityKwp: 100.0,
        powerKw: 0.0,
        yieldTodayKwh: 120.0,
        status: InverterStatus.standby,
        isNightStandby: true,
        inverterState: 40960,
        activeAlarms: const [],
      );

      expect(inv.inverterState, equals(40960));
      expect(inv.activeAlarms, isEmpty);
      expect(HuaweiAlarmDictionary.isHealthyState(inv.inverterState), isTrue);
      expect(HuaweiAlarmDictionary.getStateDescription(inv.inverterState), equals('Standby: No Irradiation'));
    });

    test('Old cached false alarms with code 40960 from Firebase JSON are automatically purged', () {
      final cachedFirebaseJson = {
        'id': 'kelanis-inv-1',
        'name': 'Kelanis Inverter 01',
        'cluster_id': '468kwp',
        'capacity_kwp': 100.0,
        'power_kw': 0.0,
        'yield_today_kwh': 120.0,
        'status': 'standby',
        'inverter_state': 40960,
        'active_alarms': [
          {
            'alarm_id': 'STATE-FAULT-40960',
            'alarm_name': 'Inverter Fault Detected (Code 40960)',
            'alarm_code': 40960,
            'severity': 'major',
            'raise_time': '2026-09-12T05:00:00.000',
            'status': 'Active',
          }
        ],
      };

      final deserializedInv = SolarInverter.fromJson(cachedFirebaseJson);
      expect(deserializedInv.activeAlarms, isEmpty);
      expect(deserializedInv.toJson()['active_alarms'], isEmpty);
    });
  });

  group('FusionSolarService isSyncingNotifier & Loading Indicator Tests', () {
    test('isSyncingNotifier default state is false and notifies on changes', () {
      final service = FusionSolarService.instance;
      expect(service.isSyncing, isFalse);
      expect(service.isSyncingNotifier.value, isFalse);

      bool notified = false;
      void listener() {
        notified = true;
      }

      service.isSyncingNotifier.addListener(listener);
      service.isSyncingNotifier.value = true;
      expect(notified, isTrue);
      expect(service.isSyncing, isTrue);

      service.isSyncingNotifier.value = false;
      expect(service.isSyncing, isFalse);
      service.isSyncingNotifier.removeListener(listener);
    });
  });
}

