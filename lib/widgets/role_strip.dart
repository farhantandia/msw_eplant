import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';

class RoleStrip extends StatelessWidget {
  final UserRole role;
  final String? subtitle;

  const RoleStrip({super.key, required this.role, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roleColor(role.label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.06),
      child: Row(
        children: [
          Icon(role.iconData, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            role.label,
            style: TextStyle(
              fontSize: AppTheme.fs14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),

          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub),
            ),
        ],
      ),
    );
  }
}
