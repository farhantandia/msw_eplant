import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/widgets/menu_grid.dart';

void main() {
  testWidgets('MenuGrid smoke test', (WidgetTester tester) async {
    final items = MenuGrid.forRole(UserRole.operation, {});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MenuGrid(items: items),
        ),
      ),
    );

    expect(find.text('CFPP'), findsOneWidget);
    expect(find.byIcon(Icons.factory_outlined), findsOneWidget);
  });
}

