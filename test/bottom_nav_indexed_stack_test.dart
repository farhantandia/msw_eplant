import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/main.dart';
import 'package:msw_eplant/pages/home_page.dart';
import 'package:msw_eplant/pages/plant_page.dart';
import 'package:msw_eplant/pages/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_role': 'operation',
      'remember_me': true,
    });
  });

  group('Bottom Navigation IndexedStack State Preservation Tests', () {
    testWidgets('MainScreen uses IndexedStack to host tab pages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify IndexedStack exists in widget tree
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);

      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0)); // Initially Home tab
      expect(indexedStack.children.length, equals(4));

      // Home tab and Plant tab widgets exist in the tree simultaneously
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(PlantPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);
    });

    testWidgets('Switching tabs updates IndexedStack index without rebuilding from scratch',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Operation tab (index 1)
      await tester.tap(find.text('Operation'));
      await tester.pumpAndSettle();

      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(1));

      // Tap Setting tab (index 3)
      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(3));

      // Tap Home tab (index 0)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(0));

      // Confirm HomePage remained mounted the entire time
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
