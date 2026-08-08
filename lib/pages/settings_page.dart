import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/services/auth_service.dart';
import 'package:msw_eplant/services/notification_service.dart';
import 'package:msw_eplant/pages/admin_menu_page.dart';
import 'package:msw_eplant/pages/manual_input_page.dart';

class SettingsPage extends StatefulWidget {
  final UserRole role;
  const SettingsPage({super.key, required this.role});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _decimalPlaces = 1;
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() {
        _decimalPlaces = prefs.getInt('decimal_places') ?? 1;
        _notifEnabled = prefs.getBool('notification_enabled') ?? true;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Settings",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // _buildTopBar(),
                _buildSectionLabel('Umum'),
                _buildMenuList([
                  _MenuItemData(
                    icon: '\uD83D\uDD22',
                    label: 'Format Angka',
                    subtitle: 'Desimal: $_decimalPlaces angka',
                    color: AppColors.general,
                    onTap: _openFormatAngka,
                  ),
                  _MenuItemData(
                    icon: '\uD83D\uDD14',
                    label: 'Notifikasi',
                    subtitle: _notifEnabled ? 'Daily reminder 08:00 WITA aktif' : 'Daily reminder nonaktif',
                    color: AppColors.maintenance,
                    onTap: _openNotifikasi,
                  ),
                  // _MenuItemData(
                  //   icon: '\uD83D\uDCDD',
                  //   label: 'Manual Input',
                  //   subtitle: 'Sales, target, revenue',
                  //   color: AppColors.primary,
                  //   onTap: _openManualInput,
                  // ),
                ]),
                _buildSectionLabel('Admin Area'),
                _buildMenuList([
                  _MenuItemData(
                    icon: '\uD83D\uDEE1',
                    label: 'Admin Menu',
                    subtitle: 'OKR Editor & Set Password Login',
                    color: AppColors.general,
                    isProtected: false, // Set to true if you want to require password for admin menu
                    onTap: _openAdminMenu,
                  ),
                ]),
                _buildSectionLabel('Tentang'),
                _buildAppInfo(),
                const SizedBox(height: 16),
                _buildLogoutButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset('asset/logo_login.png', width: 28, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setting',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              Text('MSW ePlant v2.0.0', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6),
      ),
    );
  }

  Widget _buildMenuList(List<_MenuItemData> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.value;
          final isLast = entry.key == items.length - 1;
          return GestureDetector(
            onTap: i.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: i.color.withOpacity(0.1)),
                    child: Center(child: Text(i.icon, style: const TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        if (i.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(i.subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
                          ),
                      ],
                    ),
                  ),
                  if (i.isProtected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.maintenance.withOpacity(0.1),
                        border: Border.all(color: AppColors.maintenance.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PASSWORD',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.maintenance),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Text('\u203A', style: TextStyle(fontSize: 14, color: AppColors.textDim)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppInfo() {
    return GestureDetector(
      onTap: () {
        showAboutDialog(
          
                  context: context,
                  applicationName: "MSW ePlant Monitor APP",
                  applicationVersion: "3.0.0",
                  applicationIcon: const Icon(Icons.power),
                  children: const [
                    Text("A comprehensive app to monitor MSW Power Plant data."),
                    SizedBox(height: 8),
                    Text("Developed by Farhan Tandia."),
                  ],
                );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('asset/logo_login.png', width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MSW ePlant',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                Text(
                  'v3.0.0 \u00B7 PT Makmur Sejahtera Wisesa',
                  style: TextStyle(fontSize: 14, color: AppColors.textSub),
                ),
                Text('Build: Jul 2026', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Text(
          'Logout',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Logout?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Yakin ingin keluar dari akun?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;

    await AuthService.clearSession();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _openFormatAngka() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDim.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Format Angka',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  const Text('Pilih jumlah angka desimal', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
                  const SizedBox(height: 16),
                  ...List.generate(4, (i) {
                    final val = i;
                    final selected = _decimalPlaces == val;
                    return GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('decimal_places', val);
                        if (mounted) setState(() => _decimalPlaces = val);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$val',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.primary : AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              val == 0
                                  ? 'Tanpa desimal (contoh: 10)'
                                  : val == 1
                                  ? '1 desimal (contoh: 10.5)'
                                  : val == 2
                                  ? '2 desimal (contoh: 10.50)'
                                  : '3 desimal (contoh: 10.500)',
                              style: TextStyle(fontSize: 14, color: AppColors.textSub),
                            ),
                            const Spacer(),
                            if (selected) const Icon(Icons.check, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openNotifikasi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDim.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atur notifikasi dan reminder harian',
                    style: TextStyle(fontSize: 14, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 16),
                  _notifTile(
                    icon: Icons.notifications_active,
                    title: 'Daily Reminder 08:00 WITA',
                    subtitle: _notifEnabled ? 'Aktif' : 'Nonaktif',
                    trailing: Switch(
                      value: _notifEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notification_enabled', v);
                        if (v) {
                          await NotificationService.scheduleDailyReminder();
                        }
                        if (mounted) setState(() => _notifEnabled = v);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await NotificationService.requestNotificationPermission();
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(const SnackBar(content: Text('Izin notifikasi diperbarui')));
                      }
                    },
                    child: _notifTile(
                      icon: Icons.shield_outlined,
                      title: 'Izin Notifikasi',
                      subtitle: 'Pastikan izin notifikasi aktif',
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await NotificationService.scheduleTestNotification();
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(const SnackBar(content: Text('Test notifikasi dikirim dalam 3 menit')));
                      }
                      Navigator.pop(ctx);
                    },
                    child: _notifTile(
                      icon: Icons.send_outlined,
                      title: 'Kirim Test Notifikasi',
                      subtitle: 'Terima notifikasi dalam 3 menit',
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _notifTile({required IconData icon, required String title, required String subtitle, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.maintenance),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _openAdminMenu() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMenuPage()));
  }

  void _openManualInput() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualInputPage()));
  }
}

class _MenuItemData {
  final String icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isProtected;
  final VoidCallback? onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.isProtected = false,
    this.onTap,
  });
}
