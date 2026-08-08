import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/services/auth_service.dart';
import 'package:msw_eplant/pages/okr_editor_page.dart';
import 'package:msw_eplant/pages/set_password_page.dart';

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Admin Menu'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMenuList([
                  _AdminMenuItemData(
                    icon: '\uD83C\uDFAF',
                    label: 'OKR Editor',
                    subtitle: 'Kelola struktur & progress OKR',
                    color: AppColors.general,
                    scope: 'okr_editor',
                    onTap: _openOkrEditor,
                  ),
                  _AdminMenuItemData(
                    icon: '\uD83D\uDD11',
                    label: 'Set Password',
                    subtitle: 'Ubah password login semua role',
                    color: AppColors.purple,
                    scope: 'admin',
                    onTap: _openSetPassword,
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSub,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuList(List<_AdminMenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Menu Admin'),
        const SizedBox(height: 6),
        Container(
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: i.color.withOpacity(0.1),
                        ),
                        child: Center(child: Text(i.icon, style: const TextStyle(fontSize: 14))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            if (i.subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  i.subtitle!,
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSub),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: i.color.withOpacity(0.1),
                          border: Border.all(color: i.color.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: i.color,
                          ),
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
        ),
      ],
    );
  }

  void _openOkrEditor() {
    _requirePassword(
      AppColors.general,
      'OKR Editor',
      'okr_editor',
      () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OkrEditorPage()));
      },
    );
  }

  void _openSetPassword() {
    _requirePassword(
      AppColors.purple,
      'Set Password',
      'admin',
      () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPasswordPage()));
      },
    );
  }

  void _requirePassword(Color color, String label, String scope, VoidCallback onSuccess) {
    final ctl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          label.contains('Password') ? '\uD83D\uDD11' : '\uD83C\uDFAF',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Password $label',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan password untuk membuka menu ini',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        border: Border.all(color: error != null ? AppColors.danger : AppColors.border),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          const Text('\uD83D\uDD11', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: ctl,
                              obscureText: true,
                              style: const TextStyle(color: AppColors.text, fontSize: 14),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Masukkan password',
                                hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
                              ),
                              onChanged: (_) => setDlgState(() => error = null),
                              onSubmitted: (_) async {
                                final ok = await AuthService.verifyPasswordScope(scope, ctl.text);
                                if (ctx.mounted) {
                                  if (ok) {
                                    Navigator.pop(ctx);
                                    onSuccess();
                                  } else {
                                    setDlgState(() => error = 'Password salah');
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('\u26A0\uFE0F', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                          const SizedBox(width: 4),
                          Text(error!, style: const TextStyle(fontSize: 14, color: AppColors.danger)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSub),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await AuthService.verifyPasswordScope(scope, ctl.text);
                    if (ctx.mounted) {
                      if (ok) {
                        Navigator.pop(ctx);
                        onSuccess();
                      } else {
                        setDlgState(() => error = 'Password salah');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Buka', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AdminMenuItemData {
  final String icon;
  final String label;
  final String? subtitle;
  final Color color;
  final String scope;
  final VoidCallback? onTap;

  const _AdminMenuItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.scope,
    this.onTap,
  });
}