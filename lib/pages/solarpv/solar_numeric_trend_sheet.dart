import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/pages/solarpv/solar_landscape_trend_page.dart';

enum SolarMetricType {
  power('Active Power', 'kW', AppColors.primary),
  dailyYield('Daily Generation', 'kWh', Color(0xFF00E5A0)),
  irradiance('Solar Irradiance', 'kWh/m²', Color(0xFFFFB300)),
  pr('Performance Ratio', '%', Color(0xFF38BDF8)),
  gridExport('Grid Export', 'kW', Color(0xFF818CF8)),
  inverterTemp('Internal Temperature', '°C', Color(0xFFFF7A00)),
  inverterEfficiency('Inverter Efficiency', '%', Color(0xFF10B981)),
  gridFrequency('Grid Frequency', 'Hz', Color(0xFF38BDF8)),
  voltage('Line Voltage', 'V', Color(0xFFEAB308)),
  current('Phase Current', 'A', Color(0xFFEC4899)),
  specificEnergy('Specific Energy', 'kWh/kWp', Color(0xFF06B6D4)),
  co2('Avoided CO₂', 'Ton', Color(0xFF10B981)),
  coal('Coal Saved', 'Ton', Color(0xFFF59E0B));

  final String label;
  final String unit;
  final Color color;
  const SolarMetricType(this.label, this.unit, this.color);
}

class SolarNumericTrendSheet extends StatefulWidget {
  final SolarMetricType metricType;
  final String? plantId; // 'msw' | 'kelanis' | null (total)
  final String? inverterId;
  final String? inverterName;
  final double currentValue;

  const SolarNumericTrendSheet({
    super.key,
    required this.metricType,
    this.plantId,
    this.inverterId,
    this.inverterName,
    required this.currentValue,
  });

