import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logsheet_service.dart';
import 'logsheet_models.dart';

class LogsheetEntryPage extends StatefulWidget {
  final String area;
  final GoogleSheetsService service;

  const LogsheetEntryPage({
    super.key,
    required this.area,
    required this.service,
  });

  @override
  State<LogsheetEntryPage> createState() => _LogsheetEntryPageState();
}

class _LogsheetEntryPageState extends State<LogsheetEntryPage> {
  static const _prefPrefix = 'logsheet_draft_';

  int _step = 1;
  int _selectedUnit = 0;
  int _shift = 1;
  final TextEditingController _operatorCtrl = TextEditingController();
  final TextEditingController _supervisorCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  String? _newOperator;
  String? _newSupervisor;
  List<String> _operatorList = ["- Select -"];
  List<String> _supervisorList = ["- Select -"];
  bool _otherOperator = false;
  bool _otherSupervisor = false;
  List<String> _availableSlots = [];
  String? _selectedSlot;
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  List<String> _fieldKeys = [];
  Timer? _autoSaveTimer;
  bool _saving = false;
  String? _spreadsheetId;
  bool _loading = false;

  List<FieldGroup> get _groups =>
      widget.area == "boiler" ? boilerGroups : steamTurbineGroups;

  String _pk(String key) => '$_prefPrefix${widget.area}_$key';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _shift = getShiftFromHour(now.hour);
    _availableSlots = getAvailableSlots(now);
    _selectedSlot = _availableSlots.isNotEmpty ? _availableSlots.last : null;
    _loadOperatorList();
    _initFieldControllers();
    _restoreDraft();
    _autoSaveTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _saveDraft());
    _setupSheet();
  }

  Future<void> _loadOperatorList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> ops = prefs.getStringList('logsheet_operators') ?? [];
      List<String> sups = prefs.getStringList('logsheet_supervisors') ?? [];

      if (ops.isEmpty) {
        ops = [
          "MASRUDI", "YUSUF ADHANTO", "ADI RIFKI SATRIO", "HELMI RIDANY",
          "ROSYID RIDLO", "MUHAMMAD EKHSAN", "YAMANI", "SYAMSUL",
          "SUMARDI", "MUHAMMAD SYARFAINI", "ZAINAL FAHMI", "RAHMAD AFANDI",
          "RIDHO AZHAR", "EFINDI HIDAYAT", "HAFIZ ANSHARI", "MUHAMMAD MAKI",
          "NANDA RISANDI", "SUMMA SANJAYA S.", "ARY SUHARTO", "SANDY HIDAYAT",
          "FADLI", "AKHMAD KISWARI", "TAHSYAR RUSADI", "NUR IKHSAN DAMARJATI",
          "NUR HORO'U", "JUNAIDI", "JUFRI SANUARI", "ANSHARI AMIN",
          "M. SYAIFURRAHMAN", "HASAN", "FRENGKI",
        ];
        await prefs.setStringList('logsheet_operators', ops);
      }

      if (sups.isEmpty) {
        sups = [
          "AGUNG TRIYONO", "SALFIANNUR", "HERMAN HARIYANTO", "RUDI HARTANTO",
        ];
        await prefs.setStringList('logsheet_supervisors', sups);
      }

      setState(() {
        _operatorList = ["- Select -", ...ops, "Lainnya..."];
        _supervisorList = ["- Select -", ...sups, "Lainnya..."];
      });
    } catch (_) {}
  }

  Future<void> _saveOperatorList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ops = prefs.getStringList('logsheet_operators') ?? [];
      final sups = prefs.getStringList('logsheet_supervisors') ?? [];
      if (_newOperator != null && !ops.contains(_newOperator)) {
        ops.add(_newOperator!);
        await prefs.setStringList('logsheet_operators', ops);
      }
      if (_newSupervisor != null && !sups.contains(_newSupervisor)) {
        sups.add(_newSupervisor!);
        await prefs.setStringList('logsheet_supervisors', sups);
      }
    } catch (_) {}
  }

  void _initFieldControllers() {
    _fieldKeys = [];
    for (var group in _groups) {
      for (var field in group.fields) {
        _fieldKeys.add(field.id);
        _fieldControllers[field.id] = TextEditingController();
        _focusNodes[field.id] = FocusNode();
      }
    }
  }

  Future<void> _setupSheet() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final sheetName = getSheetName(now);
    final spreadsheetName = getSpreadsheetName(
        widget.area, _selectedUnit, now);

    _spreadsheetId =
        await widget.service.findOrCreateSpreadsheet(spreadsheetName);
    if (_spreadsheetId != null) {
      await widget.service.ensureSheet(_spreadsheetId!, sheetName, widget.area);
      await _loadExistingData();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadExistingData() async {
    if (_spreadsheetId == null) return;
    final sheetName = getSheetName(DateTime.now());
    final data =
        await widget.service.getExistingData(_spreadsheetId!, sheetName);
    if (data == null || _selectedSlot == null) return;

    final existingSlot = data.where((e) => e["Time"] == _selectedSlot).toList();
    if (existingSlot.isEmpty) return;

    for (var group in _groups) {
      for (var field in group.fields) {
        final key = getHeaderLabel(field);
        if (existingSlot.first.containsKey(key)) {
          _fieldControllers[field.id]?.text = existingSlot.first[key] ?? "";
        }
      }
    }
    _remarkCtrl.text = existingSlot.first["Remark"] ?? "";
  }

  void _generateDummyData() {
    final rng = Random();
    for (var group in _groups) {
      for (var field in group.fields) {
        if (field.isStatus) {
          _fieldControllers[field.id]?.text =
              rng.nextBool() ? "No.1" : "No.2";
        } else {
          double? lo = field.minNormal;
          double? hi = field.maxNormal;

          double value;
          if (lo != null && hi != null) {
            value = lo + rng.nextDouble() * (hi - lo);
          } else if (lo != null) {
            value = lo + rng.nextDouble() * (lo * 0.4);
          } else if (hi != null) {
            value = rng.nextDouble() * hi;
          } else {
            value = rng.nextDouble() * 100;
          }

          int decimals = _guessDecimals(lo, hi);
          double variation =
              (rng.nextDouble() - 0.5) * 0.08 * (value + 1);
          value = (value + variation).clamp(0, double.infinity);

          _fieldControllers[field.id]?.text =
              value.toStringAsFixed(decimals);
        }
      }
    }
    setState(() {});
  }

  int _guessDecimals(double? lo, double? hi) {
    for (var v in [lo, hi]) {
      if (v == null) continue;
      String s = v.toString();
      int dot = s.indexOf('.');
      if (dot != -1) {
        int d = s.length - dot - 1;
        if (d > 0) return d;
      }
    }
    return 1;
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setInt(_pk('step'), _step);
      await prefs.setInt(_pk('unit'), _selectedUnit);
      await prefs.setInt(_pk('shift'), _shift);
      await prefs.setBool(_pk('otherOperator'), _otherOperator);
      await prefs.setBool(_pk('otherSupervisor'), _otherSupervisor);
      await prefs.setString(_pk('operator'), _operatorCtrl.text);
      await prefs.setString(_pk('supervisor'), _supervisorCtrl.text);
      await prefs.setString(_pk('remark'), _remarkCtrl.text);
      await prefs.setString(_pk('slot'), _selectedSlot ?? '');
      await prefs.setString(_pk('lastEdited'), DateTime.now().toIso8601String());
      for (var key in _fieldKeys) {
        await prefs.setString(_pk('f_$key'), _fieldControllers[key]?.text ?? '');
      }
      List<String> drafts = prefs.getStringList('logsheet_drafts') ?? [];
      if (!drafts.contains(widget.area)) {
        drafts.add(widget.area);
        await prefs.setStringList('logsheet_drafts', drafts);
      }
    } catch (_) {}
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _step = prefs.getInt(_pk('step')) ?? 1;
      _selectedUnit = prefs.getInt(_pk('unit')) ?? 0;
      _otherOperator = prefs.getBool(_pk('otherOperator')) ?? false;
      _otherSupervisor = prefs.getBool(_pk('otherSupervisor')) ?? false;
      _operatorCtrl.text = prefs.getString(_pk('operator')) ?? '';
      _supervisorCtrl.text = prefs.getString(_pk('supervisor')) ?? '';
      _remarkCtrl.text = prefs.getString(_pk('remark')) ?? '';
      final savedSlot = prefs.getString(_pk('slot')) ?? '';
      if (_availableSlots.contains(savedSlot)) {
        _selectedSlot = savedSlot;
      }
      for (var key in _fieldKeys) {
        final val = prefs.getString(_pk('f_$key'));
        if (val != null) {
          _fieldControllers[key]?.text = val;
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_spreadsheetId == null || _selectedSlot == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
        content: Text(
          "Simpan data untuk jam $_selectedSlot ke Google Sheets?",
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.8),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);

    await _saveOperatorList();
    Map<String, String> fieldValues = {};
    for (var group in _groups) {
      for (var field in group.fields) {
        fieldValues[field.id] = _fieldControllers[field.id]?.text ?? "";
      }
    }

    final err = await widget.service.saveTimeSlot(
      spreadsheetId: _spreadsheetId!,
      sheetName: getSheetName(DateTime.now()),
      groups: _groups,
      timeSlot: _selectedSlot!,
      operatorName: _operatorCtrl.text,
      shift: _shift,
      supervisor: _supervisorCtrl.text,
      remark: _remarkCtrl.text,
      fieldValues: fieldValues,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (err == null) {
        await _clearDraft();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data berhasil disimpan"),
              backgroundColor: Colors.greenAccent,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Data gagal disimpan: $err"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_prefPrefix${widget.area}_';
    for (var key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix)) await prefs.remove(key);
    }
    List<String> drafts = prefs.getStringList('logsheet_drafts') ?? [];
    drafts.remove(widget.area);
    await prefs.setStringList('logsheet_drafts', drafts);
  }

  bool get _step1Valid =>
      _operatorCtrl.text.isNotEmpty &&
      _operatorCtrl.text != "- Select -" &&
      _supervisorCtrl.text.isNotEmpty &&
      _supervisorCtrl.text != "- Select -";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black87,
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "${widget.area == "boiler" ? "Boiler" : "Steam Turbine"} Logsheet",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (_step == 2)
              IconButton(
                tooltip: "Generate dummy data",
                icon: const Icon(Icons.shuffle, color: Colors.cyanAccent),
                onPressed: _generateDummyData,
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              )
            : _step == 1
                ? _buildStep1()
                : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("UNIT"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildToggle("Unit 1", _selectedUnit == 0, () {
                      setState(() {
                        _selectedUnit = 0;
                        _setupSheet();
                      });
                      _saveDraft();
                    }),
                    const SizedBox(width: 12),
                    _buildToggle("Unit 2", _selectedUnit == 1, () {
                      setState(() {
                        _selectedUnit = 1;
                        _setupSheet();
                      });
                      _saveDraft();
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionLabel("SHIFT (otomatis)"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.cyanAccent),
                      const SizedBox(width: 8),
                      Text(
                        getShiftLabel(_shift),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("NAMA OPERATOR"),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _otherOperator ? "Lainnya..." : _operatorCtrl.text,
                  items: _operatorList,
                  onChanged: (v) {
                    if (v == "Lainnya...") {
                      setState(() {
                        _otherOperator = true;
                        _operatorCtrl.text = "";
                      });
                    } else {
                      setState(() {
                        _otherOperator = false;
                        _operatorCtrl.text = v ?? "";
                      });
                    }
                  },
                ),
                if (_otherOperator) ...[
                  const SizedBox(height: 8),
                  _buildTextField(_operatorCtrl, "Ketik nama operator"),
                ],
                const SizedBox(height: 16),
                _buildSectionLabel("NAMA SUPERVISOR"),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _otherSupervisor
                      ? "Lainnya..."
                      : _supervisorCtrl.text,
                  items: _supervisorList,
                  onChanged: (v) {
                    if (v == "Lainnya...") {
                      setState(() {
                        _otherSupervisor = true;
                        _supervisorCtrl.text = "";
                      });
                    } else {
                      setState(() {
                        _otherSupervisor = false;
                        _supervisorCtrl.text = v ?? "";
                      });
                    }
                  },
                ),
                if (_otherSupervisor) ...[
                  const SizedBox(height: 8),
                  _buildTextField(_supervisorCtrl, "Ketik nama supervisor"),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _step1Valid
                ? () {
                    setState(() => _step = 2);
                    _saveDraft();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Lanjut ke Input Data",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildSlotSelector(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 4),
              ..._groups.map((group) => _buildAccordionGroup(group)),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel("REMARK / CATATAN"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Keterangan tambahan...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text("Generate Random Data",
                      style: TextStyle(fontSize: 14)),
                  onPressed: _generateDummyData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          "Simpan Data Jam $_selectedSlot",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          Text("Time Slot: ",
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ..._availableSlots.map((slot) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(slot,
                      style: TextStyle(
                          fontSize: 14,
                          color: _selectedSlot == slot
                              ? Colors.black
                              : Colors.white)),
                  selected: _selectedSlot == slot,
                  selectedColor: Colors.cyanAccent,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  onSelected: (v) {
                    if (v) {
                      setState(() => _selectedSlot = slot);
                      _loadExistingData();
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAccordionGroup(FieldGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ExpansionTile(
          title: Text(group.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          subtitle: Text("${group.fields.length} parameter",
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          iconColor: Colors.cyanAccent,
          collapsedIconColor: Colors.grey,
          initiallyExpanded: group == _groups.first,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: group.fields
                    .map((f) => _buildFieldInput(f))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fieldBoundary(LogsheetField field) {
    if (field.minNormal != null && field.maxNormal != null) {
      return "${field.minNormal!.toStringAsFixed(1)} – ${field.maxNormal!.toStringAsFixed(1)} ${field.unit}";
    } else if (field.minNormal != null) {
      return "Min ${field.minNormal!.toStringAsFixed(1)} ${field.unit}";
    } else if (field.maxNormal != null) {
      return "Max ${field.maxNormal!.toStringAsFixed(1)} ${field.unit}";
    } else if (field.unit.isNotEmpty) {
      return "Monitor";
    }
    return "";
  }

  Widget _buildFieldInput(LogsheetField field) {
    final ctrl = _fieldControllers[field.id]!;
    final fn = _focusNodes[field.id]!;
    final color = field.indicatorColor(ctrl.text);
    final idx = _fieldKeys.indexOf(field.id);
    final isLast = idx == _fieldKeys.length - 1;
    final boundary = _fieldBoundary(field);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                if (boundary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      boundary,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              focusNode: fn,
              textInputAction:
                  isLast ? TextInputAction.done : TextInputAction.next,
              keyboardType:
                  field.isStatus ? null : TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: color == Colors.greenAccent
                    ? Colors.white
                    : color,
              ),
              decoration: InputDecoration(
                hintText: field.isStatus ? "No.1/No.2" : "0",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: color == Colors.greenAccent
                        ? Colors.grey.withOpacity(0.2)
                        : color,
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: color == Colors.greenAccent
                        ? Colors.grey.withOpacity(0.2)
                        : color,
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (!isLast) {
                  final nextKey = _fieldKeys[idx + 1];
                  _focusNodes[nextKey]?.requestFocus();
                } else {
                  _focusNodes[_fieldKeys.last]?.unfocus();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Text(field.unit,
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8),
    );
  }

  Widget _buildToggle(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.cyanAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.cyanAccent : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    String? validValue =
        (value != null && value.isNotEmpty && items.contains(value))
            ? value
            : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isExpanded: true,
          hint: const Text("Pilih", style: TextStyle(color: Colors.grey)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _operatorCtrl.dispose();
    _supervisorCtrl.dispose();
    _remarkCtrl.dispose();
    for (var ctrl in _fieldControllers.values) {
      ctrl.dispose();
    }
    for (var fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }
}
