import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/okr_models.dart';
import 'package:msw_eplant/services/okr_service.dart';
import 'package:msw_eplant/widgets/password_gate.dart';

class OkrProgressPage extends StatefulWidget {
  const OkrProgressPage({super.key});

  @override
  State<OkrProgressPage> createState() => _OkrProgressPageState();
}

class _OkrProgressPageState extends State<OkrProgressPage> {
  final _service = OkrService();
  bool _authenticated = false;
  final Map<String, TextEditingController> _ctrls = {};

  TextEditingController _ctrl(String key, String initialText) {
    if (_ctrls.containsKey(key)) return _ctrls[key]!;
    return _ctrls[key] = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Update OKR Progress'),
        ),
        body: _authenticated ? _buildProgressList() : _buildGate(),
      ),
    );
  }

  Widget _buildGate() {
    return SingleChildScrollView(
      child: PasswordGate(
        title: 'Update OKR',
        subtitle: 'Masukkan password Admin untuk mengubah data OKR.\nPerubahan akan langsung tampil ke semua user.',
        icon: '\uD83D\uDD10',
        color: AppColors.maintenance,
        roleLabel: 'OKR Editor',
        roleIcon: '\uD83C\uDFAF',
        roleDescription: 'Edit struktur & update progress semua OKR',
        onUnlock: () => setState(() => _authenticated = true),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProgressList() {
    final objectives = _service.currentObjectives;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              '\uD83D\uDCCA UPDATE PROGRESS KEY RESULTS',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...objectives.expand((obj) {
            return obj.keyResults.map((kr) => _buildKrInputCard(kr, obj));
          }),
          const SizedBox(height: 10),
          _buildSaveAllButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKrInputCard(KeyResult kr, Objective obj) {
    final color = _parseHex(obj.color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: const BorderSide(color: AppColors.border),
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'O${obj.order} \u00B7 ${kr.label}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(kr.description, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: kr.type == KrType.binary ? _buildBinaryInput(kr, color) : _buildNumericInput(kr, color),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericInput(KeyResult kr, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Aktual', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.1),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: (kr.progressPct / 100).clamp(0, 1),
                  onChanged: (v) {
                    setState(() {
                      kr.progressPct = (v * 100).roundToDouble();
                    });
                  },
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: TextField(
                controller: _ctrl('kr_val_${kr.id}', kr.actualValue),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (v) => kr.actualValue = v,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Target: ${kr.target}${kr.targetUnit.isNotEmpty ? ' ${kr.targetUnit}' : ''} \u00B7 Progress: ${kr.progressPct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 14, color: AppColors.textSub),
          ),
        ),
        _buildStatusChips(kr),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl('kr_notes_${kr.id}', kr.notes),
          maxLines: 2,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Catatan / keterangan progress...',
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textDim),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.black.withOpacity(0.65),
            contentPadding: const EdgeInsets.all(8),
          ),
          onChanged: (v) => kr.notes = v,
        ),
      ],
    );
  }

  Widget _buildBinaryInput(KeyResult kr, Color color) {
    final categories = ['Fatality', 'LTI', 'MTC', 'Env. Incident'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.map((cat) {
            return Container(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                border: Border.all(color: AppColors.general.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '0',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.general),
                  ),
                  Text(cat, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        const Text('Tap angka untuk update jika ada insiden', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
        const SizedBox(height: 8),
        _buildStatusChips(kr),
      ],
    );
  }

  Widget _buildStatusChips(KeyResult kr) {
    final statuses = [
      (KrStatus.onTrack, '\u2705 On Track'),
      (KrStatus.onProgress, '\uD83D\uDD04 On Progress'),
      (KrStatus.behind, '\uD83D\uDD34 Behind'),
    ];
    return Row(
      children: statuses.map((s) {
        final selected = kr.status == s.$1;
        Color chipColor;
        switch (s.$1) {
          case KrStatus.onTrack:
            chipColor = AppColors.general;
            break;
          case KrStatus.onProgress:
            chipColor = AppColors.maintenance;
            break;
          case KrStatus.behind:
            chipColor = AppColors.danger;
            break;
          default:
            chipColor = AppColors.textSub;
        }
        return GestureDetector(
          onTap: () => setState(() => kr.status = s.$1),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? chipColor.withOpacity(0.08) : Colors.transparent,
              border: Border.all(color: selected ? chipColor : AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              s.$2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? chipColor : AppColors.textSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveAllButton() {
    return GestureDetector(
      onTap: () async {
        for (final obj in _service.currentObjectives) {
          for (final kr in obj.keyResults) {
            await _service.saveKeyResult(kr);
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua perubahan progress OKR tersimpan'), backgroundColor: AppColors.general),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.maintenance, Color(0xFFFF8C00)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Text(
              '\uD83D\uDCBE Simpan Semua & Update Firestore',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            SizedBox(height: 4),
            Text(
              'Data akan tersimpan ke Firestore dan langsung tampil real-time ke semua pengguna app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
