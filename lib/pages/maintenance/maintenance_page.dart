import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

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
        appBar: AppBar(title: const Text('Maintenance'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              icon: Icons.engineering_outlined,
              title: 'Work Order',
              subtitle: 'Active WO list and repair history',
              color: AppColors.maintenance,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.calendar_month_outlined,
              title: 'Schedule Maintenance',
              subtitle: 'Preventive & predictive maintenance schedule',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.notifications_active_outlined,
              title: 'Alarm & Notification',
              subtitle: 'Equipment alarm and notification history',
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.insights_outlined,
              title: 'Equipment Performance',
              subtitle: 'MTBF, MTTR, and reliability reports',
              color: AppColors.general,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, size: 20, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Icon(Icons.chevron_right_rounded, size: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
