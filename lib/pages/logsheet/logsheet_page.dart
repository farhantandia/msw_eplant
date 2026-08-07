import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'logsheet_service.dart';
import 'logsheet_entry_page.dart';

class LogsheetPage extends StatefulWidget {
  const LogsheetPage({super.key});

  @override
  State<LogsheetPage> createState() => _LogsheetPageState();
}

class _LogsheetPageState extends State<LogsheetPage> {
  final GoogleSheetsService _service = GoogleSheetsService();
  List<Map<String, String>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _checkSignIn();
    _loadDrafts();
  }

  Future<void> _checkSignIn() async {
    if (_service.isSignedIn) setState(() {});
  }

  Future<void> _handleSignIn() async {
    final err = await _service.signIn();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign in failed: $err")),
      );
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSignOut() async {
    await _service.signOut();
    if (mounted) setState(() {});
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> draftAreas = prefs.getStringList('logsheet_drafts') ?? [];
    List<Map<String, String>> list = [];
    for (var area in draftAreas) {
      final p = 'logsheet_draft_${area}_';
      final slot = prefs.getString('${p}slot') ?? '';
      final operatorName = prefs.getString('${p}operator') ?? '';
      final supervisor = prefs.getString('${p}supervisor') ?? '';
      final shift = prefs.getInt('${p}shift') ?? 0;
      final lastEdited = prefs.getString('${p}lastEdited') ?? '';
      final step = prefs.getInt('${p}step') ?? 1;
      final unit = prefs.getInt('${p}unit') ?? 0;
      list.add({
        'area': area,
        'slot': slot,
        'operator': operatorName,
        'supervisor': supervisor,
        'shift': shift.toString(),
        'lastEdited': lastEdited,
        'step': step.toString(),
        'unit': unit.toString(),
      });
    }
    list.sort((a, b) => b['lastEdited']!.compareTo(a['lastEdited']!));
    if (mounted) setState(() => _drafts = list);
  }

  void _openArea(String area) {
    if (!_service.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in with Google first")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogsheetEntryPage(area: area, service: _service),
      ),
    ).then((_) => _loadDrafts());
  }

  Future<void> _deleteDraft(String area) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Hapus Draft", style: TextStyle(color: Colors.white)),
        content: Text(
          "Hapus draft ${area == 'boiler' ? 'Boiler' : 'Steam Turbine'}?",
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final prefix = 'logsheet_draft_${area}_';
    for (var key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix)) await prefs.remove(key);
    }
    List<String> drafts = prefs.getStringList('logsheet_drafts') ?? [];
    drafts.remove(area);
    await prefs.setStringList('logsheet_drafts', drafts);
    _loadDrafts();
  }

  String _formatEdited(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}h lalu';
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Logsheet",
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAuthSection(),
              const SizedBox(height: 24),
              _buildSectionTitle("BUAT BARU"),
              const SizedBox(height: 12),
              _buildAreaCard(
                icon: Icons.local_fire_department,
                title: "Boiler",
                subtitle: "F-MSW-OPR-06-009",
                gradientColors: [Colors.orange.shade800, Colors.red.shade900],
                onTap: () => _openArea("boiler"),
              ),
              const SizedBox(height: 12),
              _buildAreaCard(
                icon: Icons.settings_power,
                title: "Steam Turbine",
                subtitle: "F-MSW-OPR-06-011",
                gradientColors: [Colors.cyan.shade800, Colors.blue.shade900],
                onTap: () => _openArea("steam_turbine"),
              ),
              const SizedBox(height: 12),
              _buildSectionTitle("DRAFT TERSIMPAN"),
              const SizedBox(height: 12),
              if (_drafts.isEmpty) _buildEmptyDraft(),
              ..._drafts.map((d) => _buildDraftCard(d)),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _service.isSignedIn
                  ? Colors.greenAccent.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _service.isSignedIn ? Icons.check_circle : Icons.account_circle,
              color: _service.isSignedIn ? Colors.greenAccent : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _service.isSignedIn
                      ? (_service.account?.email ?? "Connected")
                      : "Not connected",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                if (_service.isSignedIn)
                  Text(
                    "Google Sheets ready",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed:
                _service.isSignedIn ? _handleSignOut : _handleSignIn,
            child: Text(
              _service.isSignedIn ? "Sign Out" : "Sign In",
              style: TextStyle(
                  color: _service.isSignedIn
                      ? Colors.redAccent
                      : Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDraft() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Center(
        child: Text(
          "Belum ada draft. Mulai isi data dengan memilih area diatas.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, String> draft) {
    final area = draft['area']!;
    final slot = draft['slot'] ?? '';
    final operatorName = draft['operator'] ?? '';
    final supervisor = draft['supervisor'] ?? '';
    final shift = draft['shift'] ?? '';
    final edited = _formatEdited(draft['lastEdited']);
    final unit = draft['unit'] == '1' ? 'Unit 2' : 'Unit 1';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _openArea(area),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: area == 'boiler'
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  area == 'boiler'
                      ? Icons.local_fire_department
                      : Icons.settings_power,
                  color: area == 'boiler' ? Colors.orange : Colors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          area == 'boiler' ? 'Boiler' : 'Steam Turbine',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (slot.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              slot,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (operatorName.isNotEmpty)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline,
                                    size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    operatorName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[400]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        if (supervisor.isNotEmpty)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_outlined,
                                    size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    supervisor,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[400]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (edited.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 11, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(edited,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (shift.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                  ),
                  child: Text(
                    "Shift $shift",
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _deleteDraft(area),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right,
                  size: 20, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAreaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors.map((c) => c.withOpacity(0.6)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[300])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
