import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';

class PasswordGate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final String roleLabel;
  final String roleIcon;
  final String roleDescription;
  final VoidCallback onUnlock;
  final VoidCallback? onCancel;

  const PasswordGate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.roleLabel,
    required this.roleIcon,
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
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
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
                    color: roleIcon.contains('AI') || roleIcon.contains('OKR')
                        ? AppColors.general.withOpacity(0.1)
                        : color.withOpacity(0.1),
                  ),
                  child: Center(child: Text(roleIcon, style: const TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleLabel,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Text(roleDescription, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
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
              color: Colors.black.withOpacity(0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Text('\uD83D\uDD11', style: TextStyle(fontSize: 14)),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    obscureText: true,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Masukkan password',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
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
                gradient: LinearGradient(
                  colors: [color, color == AppColors.purple ? const Color(0xFF9333EA) : const Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Text(
                '\uD83D\uDD13 Buka $title',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
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
                  'Batal',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Lupa password? Hubungi Admin IC&IT\nuntuk reset via Firestore Console.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textDim, height: 1.5),
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6),
      ),
    );
  }
}
