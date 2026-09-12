import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/plant_overview_models.dart';
import 'package:msw_eplant/pages/analytics_page.dart';
import 'package:msw_eplant/pages/cems_detail_page.dart';
import 'package:msw_eplant/pages/chart_page.dart';
import 'package:msw_eplant/pages/nphr_page.dart';
import 'package:msw_eplant/pages/unit_detail_page.dart';
import 'package:msw_eplant/services/dashboard_share_service.dart';
import 'package:msw_eplant/widgets/plant_energy_flow_widget.dart';

class PlantOverviewDetailPage extends StatefulWidget {
  const PlantOverviewDetailPage({super.key});

  @override
  State<PlantOverviewDetailPage> createState() => _PlantOverviewDetailPageState();
}

class _PlantOverviewDetailPageState extends State<PlantOverviewDetailPage> {
  DatabaseReference? _overviewRef;
  DatabaseReference? _table1Ref;
  DatabaseReference? _table2Ref;
  DatabaseReference? _cems1Ref;
  DatabaseReference? _cems2Ref;
  DatabaseReference? _nphrRef;

  StreamSubscription<DatabaseEvent>? _overviewSub;
  StreamSubscription<DatabaseEvent>? _t1Sub;
  StreamSubscription<DatabaseEvent>? _t2Sub;
  StreamSubscription<DatabaseEvent>? _c1Sub;
  StreamSubscription<DatabaseEvent>? _c2Sub;
  StreamSubscription<DatabaseEvent>? _nphrSub;

  List<List> _overviewData = [];
  List<List> _table1Data = [];
  List<List> _table2Data = [];
  List<List> _cems1Data = [];
  List<List> _cems2Data = [];
  List<List> _nphrData = [];

  bool _isLoading = true;
  String? _errorMessage;
  int _selectedChartTab = 0; // 0: Load & HL, 1: PLN vs AI, 2: Boiler Eff, 3: NPHR
  final GlobalKey _plantDashboardKey = GlobalKey();
  bool _isSharing = false;

