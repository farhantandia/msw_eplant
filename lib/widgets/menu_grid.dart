import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';

class MenuItem {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badgeCount;
  final bool hidden;

  const MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badgeCount,
    this.hidden = false,
  });
}

class MenuGrid extends StatelessWidget {
  final List<MenuItem> items;

  const MenuGrid({super.key, required this.items});

  static List<MenuItem> forRole(UserRole role, Map<String, VoidCallback> nav) {
    final all = <MenuItem>[];
    final op = UserRole.operation;
    final mt = UserRole.maintenance;

    void add(String icon, String label, Color color, String key) {
      all.add(MenuItem(icon: icon, label: label, color: color, onTap: nav[key]));
    }

    add('\uD83C\uDFED', 'Plant', AppColors.primary, 'plant');
    add('\uD83D\uDCA8', 'CEMS', const Color(0xFF00BCD4), 'cems');
    add('\u2600\uFE0F', 'Solar PV', AppColors.general, 'solar');
    add('\uD83D\uDCCA', 'Analytics', const Color(0xFF38BDF8), 'analytics');
    add('\u26A0\uFE0F', 'Hazard Report', AppColors.maintenance, 'hazard');
    add('\uD83D\uDCE6', 'Warehouse', AppColors.purple, 'warehouse');
    add('\uD83C\uDFAF', 'OKR', AppColors.pink, 'okr');

    if (role == op || role == mt) {
      all.add(
        MenuItem(
          icon: '\uD83D\uDD27',
          label: 'Maintenance',
          color: AppColors.maintenance,
          onTap: nav['maintenance'],
          badgeCount: role == mt ? 3 : null,
          hidden: role == op,
        ),
      );
    }

    if (role == op) {
      all.add(
        MenuItem(
          icon: '\uD83D\uDCCB',
          label: 'Logsheet',
          color: AppColors.primary,
          onTap: nav['logsheet'],
          hidden: false,
        ),
      );
    }

    if (role == mt) {
      all.add(
        MenuItem(icon: '\uD83E\uDD16', label: 'MSW AI', color: AppColors.purple, onTap: nav['ai'], hidden: false),
      );
    }

    return all;
  }

  @override
  Widget build(BuildContext context) {
    final visible = items.where((m) => !m.hidden).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: visible.map((m) {
          return _MenuItemCard(item: m);
        }).toList(),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4;
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: item.color.withOpacity(0.14),
                      ),
                      child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        // fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                if (item.badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${item.badgeCount}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
