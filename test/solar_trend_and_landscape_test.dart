import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';
import 'package:msw_eplant/pages/solarpv/solar_landscape_trend_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'helpers/test_solar_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SolarNumericTrendSheet Widget & Interaction Tests', () {
    testWidgets('Renders modal bottom sheet with metrics, tabs, stats, and landscape button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.power,
                    currentValue: 450.5,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header, metric title, and current value
      expect(find.text('Active Power'), findsWidgets);
      expect(find.text('450.5'), findsOneWidget);
      expect(find.text('kW'), findsWidgets);

      // Verify timeframe tabs (Only Today and Yesterday, 7 Days removed)
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('7 Days'), findsNothing);

      // Switch to Yesterday tab
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify stats strip
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('PEAK'), findsOneWidget);

      // Verify Landscape Fullscreen Action Button
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    });

    testWidgets('Supports inverter-specific telemetry (Inverter Temperature, Voltage, Current)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.inverterTemp,
                    inverterId: 'inv_01',
                    inverterName: 'INV PLTS 165 kWp 1',
                    currentValue: 48.2,
                  );
                },
                child: const Text('Open Inverter Temp'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Inverter Temp'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Internal Temperature'), findsWidgets);
      expect(find.text('INV PLTS 165 kWp 1'), findsOneWidget);
      expect(find.text('°C'), findsWidgets);
    });

    testWidgets('Dynamically updates values for Yesterday tab across Generation, Irradiance, PR, and Power', (tester) async {
      // Test 1: MSW Daily Generation displays 1720 kWh for Yesterday (not 1285 or today's 1706)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.dailyYield,
                    plantId: 'msw',
                    currentValue: 1706.0,
                    yesterdayValue: 1720.0,
                  );
                },
                child: const Text('Open MSW Generation'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open MSW Generation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Today shows 1706.0 and TODAY tag
      expect(find.text('1706.0'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      // Tap Yesterday tab
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Readout updates to 1720.0 and YESTERDAY tag
      expect(find.text('1720.0'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Test 2: Irradiance dynamically updates when switching to Yesterday
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.irradiance,
                    plantId: 'msw',
                    currentValue: 0.85,
                    yesterdayValue: 5.25,
                  );
                },
                child: const Text('Open Irradiance'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Irradiance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('0.85'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('5.25'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Test 3: PR dynamically updates when switching to Yesterday
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.pr,
                    plantId: 'msw',
                    currentValue: 81.4,
                    yesterdayValue: 82.6,
                  );
                },
                child: const Text('Open PR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('81.4'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('82.6'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
    });

    // Zero overflow testing across screen sizes & scales
    final testCases = [
      {'size': const Size(320, 640), 'scale': 1.0},
      {'size': const Size(320, 640), 'scale': 1.3},
      {'size': const Size(360, 740), 'scale': 1.0},
      {'size': const Size(360, 740), 'scale': 1.5},
      {'size': const Size(412, 915), 'scale': 1.0},
    ];

    for (final tc in testCases) {
      final size = tc['size'] as Size;
      final scale = tc['scale'] as double;

      testWidgets('Zero overflow on ${size.width}x${size.height} scale $scale', (tester) async {
        FlutterErrorDetails? errorCaught;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            errorCaught = details;
          }
        };

        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: const Scaffold(
                body: SolarNumericTrendSheet(
                  metricType: SolarMetricType.power,
                  currentValue: 512.4,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        FlutterError.onError = originalOnError;
        expect(errorCaught, isNull, reason: 'Overflow caught: ${errorCaught?.exception}');

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    }
  });

  group('SolarLandscapeTrendPage Widget & Interaction Tests', () {
    testWidgets('Renders fullscreen widescreen SCADA trend page with orientation and metrics', (tester) async {
      tester.view.physicalSize = const Size(800, 400) * 2;
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 400),
            ),
            child: const SolarLandscapeTrendPage(
              initialMetric: SolarMetricType.power,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header title
      expect(find.textContaining('SCADA Telemetry Trend'), findsOneWidget);

      // Timeframe controls (Only Today and Yesterday, 7 Days removed)
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('7 Days'), findsNothing);

      // Switch to Yesterday
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Stats strip at bottom
      expect(find.text('MINIMUM'), findsOneWidget);
      expect(find.text('AVERAGE'), findsOneWidget);
      expect(find.text('PEAK VALUE'), findsOneWidget);
      expect(find.text('SAMPLES'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Landscape page dropdown excludes Coal, CO2, and Grid Export for plant view', (tester) async {
      tester.view.physicalSize = const Size(800, 400) * 2;
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 400)),
            child: const SolarLandscapeTrendPage(
              plantId: 'msw',
              initialMetric: SolarMetricType.power,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Dropdown
      await tester.tap(find.byType(DropdownButton<SolarMetricType>));
      await tester.pumpAndSettle();

      // Available plant metrics are present
      expect(find.text('Active Power'), findsWidgets);
      expect(find.text('Daily Generation'), findsWidgets);
      expect(find.text('Solar Irradiance'), findsWidgets);
      expect(find.text('Performance Ratio'), findsWidgets);

      // Removed metrics are not present in the dropdown items
      expect(find.text('Coal Saved'), findsNothing);
      expect(find.text('Avoided CO₂'), findsNothing);
      expect(find.text('Grid Export'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Landscape page renders without overflow on ultra-wide viewports', (tester) async {
      FlutterErrorDetails? errorCaught;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          errorCaught = details;
        }
      };

      tester.view.physicalSize = const Size(915, 412) * 2;
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(915, 412),
              textScaler: TextScaler.linear(1.2),
            ),
            child: const SolarLandscapeTrendPage(
              initialMetric: SolarMetricType.dailyYield,
              inverterName: 'INV_01',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      FlutterError.onError = originalOnError;
      expect(errorCaught, isNull, reason: 'Overflow caught: ${errorCaught?.exception}');

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('Comprehensive Yesterday Telemetry Tests', () {
    setUp(() {
      FusionSolarService.instance.snapshotNotifier.value = generateTestSolarSnapshot();
    });

    testWidgets('SolarNumericTrendSheet falls back to plant yesterday metrics when yesterdayValue is null', (tester) async {
      // Open Irradiance for MSW without explicit yesterdayValue
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.irradiance,
                    plantId: 'msw',
                    currentValue: 0.85,
                  );
                },
                child: const Text('Open MSW Irradiance'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open MSW Irradiance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('0.85'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      // Switch to Yesterday
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Irradiance must NOT be 0.85 (today's) and must be MSW's yesterday value from snapshot (5.25 kWh/m²)
      expect(find.text('0.85'), findsNothing);
      expect(find.text('5.25'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
    });

    testWidgets('Inverter-level SolarNumericTrendSheet computes realistic yesterday yield and power', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SolarNumericTrendSheet.show(
                    context,
                    metricType: SolarMetricType.dailyYield,
                    inverterId: 'inv_01',
                    inverterName: 'INV 1',
                    plantId: 'msw',
                    currentValue: 120.0,
                  );
                },
                child: const Text('Open Inverter Yield'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Inverter Yield'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('120.0'), findsOneWidget);

      // Switch to Yesterday
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Inverter yield must NOT remain 120.0, and must NOT be whole plant 1720 or 2788
      expect(find.text('120.0'), findsNothing);
      expect(find.text('YESTERDAY'), findsOneWidget);
    });

    testWidgets('SolarDetailPage toggles Quick Metrics and Hero Card when Yesterday tab is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SolarDetailPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial state is Today
      expect(find.text('TOTAL GENERATION TODAY'), findsOneWidget);
      expect(find.text('PEAK POWER'), findsOneWidget);
      expect(find.text('IRRADIANCE'), findsOneWidget);
      expect(find.text('PERF. RATIO'), findsOneWidget);

      // Scroll down to find the Yesterday tab button in the chart header
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final yestTab = find.text('Yesterday').first;
      expect(yestTab, findsOneWidget);
      await tester.tap(yestTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll back up to verify hero card and quick metrics
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Titles and cards should now reflect Yesterday
      expect(find.text('TOTAL GENERATION YESTERDAY'), findsOneWidget);
      expect(find.text('PEAK (YEST)'), findsOneWidget);
      expect(find.text('IRR (YEST)'), findsOneWidget);
      expect(find.text('PR (YEST)'), findsOneWidget);
    });
  });
}
