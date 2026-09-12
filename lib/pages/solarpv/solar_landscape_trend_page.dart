import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';

class SolarLandscapeTrendPage extends StatefulWidget {
  final SolarMetricType initialMetric;
  final String? plantId; // 'msw' | 'kelanis' | null (total)
  final String? inverterId;
  final String? inverterName;
  final int initialTimeframe; // 0: Today, 1: Yesterday, 2: 7 Days

  const SolarLandscapeTrendPage({
    super.key,
    this.initialMetric = SolarMetricType.power,
    this.plantId,
    this.inverterId,
    this.inverterName,
    this.initialTimeframe = 0,
  });

  @override
  State<SolarLandscapeTrendPage> createState() => _SolarLandscapeTrendPageState();
}

class _SolarLandscapeTrendPageState extends State<SolarLandscapeTrendPage> {
  late SolarMetricType _activeMetric;
  late int _selectedTimeframe;
  Map<String, Map<String, dynamic>>? _historyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeMetric = widget.initialMetric;
    _selectedTimeframe = widget.initialTimeframe;

    // Lock to landscape orientation and enable immersive sticky mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadData();
  }

  @override
  void dispose() {
    // Restore portrait mode and standard system UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
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

        double pointVal = maxDayVal;
        if (_activeMetric == SolarMetricType.pr ||
            _activeMetric == SolarMetricType.gridFrequency ||
            _activeMetric == SolarMetricType.voltage) {
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

    // Inverter metrics
    if (widget.inverterId != null) {
      final invList = map['inverters'];
      if (invList is List) {
        for (final item in invList) {
          if (item is Map && (item['id'] == widget.inverterId || item['name'] == widget.inverterName)) {
            final invMap = Map<String, dynamic>.from(item);
            switch (_activeMetric) {
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

    // Plant-specific metrics
    if (widget.plantId != null) {
      final plants = map['plants'];
      if (plants is Map && plants.containsKey(widget.plantId)) {
        final pMap = Map<String, dynamic>.from(plants[widget.plantId] as Map);
        switch (_activeMetric) {
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

    // Overall aggregate metrics
    switch (_activeMetric) {
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

  List<SolarMetricType> _getAvailableMetrics() {
    if (widget.inverterId != null) {
      return const [
        SolarMetricType.power,
        SolarMetricType.dailyYield,
        SolarMetricType.specificEnergy,
        SolarMetricType.inverterTemp,
        SolarMetricType.inverterEfficiency,
        SolarMetricType.gridFrequency,
        SolarMetricType.voltage,
        SolarMetricType.current,
      ];
    }
    return const [
      SolarMetricType.power,
      SolarMetricType.dailyYield,
      SolarMetricType.irradiance,
      SolarMetricType.pr,
      SolarMetricType.gridExport,
      SolarMetricType.co2,
      SolarMetricType.coal,
    ];
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
            ? 'PLTS Kelanis (468 kWp)'
            : (widget.plantId == 'msw' ? 'PLTS MSW (400 kWp)' : 'Solar Plant Total (868 kWp)'));

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Top Widescreen Telemetry Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Title and active metric
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$titlePrefix — SCADA Telemetry Trend',
                          style: const TextStyle(
                            fontSize: AppTheme.fs12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_activeMetric.label} (${_activeMetric.unit})',
                          style: TextStyle(
                            fontSize: AppTheme.fs11,
                            fontWeight: FontWeight.w600,
                            color: _activeMetric.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Parameter Dropdown Selector
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SolarMetricType>(
                        value: _activeMetric,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSub, size: 20),
                        items: _getAvailableMetrics().map((m) {
                          return DropdownMenuItem<SolarMetricType>(
                            value: m,
                            child: Text(
                              m.label,
                              style: TextStyle(
                                fontSize: AppTheme.fs11,
                                fontWeight: FontWeight.w600,
                                color: m == _activeMetric ? m.color : AppColors.text,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _activeMetric = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timeframe Segmented Switcher
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Exit Fullscreen',
                    icon: const Icon(Icons.fullscreen_exit_rounded, size: 22, color: AppColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Middle Expanded Chart Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval: _selectedTimeframe == 2 ? 1 : 2,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.border.withValues(alpha: 0.35),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (_) => FlLine(
                              color: AppColors.border.withValues(alpha: 0.20),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (val, _) {
                                  if (val <= 0 || val >= chartMaxY) return const SizedBox.shrink();
                                  return Text(
                                    val < 10 ? val.toStringAsFixed(1) : val.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w600,
                                      color: _activeMetric.color.withValues(alpha: 0.8),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
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
                                reservedSize: 24,
                                interval: _selectedTimeframe == 2 ? 1 : 2,
                                getTitlesWidget: (val, _) {
                                  if (_selectedTimeframe == 2) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < sortedDates.length) {
                                      final d = sortedDates[idx];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          d,
                                          style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${val.toInt().toString().padLeft(2, '0')}:00',
                                        style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                          ),
                          minY: 0,
                          maxY: chartMaxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.32,
                              color: _activeMetric.color,
                              barWidth: 2.8,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                  radius: _selectedTimeframe == 2 ? 4.5 : 3.0,
                                  color: _activeMetric.color,
                                  strokeWidth: 2,
                                  strokeColor: Colors.black,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _activeMetric.color.withValues(alpha: 0.32),
                                    _activeMetric.color.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  String timeLabel;
                                  if (_selectedTimeframe == 2) {
                                    final idx = spot.x.toInt();
                                    timeLabel = idx < sortedDates.length ? sortedDates[idx] : 'Day $idx';
                                  } else {
                                    timeLabel = '${spot.x.toInt().toString().padLeft(2, '0')}:00 WITA';
                                  }
                                  final numStr = spot.y < 10 ? spot.y.toStringAsFixed(2) : spot.y.toStringAsFixed(1);
                                  return LineTooltipItem(
                                    '$timeLabel\n$numStr ${_activeMetric.unit}',
                                    TextStyle(
                                      color: _activeMetric.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppTheme.fs12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Bottom SCADA Telemetry Summary Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('MINIMUM', minVal),
                  Container(width: 1, height: 26, color: AppColors.border),
                  _buildStatCard('AVERAGE', avgVal),
                  Container(width: 1, height: 26, color: AppColors.border),
                  _buildStatCard('PEAK VALUE', maxVal, isPeak: true),
                  Container(width: 1, height: 26, color: AppColors.border),
                  _buildStatCard('SAMPLES', spots.length.toDouble(), isCount: true),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fs11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double val, {bool isPeak = false, bool isCount = false}) {
    String display;
    if (isCount) {
      display = '${val.toInt()} pts';
    } else {
      display = '${val < 10 ? val.toStringAsFixed(2) : val.toStringAsFixed(1)} ${_activeMetric.unit}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fs11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          display,
          style: TextStyle(
            fontSize: AppTheme.fs13,
            fontWeight: FontWeight.w800,
            color: isPeak ? const Color(0xFFFFB020) : Colors.white,
          ),
        ),
      ],
    );
  }
}
