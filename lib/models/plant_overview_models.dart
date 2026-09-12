import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';

/// Kondisi operasional unit pembangkit berdasarkan beban Gross MW
enum UnitOperatingCondition {
  normal, // >= 12 MW
  lowLoad, // 4 <= MW < 12
  houseLoad, // 0 < MW < 4
  shutdown, // <= 0 MW
}

extension UnitOperatingConditionX on UnitOperatingCondition {
  String get label {
    switch (this) {
      case UnitOperatingCondition.normal:
        return 'Normal Running';
      case UnitOperatingCondition.lowLoad:
        return 'Low Load Operation';
      case UnitOperatingCondition.houseLoad:
        return 'House Load Island';
      case UnitOperatingCondition.shutdown:
        return 'Shutdown / Standby';
    }
  }

  String get shortLabel {
    switch (this) {
      case UnitOperatingCondition.normal:
        return 'NORMAL';
      case UnitOperatingCondition.lowLoad:
        return 'LOW LOAD';
      case UnitOperatingCondition.houseLoad:
        return 'HOUSE LOAD';
      case UnitOperatingCondition.shutdown:
        return 'SHUTDOWN';
    }
  }

  Color get color {
    switch (this) {
      case UnitOperatingCondition.normal:
        return AppColors.general; // #00E5A0 Neon Green
      case UnitOperatingCondition.lowLoad:
        return AppColors.maintenance; // #FFB020 Amber
      case UnitOperatingCondition.houseLoad:
        return AppColors.primary; // #00C2FF Cyan
      case UnitOperatingCondition.shutdown:
        return AppColors.danger; // #FF4D6A Red
    }
  }

  IconData get icon {
    switch (this) {
      case UnitOperatingCondition.normal:
        return Icons.check_circle_rounded;
      case UnitOperatingCondition.lowLoad:
        return Icons.speed_rounded;
      case UnitOperatingCondition.houseLoad:
        return Icons.home_repair_service_rounded;
      case UnitOperatingCondition.shutdown:
        return Icons.power_off_rounded;
    }
  }
}

/// Data spesifik per unit (Unit 1 / Unit 2)
class UnitOverviewData {
  final int unitIndex; // 0 for Unit 1, 1 for Unit 2
  final double? grossLoad; // MW
  final double? tmgcr; // Turbine Maximum Continuous Rating (MW)
  final double? bmcr; // Boiler Maximum Continuous Rating (MW or Ton/h)
  final double? boilerEfficiency; // %
  final double? eaf; // Equivalent Availability Factor (%)
  final double? capacityFactor; // %
  final double? nphr; // kCal/kWh
  final bool isLive;

  const UnitOverviewData({
    required this.unitIndex,
    this.grossLoad,
    this.tmgcr,
    this.bmcr,
    this.boilerEfficiency,
    this.eaf,
    this.capacityFactor,
    this.nphr,
    this.isLive = false,
  });

  String get unitName => 'UNIT ${unitIndex + 1}';

  UnitOperatingCondition get condition {
    if (grossLoad == null || grossLoad! <= 0) {
      return UnitOperatingCondition.shutdown;
    }
    if (grossLoad! >= 12.0) {
      return UnitOperatingCondition.normal;
    }
    if (grossLoad! >= 4.0) {
      return UnitOperatingCondition.lowLoad;
    }
    return UnitOperatingCondition.houseLoad;
  }

  /// Rasio pembebanan terhadap TMGCR (%)
  double? get loadingRatio {
    if (grossLoad != null && tmgcr != null && tmgcr! > 0) {
      return (grossLoad! / tmgcr! * 100).clamp(0.0, 150.0);
    }
    return null;
  }

  bool get hasAnyData =>
      grossLoad != null ||
      tmgcr != null ||
      bmcr != null ||
      boilerEfficiency != null ||
      eaf != null ||
      capacityFactor != null ||
      nphr != null;
}

/// Item parameter CEMS untuk Unit 1 & Unit 2
class CemsParamItem {
  final String paramKey;
  final String displayName;
  final String unit;
  final double? unit1Value;
  final double? unit2Value;
  final double? threshold; // Baku Mutu

  const CemsParamItem({
    required this.paramKey,
    required this.displayName,
    required this.unit,
    this.unit1Value,
    this.unit2Value,
    this.threshold,
  });

