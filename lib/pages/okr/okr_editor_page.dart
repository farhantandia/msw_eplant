import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/okr_models.dart';
import 'package:msw_eplant/services/okr_service.dart';

class OkrEditorPage extends StatefulWidget {
  const OkrEditorPage({super.key});

  @override
  State<OkrEditorPage> createState() => _OkrEditorPageState();
}

class _OkrEditorPageState extends State<OkrEditorPage> {
  final _service = OkrService();
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

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static const _colorOptions = [
    Color(0xFF00C2FF),
    Color(0xFFC084FC),
    Color(0xFF00E5A0),
    Color(0xFFFFB020),
    Color(0xFFFF4D6A),
    Color(0xFFF472B6),
  ];

  @override
  Widget build(BuildContext context) {
    final objectives = _service.currentObjectives;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('OKR Editor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildYearSelector(),
            const SizedBox(height: 8),
            _buildNewYearButton(),
            const Divider(color: AppColors.border, height: 24),
            _buildSectionLabel('Objectives & Key Results'),
            const SizedBox(height: 8),
            ...objectives.map((obj) => _buildObjectiveEditor(obj)),
            _buildAddObjectiveButton(),
            const SizedBox(height: 12),
            _buildSaveAllButton(),
            const SizedBox(height: 8),
            _buildChangelog(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text.toUpperCase(), style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6)),
          GestureDetector(
            onTap: _addObjective,
            child: const Row(
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Objective', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final years = _service.years.map((y) => y.year).toSet().toList()..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OKR YEAR', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final idx = years.indexOf(_service.currentYear);
                  if (idx > 0) {
                    setState(() => _service.switchYear(years[idx - 1]));
                  }
                },
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textSub)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_service.currentYear}', style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: AppColors.text)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.general.withOpacity(0.1),
                          border: Border.all(color: AppColors.general.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: AppColors.general),
                            SizedBox(width: 5),
                            Text('Active Year', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.general)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final idx = years.indexOf(_service.currentYear);
                  if (idx < years.length - 1) {
                    setState(() => _service.switchYear(years[idx + 1]));
                  }
                },
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSub)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: years.where((y) => y != _service.currentYear).map((y) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$y', style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w600, color: AppColors.textDim)),
                    const SizedBox(width: 3),
                    const Icon(Icons.north_east_rounded, size: 11, color: AppColors.textDim),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewYearButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showNewYearSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 16, color: AppColors.textSub),
              SizedBox(width: 6),
              Text('New Year', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveEditor(Objective obj) {
    final color = _parseHex(obj.color);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
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
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: color.withOpacity(0.15),
                  ),
                  child: Center(child: Text('${obj.order}', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: color))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl('obj_title_${obj.id}', obj.title),
                    style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (v) => obj.title = v,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textDim),
                  color: Colors.black.withOpacity(0.65),
                  onSelected: (val) {
                    if (val == 'delete') _confirmDeleteObjective(obj);
                    if (val == 'color') _showColorPicker(obj);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'color',
                      child: Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 16, color: AppColors.text),
                          SizedBox(width: 8),
                          Text('Color', style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.text)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (obj.keyResults.isNotEmpty)
            ...obj.keyResults.map((kr) => _buildKrEditor(kr, obj)),
          GestureDetector(
            onTap: () => _addKeyResult(obj),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 15, color: AppColors.textDim),
                  SizedBox(width: 5),
                  Text('Add Key Result', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textDim)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKrEditor(KeyResult kr, Objective obj) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x661F2D45))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Text('\uD83D\uDC40', style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textDim)),
          // const SizedBox(width: 7),
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.black.withOpacity(0.65),
            ),
            child: Center(child: Text(kr.label, style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub))),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _ctrl('kr_desc_${kr.id}', kr.description),
                  maxLines: 2,
                  style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Key Result Description',
                    hintStyle: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textDim),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.65),
                    contentPadding: const EdgeInsets.all(6),
                  ),
                  onChanged: (v) => kr.description = v,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _buildSmallDropdown(
                      value: kr.type,
                      items: KrType.values,
                      labelBuilder: (t) {
                        switch (t) {
                          case KrType.numeric:
                            return 'Numerik';
                          case KrType.qualitative:
                            return 'Kualitatif';
                          case KrType.binary:
                            return 'Binary';
                        }
                      },
                      onChanged: (v) => setState(() => kr.type = v),
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _ctrl('kr_target_${kr.id}', kr.target),
                        style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.text),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Target',
                          hintStyle: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textDim),
                          filled: true,
                          fillColor: Color(0xA6000000),
                          contentPadding: EdgeInsets.all(6),
                        ),
                        onChanged: (v) => kr.target = v,
                      ),
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _ctrl('kr_unit_${kr.id}', kr.targetUnit),
                        style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.text),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Satuan',
                          hintStyle: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textDim),
                          filled: true,
                          fillColor: Color(0xA6000000),
                          contentPadding: EdgeInsets.all(6),
                        ),
                        onChanged: (v) => kr.targetUnit = v,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDeleteKr(obj, kr),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.map((t) {
            return DropdownMenuItem(value: t, child: Text(labelBuilder(t), style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildAddObjectiveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _addObjective,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 16, color: AppColors.textSub),
              SizedBox(width: 6),
              Text('Add New Objective', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveAllButton() {
    return GestureDetector(
      onTap: _saveAll,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.maintenance, Color(0xFFFF8C00)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 18, color: Colors.black),
            SizedBox(width: 6),
            Text('Save OKR Structure Changes', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelog() {
    final logs = _service.changelog;
    if (logs.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHANGE HISTORY', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: logs.reversed.take(10).map((log) {
                final date =
                    '${log.timestamp.day} ${_months[log.timestamp.month - 1]} ${log.timestamp.year} \u00B7 ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.description.split('\n').first,
                          style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text('$date \u00B7 ${log.changedBy}',
                          style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
                      if (log.description.contains('\n'))
                        Text(log.description.split('\n').skip(1).join('\n'),
                            style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _addObjective() {
    setState(() {
      final objectives = _service.currentObjectives;
      final newObj = Objective(
        title: 'New Objective',
        order: objectives.length + 1,
      );
      objectives.add(newObj);
    });
  }

  void _addKeyResult(Objective obj) {
    setState(() {
      final nextLabel = String.fromCharCode('a'.codeUnitAt(0) + obj.keyResults.length);
      obj.keyResults.add(KeyResult(
        objectiveId: obj.id,
        label: nextLabel,
        description: '',
        order: obj.keyResults.length + 1,
      ));
    });
  }

  void _showColorPicker(Objective obj) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Objective Color', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((c) {
                  final hex = _colorToHex(c);
                  final isSelected = obj.color == hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => obj.color = hex);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.text, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Center(child: Icon(Icons.check, color: Colors.white, size: 16))
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteObjective(Objective obj) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Delete Objective?', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 6),
              Text('"${obj.title}" and all its Key Results will be permanently deleted.',
                  style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All KR progress data within this Objective will also be deleted and cannot be recovered.',
                        style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.danger, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    final objectives = _service.currentObjectives;
                    objectives.removeWhere((o) => o.id == obj.id);
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Text('Yes, Delete this Objective',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Text('Cancel',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.textSub)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteKr(Objective obj, KeyResult kr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.65),
        title: const Text('Delete Key Result?', style: TextStyle(color: AppColors.text, fontSize: AppTheme.fs14)),
        content: Text('"${kr.description.isEmpty ? 'Key Result' : kr.description}" will be deleted.',
            style: const TextStyle(color: AppColors.textSub, fontSize: AppTheme.fs14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () {
              setState(() => obj.keyResults.removeWhere((k) => k.id == kr.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showNewYearSheet() {
    final nextYear = _service.currentYear + 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.post_add_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Create New Year OKR', style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Choose whether to start from blank or copy structure from the previous year.',
                  style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('$nextYear', style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  _service.addYear(nextYear, copyFromPrevious: true);
                  _service.switchYear(nextYear);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Icon(Icons.circle, color: Colors.white, size: 6)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Copy OKR structure from ${_service.currentYear}',
                              style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          Text('Copy all Objectives & KRs, reset progress to 0',
                              style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _service.addYear(nextYear, copyFromPrevious: false);
                  _service.switchYear(nextYear);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start from blank',
                              style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          const Text('Enter new Objectives & KRs from scratch',
                              style: TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('OKR ${_service.currentYear}',
                            style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('OKR ${_service.currentYear} remains saved and can be viewed via the year selector. No data is deleted.',
                        style: const TextStyle(fontSize: AppTheme.fs14, color: AppColors.textSub, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAll() async {
    for (final obj in _service.currentObjectives) {
      await _service.saveObjective(obj);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OKR structure changes saved'),
        backgroundColor: AppColors.general,
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
