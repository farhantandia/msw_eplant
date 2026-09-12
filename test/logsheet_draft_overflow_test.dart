import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/logsheet/logsheet_page.dart';

void main() {
  group('LogsheetDraftCard Overflow & Functional Tests', () {
    final sampleDraft = {
      'area': 'steam_turbine',
      'slot': '08:00',
      'operator': 'Muhammad Farhan Tandia',
      'supervisor': 'Ir. Budi Santoso, M.T.',
      'shift': '1',
      'unit': '1',
      'lastEdited': '2026-09-05T20:30:00Z',
    };

    testWidgets('Renders all draft information accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LogsheetDraftCard(
                draft: sampleDraft,
                onOpen: () {},
                onDelete: () {},
                formattedEdited: '10m ago',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Steam Turbine'), findsOneWidget);
      expect(find.text('Unit 2'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Shift 1'), findsOneWidget);
      expect(find.text('Muhammad Farhan Tandia'), findsOneWidget);
      expect(find.text('Ir. Budi Santoso, M.T.'), findsOneWidget);
      expect(find.text('10m ago'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('onOpen and onDelete callbacks fire on user interactions',
        (WidgetTester tester) async {
      bool opened = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LogsheetDraftCard(
                draft: sampleDraft,
                onOpen: () => opened = true,
                onDelete: () => deleted = true,
                formattedEdited: '10m ago',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the delete button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);

      // Tap the card to open
      await tester.tap(find.text('Steam Turbine'));
      expect(opened, isTrue);
    });

    testWidgets(
        'Zero overflow on varied screen widths (320-412px) and text scale (1.0-1.5x) with long names',
        (WidgetTester tester) async {
      final longDraft = {
        'area': 'steam_turbine',
        'slot': '12:00 - 14:00',
        'operator': 'Operator Muhammad Farhan Tandia Sangat Panjang Sekali',
        'supervisor': 'Supervisor Ir. H. Budi Santoso, M.T., Ph.D.',
        'shift': '3',
        'unit': '1',
        'lastEdited': '2026-09-05T20:30:00Z',
      };

      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        for (final scale in [1.0, 1.25, 1.5]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          FlutterErrorDetails? errorDetails;
          final originalOnError = FlutterError.onError;
          try {
            FlutterError.onError = (details) {
              errorDetails = details;
            };

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
                          LogsheetDraftCard(
                            draft: longDraft,
                            onOpen: () {},
                            onDelete: () {},
                            formattedEdited: '05 Sep 2026, 20:30',
                          ),
                          const SizedBox(height: 12),
                          LogsheetDraftCard(
                            draft: {
                              'area': 'boiler',
                              'slot': '08:00',
                              'operator': 'Budi',
                              'supervisor': '',
                              'shift': '1',
                              'unit': '0',
                              'lastEdited': '',
                            },
                            onOpen: () {},
                            onDelete: () {},
                            formattedEdited: '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          } finally {
            FlutterError.onError = originalOnError;
          }

          if (errorDetails != null) {
            debugPrint("FULL ERROR STRING:\n${errorDetails.toString()}");
          }
          expect(
            errorDetails,
            isNull,
            reason: 'Overflow occurred at width $width with text scale $scale',
          );
        }
      }
      tester.view.resetPhysicalSize();
    });
  });
}