  void _openMetricChart({
    required String title,
    required List<String> candidateColumns,
    required String unit,
    double? thresholdValue,
    List<List>? preferredSource,
  }) {
    List<List> source = [];
    int colIdx = -1;
    List<String> header = [];

    final sourcesToCheck = [
      if (preferredSource != null && preferredSource.length > 1) preferredSource,
      if (_overviewData.length > 1) _overviewData,
      if (_table1Data.length > 1) _table1Data,
      if (_table2Data.length > 1) _table2Data,
      if (_nphrData.length > 1) _nphrData,
      if (_cems1Data.length > 1) _cems1Data,
      if (_cems2Data.length > 1) _cems2Data,
    ];

    for (final s in sourcesToCheck) {
      final h = s.first.map((e) => e.toString().trim()).toList();
      for (final candidate in candidateColumns) {
        final norm = candidate.trim().toUpperCase();
        int idx = h.indexWhere((col) => col.trim().toUpperCase() == norm);
        if (idx == -1) {
          idx = h.indexWhere((col) => col.trim().toUpperCase().contains(norm));
        }
        if (idx != -1) {
          source = s;
          colIdx = idx;
          header = h;
          break;
        }
      }
      if (colIdx != -1) break;
    }

    // Special fallback for NPHR if candidate column wasn't found by exact name
    if (colIdx == -1 && title.toUpperCase().contains('NPHR') && _nphrData.length > 1) {
      source = _nphrData;
      header = _nphrData.first.map((e) => e.toString().trim()).toList();
      bool firstColIsDate = false;
      if (_nphrData.length > 1 && _nphrData[1].isNotEmpty) {
        final s0 = _nphrData[1][0].toString().trim();
        firstColIsDate = DateTime.tryParse(s0) != null || DateTime.tryParse(s0.replaceAll(' ', 'T')) != null;
      }
      final bool isU2 = title.contains('2') || title.toUpperCase().contains('U2');
      if (firstColIsDate) {
        colIdx = isU2 ? (header.length > 2 ? 2 : 1) : 1;
      } else {
        colIdx = isU2 ? (header.length > 1 ? 1 : 0) : 0;
      }
    }

    if (colIdx == -1 || source.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No historical telemetry available for $title'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    // Ensure source has a valid DateTime column, or synthesize it if needed
    int dtIdx = header.indexWhere((h) => h.trim().toUpperCase() == "DATETIME");
    List<dynamic> chartData;
    List<String> chartHeader;
    int chartColIdx = colIdx;

    if (dtIdx == -1) {
      bool col0IsDate = false;
      if (source.length > 1) {
        final val0 = source[1][0].toString();
        if (DateTime.tryParse(val0) != null || DateTime.tryParse(val0.replaceAll(' ', 'T')) != null) {
          col0IsDate = true;
        }
      }

      if (!col0IsDate) {
        chartHeader = ['DATETIME', header[colIdx]];
        chartColIdx = 1;
        chartData = [chartHeader];
        for (int i = 1; i < source.length; i++) {
          final row = source[i];
          String dtStr = '';
          if (i < _table1Data.length && _table1Data[i].isNotEmpty) {
            dtStr = _table1Data[i][0].toString();
          } else {
            dtStr = DateTime.now()
                .subtract(Duration(minutes: (source.length - i) * 5))
                .toIso8601String();
          }
          final val = colIdx < row.length ? row[colIdx] : null;
          chartData.add([dtStr, val]);
        }
      } else {
        chartData = source;
        chartHeader = header;
      }
    } else {
      chartData = source;
      chartHeader = header;
    }

    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartPage(
          columnName: title,
          columnIndex: chartColIdx,
          header: chartHeader,
          fullData: chartData,
          unit: unit,
          date: dateStr,
          thresholdValue: thresholdValue,
        ),
      ),
    );
  }

  void _openTotalGenerationChart() {
    int ovIdx = -1;
    if (_overviewData.length > 1) {
      final h = _overviewData.first.map((e) => e.toString().trim().toUpperCase()).toList();
      ovIdx = h.indexOf("TOTAL LOAD");
      if (ovIdx == -1) ovIdx = h.indexOf("TOTAL GENERATION");
      if (ovIdx == -1) ovIdx = h.indexWhere((col) => col.contains("TOTAL LOAD"));
    }

    if (ovIdx != -1) {
      _openMetricChart(
        title: 'TOTAL GROSS GENERATION',
        candidateColumns: ['TOTAL LOAD', 'TOTAL GENERATION'],
        unit: 'MW',
        preferredSource: _overviewData,
      );
      return;
    }

    if (_table1Data.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No telemetry available for Total Generation'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    final t1H = _table1Data.first.map((e) => e.toString().trim().toUpperCase()).toList();
    final t2H = _table2Data.isNotEmpty
        ? _table2Data.first.map((e) => e.toString().trim().toUpperCase()).toList()
        : <String>[];

    final u1Idx = t1H.indexOf("UNIT 1 LOAD");
    int u2Idx = t2H.indexOf("UNIT 2 LOAD");
    if (u2Idx == -1) u2Idx = t2H.indexWhere((h) => h.contains("LOAD"));

    List<dynamic> fullData = [
      ['DATETIME', 'TOTAL GENERATION']
    ];
    for (int i = 1; i < _table1Data.length; i++) {
      final dtStr = _table1Data[i][0].toString();
      final u1 = (u1Idx != -1 && u1Idx < _table1Data[i].length)
          ? (double.tryParse(_table1Data[i][u1Idx].toString()) ?? 0.0)
          : 0.0;
      final u2 = (i < _table2Data.length && u2Idx != -1 && u2Idx < _table2Data[i].length)
          ? (double.tryParse(_table2Data[i][u2Idx].toString()) ?? 0.0)
          : 0.0;
      fullData.add([dtStr, u1 + u2]);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartPage(
          columnName: 'TOTAL GROSS GENERATION',
          columnIndex: 1,
          header: ['DATETIME', 'TOTAL GENERATION'],
          fullData: fullData,
          unit: 'MW',
          date: DateFormat('dd MMM yyyy').format(DateTime.now()),
        ),
      ),
    );
  }

  void _openNodeChartFromFlow(String nodeTitle, String columnName, String unit) {
    if (columnName == 'TOTAL LOAD') {
      _openTotalGenerationChart();
    } else {
      _openMetricChart(
        title: nodeTitle,
        candidateColumns: [columnName],
        unit: unit,
      );
    }
  }

  Future<void> _shareDashboard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await DashboardShareService.captureAndShare(
        key: _plantDashboardKey,
        title: 'PLTU MSW Tanjung - Plant Overview Dashboard',
        fileNamePrefix: 'pltu_msw_overview_dashboard',
        context: context,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _openSelectedTrendTabChart() {
    switch (_selectedChartTab) {
      case 0:
        _openTotalGenerationChart();
        break;
      case 1:
        _openMetricChart(
          title: 'PLN Export',
          candidateColumns: ['LOAD TO PLN', 'PLN LOAD', 'PLN'],
          unit: 'MW',
        );
        break;
      case 2:
        _openMetricChart(
          title: 'Unit 1 Boiler Efficiency',
          candidateColumns: ['UNIT 1 BOILER EFFICIENCY', 'BOILER EFFICIENCY 1', 'BOILER EFFICIENCY'],
          unit: '%',
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NphrPage()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  @override
  void dispose() {
    _overviewSub?.cancel();
    _t1Sub?.cancel();
    _t2Sub?.cancel();
    _c1Sub?.cancel();
    _c2Sub?.cancel();
    _nphrSub?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    try {
      final rtdb = FirebaseDatabase.instance;
      _overviewRef = rtdb.ref("excel_data/overview");
      _table1Ref = rtdb.ref("excel_data/table1");
      _table2Ref = rtdb.ref("excel_data/table2");
      _cems1Ref = rtdb.ref("excel_data/cems1");
      _cems2Ref = rtdb.ref("excel_data/cems2");
      _nphrRef = rtdb.ref("excel_data/nphr");

      _overviewSub = _overviewRef?.onValue.listen(
        (e) => _onData(e, (v) => _overviewData = v),
        onError: (err) => _handleStreamError('Overview: $err'),
      );
      _t1Sub = _table1Ref?.onValue.listen(
        (e) => _onData(e, (v) => _table1Data = v),
        onError: (err) => _handleStreamError('Unit 1: $err'),
      );
      _t2Sub = _table2Ref?.onValue.listen(
        (e) => _onData(e, (v) => _table2Data = v),
        onError: (err) => _handleStreamError('Unit 2: $err'),
      );
      _c1Sub = _cems1Ref?.onValue.listen(
        (e) => _onData(e, (v) => _cems1Data = v),
        onError: (err) => _handleStreamError('CEMS 1: $err'),
      );
      _c2Sub = _cems2Ref?.onValue.listen(
        (e) => _onData(e, (v) => _cems2Data = v),
        onError: (err) => _handleStreamError('CEMS 2: $err'),
      );
      _nphrSub = _nphrRef?.onValue.listen(
        (e) => _onData(e, (v) => _nphrData = v),
        onError: (err) => _handleStreamError('NPHR: $err'),
      );
    } catch (e) {
      debugPrint("Firebase stream setup skipped/mock mode: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onData(DatabaseEvent event, Function(List<List>) setter) {
    if (!mounted) return;
    if (event.snapshot.value == null) {
      setState(() => _isLoading = false);
      return;
    }
    final parsed = _parseToList(event.snapshot.value);
    if (parsed.length > 1) {
      setState(() {
        setter(parsed);
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _handleStreamError(String msg) {
    if (!mounted) return;
    debugPrint('Firebase Stream Error: $msg');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Failed to load some telemetry data: $msg';
    });
  }

  List<List> _parseToList(dynamic data) {
    if (data is List) return List<List>.from(data.map((e) => List.from(e)));
    if (data is Map) return List<List>.from(data.values.map((e) => List.from(e)));
    return [];
  }

  PlantOverviewSnapshot _buildSnapshot() {
    return PlantOverviewSnapshot.fromFirebase(
      overviewData: _overviewData,
      table1Data: _table1Data,
      table2Data: _table2Data,
      cems1Data: _cems1Data,
      cems2Data: _cems2Data,
      nphrData: _nphrData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _buildSnapshot();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.82),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(snapshot),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (mounted) setState(() => _isLoading = false);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 32),
              child: RepaintBoundary(
                key: _plantDashboardKey,
                child: Container(
                  color: AppColors.bg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isLoading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.primary,
                          backgroundColor: Colors.transparent,
                        ),
                      // Error Banner if stream encountered errors
                      if (_errorMessage != null) _buildErrorBanner(),

                      const SizedBox(height: 6),

                      // 1. HERO LOAD BALANCE CARD
                      _buildHeroLoadBalanceCard(snapshot),

                      // 2. ANIMATED PLANT ENERGY FLOW WIDGET
                      PlantEnergyFlowWidget(
                        snapshot: snapshot,
                        onOpenNodeChart: _openNodeChartFromFlow,
                      ),

                      // 3. UNIT 1 & UNIT 2 PERFORMANCE & CAPABILITY MATRIX
                      _buildUnitPerformanceSection(snapshot),

                      // 4. CEMS 4 PARAMETER UTAMA ENVIRONMENTAL STRIP
                      _buildCemsComplianceSection(snapshot),

                      // 5. INTERACTIVE TREND CHART (fl_chart)
                      _buildTrendChartSection(snapshot),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- APP BAR ---

  PreferredSizeWidget _buildAppBar(PlantOverviewSnapshot snapshot) {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.text),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'PLTU MSW TANJUNG',
              style: TextStyle(
                fontSize: AppTheme.fs15,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: 0.6,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              snapshot.formattedTimestamp.isNotEmpty
                  ? 'Coal-Fired Power Plant · 2 × 30 MW · ${snapshot.formattedTimestamp}'
                  : 'Coal-Fired Power Plant · 2 × 30 MW',
              style: const TextStyle(
                fontSize: AppTheme.fs11,
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // Share Dashboard Image Action
        IconButton(
          tooltip: 'Share Dashboard Image',
          icon: _isSharing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.share_outlined, color: AppColors.text, size: 21),
          onPressed: _isSharing ? null : _shareDashboard,
        ),
        // Analytics Shortcut Button
        IconButton(
          tooltip: 'Open Analytics & History',
          icon: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 22),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsPage()),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // --- ERROR BANNER ---

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.text),
            onPressed: () => setState(() => _setupStreams()),
          ),
        ],
      ),
    );
  }

  // --- 1. HERO LOAD BALANCE CARD ---

  Widget _buildHeroLoadBalanceCard(PlantOverviewSnapshot snapshot) {
    final double? totalLoad = snapshot.totalLoad;
    final double? pln = snapshot.loadToPln;
    final double? ai = snapshot.loadToAi;
    final double? hl = snapshot.totalHouseLoad;
    final double? hlPct = snapshot.houseLoadPct;

    final String dateStr = snapshot.timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(snapshot.timestamp!.toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            const Color(0xFF0F1E36).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _openTotalGenerationChart,
                borderRadius: BorderRadius.circular(4),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TOTAL GROSS GENERATION',
                        style: TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSub,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: snapshot.isLive
                          ? AppColors.general
                          : (snapshot.hasData ? AppColors.maintenance : AppColors.danger),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    snapshot.formattedTimestamp.isNotEmpty
                        ? snapshot.formattedTimestamp
                        : (snapshot.hasData ? 'Offline' : 'Awaiting Telemetry...'),
                    style: const TextStyle(
                      fontSize: AppTheme.fs11,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Large Total Gross Display
          InkWell(
            onTap: _openTotalGenerationChart,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      PlantOverviewSnapshot.formatVal(totalLoad, decimals: 1),
                      style: const TextStyle(
                        fontSize: AppTheme.fs34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MW',
                      style: TextStyle(
                        fontSize: AppTheme.fs18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Installed Capacity Comparison
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        totalLoad != null
                            ? '${(totalLoad / 60.0 * 100).clamp(0.0, 120.0).toStringAsFixed(1)}% Capacity'
                            : '-',
                        style: const TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Proportional Power Distribution Stack Bar
          _buildDistributionBar(totalLoad, pln, ai, hl),

          const SizedBox(height: 14),

          // 3 Metric Cells: Export PLN, Export AI, House Load
          Row(
            children: [
              Expanded(
                child: _buildBalanceMetricCell(
                  title: 'PLN EXPORT',
                  val: pln,
                  unit: 'MW',
                  color: const Color(0xFF00C2FF),
                  icon: Icons.electric_bolt_rounded,
                  onTap: () => _openMetricChart(
                    title: 'PLN Export',
                    candidateColumns: ['LOAD TO PLN', 'PLN LOAD', 'PLN'],
                    unit: 'MW',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBalanceMetricCell(
                  title: 'AI EXPORT',
                  val: ai,
                  unit: 'MW',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.precision_manufacturing_rounded,
                  onTap: () => _openMetricChart(
                    title: 'AI Export',
                    candidateColumns: ['LOAD TO AI', 'AI LOAD', 'AI'],
                    unit: 'MW',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBalanceMetricCell(
                  title: 'HOUSE LOAD',
                  val: hl,
                  unit: 'MW',
                  subtitle: hlPct != null ? '${hlPct.toStringAsFixed(1)}%' : null,
                  color: const Color(0xFF10B981),
                  icon: Icons.home_repair_service_rounded,
                  onTap: () => _openMetricChart(
                    title: 'House Load',
                    candidateColumns: ['TOTAL HOUSE LOAD', 'HOUSE LOAD'],
                    unit: 'MW',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(double? total, double? pln, double? ai, double? hl) {
    if (total == null || total <= 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final double p = ((pln ?? 0) / total).clamp(0.0, 1.0);
    final double a = ((ai ?? 0) / total).clamp(0.0, 1.0);
    final double h = ((hl ?? 0) / total).clamp(0.0, 1.0);

    final int flexP = (p * 1000).toInt();
    final int flexA = (a * 1000).toInt();
    final int flexH = (h * 1000).toInt();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              if (flexP > 0)
                Expanded(
                  flex: flexP,
                  child: Container(height: 6, color: const Color(0xFF00C2FF)),
                ),
              if (flexA > 0)
                Expanded(
                  flex: flexA,
                  child: Container(height: 6, color: const Color(0xFFF59E0B)),
                ),
              if (flexH > 0)
                Expanded(
                  flex: flexH,
                  child: Container(height: 6, color: const Color(0xFF10B981)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendDot(const Color(0xFF00C2FF), 'PLN ${(p * 100).toStringAsFixed(0)}%'),
            _legendDot(const Color(0xFFF59E0B), 'AI ${(a * 100).toStringAsFixed(0)}%'),
            _legendDot(const Color(0xFF10B981), 'House Load ${(h * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: AppColors.textDim),
        ),
      ],
    );
  }

  Widget _buildBalanceMetricCell({
    required String title,
    required double? val,
    required String unit,
    String? subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSub,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.show_chart_rounded, size: 11, color: color.withValues(alpha: 0.7)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    PlantOverviewSnapshot.formatVal(val, decimals: 1),
                    style: const TextStyle(
                      fontSize: AppTheme.fs18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildUnitOperatingCard(UnitOverviewData unit, int unitIndex) {
    final cond = unit.condition;
    final color = cond.color;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UnitDetailPage(unitIndex: unitIndex)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.55),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Unit Name & Live Pulse
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unit.unitName,
                  style: const TextStyle(
                    fontSize: AppTheme.fs14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: 0.4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cond.shortLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Gross MW with chart tap
            InkWell(
              onTap: () => _openMetricChart(
                title: 'Unit ${unitIndex + 1} Gross Load',
                candidateColumns: ['UNIT ${unitIndex + 1} LOAD', 'UNIT${unitIndex + 1} LOAD', 'LOAD'],
                unit: 'MW',
                preferredSource: unitIndex == 0 ? _table1Data : _table2Data,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    PlantOverviewSnapshot.formatVal(unit.grossLoad, decimals: 1),
                    style: const TextStyle(
                      fontSize: AppTheme.fs22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'MW',
                    style: TextStyle(
                      fontSize: AppTheme.fs12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.show_chart_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // TMGCR Loading Bar
            if (unit.tmgcr != null && unit.tmgcr! > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ((unit.grossLoad ?? 0) / unit.tmgcr!).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loading: ${PlantOverviewSnapshot.formatVal(unit.loadingRatio, decimals: 1, suffix: '%')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                  ),
                  Text(
                    'TMGCR: ${PlantOverviewSnapshot.formatVal(unit.tmgcr, decimals: 0)}MW',
                    style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                  ),
                ],
              ),
            ] else ...[
              Text(
                cond.label,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOperatingCriteriaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Unit Operating Status Criteria', style: TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _criteriaItem(AppColors.general, 'Normal Running', 'Gross Load >= 12 MW'),
            const SizedBox(height: 8),
            _criteriaItem(AppColors.maintenance, 'Low Load Operation', 'Gross Load 4 - 12 MW'),
            const SizedBox(height: 8),
            _criteriaItem(AppColors.primary, 'House Load Island', 'Gross Load 0 - 4 MW'),
            const SizedBox(height: 8),
            _criteriaItem(AppColors.danger, 'Shutdown / Standby', 'Gross Load <= 0 MW (Unit Off)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _criteriaItem(Color color, String label, String desc) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: AppTheme.fs13, fontWeight: FontWeight.bold, color: color)),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. UNIT 1 & UNIT 2 PERFORMANCE & CAPABILITY MATRIX ---

  Widget _buildUnitPerformanceSection(PlantOverviewSnapshot snapshot) {
    final u1 = snapshot.unit1;
    final u2 = snapshot.unit2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UNIT CAPABILITY & PERFORMANCE',
                style: TextStyle(
                  fontSize: AppTheme.fs12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSub,
                  letterSpacing: 0.6,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textDim),
                onPressed: () => _showMetricHelpDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Header: Parameter, Unit 1, Unit 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('PARAMETER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDim)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('UNIT 1', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('UNIT 2', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 1. TMGCR
          _buildPerformanceRow(
            label: 'TMGCR (Turbine Rating)',
            u1Val: PlantOverviewSnapshot.formatVal(u1.tmgcr, suffix: ' MW'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.tmgcr, suffix: ' MW'),
            onU1Tap: () => _openMetricChart(
              title: 'Unit 1 TMGCR',
              candidateColumns: ['UNIT 1 TMGCR', 'TMGCR 1', 'TMGCR'],
              unit: 'MW',
            ),
            onU2Tap: () => _openMetricChart(
              title: 'Unit 2 TMGCR',
              candidateColumns: ['UNIT 2 TMGCR', 'TMGCR 2'],
              unit: 'MW',
            ),
          ),

          // 2. BMCR
          _buildPerformanceRow(
            label: 'BMCR (Boiler Rating)',
            u1Val: PlantOverviewSnapshot.formatVal(u1.bmcr, suffix: ' T/h'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.bmcr, suffix: ' T/h'),
            onU1Tap: () => _openMetricChart(
              title: 'Unit 1 BMCR',
              candidateColumns: ['UNIT 1 BMCR', 'BMCR 1', 'BMCR'],
              unit: 'T/h',
            ),
            onU2Tap: () => _openMetricChart(
              title: 'Unit 2 BMCR',
              candidateColumns: ['UNIT 2 BMCR', 'BMCR 2'],
              unit: 'T/h',
            ),
          ),

          // 3. Boiler Efficiency
          _buildPerformanceRow(
            label: 'Boiler Efficiency',
            u1Val: PlantOverviewSnapshot.formatVal(u1.boilerEfficiency, suffix: '%'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.boilerEfficiency, suffix: '%'),
            highlight: true,
            onU1Tap: () => _openMetricChart(
              title: 'Unit 1 Boiler Efficiency',
              candidateColumns: ['UNIT 1 BOILER EFFICIENCY', 'BOILER EFFICIENCY 1', 'BOILER EFFICIENCY'],
              unit: '%',
            ),
            onU2Tap: () => _openMetricChart(
              title: 'Unit 2 Boiler Efficiency',
              candidateColumns: ['UNIT 2 BOILER EFFICIENCY', 'BOILER EFFICIENCY 2'],
              unit: '%',
            ),
          ),

          // 4. EAF (Equivalent Availability Factor)
          _buildPerformanceRow(
            label: 'EAF (Availability Factor)',
            u1Val: PlantOverviewSnapshot.formatVal(u1.eaf, suffix: '%'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.eaf, suffix: '%'),
            onU1Tap: () => _openMetricChart(
              title: 'Unit 1 EAF',
              candidateColumns: ['UNIT 1 EAF', 'EAF 1', 'EAF'],
              unit: '%',
            ),
            onU2Tap: () => _openMetricChart(
              title: 'Unit 2 EAF',
              candidateColumns: ['UNIT 2 EAF', 'EAF 2'],
              unit: '%',
            ),
          ),

          // 5. Capacity Factor
          _buildPerformanceRow(
            label: 'Capacity Factor (CF)',
            u1Val: PlantOverviewSnapshot.formatVal(u1.capacityFactor, suffix: '%'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.capacityFactor, suffix: '%'),
            onU1Tap: () => _openMetricChart(
              title: 'Unit 1 Capacity Factor',
              candidateColumns: ['UNIT 1 CAPACITY FACTOR', 'CAPACITY FACTOR 1', 'CF 1', 'CAPACITY FACTOR'],
              unit: '%',
            ),
            onU2Tap: () => _openMetricChart(
              title: 'Unit 2 Capacity Factor',
              candidateColumns: ['UNIT 2 CAPACITY FACTOR', 'CAPACITY FACTOR 2', 'CF 2'],
              unit: '%',
            ),
          ),

          // 6. NPHR (Heat Rate) - Tapping navigates directly to NphrPage (Curve)
          _buildPerformanceRow(
            label: 'NPHR Heat Rate',
            u1Val: PlantOverviewSnapshot.formatVal(u1.nphr, decimals: 0, suffix: ' kCal'),
            u2Val: PlantOverviewSnapshot.formatVal(u2.nphr, decimals: 0, suffix: ' kCal'),
            isLast: true,
            onU1Tap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NphrPage()),
            ),
            onU2Tap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NphrPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow({
    required String label,
    required String u1Val,
    required String u2Val,
    bool highlight = false,
    bool isLast = false,
    VoidCallback? onU1Tap,
    VoidCallback? onU2Tap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        color: highlight ? AppColors.primary.withValues(alpha: 0.05) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fs12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.text : AppColors.textSub,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onU1Tap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        u1Val,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTheme.fs13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (onU1Tap != null) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.show_chart_rounded, size: 10, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onU2Tap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        u2Val,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTheme.fs13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (onU2Tap != null) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.show_chart_rounded, size: 10, color: Color(0xFF38BDF8)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMetricHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Unit Parameter Descriptions', style: TextStyle(color: AppColors.text)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricHelpItem('TMGCR', 'Turbine Maximum Continuous Rating — Maximum continuous power output capability of the turbine.'),
              const SizedBox(height: 8),
              _metricHelpItem('BMCR', 'Boiler Maximum Continuous Rating — Maximum continuous steam generation capacity of the boiler.'),
              const SizedBox(height: 8),
              _metricHelpItem('Boiler Efficiency', 'Thermal efficiency of the boiler converting coal thermal energy into high-pressure steam.'),
              const SizedBox(height: 8),
              _metricHelpItem('EAF', 'Equivalent Availability Factor — Availability and readiness of the unit to generate power without derating.'),
              const SizedBox(height: 8),
              _metricHelpItem('Capacity Factor', 'Ratio of actual electrical energy generated over a period to theoretical installed capacity.'),
              const SizedBox(height: 8),
              _metricHelpItem('NPHR', 'Net Plant Heat Rate — Coal thermal energy input (kCal) required to produce 1 kWh of net electrical energy.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _metricHelpItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: AppTheme.fs13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.3)),
      ],
    );
  }

  // --- 5. CEMS 4 PARAMETER UTAMA ENVIRONMENTAL STRIP ---

  Widget _buildCemsComplianceSection(PlantOverviewSnapshot snapshot) {
    final cemsList = snapshot.cemsParams;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.eco_rounded, size: 16, color: Color(0xFF00E5A0)),
                  SizedBox(width: 6),
                  Text(
                    'CEMS 4 KEY PARAMETERS',
                    style: TextStyle(
                      fontSize: AppTheme.fs12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              // Link to CemsDetailPage
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CemsDetailPage(unitIndex: 0)),
                ),
                child: const Row(
                  children: [
                    Text(
                      'CEMS Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Coal-Fired Power Plant Emission Standards (Permen LHK No. P.15/2019)',
            style: TextStyle(fontSize: 10, color: AppColors.textDim),
          ),
          const SizedBox(height: 10),

          // 4 Parameter Grid
          Column(
            children: cemsList.map((param) => _buildCemsParamRow(param)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCemsParamRow(CemsParamItem param) {
    final bool hasThresh = param.threshold != null;
    final bool u1Ok = param.isUnit1Compliant ?? true;
    final bool u2Ok = param.isUnit2Compliant ?? true;
    final int cemsDecimals = (hasThresh && param.threshold! < 1) ? 3 : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // Param Name & Limit
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  param.displayName,
                  style: const TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  hasThresh
                      ? 'Standard: ${param.threshold! < 1 ? param.threshold!.toString() : param.threshold!.toStringAsFixed(0)} ${param.unit}'
                      : 'Monitored Indicator',
                  style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),

          // Unit 1 Value & Compliance (Tappable to open Chart)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _openMetricChart(
                title: 'Unit 1 ${param.displayName}',
                candidateColumns: [
                  param.paramKey,
                  '${param.paramKey} COR',
                  '${param.paramKey}_COR',
                  '${param.paramKey} CORRECTION',
                  if (param.paramKey == 'HG') ...['HG', 'HG CORRECTION', 'HG_COR', 'MERCURY'],
                ],
                unit: param.unit,
                thresholdValue: param.threshold,
                preferredSource: _cems1Data,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlantOverviewSnapshot.formatVal(param.unit1Value, decimals: cemsDecimals),
                          style: const TextStyle(
                            fontSize: AppTheme.fs13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (hasThresh && param.unit1Value != null)
                          Icon(
                            u1Ok ? Icons.check_circle_rounded : Icons.warning_rounded,
                            size: 12,
                            color: u1Ok ? AppColors.general : AppColors.danger,
                          )
                        else
                          const Icon(Icons.show_chart_rounded, size: 11, color: AppColors.primary),
                      ],
                    ),
                    const Text('Unit 1 (Trend)', style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Unit 2 Value & Compliance (Tappable to open Chart)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _openMetricChart(
                title: 'Unit 2 ${param.displayName}',
                candidateColumns: [
                  param.paramKey,
                  '${param.paramKey} COR',
                  '${param.paramKey}_COR',
                  '${param.paramKey} CORRECTION',
                  if (param.paramKey == 'HG') ...['HG', 'HG CORRECTION', 'HG_COR', 'MERCURY'],
                ],
                unit: param.unit,
                thresholdValue: param.threshold,
                preferredSource: _cems2Data,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlantOverviewSnapshot.formatVal(param.unit2Value, decimals: cemsDecimals),
                          style: const TextStyle(
                            fontSize: AppTheme.fs13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (hasThresh && param.unit2Value != null)
                          Icon(
                            u2Ok ? Icons.check_circle_rounded : Icons.warning_rounded,
                            size: 12,
                            color: u2Ok ? AppColors.general : AppColors.danger,
                          )
                        else
                          const Icon(Icons.show_chart_rounded, size: 11, color: Color(0xFF38BDF8)),
                      ],
                    ),
                    const Text('Unit 2 (Trend)', style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. INTERACTIVE TREND CHART (fl_chart) ---

  Widget _buildTrendChartSection(PlantOverviewSnapshot snapshot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HISTORICAL TELEMETRY TRENDS',
                style: TextStyle(
                  fontSize: AppTheme.fs12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSub,
                  letterSpacing: 0.6,
                ),
              ),
              InkWell(
                onTap: _openSelectedTrendTabChart,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Full Chart',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Parameter Switcher Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chartChip(0, 'Load & House Load'),
                const SizedBox(width: 6),
                _chartChip(1, 'PLN vs AI Export'),
                const SizedBox(width: 6),
                _chartChip(2, 'Boiler Efficiency'),
                const SizedBox(width: 6),
                _chartChip(3, 'NPHR Heat Rate'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Chart Display
          SizedBox(
            height: 190,
            child: _buildDynamicLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _chartChip(int index, String label) {
    final isSelected = _selectedChartTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fs11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicLineChart() {
    // Determine data source and columns based on selected chip
    List<FlSpot> series1 = [];
    List<FlSpot> series2 = [];
    String s1Label = '';
    String s2Label = '';
    Color s1Color = AppColors.primary;
    Color s2Color = const Color(0xFF10B981);
    String unit = 'MW';

    switch (_selectedChartTab) {
      case 0: // Total Load & House Load
        s1Label = 'Total Load';
        s2Label = 'House Load';
        s1Color = AppColors.primary;
        s2Color = const Color(0xFF10B981);
        unit = 'MW';
        _extractSeriesFromTable(
          col1Names: ['TOTAL LOAD', 'TOTAL GENERATION', 'UNIT 1 LOAD'],
          col2Names: ['TOTAL HOUSE LOAD', 'HOUSE LOAD'],
          out1: series1,
          out2: series2,
        );
        break;
      case 1: // PLN vs AI Export
        s1Label = 'PLN Export';
        s2Label = 'AI Export';
        s1Color = const Color(0xFF00C2FF);
        s2Color = const Color(0xFFF59E0B);
        unit = 'MW';
        _extractSeriesFromTable(
          col1Names: ['LOAD TO PLN', 'PLN LOAD', 'PLN'],
          col2Names: ['LOAD TO AI', 'AI LOAD', 'AI'],
          out1: series1,
          out2: series2,
        );
        break;
      case 2: // Boiler Efficiency
        s1Label = 'Eff Unit 1';
        s2Label = 'Eff Unit 2';
        s1Color = AppColors.general;
        s2Color = const Color(0xFF38BDF8);
        unit = '%';
        _extractSeriesFromTable(
          col1Names: ['UNIT 1 BOILER EFFICIENCY', 'BOILER EFFICIENCY 1', 'BOILER EFFICIENCY'],
          col2Names: ['UNIT 2 BOILER EFFICIENCY', 'BOILER EFFICIENCY 2'],
          out1: series1,
          out2: series2,
        );
        break;
      case 3: // NPHR Heat Rate
        s1Label = 'NPHR U1';
        s2Label = 'NPHR U2';
        s1Color = const Color(0xFFFFB020);
        s2Color = const Color(0xFFC084FC);
        unit = 'kCal';
        _extractSeriesFromNphr(series1, series2);
        break;
    }

    if (series1.isEmpty && series2.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart_rounded, size: 28, color: AppColors.textDim),
            const SizedBox(height: 6),
            const Text(
              'Awaiting telemetry history from Firebase...',
              style: TextStyle(fontSize: AppTheme.fs12, color: AppColors.textDim),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _legendDot(s1Color, s1Label),
            const SizedBox(width: 12),
            _legendDot(s2Color, s2Label),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (val, meta) {
                      if (val == meta.max || val == meta.min) return const SizedBox.shrink();
                      return Text(
                        val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : '${val.toInt()}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (series1.length > 5 ? (series1.length / 4).floorToDouble() : 1),
                    getTitlesWidget: (val, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'P${val.toInt() + 1}',
                          style: const TextStyle(fontSize: 9, color: AppColors.textDim),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                if (series1.isNotEmpty)
                  LineChartBarData(
                    spots: series1,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: s1Color,
                    barWidth: 2.2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: s1Color.withValues(alpha: 0.12),
                    ),
                  ),
                if (series2.isNotEmpty)
                  LineChartBarData(
                    spots: series2,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: s2Color,
                    barWidth: 2.0,
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.barIndex == 0 ? s1Label : s2Label;
                      return LineTooltipItem(
                        '$label: ${spot.y.toStringAsFixed(1)} $unit',
                        const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _extractSeriesFromTable({
    required List<String> col1Names,
    required List<String> col2Names,
    required List<FlSpot> out1,
    required List<FlSpot> out2,
  }) {
    final source = _overviewData.length > 1
        ? _overviewData
        : (_table1Data.length > 1 ? _table1Data : []);

    if (source.length <= 1) return;

    final header = source.first.map((e) => e.toString().trim().toUpperCase()).toList();

    int idx1 = -1;
    for (final name in col1Names) {
      idx1 = header.indexOf(name.toUpperCase());
      if (idx1 != -1) break;
    }

    int idx2 = -1;
    for (final name in col2Names) {
      idx2 = header.indexOf(name.toUpperCase());
      if (idx2 != -1) break;
    }

    // Limit to latest 20 points
    final int start = source.length > 21 ? source.length - 20 : 1;
    int pointIdx = 0;
    for (int i = start; i < source.length; i++) {
      final row = source[i];
      if (idx1 != -1 && idx1 < row.length) {
        final v = double.tryParse(row[idx1].toString());
        if (v != null) out1.add(FlSpot(pointIdx.toDouble(), v));
      }
      if (idx2 != -1 && idx2 < row.length) {
        final v = double.tryParse(row[idx2].toString());
        if (v != null) out2.add(FlSpot(pointIdx.toDouble(), v));
      }
      pointIdx++;
    }

    // Fallback: if out2 is empty (e.g. Unit 2 Boiler Efficiency not in overviewData) check _table2Data
    if (out2.isEmpty && _table2Data.length > 1) {
      final t2Header = _table2Data.first.map((e) => e.toString().trim().toUpperCase()).toList();
      int t2Idx = -1;
      for (final name in col2Names) {
        t2Idx = t2Header.indexOf(name.toUpperCase());
        if (t2Idx == -1) {
          t2Idx = t2Header.indexWhere((col) => col.contains(name.toUpperCase()));
        }
        if (t2Idx != -1) break;
      }
      if (t2Idx != -1) {
        final int t2Start = _table2Data.length > 21 ? _table2Data.length - 20 : 1;
        int t2Point = 0;
        for (int i = t2Start; i < _table2Data.length; i++) {
          final row = _table2Data[i];
          if (t2Idx < row.length) {
            final v = double.tryParse(row[t2Idx].toString());
            if (v != null) out2.add(FlSpot(t2Point.toDouble(), v));
          }
          t2Point++;
        }
      }
    }
  }

  void _extractSeriesFromNphr(List<FlSpot> out1, List<FlSpot> out2) {
    if (_nphrData.length <= 1) return;
    final int start = _nphrData.length > 21 ? _nphrData.length - 20 : 1;
    bool firstColIsDate = false;
    if (_nphrData.length > 1 && _nphrData[1].isNotEmpty) {
      final s0 = _nphrData[1][0].toString().trim();
      firstColIsDate = DateTime.tryParse(s0) != null || DateTime.tryParse(s0.replaceAll(' ', 'T')) != null;
    }
    final int u1Idx = firstColIsDate ? 1 : 0;
    final int u2Idx = firstColIsDate ? 2 : 1;

    int pointIdx = 0;
    for (int i = start; i < _nphrData.length; i++) {
      final row = _nphrData[i];
      if (row.length > u1Idx) {
        final v1 = double.tryParse(row[u1Idx].toString());
        if (v1 != null) out1.add(FlSpot(pointIdx.toDouble(), v1));
      }
      if (row.length > u2Idx) {
        final v2 = double.tryParse(row[u2Idx].toString());
        if (v2 != null) out2.add(FlSpot(pointIdx.toDouble(), v2));
      }
      pointIdx++;
    }
  }
}
