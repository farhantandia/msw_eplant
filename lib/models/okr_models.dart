enum KrType { numeric, qualitative, binary }

enum KrStatus { onTrack, atRisk, behind, na }

extension KrStatusX on KrStatus {
  String get label {
    switch (this) {
      case KrStatus.onTrack:
        return 'On Track';
      case KrStatus.atRisk:
        return 'At Risk';
      case KrStatus.behind:
        return 'Behind';
      case KrStatus.na:
        return 'N/A';
    }
  }

  String get icon {
    switch (this) {
      case KrStatus.onTrack:
        return '\u2705';
      case KrStatus.atRisk:
        return '\u26A0\uFE0F';
      case KrStatus.behind:
        return '\uD83D\uDD34';
      case KrStatus.na:
        return '\u2B1C';
    }
  }
}

class OkrYear {
  final int year;
  final bool isActive;
  final DateTime createdAt;
  final String? copiedFrom;

  OkrYear({
    required this.year,
    this.isActive = false,
    DateTime? createdAt,
    this.copiedFrom,
  }) : createdAt = createdAt ?? DateTime.now();
}

class Objective {
  final String id;
  String title;
  String color;
  int order;
  List<KeyResult> keyResults;

  Objective({
    String? id,
    required this.title,
    this.color = '#00C2FF',
    this.order = 0,
    List<KeyResult>? keyResults,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        keyResults = keyResults ?? [];

  double get progress {
    if (keyResults.isEmpty) return 0;
    final total = keyResults.fold<double>(0, (sum, kr) => sum + kr.progressPct);
    return (total / keyResults.length).clamp(0, 100);
  }

  Objective copyWith({
    String? title,
    String? color,
    int? order,
    List<KeyResult>? keyResults,
  }) {
    return Objective(
      id: id,
      title: title ?? this.title,
      color: color ?? this.color,
      order: order ?? this.order,
      keyResults: keyResults ?? List.from(this.keyResults),
    );
  }
}

class KeyResult {
  final String id;
  final String objectiveId;
  String label;
  String description;
  KrType type;
  String target;
  String targetUnit;
  String actualValue;
  double progressPct;
  KrStatus status;
  String notes;
  List<String> phaseOptions;
  int order;

  KeyResult({
    String? id,
    required this.objectiveId,
    this.label = 'a',
    required this.description,
    this.type = KrType.numeric,
    this.target = '',
    this.targetUnit = '',
    this.actualValue = '',
    this.progressPct = 0,
    this.status = KrStatus.na,
    this.notes = '',
    List<String>? phaseOptions,
    this.order = 0,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        phaseOptions = phaseOptions ??
            ['Planning', 'Construction', 'Commissioning', 'Done'];

  KeyResult copyWith({
    String? label,
    String? description,
    KrType? type,
    String? target,
    String? targetUnit,
    String? actualValue,
    double? progressPct,
    KrStatus? status,
    String? notes,
    List<String>? phaseOptions,
    int? order,
  }) {
    return KeyResult(
      id: id,
      objectiveId: objectiveId,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      targetUnit: targetUnit ?? this.targetUnit,
      actualValue: actualValue ?? this.actualValue,
      progressPct: progressPct ?? this.progressPct,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      phaseOptions: phaseOptions ?? List.from(this.phaseOptions),
      order: order ?? this.order,
    );
  }
}

class OkrChangelog {
  final String id;
  final String description;
  final String changedBy;
  final DateTime timestamp;

  OkrChangelog({
    String? id,
    required this.description,
    this.changedBy = 'Admin',
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();
}
