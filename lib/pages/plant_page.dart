import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/pages/unit_detail_page.dart';
import 'package:msw_eplant/pages/cems_detail_page.dart';

class PlantPage extends StatefulWidget {
  const PlantPage({super.key});

  @override
  State<PlantPage> createState() => _PlantPageState();
}

class _PlantPageState extends State<PlantPage> {
  final DatabaseReference _table1Ref =
      FirebaseDatabase.instance.ref("excel_data/table1");
  final DatabaseReference _table2Ref =
      FirebaseDatabase.instance.ref("excel_data/table2");
  List<List> _table1Data = [];
  List<List> _table2Data = [];
  StreamSubscription<DatabaseEvent>? _sub1;
  StreamSubscription<DatabaseEvent>? _sub2;

  List<String> get _t1Header =>
      _table1Data.isNotEmpty ? _table1Data.first.cast<String>() : [];
  List<String> get _t2Header =>
      _table2Data.isNotEmpty ? _table2Data.first.cast<String>() : [];
  List get _t1Last => _table1Data.length > 1 ? _table1Data.last : [];
  List get _t2Last => _table2Data.length > 1 ? _table2Data.last : [];

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    _sub1 = _table1Ref.onValue.listen((e) => _updateData(e, (v) => _table1Data = v));
    _sub2 = _table2Ref.onValue.listen((e) => _updateData(e, (v) => _table2Data = v));
  }

  void _updateData(event, Function(List<List>) setter) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;
    List<List> values = _parseToList(event.snapshot.value);
    if (values.length > 1) {
      setState(() => setter(values));
    }
  }

  List<List> _parseToList(dynamic data) {
    if (data is List) return List<List>.from(data.map((e) => List.from(e)));
    if (data is Map) return List<List>.from(data.values.map((e) => List.from(e)));
    return [];
  }

  double _getLoad(List record, List<String> header, String label) {
    int idx = header.indexOf(label);
    if (idx != -1 && idx < record.length) {
      return double.tryParse(record[idx].toString()) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(
            "Plant Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("BOILER UNITS"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildUnitCard(
                      title: "Unit 1",
                      load: _getLoad(_t1Last, _t1Header, "UNIT 1 LOAD"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UnitDetailPage(unitIndex: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUnitCard(
                      title: "Unit 2",
                      load: _getLoad(_t2Last, _t2Header, "UNIT 2 LOAD"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UnitDetailPage(unitIndex: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("EMISSION MONITORING"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCemsCard(
                      title: "CEMS Unit 1",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CemsDetailPage(unitIndex: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCemsCard(
                      title: "CEMS Unit 2",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CemsDetailPage(unitIndex: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Color _statusColor(double load) {
    if (load <= 0) return Colors.redAccent;
    if (load >= 0 && load < 4) return Colors.blueAccent;
    if (load < 12) return Colors.amber;
    return Colors.greenAccent;
  }

  String _statusLabel(double load) {
    if (load <= 0) return "Shutdown";
    if (load >= 0 && load < 4) return "House Load";
    if (load < 12) return "Low Load";
    return "Normal";
  }

  Widget _buildUnitCard({
    required String title,
    required double load,
    required VoidCallback onTap,
  }) {
    Color sc = _statusColor(load);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: sc, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  load.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: sc == Colors.amber ? Colors.amber : Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "MW",
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  sc == Colors.redAccent
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  size: 14,
                  color: sc,
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel(load),
                  style: TextStyle(fontSize: 14, color: sc, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCemsCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Icon(Icons.air, size: 32, color: Colors.cyanAccent),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 4),
                const Text(
                  "Compliant",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
