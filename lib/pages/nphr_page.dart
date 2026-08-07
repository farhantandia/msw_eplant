import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

import 'package:msw_eplant/widgets/widgets.dart';

class NphrPage extends StatefulWidget {
  const NphrPage({super.key});

  @override
  State<NphrPage> createState() => _NphrPageState();
}

class _NphrPageState extends State<NphrPage> {
  /// Persamaan polynomial aktual
  double calculatePolynomial(double x) {
    return 0.002091081 * pow(x, 6) -
        0.25509163 * pow(x, 5) +
        12.71453427 * pow(x, 4) -
        331.7789929 * pow(x, 3) +
        4795.876444 * pow(x, 2) -
        36715.63544 * x +
        122674.5032;
  }

  /// Persamaan polynomial target
  double calculateTarget(double x) {
    return 0.00196559505 * pow(x, 6) -
        0.239778826 * pow(x, 5) +
        11.9511090 * pow(x, 4) -
        311.854308 * pow(x, 3) +
        4507.83793 * pow(x, 2) -
        34510.5291 * x +
        115307.904;
  }

  final DatabaseReference _boiler1Ref =
      FirebaseDatabase.instance.ref("excel_data/table1");
  final DatabaseReference _boiler2Ref =
      FirebaseDatabase.instance.ref("excel_data/table2");
  final DatabaseReference _nphrRef =
      FirebaseDatabase.instance.ref("excel_data/nphr");

  StreamSubscription<DatabaseEvent>? _nphrSub;
  StreamSubscription<DatabaseEvent>? _boiler1Sub;
  StreamSubscription<DatabaseEvent>? _boiler2Sub;

  double? load1, load2;
  double? nphr1, nphr2;
  String formattedDate = "";

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _fetchData();
  }

  void _fetchData() {
    _nphrSub = _nphrRef.onValue.listen((event) {
      final snapshot = event.snapshot.value;
      if (snapshot == null) return;
      if (snapshot is List && snapshot.length > 1 && snapshot.last is List) {
        final lastRow = snapshot.last;
        if (lastRow.length >= 2 && mounted) {
          setState(() {
            nphr1 = double.tryParse(lastRow[0].toString())?.clamp(0, double.infinity) ?? 0;
            nphr2 = double.tryParse(lastRow[1].toString())?.clamp(0, double.infinity) ?? 0;
          });
        }
      }
    });

    _boiler1Sub = _boiler1Ref.onValue.listen((event) {
      final snapshot = event.snapshot.value;
      if (snapshot == null) return;
      if (snapshot is List && snapshot.length > 1 && snapshot.last is List) {
        final lastRow = snapshot.last;
        if (mounted) {
          formattedDate = formatDateTime(lastRow[0].toString());
          setState(() {
            load1 = double.tryParse(lastRow[1].toString())?.clamp(0, double.infinity) ?? 0;
          });
        }
      }
    });

    _boiler2Sub = _boiler2Ref.onValue.listen((event) {
      final snapshot = event.snapshot.value;
      if (snapshot == null) return;
      if (snapshot is List && snapshot.length > 1 && snapshot.last is List) {
        final lastRow = snapshot.last;
        if (mounted) {
          setState(() {
            load2 = double.tryParse(lastRow[0].toString())?.clamp(0, double.infinity) ?? 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nphrSub?.cancel();
    _boiler1Sub?.cancel();
    _boiler2Sub?.cancel();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }
 Widget _buildLegendItem(Color color, String text, {bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            shape: isDot ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    // Generate garis polynomial
    final actualSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    for (double x = 5; x <= 30; x += 1) {
      actualSpots.add(FlSpot(x, calculatePolynomial(x)));
      targetSpots.add(FlSpot(x, calculateTarget(x)));
    }

    double minY = 1000;
    double maxY = 26000;

    // Titik realtime
    final List<LineChartBarData> realtimePoints = [];
    if (load1 != null && nphr1 != null) {
      realtimePoints.add(
        LineChartBarData(
          spots: [FlSpot(load1!, nphr1!)],
          isCurved: false,
          color: Colors.purpleAccent,
          barWidth: 0,
          dotData: FlDotData(show: true),
        ),
      );
    }
    if (load2 != null && nphr2 != null) {
      realtimePoints.add(
        LineChartBarData(
          spots: [FlSpot(load2!, nphr2!)],
          isCurved: false,
          color: Colors.greenAccent,
          barWidth: 0,
          dotData: FlDotData(show: true),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NPHR Curve", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildLegendItem(Colors.blueAccent, "Baseline", isDot: false),
                      const SizedBox(width: 8),
                      _buildLegendItem(Colors.orange, "Target", isDot: false),
                      const SizedBox(width: 8),
                      _buildLegendItem(Colors.purpleAccent, "Unit 1", isDot: true),
                      const SizedBox(width: 8),
                      _buildLegendItem(Colors.greenAccent, "Unit 2", isDot: true),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Last update: $formattedDate", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(6.0),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: const Text("kCal/kWh"),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text("MW"),
                axisNameSize: 16,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            minX: 5,
            maxX: 30,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              // Garis aktual
              LineChartBarData(
                spots: actualSpots,
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
              // Garis target
              LineChartBarData(
                spots: targetSpots,
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
              // Titik realtime
              ...realtimePoints,
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.white,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((barSpot) {
                    final xVal = barSpot.x.toStringAsFixed(1);
                    final yVal = barSpot.y.toInt();
                    String label = "";
                    if (barSpot.bar.color == Colors.purpleAccent) {
                      label = "Unit 1\nLoad: $xVal MW\nNPHR: $yVal kCal/kWh";
                    } else if (barSpot.bar.color == Colors.greenAccent) {
                      label = "Unit 2\nLoad: $xVal MW\nNPHR: $yVal kCal/kWh";
                    } else {
                      label = "Load: $xVal MW\nNPHR: $yVal kCal/kWh";
                    }
                    return LineTooltipItem(
                      label,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
    );
  }
}
