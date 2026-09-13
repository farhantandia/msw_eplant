import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/pages/solarpv/inverter_detail_page.dart';
import 'package:msw_eplant/pages/plant_page.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'helpers/test_solar_snapshot.dart';

void main() {
  group('PlantInverterCard Widget Tests', () {
    testWidgets('Renders normal active power and green LED for normal inverter',
        (WidgetTester tester) async {
      const inv = SolarInverter(
        id: 'inv_165_1',
        name: 'INV PLTS 165 kWp 1',
        clusterId: '165kwp',
        capacityKwp: 165.0,
        powerKw: 112.5,
        yieldTodayKwh: 450.0,
        status: InverterStatus.normal,
        isNightStandby: false,
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantInverterCard(
              inverter: inv,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INV PLTS 165 kWp 1'), findsOneWidget);
      expect(find.text('165 kWp'), findsOneWidget);
      expect(find.text('112.5'), findsOneWidget);
      expect(find.text('kW'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('450 kWh'), findsOneWidget);

      // Verify LED dot color
      final ledFinder = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          return box.shape == BoxShape.circle &&
              box.color == const Color(0xFF00E5A0);
        }
        return false;
      });
      expect(ledFinder, findsOneWidget);

      // Tap card
      await tester.tap(find.byType(PlantInverterCard));
      expect(tapped, isTrue);
    });

    testWidgets('Renders standby 0.0 kW and blue LED during night standby',
        (WidgetTester tester) async {
      const inv = SolarInverter(
        id: 'inv_200_1',
        name: 'INV_PLTS_200_KWP_1',
        clusterId: '200kwp',
        capacityKwp: 200.0,
        powerKw: 0.0,
        yieldTodayKwh: 780.0,
        status: InverterStatus.standby,
        isNightStandby: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: PlantInverterCard(
              inverter: inv,
              onTap: _dummyTap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INV_PLTS_200_KWP_1'), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('Standby'), findsOneWidget);
      expect(find.text('780 kWh'), findsOneWidget);
    });
  });

  group('InverterDetailPage Widget Tests', () {
    testWidgets('Renders full inverter details, specs, and diagnostics',
        (WidgetTester tester) async {
      const inv = SolarInverter(
        id: 'inv_test_1',
        name: 'Inverter(TEST-1)',
        clusterId: '468kwp',
        capacityKwp: 117.0,
        powerKw: 85.0,
        yieldTodayKwh: 340.0,
        specificEnergy: 2.91,
        status: InverterStatus.normal,
        isNightStandby: false,
      );

      // Set snapshot with this test inverter
      FusionSolarService.instance.snapshotNotifier.value = SolarSnapshot(
        timestamp: DateTime.now(),
        isLive: true,
        totalPowerKw: 85.0,
        peakPowerKw: 120.0,
        totalYieldTodayKwh: 340.0,
        yieldYesterdayKwh: 320.0,
        irradiance: 0.85,
        performanceRatio: 81.2,
        gridExportKw: 80.0,
        onlineInverterCount: 1,
        totalInverterCount: 1,
        totalCapacityKwp: 117.0,
        inverters: [inv],
        hourlyPoints: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const InverterDetailPage(
            inverterId: 'inv_test_1',
            initialInverter: inv,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inverter(TEST-1)'), findsWidgets);
      expect(find.text('ACTIVE POWER OUTPUT'), findsOneWidget);
      expect(find.text('85.0'), findsWidgets); // Appears in hero power + Peak Power analytic
      expect(find.text('DAILY YIELD'), findsOneWidget);
      expect(find.text('340.0 kWh'), findsOneWidget);
      expect(find.text('SPECIFIC ENERGY'), findsOneWidget);
      expect(find.text('PERFORMANCE ANALYTICS'), findsOneWidget);
      expect(find.text('THERMAL & DERATING RISK'), findsOneWidget);
      expect(find.text('TECHNICAL SPECIFICATIONS'), findsOneWidget);
      expect(find.text('468 kWp Array'), findsOneWidget);
      expect(find.text('DIAGNOSTICS & TELEMETRY HEALTH'), findsOneWidget);
      expect(find.text('View Entire Solar PV Plant (1.56 MWp)'), findsNothing);
    });

    testWidgets('Renders active alarm card and opens detail modal with repair suggestions',
        (WidgetTester tester) async {
      final invWithAlarm = SolarInverter(
        id: 'inv_alarm_1',
        name: 'Inverter(FAULT-1)',
        clusterId: '165kwp',
        capacityKwp: 165.0,
        powerKw: 40.0,
        yieldTodayKwh: 120.0,
        status: InverterStatus.derated,
        activeAlarms: [
          SolarAlarm(
            alarmId: 'ALM-2001',
            alarmName: 'High Internal Temperature',
            devName: 'Inverter(FAULT-1)',
            devId: 'inv_alarm_1',
            esn: '6T2469039090',
            severity: AlarmSeverity.major,
            raiseTime: DateTime(2026, 9, 6, 14, 30),
            cause: 'Suhu internal melebihi 75°C memicu pembatasan daya.',
            repairSuggestion: '1. Bersihkan filter udara heatsink.\n2. Periksa kipas pendingin.',
            status: 'Active',
            alarmCode: 2001,
          ),
        ],
      );

      FusionSolarService.instance.snapshotNotifier.value = SolarSnapshot(
        timestamp: DateTime.now(),
        isLive: true,
        totalPowerKw: 40.0,
        peakPowerKw: 120.0,
        totalYieldTodayKwh: 120.0,
        yieldYesterdayKwh: 320.0,
        irradiance: 0.85,
        performanceRatio: 81.2,
        gridExportKw: 40.0,
        onlineInverterCount: 1,
        totalInverterCount: 1,
        totalCapacityKwp: 165.0,
        inverters: [invWithAlarm],
        hourlyPoints: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: InverterDetailPage(
            inverterId: 'inv_alarm_1',
            initialInverter: invWithAlarm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify alarm card is visible
      expect(find.text('ACTIVE ALARMS & FAULTS (1)'), findsOneWidget);
      expect(find.text('High Internal Temperature'), findsOneWidget);
      expect(find.text('MAJOR'), findsOneWidget);
      expect(find.text('View Remediation Guide'), findsOneWidget);

      // Scroll to alarm card and tap it
      await tester.ensureVisible(find.text('High Internal Temperature'));
      await tester.tap(find.text('High Internal Temperature'));
      await tester.pumpAndSettle();

      // Verify modal sheet is opened
      expect(find.text('ROOT CAUSE ANALYSIS'), findsOneWidget);
      expect(find.text('REMEDIATION GUIDELINES (HUAWEI SUGGESTION)'), findsOneWidget);
      expect(find.text('1. Bersihkan filter udara heatsink.'), findsOneWidget);
      expect(find.text('2. Periksa kipas pendingin.'), findsOneWidget);

      // Scroll to bottom of modal sheet
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Copy Alarm Info'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('ROOT CAUSE ANALYSIS'), findsNothing);
    });

    testWidgets(
        'InverterDetailPage renders without overflow across multiple screen sizes and text scale factors',
        (WidgetTester tester) async {
      final inv = SolarInverter(
        id: 'inv_test_scale',
        name: 'Inverter(SCALE-TEST-1)',
        clusterId: '165kwp',
        capacityKwp: 165.0,
        powerKw: 112.5,
        yieldTodayKwh: 450.0,
        specificEnergy: 2.73,
        status: InverterStatus.normal,
        isNightStandby: false,
        temperature: 52.4,
        gridFrequency: 50.02,
        lineVoltageAb: 382.4,
        lineVoltageBc: 381.1,
        lineVoltageCa: 380.9,
        phaseCurrentA: 120.4,
        phaseCurrentB: 119.8,
        phaseCurrentC: 121.1,
        mpptPowerKw: 115.0,
        efficiency: 98.4,
        powerFactor: 0.998,
        totalLifetimeKwh: 2450000.0,
        activeAlarms: [
          SolarAlarm(
            alarmId: 'ALM-101',
            alarmName: 'Grid Overvoltage Warning',
            devName: 'Inverter(SCALE-TEST-1)',
            devId: 'inv_test_scale',
            esn: '6T12345678',
            severity: AlarmSeverity.minor,
            raiseTime: DateTime.now(),
            cause: 'Tegangan grid sempat melonjak sesaat.',
            repairSuggestion: 'Periksa setting proteksi tegangan.',
            status: 'Active',
          ),
        ],
      );

      FusionSolarService.instance.snapshotNotifier.value = SolarSnapshot(
        timestamp: DateTime.now(),
        isLive: true,
        totalPowerKw: 112.5,
        peakPowerKw: 140.0,
        totalYieldTodayKwh: 450.0,
        yieldYesterdayKwh: 420.0,
        irradiance: 0.88,
        performanceRatio: 82.0,
        gridExportKw: 110.0,
        onlineInverterCount: 1,
        totalInverterCount: 1,
        totalCapacityKwp: 165.0,
        inverters: [inv],
        hourlyPoints: const [],
      );

      for (double width in [320.0, 360.0, 390.0, 412.0]) {
        for (double textScale in [1.0, 1.2, 1.3, 1.5]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;

          FlutterErrorDetails? overflowDetails;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            overflowDetails = details;
          };

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: InverterDetailPage(
                  inverterId: 'inv_test_scale',
                  initialInverter: inv,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          FlutterError.onError = prevOnError;
          expect(overflowDetails, isNull,
              reason: 'Overflow on InverterDetailPage at width $width with textScale $textScale');
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('PlantPage Solar PV Integration Tests', () {
    testWidgets('Displays SOLAR PV section, summary banner, chips, and cards',
        (WidgetTester tester) async {
      // Set test viewport size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Ensure FusionSolarService has snapshot
      FusionSolarService.instance.snapshotNotifier.value =
          generateTestSolarSnapshot(date: DateTime(2026, 6, 15, 12, 0));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const PlantPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check classified plant sections
      expect(find.text('PLTS KELANIS (468 KWP)'), findsOneWidget);
      expect(find.text('PLTS MSW (400 KWP)'), findsOneWidget);
      expect(find.text('TOTAL ACTIVE POWER'), findsWidgets);
      expect(find.text('TODAY YIELD'), findsWidgets);

      // Check cluster chips for MSW
      expect(find.text('All (8)'), findsOneWidget);
      expect(find.text('165 kWp (4)'), findsOneWidget);
      expect(find.text('200 kWp (2)'), findsOneWidget);
      expect(find.text('15 & 20 kWp (2)'), findsOneWidget);

      // Verify inverter cards are present
      expect(find.byType(PlantInverterCard), findsWidgets);

      // Scroll to filter chips and tap 200 kWp chip
      await tester.ensureVisible(find.text('200 kWp (2)'));
      await tester.tap(find.text('200 kWp (2)'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantInverterCard), findsNWidgets(6)); // 4 Kelanis + 2 filtered MSW (200 kWp)
      expect(find.text('INV_PLTS_200_KWP_1'), findsOneWidget);
      expect(find.text('INV_PLTS_200_KWP_2'), findsOneWidget);

      // Ensure visible and tap on the first inverter card
      await tester.ensureVisible(find.text('INV_PLTS_200_KWP_1'));
      await tester.tap(find.text('INV_PLTS_200_KWP_1'));
      await tester.pumpAndSettle();

      // Verify we arrived on InverterDetailPage
      expect(find.byType(InverterDetailPage), findsOneWidget);
      expect(find.text('ACTIVE POWER OUTPUT'), findsOneWidget);
      expect(find.text('200 kWp Array'), findsOneWidget);
    });

    testWidgets(
        'PlantPage renders without overflow across multiple screen sizes and text scale factors',
        (WidgetTester tester) async {
      FusionSolarService.instance.snapshotNotifier.value =
          generateTestSolarSnapshot(date: DateTime(2026, 6, 15, 12, 0));

      for (double width in [320.0, 360.0, 390.0, 412.0]) {
        for (double textScale in [1.0, 1.2, 1.3, 1.5]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: const PlantPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Overflow on PlantPage at width $width with textScale $textScale');
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

void _dummyTap() {}
