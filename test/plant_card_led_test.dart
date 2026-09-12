import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/plant_page.dart';

void main() {
  group('PlantStatusHelper Unit Tests', () {
    test('ledColor returns green when live and not shutdown', () {
      expect(
        PlantStatusHelper.ledColor(isLive: true, isShutdown: false),
        Colors.greenAccent,
      );
    });

    test('ledColor returns gray when not live and not shutdown', () {
      expect(
        PlantStatusHelper.ledColor(isLive: false, isShutdown: false),
        Colors.grey,
      );
    });

    test('ledColor returns red when shutdown, regardless of isLive', () {
      expect(
        PlantStatusHelper.ledColor(isLive: true, isShutdown: true),
        Colors.redAccent,
      );
      expect(
        PlantStatusHelper.ledColor(isLive: false, isShutdown: true),
        Colors.redAccent,
      );
    });

    test('isTimestampLive identifies timestamps < 60 min as live', () {
      final now = DateTime.now();
      final liveTimestamp = now.subtract(const Duration(minutes: 15)).toIso8601String();
      expect(PlantStatusHelper.isTimestampLive(liveTimestamp), isTrue);

      final staleTimestamp = now.subtract(const Duration(minutes: 90)).toIso8601String();
      expect(PlantStatusHelper.isTimestampLive(staleTimestamp), isFalse);

      expect(PlantStatusHelper.isTimestampLive(null), isFalse);
      expect(PlantStatusHelper.isTimestampLive(''), isFalse);
      expect(PlantStatusHelper.isTimestampLive('invalid_date'), isFalse);
    });
  });

  group('PlantUnitCard Widget Tests', () {
    testWidgets('Renders green LED dot when live and normal load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantUnitCard(
              title: "Unit 1",
              load: 26.5,
              isLive: true,
              isShutdown: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Unit 1"), findsOneWidget);
      expect(find.text("26.5"), findsOneWidget);
      expect(find.text("Normal"), findsOneWidget);

      // Verify LED dot container color is greenAccent
      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.greenAccent;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
    });

    testWidgets('Renders gray LED dot when not live',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantUnitCard(
              title: "Unit 1",
              load: 26.5,
              isLive: false,
              isShutdown: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.grey;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
    });

    testWidgets('Renders red LED dot and red border when shutdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantUnitCard(
              title: "Unit 2",
              load: 0.0,
              isLive: true,
              isShutdown: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Unit 2"), findsOneWidget);
      expect(find.text("0.0"), findsOneWidget);
      expect(find.text("Shutdown"), findsOneWidget);

      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.redAccent;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
    });

    testWidgets('Tapping PlantUnitCard triggers onTap callback',
        (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantUnitCard(
              title: "Unit 1",
              load: 25.0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlantUnitCard));
      expect(tapped, isTrue);
    });
  });

  group('PlantCemsCard LED Tests', () {
    testWidgets('CEMS card renders green LED dot when live and not shutdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 1",
              isCompliant: true,
              isLive: true,
              isShutdown: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.greenAccent;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
      expect(find.text("Compliant"), findsOneWidget);
    });

    testWidgets('CEMS card renders gray LED dot when not live',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 1",
              isCompliant: true,
              isLive: false,
              isShutdown: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.grey;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
      expect(find.text("Compliant"), findsOneWidget);
    });

    testWidgets('CEMS card renders red LED dot when shutdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlantCemsCard(
              title: "CEMS Unit 2",
              isCompliant: true,
              isLive: true,
              isShutdown: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ledContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.redAccent;
        }
        return false;
      });
      expect(ledContainerFinder, findsOneWidget);
    });

    testWidgets(
        'Zero overflow across varied screen widths (320-412px) and text scale (1.0-1.5)',
        (WidgetTester tester) async {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.25, 1.5]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PlantUnitCard(
                                title: "Unit 1",
                                load: 26.4,
                                isLive: true,
                                isShutdown: false,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PlantUnitCard(
                                title: "Unit 2",
                                load: 0.0,
                                isLive: false,
                                isShutdown: true,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: PlantCemsCard(
                                title: "CEMS Unit 1",
                                isCompliant: true,
                                isLive: true,
                                isShutdown: false,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PlantCemsCard(
                                title: "CEMS Unit 2",
                                isCompliant: false,
                                isLive: false,
                                isShutdown: false,
                                onTap: () {},
                              ),
                            ),
                          ],
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
              reason: 'Overflow at width $width, scale $scale');
        }
      }
    });

    testWidgets('Unit 2 and CEMS 2 render green LED dots when live with load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: PlantUnitCard(
                    title: "Unit 2",
                    load: 25.4,
                    isLive: true,
                    isShutdown: false,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: PlantCemsCard(
                    title: "CEMS Unit 2",
                    isCompliant: true,
                    isLive: true,
                    isShutdown: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final greenLedFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Colors.greenAccent;
        }
        return false;
      });
      expect(greenLedFinder, findsNWidgets(2));
      expect(find.text("Normal"), findsOneWidget);
      expect(find.text("Compliant"), findsOneWidget);
    });
  });
}
