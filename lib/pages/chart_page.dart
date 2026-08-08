import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/services/cems_threshold_service.dart';

class ChartPage extends StatefulWidget {
  final String columnName;
  final int columnIndex;
  final List<String> header;
  final List<dynamic> fullData;
  final String unit;
  final String date;
  final double? thresholdValue;

  const ChartPage({
    super.key,
    required this.columnName,
    required this.columnIndex,
    required this.header,
    required this.fullData,
    required this.unit,
    required this.date,
    this.thresholdValue,
  });

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  int _decimalPlaces = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _decimalPlaces = prefs.getInt('decimal_places') ?? 1;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    double roundedY = 0;
    List<FlSpot> spots = [];
    for (int i = 1; i < widget.fullData.length; i++) {
      var row = widget.fullData[i] as List<dynamic>;

      DateTime? dt;
      try {
        dt = DateTime.parse(row[0].toString());
      } catch (_) {}

      double? yValue = double.tryParse(row[widget.columnIndex].toString());

      if (dt != null && yValue != null) {
        roundedY = double.parse(yValue.toStringAsFixed(5));
        double xVal = dt.millisecondsSinceEpoch.toDouble();
        spots.add(FlSpot(xVal, roundedY));
      }
    }

    double finalVal = roundedY;
    if (spots.isNotEmpty) {
      finalVal = spots.last.y;
    }

    double maxY = 0;
    double minY_global = double.infinity;
    double sumY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY_global) minY_global = spot.y;
      sumY += spot.y;
    }
    final threshold = widget.thresholdValue ?? CemsThresholdService.getThreshold(widget.columnName)?.max;
    final nonCompliant = threshold != null && finalVal > threshold;

    double maxVal = maxY;
    maxY = maxY + (maxY * 0.1);
    if (maxY == 0) maxY = 100;
    if (threshold != null && threshold > maxY) {
      maxY = threshold + (threshold * 0.1);
    }
    if (minY_global == double.infinity) minY_global = 0;
    const double chartMinY = 0;

    final lineColor = nonCompliant ? Colors.redAccent : Colors.cyanAccent;

    if (spots.isEmpty) {
      return Container(
        decoration: _bgDecoration(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.columnName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: const Center(
              child: Text("No data for this column",
                  style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    double avgY = spots.length > 0 ? sumY / spots.length : 0;

    final extraLines = <HorizontalLine>[];
    if (threshold != null) {
      extraLines.add(HorizontalLine(
        y: threshold,
        color: nonCompliant ? Colors.redAccent : Colors.amberAccent,
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: TextStyle(
            fontSize: 14,
            color: nonCompliant ? Colors.redAccent : Colors.amberAccent,
            fontWeight: FontWeight.bold,
          ),
          labelResolver: (_) => 'Limit ${threshold.toStringAsFixed(_decimalPlaces)} ${widget.unit}',
        ),
      ));
    }

    return Container(
      decoration: _bgDecoration(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.columnName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${finalVal.toStringAsFixed(_decimalPlaces)} ${widget.unit}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: nonCompliant ? Colors.redAccent : Colors.white),
                        ),
                        if (threshold != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            nonCompliant ? Icons.warning_rounded : Icons.check_circle_rounded,
                            color: nonCompliant ? Colors.redAccent : Colors.greenAccent,
                            size: 28,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Last Update: ${widget.date}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 8),
                  child: LineChart(
                    LineChartData(
                      minY: chartMinY,
                      maxY: maxY,
                      minX: minX,
                      maxX: maxX,
                      extraLinesData: ExtraLinesData(horizontalLines: extraLines),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.black87,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                                  spot.x.toInt());
                              String fullDate =
                                  DateFormat("dd MMM HH:mm").format(dt);
                              return LineTooltipItem(
                                "${spot.y.toStringAsFixed(_decimalPlaces)} ${widget.unit}\n$fullDate",
                                const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toStringAsFixed(_decimalPlaces),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxX - minX) / 4,
                            getTitlesWidget: (value, meta) {
                              DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              return SideTitleWidget(
                                space: 8,
                                meta: meta,
                                child: Text(
                                  DateFormat("HH:mm").format(dt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) =>
                            const FlLine(color: Colors.white10, strokeWidth: 0.5),
                        getDrawingVerticalLine: (value) =>
                            const FlLine(color: Colors.white10, strokeWidth: 0.5),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white10),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          dotData: const FlDotData(show: false),
                          color: lineColor,
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildStatsBar(minY_global, maxVal, avgY),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(double minVal, double maxVal, double avgVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("MIN", minVal.toStringAsFixed(_decimalPlaces), Colors.cyanAccent),
          _divider(),
          _statItem("AVG", avgVal.toStringAsFixed(_decimalPlaces), Colors.amberAccent),
          _divider(),
          _statItem("MAX", maxVal.toStringAsFixed(_decimalPlaces), Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          "$value ${widget.unit}",
          style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white10,
    );
  }

  BoxDecoration _bgDecoration() {
    return BoxDecoration(
      image: DecorationImage(
        image: const AssetImage('asset/msw.png'),
        fit: BoxFit.fill,
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.75),
          BlendMode.darken,
        ),
      ),
    );
  }
}
