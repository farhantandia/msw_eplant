class CemsThreshold {
  final double max;
  final double? min;

  const CemsThreshold({required this.max, this.min});
}

class CemsThresholdService {
  static const _thresholds = <String, CemsThreshold>{
    'SO2': CemsThreshold(max: 550),
    'NOX': CemsThreshold(max: 550),
    'PARTICULATE': CemsThreshold(max: 50),
    'HG': CemsThreshold(max: 0.03),
  };

  static CemsThreshold? getThreshold(String param) {
    final key = param.toUpperCase().trim();
    for (final entry in _thresholds.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static bool hasThreshold(String param) => getThreshold(param) != null;

  static bool isCompliant(String param, double value) {
    final t = getThreshold(param);
    if (t == null) return true;
    if (t.min != null && value < t.min!) return false;
    if (value > t.max) return false;
    return true;
  }

  static String complianceLabel(String param, double value) {
    return isCompliant(param, value) ? 'Compliant' : 'Exceed';
  }
}
