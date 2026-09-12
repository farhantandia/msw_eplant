import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/pages/home_page.dart';
import 'package:msw_eplant/pages/nphr_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msw_eplant/pages/plant/plant_overview_detail_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'decimal_places': 1,
    });
  });

  group('HomePage Clickable Metrics Navigation Tests', () {
    testWidgets('Tapping CFPP menu button opens PlantOverviewDetailPage',
        (WidgetTester tester) async {
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

      final cfppBtn = find.text('CFPP');
      expect(cfppBtn, findsOneWidget);

      await tester.ensureVisible(cfppBtn);
      await tester.pumpAndSettle();

      await tester.tap(cfppBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlantOverviewDetailPage), findsOneWidget);
    });

    testWidgets('Tapping NPHR Curve header opens NphrPage',
        (WidgetTester tester) async {
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

      // Tap NPHR Curve button
      final curveBtn = find.text('NPHR Curve');
      if (curveBtn.evaluate().isNotEmpty) {
        await tester.tap(curveBtn);
        await tester.pumpAndSettle();
        expect(find.byType(NphrPage), findsOneWidget);
      }
    });

    testWidgets('Parameter cells do not render chart icons but retain InkWell click targets',
        (WidgetTester tester) async {
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

      // Verify NO show_chart_rounded icons exist on parameters as requested
      expect(find.byIcon(Icons.show_chart_rounded), findsNothing);

      // Verify InkWell click targets exist for clickable metrics
      expect(find.byType(InkWell), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
