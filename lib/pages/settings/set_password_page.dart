import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/services/auth_service.dart';

class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final Map<String, TextEditingController> _ctrls = {};

  TextEditingController _ctrl(String key) {
    if (_ctrls.containsKey(key)) return _ctrls[key]!;
    return _ctrls[key] = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Set Password'),
        ),
        body: _buildPasswordList(),
      ),
    );
  }

  Future<void> _savePassword(String scope, String label) async {
    final newPass = _ctrl('${scope}_new').text.trim();
    final confirm = _ctrl('${scope}_confirm').text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
      _showMessage('New password and confirmation are required', AppColors.danger);
      return;
    }
    if (newPass != confirm) {
      _showMessage('Password and confirmation do not match', AppColors.danger);
      return;
    }
    if (newPass.length < 4) {
      _showMessage('Password must be at least 4 characters', AppColors.danger);
      return;
    }

    await AuthService.setPassword(scope, newPass);
    _ctrl('${scope}_new').clear();
    _ctrl('${scope}_confirm').clear();
    if (mounted) _showMessage('Password for $label saved', AppColors.general);
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPasswordList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Login passwords are saved on device (SharedPreferences). Each scope has its own password and is effective immediately without updating the app.',
              style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'PASSWORD PER ROLE',
              style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6),
            ),
          ),
          _buildRolePasswordCard(
            scope: 'operation',
            icon: Icons.bolt_rounded,
            label: 'Operation',
            color: AppColors.primary,
            hint: 'Used when logging in as Shift Operator. Share with Shift Leader and Operators.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            scope: 'maintenance',
            icon: Icons.handyman_outlined,
            label: 'Maintenance',
            color: AppColors.maintenance,
            hint: 'Used when logging in as Maintenance Technician. Share with maintenance team.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            scope: 'general',
            icon: Icons.factory_outlined,
            label: 'General',
            color: AppColors.pink,
            hint: 'Used when logging in as Guest / MSW Employee (view only). Share with general staff.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            scope: 'okr_editor',
            icon: Icons.track_changes_outlined,
            label: 'OKR Editor',
            color: AppColors.general,
            hint: 'Special password for OKR Editor in Admin Menu. Separate from role login passwords.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            scope: 'admin',
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin Master',
            color: AppColors.purple,
            hint: 'Master password \u2014 to access this Set Password page. Keep safe, for IC&IT Supervisor only.',
            lastChanged: '3 Jan 2026',
            isMaster: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRolePasswordCard({
    required String scope,
    required IconData icon,
    required String label,
    required Color color,
    required String hint,
    required String lastChanged,
    bool isMaster = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border: Border(
                bottom: const BorderSide(color: AppColors.border),
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.15)),
                  child: Center(child: Icon(icon, size: 16, color: color)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMaster ? AppColors.purple.withOpacity(0.1) : AppColors.general.withOpacity(0.1),
                    border: Border.all(
                      color: isMaster ? AppColors.purple.withOpacity(0.2) : AppColors.general.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMaster ? Icons.shield_outlined : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: isMaster ? AppColors.purple : AppColors.general,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMaster ? 'Master' : 'Configured',
                        style: TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: FontWeight.w700,
                          color: isMaster ? AppColors.purple : AppColors.general,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hint, style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.4)),
                const SizedBox(height: 10),
                _buildInputGroup('${scope}_new', 'New Password', 'Enter new password'),
                const SizedBox(height: 10),
                _buildInputGroup('${scope}_confirm', 'Confirm Password', 'Re-enter new password'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _savePassword(scope, label),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          'Save $label Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String key, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: AppTheme.fs14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: _ctrl(key),
            obscureText: true,
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
                fontSize: AppTheme.fs14,
                color: AppColors.textDim,
              ),
            ),
          ),
        ),
      ],
    );
  }
}