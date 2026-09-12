import 'package:flutter/material.dart';

enum InverterStatus {
  normal,
  standby,
  derated,
  offline;

  String get label {
    switch (this) {
      case InverterStatus.normal:
        return 'NORMAL';
      case InverterStatus.standby:
        return 'STANDBY';
      case InverterStatus.derated:
        return 'DERATED';
      case InverterStatus.offline:
        return 'OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case InverterStatus.normal:
        return const Color(0xFF00E5A0); // General green
      case InverterStatus.standby:
        return const Color(0xFF38BDF8); // Sky blue
      case InverterStatus.derated:
        return const Color(0xFFFFB020); // Amber
      case InverterStatus.offline:
        return const Color(0xFFFF4D6A); // Danger red
    }
  }
}

enum AlarmSeverity {
  critical,
  major,
  minor,
  warning,
  info;

  String get label {
    switch (this) {
      case AlarmSeverity.critical:
        return 'CRITICAL';
      case AlarmSeverity.major:
        return 'MAJOR';
      case AlarmSeverity.minor:
        return 'MINOR';
      case AlarmSeverity.warning:
        return 'WARNING';
      case AlarmSeverity.info:
        return 'INFO';
    }
  }

  Color get color {
    switch (this) {
      case AlarmSeverity.critical:
        return const Color(0xFFFF4D6A); // Red
      case AlarmSeverity.major:
        return const Color(0xFFFF8A00); // Orange
      case AlarmSeverity.minor:
        return const Color(0xFFFFB020); // Amber
      case AlarmSeverity.warning:
        return const Color(0xFF38BDF8); // Sky blue
      case AlarmSeverity.info:
        return const Color(0xFF94A3B8); // Slate
    }
  }
}

class SolarAlarm {
  final String alarmId;
  final String alarmName;
  final String? devName;
  final String? devId;
  final String? esn;
  final AlarmSeverity severity;
  final DateTime raiseTime;
  final String? cause;
  final String? repairSuggestion;
  final String status;
  final int? alarmCode;

  const SolarAlarm({
    required this.alarmId,
    required this.alarmName,
    this.devName,
    this.devId,
    this.esn,
    required this.severity,
    required this.raiseTime,
    this.cause,
    this.repairSuggestion,
    this.status = 'Active',
    this.alarmCode,
  });

  Map<String, dynamic> toJson() => {
    'alarm_id': alarmId,
    'alarm_name': alarmName,
    'dev_name': devName,
    'dev_id': devId,
    'esn': esn,
    'severity': severity.name,
    'raise_time': raiseTime.toIso8601String(),
    'cause': cause,
    'repair_suggestion': repairSuggestion,
    'status': status,
    'alarm_code': alarmCode,
  };

  factory SolarAlarm.fromJson(Map<dynamic, dynamic> json) {
    final sevStr = json['severity']?.toString() ?? 'warning';
    final sev = AlarmSeverity.values.firstWhere(
      (e) => e.name == sevStr,
      orElse: () => AlarmSeverity.warning,
    );
    DateTime rTime;
    if (json['raise_time'] != null) {
      try {
        rTime = DateTime.parse(json['raise_time'].toString());
      } catch (_) {
        rTime = DateTime.now();
      }
    } else {
      rTime = DateTime.now();
    }
    return SolarAlarm(
      alarmId: json['alarm_id']?.toString() ?? '',
      alarmName: json['alarm_name']?.toString() ?? 'Unknown Alarm',
      devName: json['dev_name']?.toString(),
      devId: json['dev_id']?.toString(),
      esn: json['esn']?.toString(),
      severity: sev,
      raiseTime: rTime,
      cause: json['cause']?.toString(),
      repairSuggestion: json['repair_suggestion']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      alarmCode: (json['alarm_code'] as num?)?.toInt(),
    );
  }
}

class SolarInverter {
  final String id;
  final String name;
  final String clusterId;
  final double capacityKwp;
  final double powerKw;
  final double yieldTodayKwh;
  final double? specificEnergy; // kWh/kWp, particularly for 468 kWp inverters
  final InverterStatus status;
  final bool isNightStandby;

  final String? plantId; // 'kelanis' | 'msw'

