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
              icon: '\uD83D\uDD27',
              title: 'Work Order',
              subtitle: 'Daftar WO aktif dan riwayat perbaikan',
              color: AppColors.maintenance,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: '\uD83D\uDCCB',
              title: 'Schedule Maintenance',
              subtitle: 'Jadwal preventive & predictive maintenance',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: '\uD83D\uDD14',
              title: 'Alarm & Notification',
              subtitle: 'Riwayat alarm dan notifikasi peralatan',
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: '\uD83E\uDDF0',
              title: 'Spare Part Inventory',
              subtitle: 'Stok spare part dan komponen kritis',
              color: AppColors.purple,
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: '\uD83D\uDCCA',
              title: 'Equipment Performance',
              subtitle: 'MTBF, MTTR, dan reliability report',
              color: AppColors.general,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String icon, required String title, required String subtitle, required Color color}) {
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
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 12),
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
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('\u203A', style: TextStyle(fontSize: 14, color: color)),
            ),
          ),
        ],
      ),
    );
  }
}
