import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/plant_overview_models.dart';
import 'package:msw_eplant/pages/plant/plant_overview_detail_page.dart';
import 'package:msw_eplant/widgets/plant_energy_flow_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'decimal_places': 1});
  });

  Widget createTestWidget(Widget child, {Size size = const Size(360, 800), double textScale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    );
  }

  final sampleSnapshot = PlantOverviewSnapshot(
    timestamp: DateTime(2026, 9, 11, 12, 0),
    totalLoad: 58.2,
    loadToPln: 42.5,
    loadToAi: 10.2,
    totalHouseLoad: 5.5,
    unit1: const UnitOverviewData(
      unitIndex: 0,
      grossLoad: 29.1,
      tmgcr: 65.0,
      bmcr: 280.0,
      boilerEfficiency: 88.5,
      eaf: 95.2,
      capacityFactor: 82.1,
      nphr: 2450.0,
      isLive: true,
    ),
    unit2: const UnitOverviewData(
      unitIndex: 1,
      grossLoad: 29.1,
      tmgcr: 65.0,
      bmcr: 280.0,
      boilerEfficiency: 87.9,
      eaf: 94.0,
      capacityFactor: 80.5,
      nphr: 2480.0,
      isLive: true,
    ),
    cemsParams: const [
      CemsParamItem(
        paramKey: 'SO2',
        displayName: 'Sulfur Dioksida (SO₂)',
        unit: 'mg/Nm³',
        unit1Value: 210.5,
        unit2Value: 225.0,
        threshold: 550.0,
      ),
      CemsParamItem(
        paramKey: 'NOX',
        displayName: 'Nitrogen Oksida (NOₓ)',
        unit: 'mg/Nm³',
        unit1Value: 320.1,
        unit2Value: 340.5,
        threshold: 550.0,
      ),
      CemsParamItem(
        paramKey: 'PARTICULATE',
        displayName: 'Partikulat / Debu',
        unit: 'mg/Nm³',
        unit1Value: 25.0,
        unit2Value: 28.4,
        threshold: 50.0,
      ),
      CemsParamItem(
        paramKey: 'HG',
        displayName: 'Hg Correction',
        unit: 'mg/Nm³',
        unit1Value: 0.015,
        unit2Value: 0.020,
        threshold: 0.03,
      ),
    ],
    isLive: true,
    hasData: true,
  );

  group('PlantEnergyFlowWidget Tests', () {
    testWidgets('Renders Busbar 20kV / 70kV and all nodes with live MW', (tester) async {
      await tester.pumpWidget(createTestWidget(
        PlantEnergyFlowWidget(snapshot: sampleSnapshot),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('BUSBAR 20kV / 70kV'), findsOneWidget);
      expect(find.text('TRAFO AUX'), findsOneWidget);
      expect(find.text('UNIT 1 GENERATOR'), findsOneWidget);
      expect(find.text('UNIT 2 GENERATOR'), findsOneWidget);
      expect(find.text('PLN GRID'), findsOneWidget);
      expect(find.text('PT AI FEEDER'), findsOneWidget);
      expect(find.text('HOUSE LOAD'), findsOneWidget);

      // Verify live values from snapshot (Busbar net export = 58.2 - 5.5 = 52.7 MW)
      expect(find.text('52.7'), findsOneWidget); // Commercial Export MW on Busbar
      expect(find.text('42.5'), findsOneWidget); // PLN MW
      expect(find.text('10.2'), findsOneWidget); // AI MW
      expect(find.text('5.5'), findsOneWidget);  // HL MW

      expect(tester.takeException(), isNull);
    });

    testWidgets('Zero hardcoded data: When data is null, displays dash and zero pulses', (tester) async {
      final emptySnapshot = PlantOverviewSnapshot(
        unit1: const UnitOverviewData(unitIndex: 0),
        unit2: const UnitOverviewData(unitIndex: 1),
        cemsParams: const [],
        hasData: false,
      );

      await tester.pumpWidget(createTestWidget(
        PlantEnergyFlowWidget(snapshot: emptySnapshot),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show dashes for unpopulated values
      expect(find.text('—'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Busbar node opens bottom sheet detail', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        PlantEnergyFlowWidget(snapshot: sampleSnapshot),
        size: const Size(800, 1200),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('BUSBAR 20kV / 70kV'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MSW Power Busbar 20kV / 70kV'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      Navigator.of(tester.element(find.text('CLOSE'))).pop();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CLOSE'), findsNothing);
    });

    testWidgets('Tapping Trafo Aux node opens Trafo 11kV/6.6kV detail dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        PlantEnergyFlowWidget(snapshot: sampleSnapshot),
        size: const Size(800, 1200),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('TRAFO AUX'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trafo 11kV / 6.6kV (Unit Aux Transformer)'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      Navigator.of(tester.element(find.text('CLOSE'))).pop();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CLOSE'), findsNothing);
    });

    testWidgets('Tapping OPEN HISTORICAL TREND triggers onOpenNodeChart callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? tappedNode;
      String? tappedCol;
      String? tappedUnit;

      await tester.pumpWidget(createTestWidget(
        PlantEnergyFlowWidget(
          snapshot: sampleSnapshot,
          onOpenNodeChart: (node, col, unit) {
            tappedNode = node;
            tappedCol = col;
            tappedUnit = unit;
          },
        ),
        size: const Size(800, 1800),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap PLN GRID
      await tester.tap(find.text('PLN GRID'));
      await tester.pump(const Duration(milliseconds: 300));

      final trendFinder = find.text('OPEN HISTORICAL TREND');
      expect(trendFinder, findsOneWidget);
      await tester.ensureVisible(trendFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(trendFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tappedNode, contains('PLN'));
      expect(tappedCol, equals('LOAD TO PLN'));
      expect(tappedUnit, equals('MW'));
    });
  });

  group('PlantOverviewDetailPage Widget Tests', () {
    testWidgets('Mounts safely and displays PLTU MSW Tanjung title and sections', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PLTU MSW TANJUNG'), findsOneWidget);
      expect(find.text('TOTAL GROSS GENERATION'), findsOneWidget);
      expect(find.text('PLANT ENERGY FLOW DIAGRAM'), findsOneWidget);
      expect(find.text('UNIT CAPABILITY & PERFORMANCE'), findsOneWidget);
      expect(find.text('CEMS 4 KEY PARAMETERS'), findsOneWidget);
      expect(find.text('HISTORICAL TELEMETRY TRENDS'), findsOneWidget);

      // Verify Share Dashboard Action and Analytics button exist in AppBar
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Interactive chart tap points: Total Gross, Balance cells, and Full Chart', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
        size: const Size(800, 1400),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Total Gross Generation
      await tester.tap(find.text('TOTAL GROSS GENERATION'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap PLN Export cell
      await tester.tap(find.text('PLN EXPORT'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Full Chart button on trend section
      final fullChartFinder = find.text('Full Chart');
      await tester.ensureVisible(fullChartFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(fullChartFinder);
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Trend chart switcher chips can be tapped without error', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
        size: const Size(800, 1400),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll to chart chips and tap
      final chipFinder = find.text('PLN vs AI Export');
      await tester.ensureVisible(chipFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(chipFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Use .last because 'Boiler Efficiency' also exists in capability matrix table
      final effFinder = find.text('Boiler Efficiency').last;
      await tester.ensureVisible(effFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(effFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Use .last because 'NPHR Heat Rate' also exists in capability matrix table
      final nphrFinder = find.text('NPHR Heat Rate').last;
      await tester.ensureVisible(nphrFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(nphrFinder);
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Zero overflow test on narrow screen (320x640) at font scale 1.0', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
        size: const Size(320, 640),
        textScale: 1.0,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PLTU MSW TANJUNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Zero overflow test on standard screen (360x740) at font scale 1.3', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
        size: const Size(360, 740),
        textScale: 1.3,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PLTU MSW TANJUNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Zero overflow test on large screen (412x915) at font scale 1.5', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const PlantOverviewDetailPage(),
        size: const Size(412, 915),
        textScale: 1.5,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PLTU MSW TANJUNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