  // Actual live telemetry fields from Huawei FusionSolar OpenAPI
  final String? model; // e.g. "SUN2000-100KTL-M1"
  final String? softwareVersion; // e.g. "V500R023C00SPC156"
  final String? esnCode; // e.g. "6T2469039090"
  final double? temperature; // °C internal temperature
  final double? gridFrequency; // Hz (elec_freq)
  final double? lineVoltageAb; // V (ab_u)
  final double? lineVoltageBc; // V (bc_u)
  final double? lineVoltageCa; // V (ca_u)
  final double? phaseCurrentA; // A (a_i)
  final double? phaseCurrentB; // A (b_i)
  final double? phaseCurrentC; // A (c_i)
  final double? powerFactor; // power_factor
  final double? efficiency; // % efficiency
  final double? mpptPowerKw; // kW input MPPT power
  final double? totalLifetimeKwh; // total_cap
  final int? inverterState; // run state / fault code
  final List<SolarAlarm> _activeAlarms;

  /// Returns active alarms excluding informational standby states (such as Huawei 40960).
  List<SolarAlarm> get activeAlarms => _activeAlarms.where((a) => !isFalseAlarm(a)).toList();

  /// Whether an alarm is a false alarm synthesized from a normal standby state (code 40960 / no irradiation).
  static bool isFalseAlarm(SolarAlarm a) {
    final code = a.alarmCode;
    final id = a.alarmId.toLowerCase();
    final name = a.alarmName.toLowerCase();
    return code == 40960 ||
        id.contains('40960') ||
        name.contains('40960') ||
        name.contains('no irradiation') ||
        name.contains('no sunshine');
  }

  const SolarInverter({
    required this.id,
    required this.name,
    required this.clusterId,
    this.plantId,
    required this.capacityKwp,
    required this.powerKw,
    required this.yieldTodayKwh,
    this.specificEnergy,
    required this.status,
    this.isNightStandby = false,
    this.model,
    this.softwareVersion,
    this.esnCode,
    this.temperature,
    this.gridFrequency,
    this.lineVoltageAb,
    this.lineVoltageBc,
    this.lineVoltageCa,
    this.phaseCurrentA,
    this.phaseCurrentB,
    this.phaseCurrentC,
    this.powerFactor,
    this.efficiency,
    this.mpptPowerKw,
    this.totalLifetimeKwh,
    this.inverterState,
    List<SolarAlarm> activeAlarms = const [],
  }) : _activeAlarms = activeAlarms;

  String get resolvedPlantId =>
      plantId ??
      ((clusterId == '468kwp' ||
              name.toLowerCase().contains('com1') ||
              name.contains('468'))
          ? 'kelanis'
          : 'msw');

  double get loadingPct => capacityKwp > 0 ? (powerKw / capacityKwp * 100).clamp(0.0, 120.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cluster_id': clusterId,
    'plant_id': resolvedPlantId,
    'capacity_kwp': capacityKwp,
    'power_kw': powerKw,
    'yield_today_kwh': yieldTodayKwh,
    'specific_energy': specificEnergy,
    'status': status.name,
    'is_night_standby': isNightStandby,
    'model': model,
    'software_version': softwareVersion,
    'esn_code': esnCode,
    'temperature': temperature,
    'grid_frequency': gridFrequency,
    'line_voltage_ab': lineVoltageAb,
    'line_voltage_bc': lineVoltageBc,
    'line_voltage_ca': lineVoltageCa,
    'phase_current_a': phaseCurrentA,
    'phase_current_b': phaseCurrentB,
    'phase_current_c': phaseCurrentC,
    'power_factor': powerFactor,
    'efficiency': efficiency,
    'mppt_power_kw': mpptPowerKw,
    'total_lifetime_kwh': totalLifetimeKwh,
    'inverter_state': inverterState,
    'active_alarms': activeAlarms.map((a) => a.toJson()).toList(),
  };

  factory SolarInverter.fromJson(Map<dynamic, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'normal';
    final status = InverterStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => InverterStatus.normal,
    );
    final cId = json['cluster_id']?.toString() ?? '';
    final n = json['name']?.toString() ?? '';
    final pId = json['plant_id']?.toString() ??
        ((cId == '468kwp' || n.toLowerCase().contains('com1') || n.contains('468')) ? 'kelanis' : 'msw');