  bool? get isUnit1Compliant {
    if (unit1Value == null || threshold == null) return null;
    return unit1Value! <= threshold!;
  }

  bool? get isUnit2Compliant {
    if (unit2Value == null || threshold == null) return null;
    return unit2Value! <= threshold!;
  }
}

/// Snapshot agregasi seluruh telemetry pembangkit dari Firebase RTDB
class PlantOverviewSnapshot {
  final DateTime? timestamp;
  final String? rawTimestamp;
  final double? totalLoad; // Total Gross Generation (MW)
  final double? loadToPln; // Export ke PLN (MW)
  final double? loadToAi; // Export ke AI (MW)
  final double? totalHouseLoad; // Pemakaian sendiri (MW)
  final UnitOverviewData unit1;
  final UnitOverviewData unit2;
  final List<CemsParamItem> cemsParams;
  final bool isLive;
  final bool hasData;

  const PlantOverviewSnapshot({
    this.timestamp,
    this.rawTimestamp,
    this.totalLoad,
    this.loadToPln,
    this.loadToAi,
    this.totalHouseLoad,
    required this.unit1,
    required this.unit2,
    required this.cemsParams,
    this.isLive = false,
    this.hasData = false,
  });

  /// Total Net Export = PLN + AI (MW)
  double? get totalNetExport {
    if (loadToPln == null && loadToAi == null) return null;
    return (loadToPln ?? 0.0) + (loadToAi ?? 0.0);
  }

  /// House Load Percentage (%)
  double? get houseLoadPct {
    if (totalHouseLoad != null && totalLoad != null && totalLoad! > 0) {
      return (totalHouseLoad! / totalLoad! * 100).clamp(0.0, 100.0);
    }
    return null;
  }

  /// Formatted date string for display (e.g. '11 Sep 2026, 12:00')
  String get formattedTimestamp {
    if (timestamp != null) {
      try {
        return DateFormat('dd MMM yyyy, HH:mm').format(timestamp!.toLocal());
      } catch (_) {}
    }
    if (rawTimestamp != null && rawTimestamp!.isNotEmpty) {
      return rawTimestamp!;
    }
    return '';
  }

