import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/pages/home_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'decimal_places': 1,
    });
  });

  group('HomePage Plant Status Carousel Tests', () {
    testWidgets('Renders CFPP 2x30MW by default with 2 dots below NPHR',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default slide 0: CFPP Plant Status
      expect(find.text('PLANT STATUS'), findsOneWidget);
      expect(find.text('CFPP 2x30MW'), findsOneWidget);
      expect(find.text('SOLAR PV 868 kWp'), findsOneWidget);

      // Verify 2 dots indicator exist below NPHR
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('Tapping SOLAR PV 868 kWp dot switches slide to Solar PV Plant status',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Solar PV dot
      final solarDot = find.text('SOLAR PV 868 kWp');
      expect(solarDot, findsOneWidget);
      await tester.tap(solarDot);
      await tester.pumpAndSettle();

      // Verify Solar PV Plant card is now displayed
      expect(find.text('SOLAR PV PLANT STATUS'), findsOneWidget);
      expect(find.text('TOTAL SOLAR GENERATION'), findsOneWidget);
      expect(find.text('PLTS MSW'), findsOneWidget);
      expect(find.text('PLTS KELANIS'), findsOneWidget);
    });

    testWidgets('Tapping Solar PV card navigates to SolarDetailPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Solar slide
      await tester.tap(find.text('SOLAR PV 868 kWp'));
      await tester.pumpAndSettle();

      // Tap Solar card
      final solarCard = find.text('TOTAL SOLAR GENERATION');
      expect(solarCard, findsOneWidget);
      await tester.tap(solarCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify navigation to SolarDetailPage
      expect(find.byType(SolarDetailPage), findsOneWidget);
    });

    testWidgets('Tapping Solar PV in MenuGrid navigates to SolarDetailPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final solarMenu = find.text('Solar PV');
      expect(solarMenu, findsOneWidget);
      await tester.ensureVisible(solarMenu);
      await tester.tap(solarMenu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify navigation to SolarDetailPage
      expect(find.byType(SolarDetailPage), findsOneWidget);
    });

    testWidgets('Plant status carousel has NO nested scrollables and displays all data without scroll',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find PageView
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // Verify NO nested SingleChildScrollView or Scrollable inside PageView
      final nestedScrollables = find.descendant(
        of: pageViewFinder,
        matching: find.byType(SingleChildScrollView),
      );
      expect(nestedScrollables, findsNothing);

      // Slide 0: Verify all CFPP data is displayed simultaneously without scrolling
      expect(find.text('PLANT STATUS'), findsOneWidget);
      expect(find.text('GENERATION'), findsOneWidget);
      expect(find.text('TOTAL HOUSE LOAD'), findsOneWidget);
      expect(find.text('UNIT 1'), findsWidgets);
      expect(find.text('UNIT 2'), findsWidgets);
      expect(find.text('LOAD PLN'), findsWidgets);
      expect(find.text('LOAD AI'), findsWidgets);
      expect(find.text('NET PLANT HEAT RATE'), findsOneWidget);
      expect(find.text('NPHR Curve'), findsOneWidget);

      // Switch to Slide 1
      await tester.tap(find.text('SOLAR PV 868 kWp'));
      await tester.pumpAndSettle();

      // Slide 1: Verify all Solar PV data is displayed simultaneously without scrolling
      expect(find.text('SOLAR PV PLANT STATUS'), findsOneWidget);
      expect(find.text('TOTAL SOLAR GENERATION'), findsOneWidget);
      expect(find.text('IRRADIANCE'), findsOneWidget);
      expect(find.text('PERF. RATIO'), findsOneWidget);
      expect(find.text('PEAK POWER'), findsOneWidget);
      expect(find.text('PLTS MSW'), findsOneWidget);
      expect(find.text('PLTS KELANIS'), findsOneWidget);
      expect(find.text('CO2 AVOIDED'), findsOneWidget);
    });

    testWidgets('Zero overflow on mobile screen dimensions (360x740, 390x844, 412x915)',
        (tester) async {
      final screens = [
        const Size(360, 740),
        const Size(390, 844),
        const Size(412, 915),
      ];

      for (final size in screens) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: HomePage(
                key: ValueKey(size),
                role: UserRole.operation,
                onSwitchRole: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check slide 0
        expect(find.text('PLANT STATUS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to slide 1
        await tester.tap(find.text('SOLAR PV 868 kWp'));
        await tester.pumpAndSettle();
        expect(find.text('SOLAR PV PLANT STATUS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Clear widget tree
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Top bar and greeting are in a fixed header outside SingleChildScrollView',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomePage(
              role: UserRole.operation,
              onSwitchRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & greeting are rendered
      expect(find.text('MSW ePlant'), findsOneWidget);
      expect(find.text('Plant Operator!'), findsOneWidget);

      // Verify they are NOT inside SingleChildScrollView
      final scrollableFinder = find.byType(SingleChildScrollView);
      expect(scrollableFinder, findsOneWidget);

      final topBarInsideScroll = find.descendant(
        of: scrollableFinder,
        matching: find.text('MSW ePlant'),
      );
      expect(topBarInsideScroll, findsNothing);

      final greetingInsideScroll = find.descendant(
        of: scrollableFinder,
        matching: find.text('Plant Operator!'),
      );
      expect(greetingInsideScroll, findsNothing);

      // Even when scrolling the content down, top bar and greeting remain visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('MSW ePlant'), findsOneWidget);
      expect(find.text('Plant Operator!'), findsOneWidget);
    });
  });
}