    return SolarInverter(
      id: json['id']?.toString() ?? '',
      name: n,
      clusterId: cId,
      plantId: pId,
      capacityKwp: (json['capacity_kwp'] as num?)?.toDouble() ?? 0.0,
      powerKw: (json['power_kw'] as num?)?.toDouble() ?? 0.0,
      yieldTodayKwh: (json['yield_today_kwh'] as num?)?.toDouble() ?? 0.0,
      specificEnergy: (json['specific_energy'] as num?)?.toDouble(),
      status: status,
      isNightStandby: json['is_night_standby'] == true,
      model: json['model']?.toString(),
      softwareVersion: json['software_version']?.toString(),
      esnCode: json['esn_code']?.toString(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      gridFrequency: (json['grid_frequency'] as num?)?.toDouble(),
      lineVoltageAb: (json['line_voltage_ab'] as num?)?.toDouble(),
      lineVoltageBc: (json['line_voltage_bc'] as num?)?.toDouble(),
      lineVoltageCa: (json['line_voltage_ca'] as num?)?.toDouble(),
      phaseCurrentA: (json['phase_current_a'] as num?)?.toDouble(),
      phaseCurrentB: (json['phase_current_b'] as num?)?.toDouble(),
      phaseCurrentC: (json['phase_current_c'] as num?)?.toDouble(),
      powerFactor: (json['power_factor'] as num?)?.toDouble(),
      efficiency: (json['efficiency'] as num?)?.toDouble(),
      mpptPowerKw: (json['mppt_power_kw'] as num?)?.toDouble(),
      totalLifetimeKwh: (json['total_lifetime_kwh'] as num?)?.toDouble(),
      inverterState: (json['inverter_state'] as num?)?.toInt(),
      activeAlarms: (json['active_alarms'] is List)
          ? (json['active_alarms'] as List)
              .whereType<Map>()
              .map((m) => SolarAlarm.fromJson(m))
              .where((a) => !isFalseAlarm(a))
              .toList()
          : const [],
    );
  }
}

class SolarHourlyPoint {
  final int hour; // 0..23
  final String timeStr; // "08:00"
  final double powerKw;
  final double irradiance; // kWh/m² (hourly insolation from FusionSolar API)
  final double pr; // %
  /// Per-plant breakdown for this hour (keys: 'msw', 'kelanis').
  /// Each value contains {'irradiance': double, 'power': double, 'pr': double}.
  final Map<String, Map<String, double>>? plantData;

  const SolarHourlyPoint({
    required this.hour,
    required this.timeStr,
    required this.powerKw,
    required this.irradiance,
    required this.pr,
    this.plantData,
  });

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'time_str': timeStr,
    'power_kw': powerKw,
    'irradiance': irradiance,
    'pr': pr,
    if (plantData != null) 'plant_data': plantData,
  };

  factory SolarHourlyPoint.fromJson(Map<dynamic, dynamic> json) {
    Map<String, Map<String, double>>? pd;
    if (json['plant_data'] is Map) {
      pd = {};
      (json['plant_data'] as Map).forEach((k, v) {
        if (v is Map) {
          final inner = <String, double>{};
          v.forEach((ik, iv) {
            if (iv is num) inner[ik.toString()] = iv.toDouble();
          });
          pd![k.toString()] = inner;
        }
      });
    }
    return SolarHourlyPoint(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      timeStr: json['time_str']?.toString() ?? '',
      powerKw: (json['power_kw'] as num?)?.toDouble() ?? 0.0,
      irradiance: (json['irradiance'] as num?)?.toDouble() ?? 0.0,
      pr: (json['pr'] as num?)?.toDouble() ?? 0.0,
      plantData: pd,
    );
  }
}

class SolarArrayCluster {
  final String id;
  final String name;
  final double totalCapacityKwp;
  final List<SolarInverter> inverters;

  const SolarArrayCluster({
    required this.id,
    required this.name,
    required this.totalCapacityKwp,
    required this.inverters,
  });

  double get totalPowerKw => inverters.fold(0.0, (sum, inv) => sum + inv.powerKw);
  double get totalYieldTodayKwh => inverters.fold(0.0, (sum, inv) => sum + inv.yieldTodayKwh);
  int get onlineCount => inverters.where((inv) => inv.status == InverterStatus.normal).length;
}

class SolarSnapshot {
  final DateTime timestamp;
  final bool isLive;
  final double totalPowerKw;
  final double peakPowerKw;
  final double totalYieldTodayKwh;
  final double yieldYesterdayKwh;
  final double irradiance; // kWh/m2
  final double performanceRatio; // % (e.g. 81.4)
  final double gridExportKw;
  final int onlineInverterCount;
  final int totalInverterCount;
  final double totalCapacityKwp; // 1563 kWp
  final List<SolarInverter> inverters;
  final List<SolarHourlyPoint> hourlyPoints;

