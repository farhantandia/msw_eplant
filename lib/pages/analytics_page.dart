import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ParamOption {
  final String tableName;
  final String tableKey;
  final String columnName;
  final int columnIndex;
  final bool hasDatetime;

  ParamOption({
    required this.tableName,
    required this.tableKey,
    required this.columnName,
    required this.columnIndex,
    required this.hasDatetime,
  });

  String get displayName => "$tableName: $columnName";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamOption &&
          runtimeType == other.runtimeType &&
          tableKey == other.tableKey &&
          columnIndex == other.columnIndex;

  @override
  int get hashCode => tableKey.hashCode ^ columnIndex.hashCode;
}

class SelectedParam {
  final ParamOption param;
  final Color color;
  final bool useRightAxis;

  SelectedParam({required this.param, required this.color, this.useRightAxis = false});
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final Map<String, DatabaseReference> _refs = {
    'table1': FirebaseDatabase.instance.ref("excel_data/table1"),
    'table2': FirebaseDatabase.instance.ref("excel_data/table2"),
    'cems1': FirebaseDatabase.instance.ref("excel_data/cems1"),
    'cems2': FirebaseDatabase.instance.ref("excel_data/cems2"),
    'nphr': FirebaseDatabase.instance.ref("excel_data/nphr"),
  };

  final Map<String, List<List>> _cachedData = {};
  final Map<String, StreamSubscription> _subs = {};

  List<ParamOption> _availableParams = [];
  List<SelectedParam> _selectedParams = [];

  final List<Color> _colorPalette = [
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
  ];

  final Map<String, String> _tableDisplayNames = {
    'table1': 'Boiler 1',
    'table2': 'Boiler 2',
    'cems1': 'CEMS 1',
    'cems2': 'CEMS 2',
    'nphr': 'NPHR',
  };

