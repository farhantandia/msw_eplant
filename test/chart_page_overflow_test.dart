import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/chart_page.dart';

void main() {
  group('ChartPage Stats Bar Overflow & Responsiveness Tests', () {
    final sampleData = [
      ['DATETIME', 'FURNACE TEMPERATURE RIGHT'],
      ['2026-09-05 20:00:00', 950.25],
      ['2026-09-05 20:10:00', 980.50],
      ['2026-09-05 20:20:00', 1015.75],
      ['2026-09-05 20:30:00', 960.00],
    ];

    testWidgets('ChartPage stats bar displays MIN, AVG, MAX without overflow across screen sizes',
        (WidgetTester tester) async {
      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        for (final scale in [1.0, 1.25, 1.5]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;

          FlutterErrorDetails? errorDetails;
          final originalOnError = FlutterError.onError;
          try {
            FlutterError.onError = (details) => errorDetails = details;

            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.dark,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 700),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: ChartPage(
                    columnName: 'FURNACE TEMPERATURE RIGHT',
                    columnIndex: 1,
                    header: const ['DATETIME', 'FURNACE TEMPERATURE RIGHT'],
                    fullData: sampleData,
                    unit: 'kCal/kWh',
                    date: '05 Sep 2026, 20:30',
                    thresholdValue: 1000.0,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          } finally {
            FlutterError.onError = originalOnError;
          }

          expect(errorDetails, isNull,
              reason: 'Overflow occurred on width $width with text scale $scale');
          expect(find.text('MIN'), findsOneWidget);
          expect(find.text('AVG'), findsOneWidget);
          expect(find.text('MAX'), findsOneWidget);
        }
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('ChartPage handles long units and large numbers without overflowing',
        (WidgetTester tester) async {
      final largeData = [
        ['DATETIME', 'NPHR'],
        ['2026-09-05 20:00:00', 2450.0],
        ['2026-09-05 20:10:00', 2480.0],
        ['2026-09-05 20:20:00', 2510.0],
      ];

      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(1.3),
            ),
            child: ChartPage(
              columnName: 'NPHR',
              columnIndex: 1,
              header: const ['DATETIME', 'NPHR'],
              fullData: largeData,
              unit: 'kCal/kWh',
              date: '05 Sep 2026, 20:20',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('ChartPage renders properly when column 0 is not DateTime (fallback timestamp)',
        (WidgetTester tester) async {
      final noDateData = [
        ['UNIT 2 LOAD'],
        [24.5],
        [25.0],
        [26.2],
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ChartPage(
            columnName: 'UNIT 2 LOAD',
            columnIndex: 0,
            header: const ['UNIT 2 LOAD'],
            fullData: noDateData,
            unit: 'MW',
            date: 'Live',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);
      expect(find.text('No Data'), findsNothing);
    });
  });
}
