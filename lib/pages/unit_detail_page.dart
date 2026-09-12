import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/widgets/widgets.dart';
import 'package:msw_eplant/pages/analytics_page.dart';

class UnitDetailPage extends StatefulWidget {
  final int unitIndex;

  const UnitDetailPage({super.key, required this.unitIndex});

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  DatabaseReference? _boilerRef;
  DatabaseReference? _table1Ref;
  StreamSubscription<DatabaseEvent>? _boilerSub;
  StreamSubscription<DatabaseEvent>? _table1Sub;

  List<List> _boilerData = [];
  List<List> _table1Data = [];
  List<List> _mergedData = [];

  @override
  void initState() {
    super.initState();
    try {
      String tableKey = widget.unitIndex == 0 ? "table1" : "table2";
      _table1Ref = FirebaseDatabase.instance.ref("excel_data/table1");
      _boilerRef = FirebaseDatabase.instance.ref("excel_data/$tableKey");
      _boilerSub = _boilerRef?.onValue.listen((event) => _onBoilerData(event));
      _table1Sub = _table1Ref?.onValue.listen((event) => _onTable1Data(event));
    } catch (e) {
      debugPrint('Firebase RTDB not initialized: $e');
    }
  }

  @override
  void dispose() {
    _boilerSub?.cancel();
    _table1Sub?.cancel();
    super.dispose();
  }

  void _onBoilerData(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;
    List<List> values = _parse(event.snapshot.value);
    if (values.length > 1) {
      setState(() {
        _boilerData = values;
        _mergeData();
      });
    }
  }

  void _onTable1Data(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;
    List<List> values = _parse(event.snapshot.value);
    if (values.length > 1) {
      setState(() {
        _table1Data = values;
        _mergeData();
      });
    }
  }

  void _mergeData() {
    if (_boilerData.isNotEmpty && _table1Data.isNotEmpty) {
      List<List> merged = [];
      int minLength = _boilerData.length < _table1Data.length
          ? _boilerData.length
          : _table1Data.length;

      for (int i = 0; i < minLength; i++) {
        List row = [];
        if (_table1Data[i].isNotEmpty) {
          row.add(_table1Data[i][0]);
        }
        if (_boilerData[i].length > 1) {
          row.addAll(_boilerData[i].sublist(1));
        }
        merged.add(row);
      }

      setState(() {
        _mergedData = merged;
      });
    }
  }

  List<List> _parse(dynamic data) {
    if (data is List) return List<List>.from(data.map((e) => List.from(e)));
    if (data is Map) return List<List>.from(data.values.map((e) => List.from(e)));
    return [];
  }

  @override
  Widget build(BuildContext context) {
    String unitName = widget.unitIndex == 0 ? "Unit 1" : "Unit 2";

    if (_mergedData.length < 2) {
      return Container(
        decoration: _bgDecoration(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text("$unitName Boiler",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.insights_outlined, color: Colors.cyanAccent),
                tooltip: 'Analytics',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
        ),
      );
    }

    final header = _mergedData.first.cast<String>();
    final lastRecord = _mergedData.last;

    String formattedDate = "N/A";
    if (_table1Data.length > 1) {
      formattedDate = formatDateTime(_table1Data.last[0].toString());
    }

    return Container(
      decoration: _bgDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("$unitName Boiler",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.insights_outlined, color: Colors.cyanAccent),
              tooltip: 'Analytics',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsPage()),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: buildDataView(
            context, header, lastRecord, _mergedData, widget.unitIndex, formattedDate),
      ),
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