  // Plant-specific distinct telemetry (Kelanis 468 kWp vs MSW 400 kWp)
  final Map<String, double> plantIrradiance;
  final Map<String, double> plantPr;

  const SolarSnapshot({
    required this.timestamp,
    required this.isLive,
    required this.totalPowerKw,
    required this.peakPowerKw,
    required this.totalYieldTodayKwh,
    required this.yieldYesterdayKwh,
    required this.irradiance,
    required this.performanceRatio,
    required this.gridExportKw,
    required this.onlineInverterCount,
    required this.totalInverterCount,
    required this.totalCapacityKwp,
    required this.inverters,
    required this.hourlyPoints,
    this.plantIrradiance = const {},
    this.plantPr = const {},
  });

  int get totalAlarmCount => inverters.fold(0, (sum, inv) => sum + inv.activeAlarms.length);
  List<SolarAlarm> get allActiveAlarms => inverters.expand((i) => i.activeAlarms).toList();

  /// Returns effective generation today, preventing zero display in the morning when inverters have active power
  double get effectiveYieldTodayKwh {
    if (totalYieldTodayKwh > 0.0) return totalYieldTodayKwh;
    final invSum = inverters.fold(0.0, (s, i) => s + i.yieldTodayKwh);
    if (invSum > 0.0) return invSum;
    if (totalPowerKw > 0.0) {
      final hSum = hourlyPoints.fold(0.0, (s, p) => s + p.powerKw);
      if (hSum > 0.0) return double.parse((hSum * 0.85).toStringAsFixed(1));
      return double.parse((totalPowerKw * 0.35).toStringAsFixed(1));
    }
    return 0.0;
  }

  // Solar yield delta vs yesterday (%)
  double get yieldDeltaPct {
    if (yieldYesterdayKwh <= 0.0) return 0.0;
    return ((effectiveYieldTodayKwh - yieldYesterdayKwh) / yieldYesterdayKwh) * 100.0;
  }

  // Estimated house load offset percentage (assuming typical CFPP aux load ~4.5 MW)
  double get houseLoadOffsetPct {
    const double typicalAuxKw = 4500.0;
    return (totalPowerKw / typicalAuxKw * 100.0).clamp(0.0, 100.0);
  }

  bool get isNightTime {
    final hour = timestamp.toLocal().hour;
    return hour >= 18 || hour < 6;
  }

