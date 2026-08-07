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
          Text(
            '${role.icon}  ${role.label}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
        ],
      ),
    );
  }
}
