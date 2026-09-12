import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/plant_page.dart';
import 'package:msw_eplant/services/cems_threshold_service.dart';

void main() {
  group('CEMS 4-Parameter Threshold & Compliance Unit Tests', () {
    final normalHeader = [
      'DATETIME',
      'SO2 CORRECTION',
      'NOX CORRECTION',
      'PARTICULATE O2',
      'HG CORRECTION',
    ];

    test('All 4 parameters within limit returns compliant (true)', () {
      final data = [
        normalHeader,
        ['2026-09-05 20:00:00', 120.0, 240.0, 25.0, 0.015],
      ];
      expect(CemsThresholdService.isDataCompliant(data), isTrue);
    });

    test('SO2 exceeding 550 mg/Nm3 returns not compliant (false)', () {
      final data = [
        normalHeader,
        ['2026-09-05 20:00:00', 551.0, 240.0, 25.0, 0.015],
      ];
      expect(CemsThresholdService.isDataCompliant(data), isFalse);
    });

    test('NOX exceeding 550 mg/Nm3 returns not compliant (false)', () {
      final data = [
        normalHeader,
        ['2026-09-05 20:00:00', 120.0, 560.5, 25.0, 0.015],
      ];
      expect(CemsThresholdService.isDataCompliant(data), isFalse);
    });

    test('PARTICULATE exceeding 50 mg/Nm3 returns not compliant (false)', () {
      final data = [
        normalHeader,
        ['2026-09-05 20:00:00', 120.0, 240.0, 50.8, 0.015],
      ];
      expect(CemsThresholdService.isDataCompliant(data), isFalse);
    });

    test('HG exceeding 0.03 mg/Nm3 returns not compliant (false)', () {
      final data = [
        normalHeader,
        ['2026-09-05 20:00:00', 120.0, 240.0, 25.0, 0.035],
      ];
      expect(CemsThresholdService.isDataCompliant(data), isFalse);
    });

    test('Handles short aliases (SO2, NOX, PARTICULATE, HG)', () {
      final shortHeader = ['SO2', 'NOX', 'PARTICULATE', 'HG'];
      final compliantData = [
        shortHeader,
        [300.0, 400.0, 30.0, 0.02],
      ];
      expect(CemsThresholdService.isDataCompliant(compliantData), isTrue);

      final exceedData = [
        shortHeader,
        [300.0, 600.0, 30.0, 0.02],
      ];
      expect(CemsThresholdService.isDataCompliant(exceedData), isFalse);
    });

    test('Handles fallback data when primary cemsData is empty', () {
      final fallback = [
        normalHeader,
        ['2026-09-05 20:00:00', 100.0, 150.0, 20.0, 0.01],
      ];
      expect(CemsThresholdService.isDataCompliant([], fallback), isTrue);

      final fallbackExceed = [
        normalHeader,
        ['2026-09-05 20:00:00', 100.0, 150.0, 55.0, 0.01],
      ];
      expect(CemsThresholdService.isDataCompliant([], fallbackExceed), isFalse);
    });
  });

  group('PlantCemsCard Widget Tests', () {
    testWidgets('Renders "Compliant" with green accent and check icon when compliant',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 1",
              isCompliant: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("CEMS Unit 1"), findsOneWidget);
      expect(find.text("Compliant"), findsOneWidget);
      expect(find.text("Non-Compliant"), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      // Verify text color is greenAccent
      final textWidget = tester.widget<Text>(find.text("Compliant"));
      expect(textWidget.style?.color, Colors.greenAccent);
    });

    testWidgets(
        'Renders "Non-Compliant" with red accent and warning icon when parameter exceeds limit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 2",
              isCompliant: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("CEMS Unit 2"), findsOneWidget);
      expect(find.text("Non-Compliant"), findsOneWidget);
      expect(find.text("Compliant"), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Verify text color is redAccent
      final textWidget = tester.widget<Text>(find.text("Non-Compliant"));
      expect(textWidget.style?.color, Colors.redAccent);
    });

    testWidgets('Tapping PlantCemsCard triggers onTap callback',
        (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 1",
              isCompliant: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlantCemsCard));
      expect(tapped, isTrue);
    });

    testWidgets(
        'Side-by-side CEMS cards render without overflow across screen sizes and text scale factors',
        (WidgetTester tester) async {
      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        for (final textScale in [1.0, 1.25, 1.5]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 700),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: PlantCemsCard(
                            title: "CEMS Unit 1",
                            isCompliant: true,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PlantCemsCard(
                            title: "CEMS Unit 2",
                            isCompliant: false,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason:
                  'Overflow occurred at width $width with textScale $textScale');
          expect(find.text("Compliant"), findsOneWidget);
          expect(find.text("Non-Compliant"), findsOneWidget);
        }
      }
    });
  });
}