  SolarSnapshot forPlant(String targetPlantId) {
    final plantInvs = inverters.where((i) => i.resolvedPlantId == targetPlantId).toList();
    final targetCap = targetPlantId == 'kelanis' ? 468.0 : 400.0;
    final targetInvCount = targetPlantId == 'kelanis' ? 4 : 8;

    // Distinct plant irradiance: use specific station telemetry from API (no artificial factor)
    final pIrr = plantIrradiance[targetPlantId] ?? irradiance;

    // Distinct plant PR: use specific station PR from API (no artificial offset)
    final pPr = plantPr[targetPlantId] ?? performanceRatio;

    if (plantInvs.isEmpty) {
      return SolarSnapshot(
        timestamp: timestamp,
        isLive: isLive,
        totalPowerKw: 0.0,
        peakPowerKw: 0.0,
        totalYieldTodayKwh: 0.0,
        yieldYesterdayKwh: 0.0,
        irradiance: pIrr,
        performanceRatio: pPr,
        gridExportKw: 0.0,
        onlineInverterCount: 0,
        totalInverterCount: targetInvCount,
        totalCapacityKwp: targetCap,
        inverters: const [],
        hourlyPoints: hourlyPoints,
        plantIrradiance: {targetPlantId: pIrr},
        plantPr: {targetPlantId: pPr},
      );
    }

    final pPower = plantInvs.fold(0.0, (sum, i) => sum + i.powerKw);
    final pYieldRaw = plantInvs.fold(0.0, (sum, i) => sum + i.yieldTodayKwh);
    final onlineCount = plantInvs.where((i) => i.status == InverterStatus.normal).length;

    final ratio = totalCapacityKwp > 0
        ? (targetCap / totalCapacityKwp)
        : (targetPlantId == 'kelanis' ? 468.0 / 868.0 : 400.0 / 868.0);
    final plantYesterday = double.parse((yieldYesterdayKwh * ratio).toStringAsFixed(1));
    final plantPeak = double.parse((peakPowerKw * ratio).toStringAsFixed(1));

    // Use per-plant hourly data if available from API; otherwise scale proportionally
    final plantHourly = hourlyPoints.map((h) {
      final pd = h.plantData?[targetPlantId];
      if (pd != null && (pd['power'] ?? 0) > 0) {
        return SolarHourlyPoint(
          hour: h.hour,
          timeStr: h.timeStr,
          powerKw: double.parse((pd['power'] ?? 0.0).toStringAsFixed(1)),
          irradiance: double.parse((pd['irradiance'] ?? 0.0).toStringAsFixed(2)),
          pr: double.parse((pd['pr'] ?? 0.0).toStringAsFixed(1)),
        );
      }
      // Fallback: scale by capacity ratio (no artificial variation)
      return SolarHourlyPoint(
        hour: h.hour,
        timeStr: h.timeStr,
        powerKw: double.parse((h.powerKw * ratio).toStringAsFixed(1)),
        irradiance: h.irradiance, // Same irradiance (solar resource is shared)
        pr: pPr, // Plant-specific PR from API
      );
    }).toList();

    // Anti-zero morning yield fallback:
    // If inverter yield today hasn't updated yet in the early morning but inverters are actively generating power,
    // compute the estimated morning yield from the hourly integral or current active power.
    double effectiveYield = pYieldRaw;
    if (effectiveYield <= 0.0 && totalYieldTodayKwh > 0.0) {
      effectiveYield = totalYieldTodayKwh * ratio;
    }
    if (effectiveYield <= 0.0 && pPower > 0.0) {
      final hourlyIntegral = plantHourly.fold(0.0, (s, pt) => s + (pt.powerKw > 0 ? pt.powerKw : 0.0));
      effectiveYield = hourlyIntegral > 0.0 ? (hourlyIntegral * 0.85) : (pPower * 0.35);
    }

    return SolarSnapshot(
      timestamp: timestamp,
      isLive: isLive,
      totalPowerKw: double.parse(pPower.toStringAsFixed(1)),
      peakPowerKw: plantPeak > pPower ? plantPeak : pPower,
      totalYieldTodayKwh: double.parse(effectiveYield.toStringAsFixed(1)),
      yieldYesterdayKwh: plantYesterday,
      irradiance: pIrr,
      performanceRatio: pPr,
      gridExportKw: double.parse(pPower.toStringAsFixed(1)),
      onlineInverterCount: onlineCount,
      totalInverterCount: plantInvs.length,
      totalCapacityKwp: targetCap,
      inverters: plantInvs,
      hourlyPoints: plantHourly,
      plantIrradiance: {targetPlantId: pIrr},
      plantPr: {targetPlantId: pPr},
    );
  }

  SolarSnapshot get kelanisSnapshot => forPlant('kelanis');
  SolarSnapshot get mswSnapshot => forPlant('msw');

  List<SolarArrayCluster> get clusters {
    final map = <String, List<SolarInverter>>{};
    for (final inv in inverters) {
      map.putIfAbsent(inv.clusterId, () => []).add(inv);
    }

    final hasKelanis = inverters.any((i) => i.resolvedPlantId == 'kelanis');
    final hasMsw = inverters.any((i) => i.resolvedPlantId == 'msw');

    final list = <SolarArrayCluster>[];

    // If MSW inverters are present (or combined view)
    if (hasMsw || !hasKelanis) {
      list.add(
        SolarArrayCluster(
          id: '200kwp',
          name: '200 kWp Array',
          totalCapacityKwp: 200.0,
          inverters: map['200kwp'] ?? [],
        ),
      );
      list.add(
        SolarArrayCluster(
          id: '165kwp',
          name: '165 kWp Array',
          totalCapacityKwp: 165.0,
          inverters: map['165kwp'] ?? [],
        ),
      );
      list.add(
        SolarArrayCluster(
          id: '15_20kwp',
          name: '15 & 20 kWp Array',
          totalCapacityKwp: 35.0,
          inverters: map['15_20kwp'] ?? [],
        ),
      );
    }

    // If Kelanis inverters are present (or combined view)
    if (hasKelanis || !hasMsw) {
      list.add(
        SolarArrayCluster(
          id: '468kwp',
          name: '468 kWp Array',
          totalCapacityKwp: 468.0,
          inverters: map['468kwp'] ?? [],
        ),
      );
    }

    return list;
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'is_live': isLive,
    'total_power_kw': totalPowerKw,
    'peak_power_kw': peakPowerKw,
    'total_yield_today_kwh': totalYieldTodayKwh,
    'yield_yesterday_kwh': yieldYesterdayKwh,
    'irradiance': irradiance,
    'performance_ratio': performanceRatio,
    'plant_irradiance': plantIrradiance,
    'plant_pr': plantPr,
    'grid_export_kw': gridExportKw,
    'online_inverter_count': onlineInverterCount,
    'total_inverter_count': totalInverterCount,
    'total_capacity_kwp': totalCapacityKwp,
    'inverters': inverters.map((i) => i.toJson()).toList(),
    'hourly_points': hourlyPoints.map((h) => h.toJson()).toList(),
  };

