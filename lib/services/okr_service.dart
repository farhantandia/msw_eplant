import 'package:msw_eplant/models/okr_models.dart';

class OkrService {
  static final OkrService _instance = OkrService._();
  factory OkrService() => _instance;
  OkrService._() {
    _initDummy();
  }

  final Map<int, List<Objective>> _data = {};
  final List<OkrYear> _years = [];
  final Map<int, List<OkrChangelog>> _changelogs = {};
  int _currentYear = 2026;

  int get currentYear => _currentYear;
  List<OkrYear> get years => List.unmodifiable(_years);
  List<Objective> get currentObjectives =>
      List.unmodifiable(_data[_currentYear] ?? []);

  void switchYear(int year) {
    if (_data.containsKey(year)) {
      _currentYear = year;
    }
  }

  Future<void> addYear(int year, {bool copyFromPrevious = false}) async {
    if (_data.containsKey(year)) return;
    if (copyFromPrevious && _data.containsKey(year - 1)) {
      final prev = _data[year - 1]!;
      _data[year] = prev.map((o) {
        final newId = '${DateTime.now().millisecondsSinceEpoch}_${o.order}';
        return Objective(
          id: newId,
          title: o.title,
          color: o.color,
          order: o.order,
          keyResults: o.keyResults.map((kr) {
            return KeyResult(
              objectiveId: newId,
              label: kr.label,
              description: kr.description,
              type: kr.type,
              target: kr.target,
              targetUnit: kr.targetUnit,
              phaseOptions: List.from(kr.phaseOptions),
              order: kr.order,
            );
          }).toList(),
        );
      }).toList();
    } else {
      _data[year] = [];
    }
    _years.add(OkrYear(year: year, isActive: true));
    _changelogs[year] = [];
  }

  Future<void> saveObjective(Objective obj) async {
    _data[_currentYear] ??= [];
    final idx = _data[_currentYear]!.indexWhere((o) => o.id == obj.id);
    if (idx >= 0) {
      _data[_currentYear]![idx] = obj;
    } else {
      _data[_currentYear]!.add(obj);
    }
    _addChangelog('${idx >= 0 ? "Update" : "Tambah"} Objective: ${obj.title}');
  }

  Future<void> deleteObjective(String objId) async {
    _data[_currentYear]?.removeWhere((o) => o.id == objId);
    _addChangelog('Hapus Objective');
  }

  Future<void> reorderObjectives(int oldIndex, int newIndex) async {
    final list = _data[_currentYear];
    if (list == null) return;
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (int i = 0; i < list.length; i++) {
      list[i].order = i + 1;
    }
    _addChangelog('Urutan Objective diubah');
  }

  Future<void> saveKeyResult(KeyResult kr) async {
    final objectives = _data[_currentYear];
    if (objectives == null) return;
    final obj = objectives.firstWhere(
      (o) => o.id == kr.objectiveId,
      orElse: () => Objective(title: ''),
    );
    if (obj.title.isEmpty) return;
    final idx = obj.keyResults.indexWhere((k) => k.id == kr.id);
    if (idx >= 0) {
      obj.keyResults[idx] = kr;
    } else {
      obj.keyResults.add(kr);
      obj.keyResults.sort((a, b) => a.order.compareTo(b.order));
    }
    _addChangelog('Update KR: ${kr.description}');
  }

  Future<void> deleteKeyResult(String objId, String krId) async {
    final objectives = _data[_currentYear];
    if (objectives == null) return;
    final obj = objectives.firstWhere((o) => o.id == objId);
    obj.keyResults.removeWhere((k) => k.id == krId);
    _addChangelog('Hapus Key Result');
  }

  List<OkrChangelog> get changelog =>
      List.unmodifiable(_changelogs[_currentYear] ?? []);

  void _addChangelog(String desc) {
    _changelogs[_currentYear] ??= [];
    _changelogs[_currentYear]!.add(OkrChangelog(description: desc));
  }

