import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';

// ============================================================================
// TYPOGRAPHY CONSTANTS (KLASIFIKASI FONT MENU GRID)
// Ubah konfigurasi font widget menu grid secara terpusat di bawah ini:
// ============================================================================
abstract final class _MenuGridFonts {
  /// Ubah fontFamily di sini untuk mengganti font pada seluruh Menu Grid.
  /// Contoh: 'Inter', 'Roboto', 'Outfit', atau null untuk default sistem.
  static const String? fontFamily = null;

  // --- 1. Label Menu Utama ---
  static const TextStyle menuLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.2,
  );

  // --- 2. Badge Notifikasi / Counter ---
  static const TextStyle badgeCount = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

class MenuItem {
  final IconData icon;
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

    void add(IconData icon, String label, Color color, String key) {
      all.add(MenuItem(icon: icon, label: label, color: color, onTap: nav[key] ?? (key == 'cfpp' ? nav['plant'] : null)));
    }

    add(Icons.factory_outlined, 'CFPP', AppColors.primary, 'cfpp');
    add(Icons.solar_power_outlined, 'Solar PV', AppColors.solar, 'solar');
    add(Icons.health_and_safety_outlined, 'Hazard Report', AppColors.maintenance, 'hazard');
    add(Icons.inventory_2_outlined, 'Warehouse', AppColors.primary, 'warehouse');
    add(Icons.track_changes_outlined, 'OKR', AppColors.primary, 'okr');

    if (role == op || role == mt) {
      all.add(
        MenuItem(
          icon: Icons.handyman_outlined,
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
          icon: Icons.assignment_outlined,
          label: 'Logsheet',
          color: AppColors.primary,
          onTap: nav['logsheet'],
          hidden: false,
        ),
      );
    }

    if (role == mt) {
      all.add(
        MenuItem(
          icon: Icons.auto_awesome,
          label: 'MSW AI',
          color: AppColors.primary,
          onTap: nav['ai'],
          hidden: false,
        ),
      );
    }

    return all;
  }

  @override
  Widget build(BuildContext context) {
    final visible = items.where((m) => !m.hidden).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: visible.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 98,
        ),
        itemBuilder: (context, index) {
          return _MenuItemCard(item: visible[index]);
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: item.color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: item.color,
                        ),
                      ),
                    ),
                    if (item.badgeCount != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '${item.badgeCount}',
                              style: _MenuGridFonts.badgeCount,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _MenuGridFonts.menuLabel,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

