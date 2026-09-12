import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/pages/settings/settings_page.dart';
import 'package:msw_eplant/pages/settings/admin_menu_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'decimal_places': 1,
      'notification_enabled': true,
    });
  });

  group('SettingsPage English Localization Tests', () {
    testWidgets('Renders all section labels and menu items in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(role: UserRole.general),
        ),
      );
      await tester.pumpAndSettle();

      // Section labels
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('ADMIN AREA'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Menu items
      expect(find.text('Number Format'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Admin Menu'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Subtitle checks
      expect(find.textContaining('Decimals: 1 digit'), findsOneWidget);
      expect(find.textContaining('Daily reminder 08:00 WITA active'), findsOneWidget);

      // Verify absence of old Indonesian strings
      expect(find.text('UMUM'), findsNothing);
      expect(find.text('Format Angka'), findsNothing);
      expect(find.text('Notifikasi'), findsNothing);
      expect(find.text('TENTANG'), findsNothing);
      expect(find.textContaining('angka'), findsNothing);
      expect(find.textContaining('aktif'), findsNothing);
    });

    testWidgets('Tapping Number Format displays English bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(role: UserRole.general),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Number Format'));
      await tester.pumpAndSettle();

      expect(find.text('Select decimal places'), findsOneWidget);
      expect(find.text('No decimals (e.g. 10)'), findsOneWidget);
      expect(find.text('1 decimal (e.g. 10.5)'), findsOneWidget);
    });

    testWidgets('AdminMenuPage renders all items in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminMenuPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADMIN MENU'), findsOneWidget);
      expect(find.text('OKR Editor'), findsOneWidget);
      expect(find.text('Manage OKR structure & progress'), findsOneWidget);
      expect(find.text('Set Password'), findsOneWidget);
      expect(find.text('Change login passwords for all roles'), findsOneWidget);

      expect(find.text('MENU ADMIN'), findsNothing);
      expect(find.text('Kelola struktur & progress OKR'), findsNothing);
      expect(find.text('Ubah password login semua role'), findsNothing);
    });
  });
}
