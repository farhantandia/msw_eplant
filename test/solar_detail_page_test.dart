import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/solarpv/inverter_detail_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_solar_snapshot.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FusionSolarService.instance.snapshotNotifier.value =
        generateTestSolarSnapshot();
  });

  group('Solar PV Models & Cluster Architecture Tests', () {
    test('Verifies snapshot generation and inverter clusters', () {
      final snapshot = generateTestSolarSnapshot();

      // Inverter count
      expect(snapshot.totalInverterCount, equals(12));
      expect(snapshot.inverters.length, equals(12));
      expect(snapshot.totalCapacityKwp, equals(868.0));

      // 4 standardized clusters
      final clusters = snapshot.clusters;
      expect(clusters.length, equals(4));
      final c165 = clusters.firstWhere((c) => c.id == '165kwp');
      expect(c165.inverters.length, equals(4));
      expect(c165.totalCapacityKwp, equals(165.0));
      final c200 = clusters.firstWhere((c) => c.id == '200kwp');
      expect(c200.inverters.length, equals(2));
      expect(c200.totalCapacityKwp, equals(200.0));
      final c468 = clusters.firstWhere((c) => c.id == '468kwp');
      expect(c468.inverters.length, equals(4));
      expect(c468.totalCapacityKwp, equals(468.0));
      final c1520 = clusters.firstWhere((c) => c.id == '15_20kwp');
      expect(c1520.inverters.length, equals(2));
      expect(c1520.totalCapacityKwp, equals(35.0));

      // 468 kWp inverters have specific energy tracked
      for (final inv in c468.inverters) {
        expect(inv.specificEnergy, isNotNull);
        expect(inv.specificEnergy!, greaterThan(0));
      }

      // MSW snapshot (400 kWp, 8 inverters, 3 clusters)
      final msw = snapshot.mswSnapshot;
      expect(msw.totalCapacityKwp, equals(400.0));
      expect(msw.inverters.length, equals(8));
      expect(msw.clusters.length, equals(3));

      // Kelanis snapshot (468 kWp, 4 inverters, 1 cluster)
      final kelanis = snapshot.kelanisSnapshot;
      expect(kelanis.totalCapacityKwp, equals(468.0));
      expect(kelanis.inverters.length, equals(4));
      expect(kelanis.clusters.length, equals(1));
    });
  });

  group('SolarDetailPage Widget & Interaction Tests', () {
    testWidgets('Renders all hero metrics, flow animation, ESG cards, chart, and inverter arrays',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SolarDetailPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // App Bar
      expect(find.text('PLTS MSW'), findsOneWidget);
      expect(find.textContaining('400 kWp'), findsWidgets);

      // Plant Tab Switcher
      expect(find.text('PLTS MSW (400 kWp)'), findsOneWidget);
      expect(find.text('PLTS Kelanis (468 kWp)'), findsOneWidget);

      // Energy Flow Header (for MSW: 8 Inverters in tab switcher and energy flow node)
      expect(find.textContaining('ENERGY FLOW'), findsOneWidget);
      expect(find.text('8 Inverters'), findsNWidgets(2));
      expect(find.text('Grid & Aux'), findsOneWidget);

      // Hero Generation
      expect(find.text('TOTAL GENERATION TODAY'), findsOneWidget);
      expect(find.text('kWh'), findsOneWidget);

      // Quick Metrics
      expect(find.text('PEAK POWER'), findsOneWidget);
      expect(find.text('PERF. RATIO'), findsOneWidget);
      expect(find.text('IRRADIANCE'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);

      // ESG Card should be completely removed
      expect(find.text('ENVIRONMENTAL & FUEL OFFSET (ESG)'), findsNothing);
      expect(find.text('CO2 Avoided'), findsNothing);
      expect(find.text('Coal Saved'), findsNothing);

      // Hourly Generation Profile
      expect(find.textContaining('HOURLY PROFILE'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('PEAK'), findsOneWidget);

      // Inverter Arrays for MSW (8 UNITS across 3 clusters)
      expect(find.text('INVERTER ARRAYS (8 UNITS)'), findsOneWidget);
      expect(find.text('165 KWP ARRAY'), findsOneWidget);
      expect(find.text('200 KWP ARRAY'), findsOneWidget);
      expect(find.text('15 & 20 KWP ARRAY'), findsOneWidget);

      // Scroll down to Inverter Arrays section
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Expand All'), findsOneWidget);

      // Tap Expand All to open all clusters downwards
      await tester.tap(find.text('Expand All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Collapse All'), findsOneWidget);

      // Check specific MSW inverters
      expect(find.text('INV PLTS 165 kWp 1'), findsOneWidget);
      expect(find.text('INV_PLTS_200_KWP_1'), findsOneWidget);
      expect(find.text('INV PLTS 15 kWp'), findsOneWidget);

      // Switch tab to Kelanis (468 kWp)
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('PLTS Kelanis (468 kWp)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PLTS Kelanis'), findsOneWidget);
      expect(find.text('4 Inverters'), findsWidgets);
      expect(find.text('INVERTER ARRAYS (4 UNITS)'), findsOneWidget);
      expect(find.text('468 KWP ARRAY'), findsOneWidget);
    });

    testWidgets('Tapping cluster header toggles expand and collapse of inverter list downwards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SolarDetailPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially collapsed
      expect(find.text('INV PLTS 165 kWp 1'), findsNothing);

      // Tap to expand downwards
      await tester.tap(find.text('165 KWP ARRAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('INV PLTS 165 kWp 1'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('165 KWP ARRAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('INV PLTS 165 kWp 1'), findsNothing);
    });

    testWidgets('Tapping an inverter tile navigates to InverterDetailPage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SolarDetailPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 165 KWP ARRAY to expand it downwards
      await tester.tap(find.text('165 KWP ARRAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll so inverter tile is visible
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final invTile = find.text('INV PLTS 165 kWp 1');
      await tester.tap(invTile, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigation verification
      expect(find.byType(InverterDetailPage), findsOneWidget);
      expect(find.text('ACTIVE POWER OUTPUT'), findsOneWidget);
    });

    for (final size in [
      const Size(320, 640),
      const Size(360, 740),
      const Size(412, 915),
    ]) {
      for (final scale in [1.0, 1.3, 1.5]) {
        testWidgets(
          'Zero overflow on screen ${size.width}x${size.height} with scale $scale',
          (tester) async {
            tester.view.physicalSize = Size(size.width * 2, size.height * 2);
            tester.view.devicePixelRatio = 2.0;

            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.dark,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const Scaffold(body: SolarDetailPage()),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
