import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'logsheet_service.dart';
import 'logsheet_entry_page.dart';
import 'package:msw_eplant/constants/theme.dart';

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
        title: const Text("Delete Draft", style: TextStyle(color: Colors.white)),
        content: Text(
          "Delete ${area == 'boiler' ? 'Boiler' : 'Steam Turbine'} draft?",
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
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
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
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
              _buildSectionTitle("CREATE NEW"),
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
              _buildSectionTitle("SAVED DRAFTS"),
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
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _service.isSignedIn
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: AppTheme.fs14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                if (_service.isSignedIn)
                  Text(
                    "Google Sheets ready",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppTheme.fs14, color: Colors.grey[400]),
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
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Center(
        child: Text(
          "No drafts yet. Start entering data by selecting an area above.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: AppTheme.fs14),
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, String> draft) {
    return LogsheetDraftCard(
      draft: draft,
      onOpen: () => _openArea(draft['area']!),
      onDelete: () => _deleteDraft(draft['area']!),
      formattedEdited: _formatEdited(draft['lastEdited']),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fs14,
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
            colors: gradientColors.map((c) => c.withValues(alpha: 0.6)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: AppTheme.fs14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: AppTheme.fs14, color: Colors.grey[300])),
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

class LogsheetDraftCard extends StatelessWidget {
  final Map<String, String> draft;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final String formattedEdited;

  const LogsheetDraftCard({
    super.key,
    required this.draft,
    required this.onOpen,
    required this.onDelete,
    required this.formattedEdited,
  });

  Widget _buildBadge({
    required String label,
    required Color textColor,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 0.8)
            : null,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppTheme.fs12,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = draft['area'] ?? '';
    final isBoiler = area == 'boiler';
    final slot = draft['slot'] ?? '';
    final operatorName = draft['operator'] ?? '';
    final supervisor = draft['supervisor'] ?? '';
    final shift = draft['shift'] ?? '';
    final unit = draft['unit'] == '1' ? 'Unit 2' : 'Unit 1';
    final hasMeta = operatorName.isNotEmpty ||
        supervisor.isNotEmpty ||
        formattedEdited.isNotEmpty;

    final Color accentColor = isBoiler ? Colors.orange : Colors.cyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          isBoiler
                              ? Icons.local_fire_department_rounded
                              : Icons.settings_power_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBoiler ? 'Boiler' : 'Steam Turbine',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppTheme.fs15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (unit.isNotEmpty)
                                  _buildBadge(
                                    label: unit,
                                    textColor: Colors.grey[300]!,
                                    bgColor:
                                        Colors.white.withValues(alpha: 0.08),
                                  ),
                                if (slot.isNotEmpty)
                                  _buildBadge(
                                    label: slot,
                                    textColor: Colors.cyanAccent,
                                    bgColor:
                                        Colors.cyanAccent.withValues(alpha: 0.15),
                                    borderColor:
                                        Colors.cyanAccent.withValues(alpha: 0.3),
                                  ),
                                if (shift.isNotEmpty && shift != '0')
                                  _buildBadge(
                                    label: "Shift $shift",
                                    textColor: Colors.amberAccent,
                                    bgColor:
                                        Colors.amberAccent.withValues(alpha: 0.15),
                                    borderColor:
                                        Colors.amberAccent.withValues(alpha: 0.3),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 20, color: Colors.white24),
                      ),
                    ],
                  ),
                  if (hasMeta) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 1,
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (operatorName.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  operatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppTheme.fs12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (supervisor.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_outlined,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  supervisor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppTheme.fs12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (formattedEdited.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  formattedEdited,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppTheme.fs12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
