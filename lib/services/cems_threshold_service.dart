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
    if (key == 'SO2' || key.contains('SO2 COR') || key.contains('SO2_COR') || key.contains('SO2 CONCENTRATION')) {
      return _thresholds['SO2'];
    }
    if (key == 'NOX' || key.contains('NOX COR') || key.contains('NOX_COR') || key.contains('NOX CONCENTRATION')) {
      return _thresholds['NOX'];
    }
    if (key == 'PARTICULATE' || key.contains('PARTICULATE O2') || key.contains('PARTICULATE_O2') || key.contains('PARTICULATE CONCENTRATION')) {
      return _thresholds['PARTICULATE'];
    }
    if (key == 'HG' || key.contains('HG CORRECTION') || key.contains('HG_COR') || key.contains('MERCURY')) {
      return _thresholds['HG'];
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

  static bool isDataCompliant(List<List> cemsData, [List<List>? fallbackData]) {
    final data = cemsData.length > 1
        ? cemsData
        : (fallbackData != null && fallbackData.length > 1 ? fallbackData : []);
    if (data.length < 2) return true;
    final header = data.first.map((e) => e.toString()).toList();
    final lastRecord = data.last;

    for (int i = 0; i < header.length && i < lastRecord.length; i++) {
      final colName = header[i];
      if (hasThreshold(colName)) {
        final val = double.tryParse(lastRecord[i].toString());
        if (val != null && !isCompliant(colName, val)) {
          return false;
        }
      }
    }
    return true;
  }
}