  static Future<void> show(
    BuildContext context, {
    required SolarMetricType metricType,
    String? plantId,
    String? inverterId,
    String? inverterName,
    required double currentValue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SolarNumericTrendSheet(
        metricType: metricType,
        plantId: plantId,
        inverterId: inverterId,
        inverterName: inverterName,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<SolarNumericTrendSheet> createState() => _SolarNumericTrendSheetState();
}

class _SolarNumericTrendSheetState extends State<SolarNumericTrendSheet> {
  int _selectedTimeframe = 0; // 0: Today, 1: Yesterday, 2: 7 Days
  Map<String, Map<String, dynamic>>? _historyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await FusionSolarService.instance.fetchHistory7Days();
    if (mounted) {
      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _buildSpots() {
    if (_historyData == null || _historyData!.isEmpty) return [];

    final sortedDates = _historyData!.keys.toList()..sort();
    if (sortedDates.isEmpty) return [];

    final spots = <FlSpot>[];

    if (_selectedTimeframe == 0) {
      // Today (Last date in sorted list)
      final todayKey = sortedDates.last;
      final hoursMap = _historyData![todayKey] ?? {};
      for (int h = 4; h <= 20; h++) {
        final hKey = h.toString().padLeft(2, '0');
        if (hoursMap.containsKey(hKey)) {
          final val = _extractMetricValue(hoursMap[hKey]);
          spots.add(FlSpot(h.toDouble(), val));
        }
      }
    } else if (_selectedTimeframe == 1) {
      // Yesterday (Second to last date if exists, otherwise same date)
      final yestKey = sortedDates.length >= 2 ? sortedDates[sortedDates.length - 2] : sortedDates.first;
      final hoursMap = _historyData![yestKey] ?? {};
      for (int h = 4; h <= 20; h++) {
        final hKey = h.toString().padLeft(2, '0');
        if (hoursMap.containsKey(hKey)) {
          final val = _extractMetricValue(hoursMap[hKey]);
          spots.add(FlSpot(h.toDouble(), val));
        }
      }
    } else {
      // 7 Days
      double xIndex = 0;
      for (final dateKey in sortedDates) {
        final hoursMap = _historyData![dateKey] ?? {};
        double maxDayVal = 0;
        double sumVal = 0;
        int count = 0;

        for (final hourData in hoursMap.values) {
          final val = _extractMetricValue(hourData);
          if (val > maxDayVal) maxDayVal = val;
          sumVal += val;
          count++;
        }

        // For cumulative yield, use end-of-day yield; for power/irradiance/PR/temp use peak or average
        double pointVal = maxDayVal;
        if (widget.metricType == SolarMetricType.pr ||
            widget.metricType == SolarMetricType.gridFrequency ||
            widget.metricType == SolarMetricType.voltage) {
          pointVal = count > 0 ? (sumVal / count) : 0.0;
        }

        spots.add(FlSpot(xIndex, pointVal));
        xIndex += 1.0;
      }
    }

    return spots;
  }

  double _extractMetricValue(dynamic hourRecord) {
    if (hourRecord is! Map) return 0.0;
    final map = Map<String, dynamic>.from(hourRecord);

    // 1. If looking for an inverter metric
    if (widget.inverterId != null) {
      final invList = map['inverters'];
      if (invList is List) {
        for (final item in invList) {
          if (item is Map && (item['id'] == widget.inverterId || item['name'] == widget.inverterName)) {
            final invMap = Map<String, dynamic>.from(item);
            switch (widget.metricType) {
              case SolarMetricType.power:
                return (invMap['power_kw'] as num?)?.toDouble() ?? 0.0;
              case SolarMetricType.dailyYield:
                return (invMap['yield_today_kwh'] as num?)?.toDouble() ?? 0.0;
              case SolarMetricType.specificEnergy:
                return (invMap['specific_energy'] as num?)?.toDouble() ?? 0.0;
              case SolarMetricType.inverterTemp:
                return (invMap['temperature'] as num?)?.toDouble() ?? 28.0;
              case SolarMetricType.inverterEfficiency:
                return (invMap['efficiency'] as num?)?.toDouble() ?? 98.4;
              case SolarMetricType.gridFrequency:
                return (invMap['grid_frequency'] as num?)?.toDouble() ?? 50.0;
              case SolarMetricType.voltage:
                return (invMap['line_voltage_ab'] as num?)?.toDouble() ?? 380.0;
              case SolarMetricType.current:
                return (invMap['phase_current_a'] as num?)?.toDouble() ?? 0.0;
              default:
                return (invMap['power_kw'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
      }
    }

    // 2. If looking for a specific plant metric (MSW / Kelanis)
    if (widget.plantId != null) {
      final plants = map['plants'];
      if (plants is Map && plants.containsKey(widget.plantId)) {
        final pMap = Map<String, dynamic>.from(plants[widget.plantId] as Map);
        switch (widget.metricType) {
          case SolarMetricType.power:
            return (pMap['power_kw'] as num?)?.toDouble() ?? 0.0;
          case SolarMetricType.dailyYield:
            return (pMap['yield_kwh'] as num?)?.toDouble() ?? 0.0;
          case SolarMetricType.irradiance:
            return (pMap['irradiance'] as num?)?.toDouble() ?? 0.0;
          case SolarMetricType.pr:
            return (pMap['pr'] as num?)?.toDouble() ?? 0.0;
          default:
            return (pMap['power_kw'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    // 3. Overall plant aggregates
    switch (widget.metricType) {
      case SolarMetricType.power:
        return (map['total_power_kw'] as num?)?.toDouble() ?? 0.0;
      case SolarMetricType.dailyYield:
        return (map['total_yield_kwh'] as num?)?.toDouble() ?? 0.0;
      case SolarMetricType.irradiance:
        return (map['irradiance'] as num?)?.toDouble() ?? 0.0;
      case SolarMetricType.pr:
        return (map['pr'] as num?)?.toDouble() ?? 0.0;
      case SolarMetricType.gridExport:
        return (map['grid_export_kw'] as num?)?.toDouble() ?? 0.0;
      case SolarMetricType.co2:
        final y = (map['total_yield_kwh'] as num?)?.toDouble() ?? 0.0;
        return double.parse((y * 0.00085).toStringAsFixed(2));
      case SolarMetricType.coal:
        final y = (map['total_yield_kwh'] as num?)?.toDouble() ?? 0.0;
        return double.parse((y * 0.00040).toStringAsFixed(2));
      default:
        return (map['total_power_kw'] as num?)?.toDouble() ?? 0.0;
    }
  }

  void _openLandscapePage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarLandscapeTrendPage(
          initialMetric: widget.metricType,
          plantId: widget.plantId,
          inverterId: widget.inverterId,
          inverterName: widget.inverterName,
          initialTimeframe: _selectedTimeframe,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final sortedDates = _historyData != null ? (_historyData!.keys.toList()..sort()) : <String>[];

    double minVal = spots.isNotEmpty ? spots.first.y : 0.0;
    double maxVal = spots.isNotEmpty ? spots.first.y : 0.0;
    double sumVal = 0.0;

    for (final s in spots) {
      if (s.y < minVal) minVal = s.y;
      if (s.y > maxVal) maxVal = s.y;
      sumVal += s.y;
    }
    final avgVal = spots.isNotEmpty ? (sumVal / spots.length) : 0.0;
    final chartMaxY = maxVal > 0 ? (maxVal * 1.15) : 10.0;

    final titlePrefix = widget.inverterName != null
        ? widget.inverterName!
        : (widget.plantId == 'kelanis'
            ? 'PLTS Kelanis'
            : (widget.plantId == 'msw' ? 'PLTS MSW' : 'Solar Plant Total'));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titlePrefix.toUpperCase(),
                      style: const TextStyle(
                        fontSize: AppTheme.fs11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSub,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.metricType.label,
                      style: const TextStyle(
                        fontSize: AppTheme.fs16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Fullscreen Landscape Button
              GestureDetector(
                onTap: _openLandscapePage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Landscape',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Current Value Display & Timeframe Tabs
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.currentValue < 10
                            ? widget.currentValue.toStringAsFixed(2)
                            : widget.currentValue.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: AppTheme.fs28,
                          fontWeight: FontWeight.w900,
                          color: widget.metricType.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.metricType.unit,
                        style: const TextStyle(
                          fontSize: AppTheme.fs13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Timeframe Segmented Switcher
              Flexible(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeTab('Today', 0),
                        _buildTimeTab('Yesterday', 1),
                        _buildTimeTab('7 Days', 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart Canvas
          SizedBox(
            height: 180,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (val, _) {
                              if (val <= 0 || val >= chartMaxY) return const SizedBox.shrink();
                              return Text(
                                val < 10 ? val.toStringAsFixed(1) : val.toInt().toString(),
                                style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: _selectedTimeframe == 2 ? 1 : 4,
                            getTitlesWidget: (val, _) {
                              if (_selectedTimeframe == 2) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < sortedDates.length) {
                                  final d = sortedDates[idx];
                                  final parts = d.split('-');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      parts.length >= 3 ? '${parts[1]}/${parts[2]}' : d,
                                      style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${val.toInt()}:00',
                                    style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: chartMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: widget.metricType.color,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _selectedTimeframe == 2,
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 3,
                              color: widget.metricType.color,
                              strokeWidth: 1.5,
                              strokeColor: Colors.black,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.metricType.color.withValues(alpha: 0.28),
                                widget.metricType.color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              String label;
                              if (_selectedTimeframe == 2) {
                                final idx = spot.x.toInt();
                                label = idx < sortedDates.length ? sortedDates[idx] : 'Day $idx';
                              } else {
                                label = '${spot.x.toInt().toString().padLeft(2, '0')}:00 WITA';
                              }
                              return LineTooltipItem(
                                '$label\n${spot.y < 10 ? spot.y.toStringAsFixed(2) : spot.y.toStringAsFixed(1)} ${widget.metricType.unit}',
                                TextStyle(
                                  color: widget.metricType.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTheme.fs11,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Statistics Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildStatItem('MIN', minVal)),
                Container(width: 1, height: 22, color: AppColors.border),
                Expanded(child: _buildStatItem('AVG', avgVal)),
                Container(width: 1, height: 22, color: AppColors.border),
                Expanded(child: _buildStatItem('PEAK', maxVal, isPeak: true)),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTimeTab(String label, int index) {
    final isSelected = _selectedTimeframe == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeframe = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fs11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double val, {bool isPeak = false}) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: AppColors.textSub),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${val < 10 ? val.toStringAsFixed(2) : val.toStringAsFixed(1)} ${widget.metricType.unit}',
            style: TextStyle(
              fontSize: AppTheme.fs12,
              fontWeight: FontWeight.w800,
              color: isPeak ? const Color(0xFFFFB020) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