  void _initDummy() {
    _years.addAll([
      OkrYear(year: 2025, isActive: false),
      OkrYear(year: 2026, isActive: true),
      OkrYear(year: 2027, isActive: true),
    ]);

    _changelogs[2026] = [
      OkrChangelog(
        description: 'OKR 2026 dibuat\n3 Objectives, 10 Key Results',
        changedBy: 'Admin',
        timestamp: DateTime(2026, 1, 3, 8, 0),
      ),
      OkrChangelog(
        description: 'Tambah KR 1e\nInitiate 3 cost optimization initiatives',
        changedBy: 'Admin',
        timestamp: DateTime(2026, 3, 2, 14, 30),
      ),
      OkrChangelog(
        description: 'Revisi target Solar PV\nKR 1d: 800 MWh \u2192 746 MWh',
        changedBy: 'Admin',
        timestamp: DateTime(2026, 7, 14, 9, 12),
      ),
    ];

    _data[2026] = [
      Objective(
        id: 'o1',
        title: 'Deliver Reliable and Profitable Performance',
        color: '#00C2FF',
        order: 1,
        keyResults: [
          KeyResult(
            objectiveId: 'o1', label: 'a',
            description: 'Achieve NPAT: USD 7.80 million',
            target: '7.80', targetUnit: 'USD M',
            actualValue: '4.29', progressPct: 55,
            status: KrStatus.onProgress,
          ),
          KeyResult(
            objectiveId: 'o1', label: 'b',
            description: 'Achieve EAF: 88%',
            target: '88', targetUnit: '%',
            actualValue: '80.1', progressPct: 91,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o1', label: 'c',
            description: 'Achieve SAIDI \u22641.0 jam dan SAIFI \u22641.0 frekuensi',
            target: '\u22641.0', targetUnit: 'jam/freq',
            type: KrType.qualitative,
            actualValue: 'SAIDI 0.8h, SAIFI 0.9', progressPct: 80,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o1', label: 'd',
            description: 'Solar PV Kelanis production: 746 MWh',
            target: '746', targetUnit: 'MWh',
            actualValue: '358', progressPct: 48,
            status: KrStatus.onProgress,
          ),
          KeyResult(
            objectiveId: 'o1', label: 'e',
            description: 'Initiate 3 cost optimization initiatives',
            target: '3', targetUnit: 'inisiatif',
            actualValue: '2', progressPct: 67,
            status: KrStatus.onTrack,
          ),
        ],
      ),
      Objective(
        id: 'o2',
        title: 'Execute Value-Driven Project Development',
        color: '#C084FC',
        order: 2,
        keyResults: [
          KeyResult(
            objectiveId: 'o2', label: 'a',
            description: 'Optimus \u2014 Construction and implementation-stage',
            target: 'Done', targetUnit: 'fase',
            type: KrType.qualitative,
            actualValue: 'Construction', progressPct: 60,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o2', label: 'b',
            description: 'Explore green initiatives & electrification projects',
            target: '3', targetUnit: 'proyek',
            actualValue: '1', progressPct: 40,
            status: KrStatus.onProgress,
          ),
        ],
      ),
      Objective(
        id: 'o3',
        title: 'Strengthen Sustainability and Compliance',
        color: '#00E5A0',
        order: 3,
        keyResults: [
          KeyResult(
            objectiveId: 'o3', label: 'a',
            description: 'Carbon emission intensity \u22641.297 ton CO\u2082e/MWh',
            target: '1.297', targetUnit: 'ton CO\u2082e/MWh',
            actualValue: '1.102', progressPct: 85,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o3', label: 'b',
            description: 'Carbon reduction 13.308 ton CO\u2082e via co-firing & Solar PV',
            target: '13308', targetUnit: 'ton CO\u2082e',
            actualValue: '5988', progressPct: 45,
            status: KrStatus.onProgress,
          ),
          KeyResult(
            objectiveId: 'o3', label: 'c',
            description: 'Safety: 0 Fatality, 0 LTI, 0 MTC, 0 FAC, 0 Env. Incident',
            target: '0', targetUnit: 'setiap kategori',
            type: KrType.binary,
            actualValue: '0', progressPct: 100,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o3', label: 'd',
            description: 'FABA utilization: 15.000 ton',
            target: '15000', targetUnit: 'ton',
            actualValue: '10800', progressPct: 72,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o3', label: 'e',
            description: 'Comprehensive assessment & comply all regulations',
            target: '5', targetUnit: 'regulasi',
            actualValue: '3', progressPct: 60,
            status: KrStatus.onTrack,
          ),
        ],
      ),
    ];

    _data[2025] = [
      Objective(
        title: 'Deliver Reliable and Profitable Performance',
        color: '#00C2FF',
        order: 1,
        keyResults: [
          KeyResult(
            objectiveId: 'o1_25', label: 'a',
            description: 'Achieve NPAT: USD 7.20 million',
            target: '7.20', targetUnit: 'USD M',
            actualValue: '7.80', progressPct: 108,
            status: KrStatus.onTrack,
          ),
          KeyResult(
            objectiveId: 'o1_25', label: 'b',
            description: 'Achieve EAF: 86%',
            target: '86', targetUnit: '%',
            actualValue: '87.2', progressPct: 101,
            status: KrStatus.onTrack,
          ),
        ],
      ),
    ];

    _data[2027] = [];
  }
}
