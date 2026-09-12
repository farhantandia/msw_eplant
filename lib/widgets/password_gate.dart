import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';

class PasswordGate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? icon;
  final IconData? iconData;
  final Color color;
  final String roleLabel;
  final String? roleIcon;
  final IconData? roleIconData;
  final String roleDescription;
  final VoidCallback onUnlock;
  final VoidCallback? onCancel;

  const PasswordGate({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconData,
    required this.color,
    required this.roleLabel,
    this.roleIcon,
    this.roleIconData,
    required this.roleDescription,
    required this.onUnlock,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                iconData ?? (roleLabel.contains('OKR') ? Icons.track_changes_outlined : Icons.lock_outline_rounded),
                size: 22,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      roleIconData ?? (roleLabel.contains('OKR') ? Icons.track_changes_outlined : Icons.admin_panel_settings_outlined),
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleLabel,
                        style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Text(roleDescription, style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildLabel('Password $roleLabel'),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textDim),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    obscureText: true,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter password',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: AppTheme.fs14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onUnlock,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_open_rounded, size: 18, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Unlock $title',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onCancel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Forgot password? Contact IC&IT Admin\nto reset via Firestore Console.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textDim, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6),
      ),
    );
  }
}