  bool _isLoading = true;
  int _decimalPlaces = 1;
  List<DateTime> _datetimes = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupStreams();
  }

  @override
  void dispose() {
    for (var sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
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

  void _setupStreams() {
    for (var entry in _refs.entries) {
      _subs[entry.key] = entry.value.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data == null) return;

        List<List> values = [];
        if (data is List) {
          values = List<List>.from(data.map((e) => List.from(e)));
        } else if (data is Map) {
          values = List<List>.from(data.values.map((e) => List.from(e)));
        }

        if (values.length > 1 && mounted) {
          setState(() {
            _cachedData[entry.key] = values;
            _rebuildAvailableParams();
            _isLoading = false;
          });
        }
      });
    }
  }

  void _rebuildAvailableParams() {
    List<ParamOption> params = [];

    if (_cachedData.containsKey('table1')) {
      final t1 = _cachedData['table1']!;
      _datetimes = [];
      for (int i = 1; i < t1.length; i++) {
        try {
          _datetimes.add(DateTime.parse(t1[i][0].toString()));
        } catch (_) {
          _datetimes.add(DateTime.now());
        }
      }
    }

    for (var entry in _cachedData.entries) {
      final key = entry.key;
      final header = entry.value.first;
      final displayName = _tableDisplayNames[key] ?? key;
      final hasDatetime = key == 'table1';

      for (int i = 0; i < header.length; i++) {
        String colName = header[i].toString();
        if (colName.toUpperCase() == 'DATETIME') continue;

        params.add(ParamOption(
          tableName: displayName,
          tableKey: key,
          columnName: colName,
          columnIndex: i,
          hasDatetime: hasDatetime,
        ));
      }
    }

    _availableParams = params;
    _selectedParams.removeWhere((sp) => !params.contains(sp.param));
  }

  void _showParameterPicker() {
    final available = _availableParams
        .where((p) => !_selectedParams.any((sp) => sp.param == p))
        .toList();

    final Map<String, List<ParamOption>> grouped = {};
    for (var p in available) {
      grouped.putIfAbsent(p.tableName, () => []).add(p);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    "Select Parameter 📊 (${_selectedParams.length}/3)",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Max 3 parameters. Params at index 0,1 use left axis; 2 use right axis.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                entry.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                            ...entry.value.map((param) => ListTile(
                                  dense: true,
                                  title: Text(
                                    param.columnName,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 20),
                                  onTap: () {
                                    if (_selectedParams.length >= 3) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Maximum 3 parameters allowed"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _selectedParams.add(SelectedParam(
                                        param: param,
                                        color: _colorPalette[_selectedParams.length],
                                        useRightAxis: _selectedParams.length >= 2,
                                      ));
                                    });
                                    Navigator.pop(ctx);
                                  },
                                )),
                            Divider(color: Colors.white.withOpacity(0.05)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.8),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Analytics",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (_selectedParams.isNotEmpty && !_isLoading)
              IconButton(
                icon: Icon(
                  Icons.fullscreen,
                  color: Colors.cyanAccent.withValues(alpha: 0.9),
                ),
                tooltip: 'Fullscreen',
                onPressed: _openFullscreen,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildParameterSelector(),
                    const SizedBox(height: 16),
                    _buildSelectedChips(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildChart()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildParameterSelector() {
    return GestureDetector(
      onTap: _selectedParams.length < 3 ? _showParameterPicker : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withOpacity(0.65),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_chart,
              color: _selectedParams.length < 3 ? Colors.cyanAccent : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedParams.isEmpty
                    ? "Tap to add parameter (max 3)"
                    : "Add parameter (${_selectedParams.length}/3)",
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedParams.length < 3 ? Colors.white : Colors.grey,
                ),
              ),
            ),
            if (_selectedParams.length < 3)
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChips() {
    if (_selectedParams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Text(
            "No parameters selected.\nTap above to add 1\u20133 parameters.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedParams.asMap().entries.map((entry) {
        final i = entry.key;
        final sp = entry.value;
        final axisLabel = sp.useRightAxis ? 'R' : 'L';
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: sp.color,
            radius: 7,
                child: Text(axisLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          label: Text(
            sp.param.displayName,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: sp.color.withOpacity(0.2),
          side: BorderSide(color: sp.color.withOpacity(0.5)),
          deleteIcon: Icon(Icons.close, size: 16, color: sp.color),
          onDeleted: () {
            setState(() {
              _selectedParams.removeAt(i);
              for (int j = 0; j < _selectedParams.length; j++) {
                _selectedParams[j] = SelectedParam(
                  param: _selectedParams[j].param,
                  color: _colorPalette[j],
                  useRightAxis: j >= 2,
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    return AnalyticsChart(
      selectedParams: _selectedParams,
      datetimes: _datetimes,
      cachedData: _cachedData,
      decimalPlaces: _decimalPlaces,
      colorPalette: _colorPalette,
    );
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenAnalyticsPage(
          selectedParams: _selectedParams,
          datetimes: _datetimes,
          cachedData: _cachedData,
          decimalPlaces: _decimalPlaces,
          colorPalette: _colorPalette,
        ),
      ),
    );
  }
}

class AnalyticsChart extends StatelessWidget {
  final List<SelectedParam> selectedParams;
  final List<DateTime> datetimes;
  final Map<String, List<List>> cachedData;
  final int decimalPlaces;
  final List<Color> colorPalette;

  const AnalyticsChart({
    super.key,
    required this.selectedParams,
    required this.datetimes,
    required this.cachedData,
    required this.decimalPlaces,
    required this.colorPalette,
  });

  List<FlSpot> _getSpotsForParam(ParamOption param) {
    final tableData = cachedData[param.tableKey];
    if (tableData == null || tableData.length < 2) return [];

    List<FlSpot> spots = [];
    int dataRows = tableData.length - 1;
    int timeRows = datetimes.length;
    int count = dataRows < timeRows ? dataRows : timeRows;

    for (int i = 0; i < count; i++) {
      final row = tableData[i + 1];
      if (param.columnIndex >= row.length) continue;

      double? yVal = double.tryParse(row[param.columnIndex].toString());
      if (yVal == null) continue;

      double xVal = datetimes[i].millisecondsSinceEpoch.toDouble();
      spots.add(FlSpot(xVal, yVal));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedParams.isEmpty || datetimes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "Select parameters to visualize",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    List<SelectedParam> rawParams = [];
    List<List<FlSpot>> rawSpots = [];
    double globalMinX = double.infinity;
    double globalMaxX = double.negativeInfinity;

    double leftMinY = double.infinity;
    double leftMaxY = double.negativeInfinity;
    double rightMinY = double.infinity;
    double rightMaxY = double.negativeInfinity;

    bool hasLeft = false;
    bool hasRight = false;

    for (int i = 0; i < selectedParams.length; i++) {
      final sp = selectedParams[i];
      final spots = _getSpotsForParam(sp.param);
      if (spots.isEmpty) continue;

      for (var s in spots) {
        if (s.x < globalMinX) globalMinX = s.x;
        if (s.x > globalMaxX) globalMaxX = s.x;
        if (sp.useRightAxis) {
          if (s.y < rightMinY) rightMinY = s.y;
          if (s.y > rightMaxY) rightMaxY = s.y;
          hasRight = true;
        } else {
          if (s.y < leftMinY) leftMinY = s.y;
          if (s.y > leftMaxY) leftMaxY = s.y;
          hasLeft = true;
        }
      }

      rawParams.add(sp);
      rawSpots.add(spots);
    }

    if (rawSpots.isEmpty) {
      return const Center(
        child: Text("No data available for selected parameters.", style: TextStyle(color: Colors.grey)),
      );
    }

    double leftRange = leftMaxY - leftMinY;
    if (leftRange == 0) leftRange = 1;
    double leftMin = leftMinY - leftRange * 0.05;
    double leftMax = leftMaxY + leftRange * 0.1;
    if (leftMin < 0 && leftMinY >= 0) leftMin = 0;

    double rightRange = rightMaxY - rightMinY;
    if (rightRange == 0) rightRange = 1;
    double rightMin = rightMinY - rightRange * 0.05;
    double rightMax = rightMaxY + rightRange * 0.1;
    if (rightMin < 0 && rightMinY >= 0) rightMin = 0;

    final double windowMin = hasLeft ? leftMin : rightMin;
    final double windowMax = hasLeft ? leftMax : rightMax;

    double chartToRight(double chart) =>
        rightMin + (chart - windowMin) / (windowMax - windowMin) * (rightMax - rightMin);
    double rightToChart(double raw) =>
        windowMin + (raw - rightMin) / (rightMax - rightMin) * (windowMax - windowMin);

    List<LineChartBarData> lineBars = [];
    for (int i = 0; i < rawSpots.length; i++) {
      final sp = rawParams[i];
      final spots = sp.useRightAxis
          ? rawSpots[i].map((s) => FlSpot(s.x, rightToChart(s.y))).toList()
          : rawSpots[i];
      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: sp.color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: sp.color.withOpacity(0.05),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: LineChart(
        LineChartData(
          minY: windowMin,
          maxY: windowMax,
          minX: globalMinX,
          maxX: globalMaxX,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xDD000000),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  String timeStr = DateFormat("dd MMM HH:mm").format(dt);
                  final sp =
                      rawParams.length > spot.barIndex ? rawParams[spot.barIndex] : null;
                  String label = sp?.param.columnName ?? '';
                  double yVal = (sp?.useRightAxis ?? false)
                      ? chartToRight(spot.y)
                      : spot.y;
                  return LineTooltipItem(
                    "$label\n${yVal.toStringAsFixed(decimalPlaces)}\n$timeStr",
                    TextStyle(
                      color: sp?.color ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: hasLeft,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(decimalPlaces > 1 ? 1 : decimalPlaces),
                    style: TextStyle(fontSize: 12, color: colorPalette[0]),
                  ),
                ),
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: hasRight,
                interval: hasRight ? (windowMax - windowMin) / 4 : null,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    chartToRight(value).toStringAsFixed(decimalPlaces > 1 ? 1 : decimalPlaces),
                    style: TextStyle(fontSize: 12, color: colorPalette.length > 2 ? colorPalette[2] : Colors.grey),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (globalMaxX - globalMinX) / 4,
                getTitlesWidget: (value, meta) {
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    space: 6,
                    meta: meta,
                    child: Text(
                      DateFormat("HH:mm").format(dt),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 0.5),
            getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white10),
          ),
          lineBarsData: lineBars,
        ),
      ),
    );
  }
}

class FullscreenAnalyticsPage extends StatefulWidget {
  final List<SelectedParam> selectedParams;
  final List<DateTime> datetimes;
  final Map<String, List<List>> cachedData;
  final int decimalPlaces;
  final List<Color> colorPalette;

  const FullscreenAnalyticsPage({
    super.key,
    required this.selectedParams,
    required this.datetimes,
    required this.cachedData,
    required this.decimalPlaces,
    required this.colorPalette,
  });

  @override
  State<FullscreenAnalyticsPage> createState() => _FullscreenAnalyticsPageState();
}

class _FullscreenAnalyticsPageState extends State<FullscreenAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Analytics \u2014 Fullscreen (Landscape)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: AnalyticsChart(
                  selectedParams: widget.selectedParams,
                  datetimes: widget.datetimes,
                  cachedData: widget.cachedData,
                  decimalPlaces: widget.decimalPlaces,
                  colorPalette: widget.colorPalette,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
