import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/widgets/widgets.dart';

void main() {
  group('Unit Detail Data View & DataCardWidget Tests', () {
    final sampleHeader = [
      'DATETIME',
      'LOAD',
      'MAIN STEAM PRESSURE',
      'FURNACE TEMPERATURE RIGHT',
      'SO2 CONCENTRATION EMISSION',
      'O2 LEVEL',
    ];

    final sampleRecord = [
      '2026-09-05 20:30:00',
      26.4,
      88.5,
      950.2,
      145.8,
      4.2,
    ];

    final sampleFullData = [
      [
        '2026-09-05 20:30:00',
        26.4,
        88.5,
        950.2,
        145.8,
        4.2,
      ]
    ];

    testWidgets('NPHR button is completely removed from Unit Detail Data View',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => buildDataView(
                context,
                sampleHeader,
                sampleRecord,
                sampleFullData,
                0,
                '05 Sep 2026, 20:30',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no button with text 'NPHR' exists
      expect(find.text('NPHR'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'NPHR'), findsNothing);

      // Verify Last Update is rendered with clock icon
      expect(find.text('05 Sep 2026, 20:30'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('Cards are rendered in a ListView and status dots (green/gray) are removed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => buildDataView(
                context,
                sampleHeader,
                sampleRecord,
                sampleFullData,
                0,
                '05 Sep 2026, 20:30',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ListView is used (no GridView)
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // Verify all 5 parameter cards are rendered
      final cards = tester.widgetList<DataCardWidget>(find.byType(DataCardWidget)).toList();
      expect(cards.length, equals(5));

      // Verify NO green/gray status circle dots exist inside DataCardWidget
      final dotFinder = find.descendant(
        of: find.byType(DataCardWidget),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            return decoration.shape == BoxShape.circle;
          }
          return false;
        }),
      );
      expect(dotFinder, findsNothing,
          reason: 'Green and gray status circle dots must be completely removed');

      // Verify NO icons exist inside DataCardWidget (all icons removed as requested)
      final iconFinder = find.descendant(
        of: find.byType(DataCardWidget),
        matching: find.byType(Icon),
      );
      expect(iconFinder, findsNothing,
          reason: 'All icons inside DataCardWidget must be completely removed');

      // Verify parameter count text is clearly visible with prominent styling
      final paramCountFinder = find.text('5 Parameters');
      expect(paramCountFinder, findsOneWidget);
      final paramText = tester.widget<Text>(paramCountFinder);
      expect(paramText.style?.color, equals(AppColors.primary));
      expect(paramText.style?.fontWeight, equals(FontWeight.w700));
      expect(paramText.style?.fontSize, equals(12.0));
    });

    testWidgets('Parameter title and value have uniform typography and font sizes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Column(
              children: [
                DataCardWidget(title: 'LOAD', value: '26.4', unit: 'MW'),
                DataCardWidget(
                  title: 'FURNACE TEMPERATURE RIGHT EXTRA LONG NAME',
                  value: '950.2',
                  unit: '°C',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check titles have uniform 13.0 font size
      final title1 = tester.widget<Text>(find.text('LOAD'));
      final title2 = tester.widget<Text>(find.text('FURNACE TEMPERATURE RIGHT EXTRA LONG NAME'));
      expect(title1.style?.fontSize, equals(13.0));
      expect(title2.style?.fontSize, equals(13.0));
      expect(title1.style?.fontWeight, equals(FontWeight.w600));
      expect(title2.style?.fontWeight, equals(FontWeight.w600));

      // Check values have uniform 20.0 font size
      final val1 = tester.widget<Text>(find.text('26.4'));
      final val2 = tester.widget<Text>(find.text('950.2'));
      expect(val1.style?.fontSize, equals(20.0));
      expect(val2.style?.fontSize, equals(20.0));
      expect(val1.style?.fontWeight, equals(FontWeight.w800));
      expect(val2.style?.fontWeight, equals(FontWeight.w800));
    });

    testWidgets('Zero overflow across multiple screen sizes and text scale factors',
        (WidgetTester tester) async {
      final testSizes = [
        const Size(320, 640),
        const Size(360, 740),
        const Size(412, 915),
      ];
      final scalers = [
        const TextScaler.linear(1.0),
        const TextScaler.linear(1.3),
        const TextScaler.linear(1.5),
      ];

      for (final size in testSizes) {
        for (final scaler in scalers) {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;

          FlutterErrorDetails? errorDetails;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) => errorDetails = details;
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.dark,
                home: MediaQuery(
                  data: MediaQueryData(size: size, textScaler: scaler),
                  child: Scaffold(
                    body: Builder(
                      builder: (context) => buildDataView(
                        context,
                        sampleHeader,
                        sampleRecord,
                        sampleFullData,
                        0,
                        '05 Sep 2026, 20:30',
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          } finally {
            FlutterError.onError = prevOnError;
          }

          if (errorDetails != null) {
            debugPrint("FULL ERROR STRING:\n${errorDetails.toString()}");
          }
          expect(errorDetails, isNull,
              reason: 'Zero overflow expected on ${size.width}x${size.height} at scale ${scaler.scale(1.0)}');
        }
      }
    });
  });
}