  factory SolarSnapshot.fromJson(Map<dynamic, dynamic> json) {
    final rawTs = json['timestamp']?.toString();
    final dt = rawTs != null ? DateTime.tryParse(rawTs) ?? DateTime.now() : DateTime.now();

    List<SolarInverter> invs = [];
    if (json['inverters'] is List) {
      invs = (json['inverters'] as List)
          .whereType<Map>()
          .map((m) => SolarInverter.fromJson(m))
          .toList();
    }

    List<SolarHourlyPoint> hourly = [];
    if (json['hourly_points'] is List) {
      hourly = (json['hourly_points'] as List)
          .whereType<Map>()
          .map((m) => SolarHourlyPoint.fromJson(m))
          .toList();
    }

    final Map<String, double> plantIrr = {};
    if (json['plant_irradiance'] is Map) {
      (json['plant_irradiance'] as Map).forEach((k, v) {
        if (v is num) plantIrr[k.toString()] = v.toDouble();
      });
    }

    final Map<String, double> plantPrMap = {};
    if (json['plant_pr'] is Map) {
      (json['plant_pr'] as Map).forEach((k, v) {
        if (v is num) plantPrMap[k.toString()] = v.toDouble();
      });
    }

    return SolarSnapshot(
      timestamp: dt,
      isLive: json['is_live'] == true,
      totalPowerKw: (json['total_power_kw'] as num?)?.toDouble() ?? 0.0,
      peakPowerKw: (json['peak_power_kw'] as num?)?.toDouble() ?? 0.0,
      totalYieldTodayKwh: (json['total_yield_today_kwh'] as num?)?.toDouble() ?? 0.0,
      yieldYesterdayKwh: (json['yield_yesterday_kwh'] as num?)?.toDouble() ?? 0.0,
      irradiance: (json['irradiance'] as num?)?.toDouble() ?? 0.0,
      performanceRatio: (json['performance_ratio'] as num?)?.toDouble() ?? 80.0,
      plantIrradiance: plantIrr,
      plantPr: plantPrMap,
      gridExportKw: (json['grid_export_kw'] as num?)?.toDouble() ?? 0.0,
      onlineInverterCount: (json['online_inverter_count'] as num?)?.toInt() ?? invs.length,
      totalInverterCount: (json['total_inverter_count'] as num?)?.toInt() ?? invs.length,
      totalCapacityKwp: (json['total_capacity_kwp'] as num?)?.toDouble() ?? 868.0,
      inverters: invs,
      hourlyPoints: hourly,
    );
  }

  /// Creates a clean zero/standby snapshot when waiting for first live API sync or during night standby.
  factory SolarSnapshot.emptyOrStandby({DateTime? date}) {
    final now = date ?? DateTime.now();
    return SolarSnapshot(
      timestamp: DateTime(now.year, now.month, now.day, now.hour, 0),
      isLive: false,
      totalPowerKw: 0.0,
      peakPowerKw: 0.0,
      totalYieldTodayKwh: 0.0,
      yieldYesterdayKwh: 0.0,
      irradiance: 0.0,
      performanceRatio: 0.0,
      gridExportKw: 0.0,
      onlineInverterCount: 0,
      totalInverterCount: 12,
      totalCapacityKwp: 868.0,
      inverters: const [],
      hourlyPoints: [
        for (int h = 4; h <= now.hour && h <= 20; h++)
          SolarHourlyPoint(
            hour: h,
            timeStr: '${h.toString().padLeft(2, '0')}:00',
            powerKw: 0.0,
            irradiance: 0.0,
            pr: 0.0,
          ),
      ],
    );
  }
}
