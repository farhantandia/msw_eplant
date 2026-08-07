import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/pages/settings_page.dart';
import 'package:msw_eplant/pages/manual_input_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _launchHazardReportForm(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSfI2lnY6aPm7mfI9eN0Rpw1e3XjKVuvXlUzBik-g-gZZNgLvw/viewform',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka form. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.8),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("More"), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildListItem(
              context,
              icon: Icons.settings,
              title: "Settings",
              subtitle: "Data presentation, decimal places",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage(role: UserRole.maintenance)),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildListItem(
              context,
              icon: Icons.edit_note,
              title: "Manual Input",
              subtitle: "Sales, target, revenue",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualInputPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildListItem(
              context,
              icon: Icons.report_problem_outlined,
              title: "Hazard Report",
              subtitle: "Submit safety reports",
              onTap: () => _launchHazardReportForm(context),
            ),
            const SizedBox(height: 12),
            _buildListItem(
              context,
              icon: Icons.info_outline,
              title: "About",
              subtitle: "App information",
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "MSW ePlant Monitor APP",
                  applicationVersion: "3.0.0",
                  applicationIcon: const Icon(Icons.power),
                  children: const [
                    Text("A comprehensive app to monitor MSW Power Plant data."),
                    SizedBox(height: 8),
                    Text("Developed by Farhan Tandia."),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: Colors.black.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