  /// Factory builder dari raw Firebase data dengan graceful fallback & zero hardcoded values
  factory PlantOverviewSnapshot.fromFirebase({
    List<List>? overviewData,
    List<List>? table1Data,
    List<List>? table2Data,
    List<List>? cems1Data,
    List<List>? cems2Data,
    List<List>? nphrData,
  }) {
    final bool hasOverview = overviewData != null && overviewData.length > 1;
    final bool hasT1 = table1Data != null && table1Data.length > 1;
    final bool hasT2 = table2Data != null && table2Data.length > 1;

    // Headers & last rows
    final List<String> ovHeader = hasOverview ? overviewData.first.map((e) => e.toString()).toList() : [];
    final List ovLast = hasOverview ? overviewData.last : [];

    final List<String> t1Header = hasT1 ? table1Data.first.map((e) => e.toString()).toList() : [];
    final List t1Last = hasT1 ? table1Data.last : [];

    final List<String> t2Header = hasT2 ? table2Data.first.map((e) => e.toString()).toList() : [];
    final List t2Last = hasT2 ? table2Data.last : [];

    // Helper to safely find and parse double from columns
    double? findVal(List<String> header, List row, List<String> targetLabels) {
      if (header.isEmpty || row.isEmpty) return null;
      for (final label in targetLabels) {
        final norm = label.trim().toUpperCase();
        int idx = header.indexWhere((h) => h.trim().toUpperCase() == norm);
        if (idx == -1) {
          idx = header.indexWhere((h) => h.trim().toUpperCase().contains(norm));
        }
        if (idx != -1 && idx < row.length) {
          final parsed = double.tryParse(row[idx].toString());
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    // 1. Gross Loads
    final double? u1Load = findVal(t1Header, t1Last, ["UNIT 1 LOAD", "UNIT1 LOAD", "LOAD"]);
    final double? u2Load = findVal(t2Header, t2Last, ["UNIT 2 LOAD", "UNIT2 LOAD", "LOAD"]);

    // 2. Overview general metrics: Prioritize 'overview', fallback to 'table1'
    double? totalLoad = findVal(ovHeader, ovLast, ["TOTAL LOAD", "TOTAL GENERATION", "GROSS LOAD"]);
    if (totalLoad == null && u1Load != null && u2Load != null) {
      totalLoad = u1Load + u2Load;
    } else if (totalLoad == null && (u1Load != null || u2Load != null)) {
      totalLoad = (u1Load ?? 0.0) + (u2Load ?? 0.0);
    }

    double? plnLoad = findVal(ovHeader, ovLast, ["LOAD TO PLN", "PLN LOAD", "PLN"]);
    plnLoad ??= findVal(t1Header, t1Last, ["LOAD TO PLN", "PLN LOAD", "PLN"]);

    double? aiLoad = findVal(ovHeader, ovLast, ["LOAD TO AI", "AI LOAD", "AI"]);
    aiLoad ??= findVal(t1Header, t1Last, ["LOAD TO AI", "AI LOAD", "AI"]);

    double? houseLoad = findVal(ovHeader, ovLast, ["TOTAL HOUSE LOAD", "HOUSE LOAD"]);
    houseLoad ??= findVal(t1Header, t1Last, ["TOTAL HOUSE LOAD", "HOUSE LOAD"]);
    if (houseLoad == null && totalLoad != null && (plnLoad != null || aiLoad != null)) {
      final net = (plnLoad ?? 0.0) + (aiLoad ?? 0.0);
      if (totalLoad >= net) {
        houseLoad = totalLoad - net;
      }
    }

    // 3. Unit 1 Performance parameters from overview (or table1)
    final double? u1Tmgcr = findVal(ovHeader, ovLast, ["UNIT 1 TMGCR", "UNIT1 TMGCR", "TMGCR 1", "TMGCR"]);
    final double? u1Bmcr = findVal(ovHeader, ovLast, ["UNIT 1 BMCR", "UNIT1 BMCR", "BMCR 1", "BMCR"]);
    final double? u1Eff = findVal(ovHeader, ovLast, ["UNIT 1 BOILER EFFICIENCY", "UNIT1 BOILER EFFICIENCY", "BOILER EFFICIENCY 1", "BOILER EFFICIENCY"]);
    final double? u1Eaf = findVal(ovHeader, ovLast, ["UNIT 1 EAF", "UNIT1 EAF", "EAF 1", "EAF"]);
    final double? u1Cf = findVal(ovHeader, ovLast, ["UNIT 1 CAPACITY FACTOR", "UNIT1 CAPACITY FACTOR", "CAPACITY FACTOR 1", "CF 1", "CAPACITY FACTOR"]);

    // 4. Unit 2 Performance parameters from overview (or table2)
    final double? u2Tmgcr = findVal(ovHeader, ovLast, ["UNIT 2 TMGCR", "UNIT2 TMGCR", "TMGCR 2"]);
    final double? u2Bmcr = findVal(ovHeader, ovLast, ["UNIT 2 BMCR", "UNIT2 BMCR", "BMCR 2"]);
    final double? u2Eff = findVal(ovHeader, ovLast, ["UNIT 2 BOILER EFFICIENCY", "UNIT2 BOILER EFFICIENCY", "BOILER EFFICIENCY 2"]);
    final double? u2Eaf = findVal(ovHeader, ovLast, ["UNIT 2 EAF", "UNIT2 EAF", "EAF 2"]);
    final double? u2Cf = findVal(ovHeader, ovLast, ["UNIT 2 CAPACITY FACTOR", "UNIT2 CAPACITY FACTOR", "CAPACITY FACTOR 2", "CF 2"]);

    // 5. NPHR from excel_data/nphr (Supporting both 2-column [u1, u2] and 3-column [date, u1, u2] formats)
    double? u1Nphr;
    double? u2Nphr;
    if (nphrData != null && nphrData.length > 1) {
      final nphrHeader = nphrData.first.map((e) => e.toString()).toList();
      final nphrLast = nphrData.last;
      u1Nphr = findVal(nphrHeader, nphrLast, ["NPHR UNIT 1", "NPHR1", "NPHR 1", "UNIT 1 NPHR", "NPHR_1", "HR 1", "HEAT RATE 1"]);
      u2Nphr = findVal(nphrHeader, nphrLast, ["NPHR UNIT 2", "NPHR2", "NPHR 2", "UNIT 2 NPHR", "NPHR_2", "HR 2", "HEAT RATE 2"]);

      // If not found by exact header labels, detect column format
      if (u1Nphr == null || u2Nphr == null) {
        bool firstColIsDate = false;
        if (nphrLast.isNotEmpty) {
          final s0 = nphrLast[0].toString().trim();
          firstColIsDate = DateTime.tryParse(s0) != null || DateTime.tryParse(s0.replaceAll(' ', 'T')) != null;
        }
        if (!firstColIsDate && nphrHeader.isNotEmpty) {
          final h0 = nphrHeader[0].trim().toUpperCase();
          if (h0.contains('DATE') || h0.contains('TIME')) {
            firstColIsDate = true;
          }
        }

        if (firstColIsDate) {
          // Columns: [DATETIME, NPHR_U1, NPHR_U2]
          if (u1Nphr == null && nphrLast.length > 1) {
            u1Nphr = double.tryParse(nphrLast[1].toString());
          }
          if (u2Nphr == null && nphrLast.length > 2) {
            u2Nphr = double.tryParse(nphrLast[2].toString());
          }
        } else {
          // Columns: [NPHR_U1, NPHR_U2]
          if (u1Nphr == null && nphrLast.isNotEmpty) {
            u1Nphr = double.tryParse(nphrLast[0].toString());
          }
          if (u2Nphr == null && nphrLast.length > 1) {
            u2Nphr = double.tryParse(nphrLast[1].toString());
          }
        }
      }
    }

    // 6. CEMS Parameters for Unit 1 & Unit 2
    List<CemsParamItem> cems = [];
    final List<String> c1Header = (cems1Data != null && cems1Data.length > 1)
        ? cems1Data.first.map((e) => e.toString()).toList()
        : [];
    final List c1Last = (cems1Data != null && cems1Data.length > 1) ? cems1Data.last : [];

    final List<String> c2Header = (cems2Data != null && cems2Data.length > 1)
        ? cems2Data.first.map((e) => e.toString()).toList()
        : [];
    final List c2Last = (cems2Data != null && cems2Data.length > 1) ? cems2Data.last : [];

    // SO2 (Standard: 550 mg/Nm3)
    final double? so2U1 = findVal(c1Header, c1Last, ["SO2", "SO2 COR", "SO2_COR", "SO2 CONCENTRATION"]);
    final double? so2U2 = findVal(c2Header, c2Last, ["SO2", "SO2 COR", "SO2_COR", "SO2 CONCENTRATION"]);
    cems.add(CemsParamItem(
      paramKey: 'SO2',
      displayName: 'Sulfur Dioxide (SO₂)',
      unit: 'mg/Nm³',
      unit1Value: so2U1,
      unit2Value: so2U2,
      threshold: 550.0,
    ));

    // NOx (Standard: 550 mg/Nm3)
    final double? noxU1 = findVal(c1Header, c1Last, ["NOX", "NOX COR", "NOX_COR", "NOX CONCENTRATION"]);
    final double? noxU2 = findVal(c2Header, c2Last, ["NOX", "NOX COR", "NOX_COR", "NOX CONCENTRATION"]);
    cems.add(CemsParamItem(
      paramKey: 'NOX',
      displayName: 'Nitrogen Oxides (NOₓ)',
      unit: 'mg/Nm³',
      unit1Value: noxU1,
      unit2Value: noxU2,
      threshold: 550.0,
    ));

    // Particulate Matter (Standard: 50 mg/Nm3)
    final double? pmU1 = findVal(c1Header, c1Last, ["PARTICULATE", "PARTICULATE O2", "PARTIKULAT", "DUST"]);
    final double? pmU2 = findVal(c2Header, c2Last, ["PARTICULATE", "PARTICULATE O2", "PARTIKULAT", "DUST"]);
    cems.add(CemsParamItem(
      paramKey: 'PARTICULATE',
      displayName: 'Particulate Matter (PM)',
      unit: 'mg/Nm³',
      unit1Value: pmU1,
      unit2Value: pmU2,
      threshold: 50.0,
    ));

    // Hg Correction (Standard: 0.03 mg/Nm3 per Permen LHK P.15/2019)
    final double? hgU1 = findVal(c1Header, c1Last, ["HG CORRECTION", "HG COR", "HG_COR", "HG", "MERCURY"]);
    final double? hgU2 = findVal(c2Header, c2Last, ["HG CORRECTION", "HG COR", "HG_COR", "HG", "MERCURY"]);
    cems.add(CemsParamItem(
      paramKey: 'HG',
      displayName: 'Hg Correction',
      unit: 'mg/Nm³',
      unit1Value: hgU1,
      unit2Value: hgU2,
      threshold: 0.03,
    ));

    // Timestamp & Liveness: Multi-source resolution (overview, table1, table2)
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final s = val.toString().trim();
      if (s.isEmpty) return null;
      var parsed = DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceAll(' ', 'T'));
      if (parsed != null) return parsed;
      try {
        if (s.contains('/') || s.contains('-')) {
          final parts = s.split(' ');
          final dateParts = parts[0].contains('/') ? parts[0].split('/') : parts[0].split('-');
          if (dateParts.length == 3) {
            int day, month, year;
            if (dateParts[0].length == 4) {
              year = int.parse(dateParts[0]);
              month = int.parse(dateParts[1]);
              day = int.parse(dateParts[2]);
            } else {
              day = int.parse(dateParts[0]);
              month = int.parse(dateParts[1]);
              year = int.parse(dateParts[2]);
            }
            int hour = 0, minute = 0, second = 0;
            if (parts.length > 1) {
              final timeParts = parts[1].split(':');
              if (timeParts.isNotEmpty) hour = int.parse(timeParts[0]);
              if (timeParts.length > 1) minute = int.parse(timeParts[1]);
              if (timeParts.length > 2) second = int.parse(timeParts[2].split('.')[0]);
            }
            return DateTime(year, month, day, hour, minute, second);
          }
        }
      } catch (_) {}
      return null;
    }

    DateTime? dt;
    String? dtRaw;
    for (final source in [
      if (hasT1) table1Data,
      if (hasOverview) overviewData,
      if (hasT2) table2Data,
    ]) {
      if (source == null || source.length <= 1) continue;
      final h = source.first.map((e) => e.toString().trim().toUpperCase()).toList();
      int dtIdx = h.indexOf("DATETIME");
      if (dtIdx == -1) dtIdx = h.indexWhere((col) => col.contains("DATE") || col.contains("TIME"));
      if (dtIdx == -1) dtIdx = 0;

      final lastRow = source.last;
      if (dtIdx < lastRow.length) {
        final parsed = parseDate(lastRow[dtIdx]);
        if (parsed != null) {
          dt = parsed;
          dtRaw = lastRow[dtIdx].toString();
          break;
        }
      }
    }

    bool isLive = false;
    if (dt != null) {
      final diff = DateTime.now().difference(dt.toLocal());
      isLive = diff.inMinutes.abs() < 90;
    }

    final u1 = UnitOverviewData(
      unitIndex: 0,
      grossLoad: u1Load,
      tmgcr: u1Tmgcr,
      bmcr: u1Bmcr,
      boilerEfficiency: u1Eff,
      eaf: u1Eaf,
      capacityFactor: u1Cf,
      nphr: u1Nphr,
      isLive: isLive && (u1Load != null && u1Load > 0),
    );

    final u2 = UnitOverviewData(
      unitIndex: 1,
      grossLoad: u2Load,
      tmgcr: u2Tmgcr,
      bmcr: u2Bmcr,
      boilerEfficiency: u2Eff,
      eaf: u2Eaf,
      capacityFactor: u2Cf,
      nphr: u2Nphr,
      isLive: isLive && (u2Load != null && u2Load > 0),
    );

    final bool hasData = hasOverview || hasT1 || hasT2;

    return PlantOverviewSnapshot(
      timestamp: dt,
      rawTimestamp: dtRaw,
      totalLoad: totalLoad,
      loadToPln: plnLoad,
      loadToAi: aiLoad,
      totalHouseLoad: houseLoad,
      unit1: u1,
      unit2: u2,
      cemsParams: cems,
      isLive: isLive,
      hasData: hasData,
    );
  }

  /// Safe value formatter returning "—" if value is null
  static String formatVal(double? val, {int decimals = 1, String suffix = '', String fallback = '—'}) {
    if (val == null) return fallback;
    return '${val.toStringAsFixed(decimals)}$suffix';
  }
}
