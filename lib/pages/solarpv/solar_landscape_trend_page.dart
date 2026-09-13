import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';

class SolarLandscapeTrendPage extends StatefulWidget {
  final SolarMetricType initialMetric;
  final String? plantId; // 'msw' | 'kelanis' | null (total)
  final String? inverterId;
  final String? inverterName;
  final int initialTimeframe; // 0: Today, 1: Yesterday

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
  late int _selectedTimeframe; // 0: Today, 1: Yesterday
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeMetric = widget.initialMetric;
    _selectedTimeframe = widget.initialTimeframe.clamp(0, 1);

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
    await FusionSolarService.instance.ensureYesterdayData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _buildSpots() {
    final service = FusionSolarService.instance;
    final isYesterday = _selectedTimeframe == 1;
    final points = isYesterday
        ? (service.yesterdayHourlyPoints ?? const <SolarHourlyPoint>[])
        : service.snapshotNotifier.value.hourlyPoints;

    if (points.isEmpty) return [];

    final spots = <FlSpot>[];
    final snapshot = service.snapshotNotifier.value;

    // Check if inverter specific
    SolarInverter? inv;
    if (widget.inverterId != null) {
      try {
        inv = snapshot.inverters.firstWhere(
          (i) => i.id == widget.inverterId || i.name == widget.inverterName,
        );
      } catch (_) {}
    }

    final double invCapRatio = (inv != null && snapshot.totalCapacityKwp > 0)
        ? (inv.capacityKwp / snapshot.totalCapacityKwp)
        : 1.0;

    double cumulativeYield = 0.0;

    for (final p in points) {
      final hour = p.hour.toDouble();
      double val = 0.0;

      if (inv != null) {
        // Inverter metrics
        switch (_activeMetric) {
          case SolarMetricType.power:
            val = p.powerKw * invCapRatio;
            break;
          case SolarMetricType.dailyYield:
            cumulativeYield += (p.powerKw * invCapRatio) * 0.85;
            val = cumulativeYield;
            break;
          case SolarMetricType.specificEnergy:
            val = inv.specificEnergy ?? 0.0;
            break;
          case SolarMetricType.inverterTemp:
            val = inv.temperature ?? 28.0;
            break;
          case SolarMetricType.inverterEfficiency:
            val = inv.efficiency ?? 98.4;
            break;
          case SolarMetricType.gridFrequency:
            val = inv.gridFrequency ?? 50.0;
            break;
          case SolarMetricType.voltage:
            val = inv.lineVoltageAb ?? 380.0;
            break;
          case SolarMetricType.current:
            val = inv.phaseCurrentA ?? 0.0;
            break;
          default:
            val = p.powerKw * invCapRatio;
        }
      } else if (widget.plantId != null) {
        // Plant-specific metrics
        final pData = p.plantData?[widget.plantId];
        switch (_activeMetric) {
          case SolarMetricType.power:
            val = pData?['power'] ?? (p.powerKw * 0.5);
            break;
          case SolarMetricType.dailyYield:
            cumulativeYield += (pData?['power'] ?? (p.powerKw * 0.5)) * 0.85;
            val = cumulativeYield;
            break;
          case SolarMetricType.irradiance:
            val = pData?['irradiance'] ?? p.irradiance;
            break;
          case SolarMetricType.pr:
            val = pData?['pr'] ?? p.pr;
            break;
          default:
            val = pData?['power'] ?? (p.powerKw * 0.5);
        }
      } else {
        // Overall aggregate metrics
        switch (_activeMetric) {
          case SolarMetricType.power:
            val = p.powerKw;
            break;
          case SolarMetricType.dailyYield:
            cumulativeYield += p.powerKw * 0.85;
            val = cumulativeYield;
            break;
          case SolarMetricType.irradiance:
            val = p.irradiance;
            break;
          case SolarMetricType.pr:
            val = p.pr;
            break;
          case SolarMetricType.gridExport:
            val = (p.powerKw > 20.0) ? (p.powerKw * 0.92) : 0.0;
            break;
          case SolarMetricType.co2:
            cumulativeYield += p.powerKw * 0.85;
            val = double.parse((cumulativeYield * 0.00085).toStringAsFixed(2));
            break;
          case SolarMetricType.coal:
            cumulativeYield += p.powerKw * 0.85;
            val = double.parse((cumulativeYield * 0.00040).toStringAsFixed(2));
            break;
          default:
            val = p.powerKw;
        }
      }

      spots.add(FlSpot(hour, val));
    }

    return spots;
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

    final isYesterdayNoData = _selectedTimeframe == 1 &&
        (FusionSolarService.instance.yesterdayHourlyPoints == null ||
            FusionSolarService.instance.yesterdayHourlyPoints!.isEmpty);

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
                  // Timeframe Segmented Switcher (Today & Yesterday only)
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
                    : isYesterdayNoData
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: AppColors.textDim, size: 36),
                                SizedBox(height: 8),
                                Text(
                                  'Data kemarin belum tersedia',
                                  style: TextStyle(color: AppColors.textDim, fontSize: AppTheme.fs13),
                                ),
                              ],
                            ),
                          )
                        : spots.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada data untuk metrik ini',
                                  style: TextStyle(color: AppColors.textDim, fontSize: AppTheme.fs13),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    verticalInterval: 2,
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
                                        interval: 2,
                                        getTitlesWidget: (val, _) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${val.toInt().toString().padLeft(2, '0')}:00',
                                              style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                                  ),
                                  minX: 4,
                                  maxX: 20,
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
                                          radius: 3.0,
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
                                          final timeLabel = '${spot.x.toInt().toString().padLeft(2, '0')}:00 WITA';
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
