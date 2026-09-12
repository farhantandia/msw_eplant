import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';
import 'package:msw_eplant/pages/solarpv/solar_landscape_trend_page.dart';

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

      // Verify timeframe tabs
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);

      // Switch to Yesterday tab
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to 7 Days tab
      await tester.tap(find.text('7 Days'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify stats strip
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('PEAK'), findsOneWidget);

      // Verify Landscape Fullscreen Action Button
      expect(find.text('Landscape'), findsOneWidget);
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
      expect(find.text('INV PLTS 165 KWP 1'), findsOneWidget);
      expect(find.text('°C'), findsWidgets);
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

      // Timeframe controls
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);

      // Switch to Yesterday
      await tester.tap(find.text('Yesterday'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to 7 Days
      await tester.tap(find.text('7 Days'));
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
}
