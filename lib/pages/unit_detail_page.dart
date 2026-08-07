import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/widgets/widgets.dart';

class UnitDetailPage extends StatefulWidget {
  final int unitIndex;

  const UnitDetailPage({super.key, required this.unitIndex});

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  late final DatabaseReference _boilerRef;
  final DatabaseReference _table1Ref =
      FirebaseDatabase.instance.ref("excel_data/table1");
  StreamSubscription<DatabaseEvent>? _boilerSub;
  StreamSubscription<DatabaseEvent>? _table1Sub;

  List<List> _boilerData = [];
  List<List> _table1Data = [];
  List<List> _mergedData = [];

  @override
  void initState() {
    super.initState();
    String tableKey = widget.unitIndex == 0 ? "table1" : "table2";
    _boilerRef = FirebaseDatabase.instance.ref("excel_data/$tableKey");

    _boilerSub = _boilerRef.onValue.listen((event) => _onBoilerData(event));
    _table1Sub = _table1Ref.onValue.listen((event) => _onTable1Data(event));
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
    if (_boilerData.length < 2) return;
    if (widget.unitIndex == 0) {
      _mergedData = List<List>.from(_boilerData.map((e) => List.from(e)));
    } else {
      _mergedData = List<List>.from(_boilerData.map((e) => List.from(e)));
      if (_mergedData.isNotEmpty && !_mergedData[0].contains("DATETIME")) {
        _mergedData[0].insert(0, "DATETIME");
        var src = _table1Data.length > 1 ? _table1Data : _boilerData;
        for (int i = 1; i < _mergedData.length && i < src.length; i++) {
          _mergedData[i].insert(0, src[i][0]);
        }
      }
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
