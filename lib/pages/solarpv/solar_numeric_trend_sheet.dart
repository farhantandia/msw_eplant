import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
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
  int _selectedTimeframe = 0; // 0: Today, 1: Yesterday
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
        switch (widget.metricType) {
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
        switch (widget.metricType) {
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
        switch (widget.metricType) {
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
    final chartMaxY = maxVal > 0 ? (maxVal * 1.2) : 10.0;

    final isYesterdayNoData = _selectedTimeframe == 1 &&
        (FusionSolarService.instance.yesterdayHourlyPoints == null ||
            FusionSolarService.instance.yesterdayHourlyPoints!.isEmpty);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Metric Title, Subtitle, Fullscreen & Timeframe Tabs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.metricType.label,
                        style: const TextStyle(
                          fontSize: AppTheme.fs16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.inverterName != null
                            ? widget.inverterName!
                            : (widget.plantId == 'kelanis'
                                ? 'PLTS Kelanis (468 kWp)'
                                : (widget.plantId == 'msw' ? 'PLTS MSW (400 kWp)' : 'Solar Plant Total (868 kWp)')),
                        style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                // Fullscreen Landscape Trend button
                Tooltip(
                  message: 'Fullscreen Landscape View',
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context); // Close sheet
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
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.solar.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.solar.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.solar),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSub, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Value banner and timeframe tabs row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Real-time current readout
                Flexible(
                  flex: 5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
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
                // Timeframe Segmented Switcher (Today & Yesterday only)
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
                  : isYesterdayNoData
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: AppColors.textDim, size: 32),
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
                                      interval: 4,
                                      getTitlesWidget: (val, _) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '${val.toInt()}:00',
                                            style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 4,
                                maxX: 20,
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
                                    dotData: const FlDotData(show: false),
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
                                        final label = '${spot.x.toInt().toString().padLeft(2, '0')}:00 WITA';
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
