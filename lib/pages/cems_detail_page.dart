import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/widgets/widgets.dart';
import 'package:msw_eplant/services/cems_threshold_service.dart';
import 'package:msw_eplant/services/notification_service.dart';

class CemsDetailPage extends StatefulWidget {
  final int unitIndex;

  const CemsDetailPage({super.key, required this.unitIndex});

  @override
  State<CemsDetailPage> createState() => _CemsDetailPageState();
}

class _CemsDetailPageState extends State<CemsDetailPage> {
  late final DatabaseReference _cemsRef;
  final DatabaseReference _table1Ref =
      FirebaseDatabase.instance.ref("excel_data/table1");
  StreamSubscription<DatabaseEvent>? _cemsSub;
  StreamSubscription<DatabaseEvent>? _table1Sub;

  List<List> _cemsData = [];
  List<List> _table1Data = [];
  List<List> _mergedData = [];
  final Set<String> _notifiedExceeds = {};

  @override
  void initState() {
    super.initState();
    NotificationService.requestNotificationPermission();
    String cemsKey = widget.unitIndex == 0 ? "cems1" : "cems2";
    _cemsRef = FirebaseDatabase.instance.ref("excel_data/$cemsKey");

    _cemsSub = _cemsRef.onValue.listen((event) => _onCemsData(event));
    _table1Sub = _table1Ref.onValue.listen((event) => _onTable1Data(event));
  }

  @override
  void dispose() {
    _cemsSub?.cancel();
    _table1Sub?.cancel();
    super.dispose();
  }

  void _onCemsData(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;
    List<List> values = _parse(event.snapshot.value);
    if (values.length > 1) {
      setState(() {
        _cemsData = values;
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
    if (_cemsData.length < 2) {
      _mergedData = [];
      return;
    }
    _mergedData = List<List>.from(_cemsData.map((e) => List.from(e)));
    if (_mergedData.isNotEmpty && !_mergedData[0].contains("DATETIME")) {
      _mergedData[0].insert(0, "DATETIME");
      var src = _table1Data.length > 1 ? _table1Data : _cemsData;
      for (int i = 1; i < _mergedData.length && i < src.length; i++) {
        _mergedData[i].insert(0, src[i][0]);
      }
    }
    _checkExceedAndNotify();
  }

  void _checkExceedAndNotify() {
    if (_mergedData.length < 2) return;
    final header = _mergedData.first.cast<String>();
    final lastRecord = _mergedData.last;
    final unitName = widget.unitIndex == 0 ? "Unit 1" : "Unit 2";

    for (int i = 1; i < header.length; i++) {
      final val = double.tryParse(lastRecord[i].toString());
      if (val == null) continue;
      final threshold = CemsThresholdService.getThreshold(header[i]);
      if (threshold == null) continue;

      final key = '${header[i]}:exceed';
      final isExceeding = !CemsThresholdService.isCompliant(header[i], val);

      if (isExceeding && !_notifiedExceeds.contains(key)) {
        _notifiedExceeds.add(key);
        NotificationService.showExceedNotification(
          unitName: unitName,
          parameter: header[i],
          value: val,
          limit: threshold.max,
        );
      } else if (!isExceeding) {
        _notifiedExceeds.remove(key);
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
            title: Text("$unitName CEMS",
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

    int compliantCount = 0;
    int exceedCount = 0;
    for (int i = 1; i < header.length; i++) {
      final val = double.tryParse(lastRecord[i].toString());
      if (val != null && CemsThresholdService.hasThreshold(header[i])) {
        if (CemsThresholdService.isCompliant(header[i], val)) {
          compliantCount++;
        } else {
          exceedCount++;
        }
      }
    }
    final totalChecked = compliantCount + exceedCount;
    final isAllCompliant = exceedCount == 0 && totalChecked > 0;

    return Container(
      decoration: _bgDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("$unitName CEMS",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (totalChecked > 0)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (isAllCompliant ? Colors.green : Colors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isAllCompliant ? Colors.green : Colors.red).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAllCompliant ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: isAllCompliant ? Colors.greenAccent : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAllCompliant ? 'All Parameters Compliant' : '$exceedCount Parameter(s) Exceed Limit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isAllCompliant ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$compliantCount / $totalChecked',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isAllCompliant ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: buildDataView(
                  context, header, lastRecord, _mergedData, widget.unitIndex, formattedDate),
            ),
          ],
        ),
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
