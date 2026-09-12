import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/pages/solarpv/inverter_detail_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:msw_eplant/pages/unit_detail_page.dart';
import 'package:msw_eplant/pages/cems_detail_page.dart';
import 'package:msw_eplant/pages/plant/plant_overview_detail_page.dart';
import 'package:msw_eplant/services/cems_threshold_service.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';

// ============================================================================
// TYPOGRAPHY CONSTANTS (KLASIFIKASI FONT HALAMAN PLANT)
// Ubah konfigurasi font halaman ini secara terpusat di bawah ini:
// ============================================================================
abstract final class _PlantFonts {
  /// Ubah fontFamily di sini untuk mengganti seluruh font pada halaman Plant Overview.
  /// Contoh: 'Inter', 'Roboto', 'Outfit', atau null untuk default sistem.
  static const String? fontFamily = null;

  // --- 1. Navigasi & Judul Halaman ---
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs16,
    fontWeight: FontWeight.bold,
  );

  // --- 2. Judul Seksi (Section Headers) ---
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: 0.6,
  );

  // --- 3. Ringkasan Solar & Badge Seksi ---
  static const TextStyle summaryLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.4,
  );

  static const TextStyle summaryPower = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs14,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
  );

  static const TextStyle summaryYield = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs14,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const TextStyle onlineBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: Color(0xFF00E5A0),
  );

  // --- 4. Filter Chips ---
  static const TextStyle chipSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const TextStyle chipUnselected = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDim,
  );

  // --- 5. Judul Card & Label Komponen ---
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: 0.4,
  );

  static const TextStyle inverterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // --- 6. Nilai Metrik & Satuan (Metrics & Values) ---
  static const TextStyle primaryValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs16,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
  );

  static const TextStyle unitText = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDim,
  );

  // --- 7. Status & Indikator ---
  static const TextStyle statusText = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w700,
  );

  // --- 8. Keterangan & Metadata ---
  static const TextStyle capacityMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w500,
    color: AppColors.textDim,
  );

  static const TextStyle yieldMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSub,
  );

  static const TextStyle emptyNotice = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    color: AppColors.textSub,
  );
}

class PlantPage extends StatefulWidget {
  const PlantPage({super.key});

  @override
  State<PlantPage> createState() => _PlantPageState();
}

class _PlantPageState extends State<PlantPage> {
  String _selectedSolarCluster = 'all';
  DatabaseReference? _overviewRef;
  DatabaseReference? _table1Ref;
  DatabaseReference? _table2Ref;
  DatabaseReference? _cems1Ref;
  DatabaseReference? _cems2Ref;
  List<List> _overviewData = [];
  List<List> _table1Data = [];
  List<List> _table2Data = [];
  List<List> _cems1Data = [];
  List<List> _cems2Data = [];
  StreamSubscription<DatabaseEvent>? _overviewSub;
  StreamSubscription<DatabaseEvent>? _sub1;
  StreamSubscription<DatabaseEvent>? _sub2;
  StreamSubscription<DatabaseEvent>? _c1Sub;
  StreamSubscription<DatabaseEvent>? _c2Sub;

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
    _overviewSub?.cancel();
    _sub1?.cancel();
    _sub2?.cancel();
    _c1Sub?.cancel();
    _c2Sub?.cancel();
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

      _overviewSub = _overviewRef?.onValue.listen((e) => _updateData(e, (v) => _overviewData = v));
      _sub1 = _table1Ref?.onValue.listen((e) => _updateData(e, (v) => _table1Data = v));
      _sub2 = _table2Ref?.onValue.listen((e) => _updateData(e, (v) => _table2Data = v));
      _c1Sub = _cems1Ref?.onValue.listen((e) => _updateData(e, (v) => _cems1Data = v));
      _c2Sub = _cems2Ref?.onValue.listen((e) => _updateData(e, (v) => _cems2Data = v));
    } catch (e) {
      debugPrint("Firebase RTDB streams in PlantPage skipped: $e");
    }
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
    if (idx == -1) {
      final target = label.trim().toUpperCase();
      idx = header.indexWhere((h) => h.trim().toUpperCase() == target);
    }
    if (idx == -1) {
      final target = label.trim().toUpperCase();
      idx = header.indexWhere((h) {
        final s = h.trim().toUpperCase();
        return s.contains(target) || (target.contains("LOAD") && s.contains("LOAD") && (target.contains("2") ? s.contains("2") : s.contains("1")));
      });
    }
    if (idx != -1 && idx < record.length) {
      return double.tryParse(record[idx].toString()) ?? 0.0;
    }
    return 0.0;
  }

  bool _isListLive(List<List> data, [List<List>? fallbackData]) {
    String? rawDate;
    if (data.length > 1) {
      final header = data.first.map((e) => e.toString().toUpperCase().trim()).toList();
      int dtIdx = header.indexOf("DATETIME");
      if (dtIdx != -1 && dtIdx < data.last.length) {
        rawDate = data.last[dtIdx]?.toString();
      }
    }

    // If rawDate was not found or is not live, fall back to fallbackData
    if (!PlantStatusHelper.isTimestampLive(rawDate) && fallbackData != null && fallbackData.length > 1) {
      final fbHeader = fallbackData.first.map((e) => e.toString().toUpperCase().trim()).toList();
      int fbDtIdx = fbHeader.indexOf("DATETIME");
      if (fbDtIdx != -1 && fbDtIdx < fallbackData.last.length) {
        rawDate = fallbackData.last[fbDtIdx]?.toString();
      } else {
        rawDate = fallbackData.last[0]?.toString();
      }
    }

    // Fallback: check if data.last[0] is a valid timestamp
    if (!PlantStatusHelper.isTimestampLive(rawDate) && data.length > 1) {
      final candidate = data.last[0]?.toString();
      if (PlantStatusHelper.isTimestampLive(candidate)) {
        rawDate = candidate;
      }
    }

    return PlantStatusHelper.isTimestampLive(rawDate);
  }

  @override
  Widget build(BuildContext context) {
    final double u1Load = _getLoad(_t1Last, _t1Header, "UNIT 1 LOAD");
    final bool u1HasData = _table1Data.length > 1;
    final bool u1Live = _isListLive(_table1Data);
    final bool u1Shutdown = u1HasData && u1Load <= 0;

    final double u2Load = _getLoad(_t2Last, _t2Header, "UNIT 2 LOAD");
    final bool u2HasData = _table2Data.length > 1;
    final bool u2Live = _isListLive(_table2Data, _table1Data);
    final bool u2Shutdown = u2HasData && u2Load <= 0;

    final bool c1Live = _isListLive(_cems1Data, _table1Data);
    final bool c1Shutdown = u1Shutdown;

    final bool c2Live = _isListLive(_cems2Data, _table1Data);
    final bool c2Shutdown = u2Shutdown;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.75),
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
            style: _PlantFonts.appBarTitle,
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: FusionSolarService.instance.isSyncingNotifier,
              builder: (context, isSyncing, _) {
                if (!isSyncing) return const SizedBox(height: 2.0);
                return const LinearProgressIndicator(
                  minHeight: 2.0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.solar),
                );
              },
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverviewDetailBanner(),
              const SizedBox(height: 12),
              _buildSectionTitle("BOILER"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildUnitCard(
                      title: "UNIT 1",
                      load: u1Load,
                      isLive: u1Live,
                      isShutdown: u1Shutdown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UnitDetailPage(unitIndex: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildUnitCard(
                      title: "UNIT 2",
                      load: u2Load,
                      isLive: u2Live,
                      isShutdown: u2Shutdown,
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
              const SizedBox(height: 14),
              _buildSectionTitle("EMISSION"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildCemsCard(
                      title: "CEMS 1",
                      isCompliant: CemsThresholdService.isDataCompliant(
                          _cems1Data, _table1Data),
                      isLive: c1Live,
                      isShutdown: c1Shutdown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CemsDetailPage(unitIndex: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCemsCard(
                      title: "CEMS 2",
                      isCompliant: CemsThresholdService.isDataCompliant(
                          _cems2Data, _table2Data),
                      isLive: c2Live,
                      isShutdown: c2Shutdown,
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
              // const SizedBox(height: 14),
              Divider(color: AppColors.border),
              const SizedBox(height: 8),
              _buildKelanisSolarSection(),
              const SizedBox(height: 16),
              Divider(color: AppColors.border),
              const SizedBox(height: 8),
              _buildMswSolarSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewDetailBanner() {
    double totalGross = 0.0;
    if (_overviewData.length > 1) {
      final header = _overviewData.first.map((e) => e.toString()).toList();
      totalGross = _getLoad(_overviewData.last, header, "TOTAL LOAD");
      if (totalGross == 0.0) {
        totalGross = _getLoad(_overviewData.last, header, "TOTAL GENERATION");
      }
    }
    if (totalGross == 0.0) {
      final double u1 = _getLoad(_t1Last, _t1Header, "UNIT 1 LOAD");
      final double u2 = _getLoad(_t2Last, _t2Header, "UNIT 2 LOAD");
      totalGross = u1 + u2;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlantOverviewDetailPage()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PLANT OVERVIEW DETAIL',
                      style: const TextStyle(
                        fontSize: AppTheme.fs13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalGross > 0
                        ? 'Live Gross: ${totalGross.toStringAsFixed(1)} MW · Busbar 20kV/70kV'
                        : 'Gross Generation, Busbar 20kV/70kV Power Flow, CEMS & NPHR',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OPEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color accentColor = AppColors.primary, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _PlantFonts.sectionTitle,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildKelanisSolarSection() {
    return ValueListenableBuilder<SolarSnapshot>(
      valueListenable: FusionSolarService.instance.snapshotNotifier,
      builder: (context, globalSolar, _) {
        final solar = globalSolar.kelanisSnapshot;
        final isNight = solar.isNightTime;
        final totalPowerStr =
            isNight ? '0.0 kW' : '${solar.totalPowerKw.toStringAsFixed(1)} kW';
        final onlineText =
            '${solar.onlineInverterCount}/${solar.totalInverterCount} Online';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(
              "PLTS KELANIS (468 kWp)",
              accentColor: AppColors.solar,
            ),
            const SizedBox(height: 6),
            // Kelanis Overview Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solar.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.solar.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TOTAL ACTIVE POWER',
                            style: _PlantFonts.summaryLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalPowerStr,
                            style: _PlantFonts.summaryPower.copyWith(
                              color: isNight
                                  ? AppColors.textDim
                                  : const Color(0xFF00E5A0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 26, color: AppColors.border),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TODAY YIELD',
                            style: _PlantFonts.summaryLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${solar.effectiveYieldTodayKwh < 10 ? solar.effectiveYieldTodayKwh.toStringAsFixed(1) : solar.effectiveYieldTodayKwh.toStringAsFixed(0)} kWh',
                            style: _PlantFonts.summaryYield,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 26, color: AppColors.border),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SolarDetailPage(initialPlant: 'kelanis'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.solar.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AppColors.solar.withValues(alpha: 0.35)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              onlineText,
                              style: _PlantFonts.onlineBadge.copyWith(color: AppColors.solar),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: AppColors.solar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2-column Inverter Cards (4 units)
            _buildInverterCardGrid(solar.inverters),
          ],
        );
      },
    );
  }

  Widget _buildMswSolarSection() {
    return ValueListenableBuilder<SolarSnapshot>(
      valueListenable: FusionSolarService.instance.snapshotNotifier,
      builder: (context, globalSolar, _) {
        final solar = globalSolar.mswSnapshot;
        final inverters = solar.inverters;
        final filteredInverters = _selectedSolarCluster == 'all'
            ? inverters
            : inverters
                .where((inv) =>
                    inv.clusterId.toLowerCase() ==
                    _selectedSolarCluster.toLowerCase())
                .toList();

        final isNight = solar.isNightTime;
        final totalPowerStr =
            isNight ? '0.0 kW' : '${solar.totalPowerKw.toStringAsFixed(1)} kW';
        final onlineText =
            '${solar.onlineInverterCount}/${solar.totalInverterCount} Online';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(
              "PLTS MSW (400 kWp)",
              accentColor: AppColors.solar,
            ),
            const SizedBox(height: 6),
            // MSW Overview Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solar.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.solar.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TOTAL ACTIVE POWER',
                            style: _PlantFonts.summaryLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalPowerStr,
                            style: _PlantFonts.summaryPower.copyWith(
                              color: isNight
                                  ? AppColors.textDim
                                  : const Color(0xFF00E5A0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 26, color: AppColors.border),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TODAY YIELD',
                            style: _PlantFonts.summaryLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${solar.effectiveYieldTodayKwh < 10 ? solar.effectiveYieldTodayKwh.toStringAsFixed(1) : solar.effectiveYieldTodayKwh.toStringAsFixed(0)} kWh',
                            style: _PlantFonts.summaryYield,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 26, color: AppColors.border),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SolarDetailPage(initialPlant: 'msw'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.solar.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AppColors.solar.withValues(alpha: 0.35)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              onlineText,
                              style: _PlantFonts.onlineBadge.copyWith(color: AppColors.solar),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: AppColors.solar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // MSW Sub-Array Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildClusterFilterChip('all', 'All (${inverters.length})'),
                  _buildClusterFilterChip('200kwp', '200 kWp (2)'),
                  _buildClusterFilterChip('165kwp', '165 kWp (4)'),
                  _buildClusterFilterChip('15_20kwp', '15 & 20 kWp (2)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2-column Inverter Cards (8 units)
            _buildInverterCardGrid(filteredInverters),
          ],
        );
      },
    );
  }

  Widget _buildClusterFilterChip(String clusterId, String label) {
    final isSelected = _selectedSolarCluster == clusterId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedSolarCluster = clusterId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.solar.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.solar
                  : AppColors.border,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Text(
            label,
            style: isSelected
                ? _PlantFonts.chipSelected.copyWith(color: AppColors.solar)
                : _PlantFonts.chipUnselected,
          ),
        ),
      ),
    );
  }

  Widget _buildInverterCardGrid(List<SolarInverter> inverters) {
    if (inverters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No inverters found',
            style: _PlantFonts.emptyNotice,
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < inverters.length; i += 2) {
      final inv1 = inverters[i];
      final inv2 = (i + 1 < inverters.length) ? inverters[i + 1] : null;

      rows.add(
        Row(
          children: [
            Expanded(
              child: PlantInverterCard(
                inverter: inv1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InverterDetailPage(
                        inverterId: inv1.id,
                        initialInverter: inv1,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: inv2 != null
                  ? PlantInverterCard(
                      inverter: inv2,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InverterDetailPage(
                              inverterId: inv2.id,
                              initialInverter: inv2,
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < inverters.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildUnitCard({
    required String title,
    required double load,
    bool isLive = true,
    bool isShutdown = false,
    required VoidCallback onTap,
  }) {
    return PlantUnitCard(
      title: title,
      load: load,
      isLive: isLive,
      isShutdown: isShutdown,
      onTap: onTap,
    );
  }

  Widget _buildCemsCard({
    required String title,
    required bool isCompliant,
    bool isLive = true,
    bool isShutdown = false,
    required VoidCallback onTap,
  }) {
    return PlantCemsCard(
      title: title,
      isCompliant: isCompliant,
      isLive: isLive,
      isShutdown: isShutdown,
      onTap: onTap,
    );
  }
}

class PlantStatusHelper {
  static bool isTimestampLive(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return false;
    final dt = DateTime.tryParse(rawDate)?.toLocal() ??
        DateTime.tryParse(rawDate.replaceAll(' ', 'T'))?.toLocal();
    if (dt == null) return false;
    final diff = DateTime.now().difference(dt);
    return diff.inMinutes.abs() < 60;
  }

  static Color ledColor({required bool isLive, required bool isShutdown}) {
    if (isShutdown) return Colors.redAccent;
    if (isLive) return Colors.greenAccent;
    return Colors.grey;
  }
}

class PlantUnitCard extends StatelessWidget {
  final String title;
  final double load;
  final bool isLive;
  final bool isShutdown;
  final VoidCallback onTap;

  const PlantUnitCard({
    super.key,
    required this.title,
    required this.load,
    this.isLive = true,
    this.isShutdown = false,
    required this.onTap,
  });

  Color get _statusColor {
    if (load <= 0) return Colors.redAccent;
    if (load >= 0 && load < 4) return Colors.blueAccent;
    if (load < 12) return Colors.amber;
    return Colors.greenAccent;
  }

  String get _statusLabel {
    if (load <= 0) return "Shutdown";
    if (load >= 0 && load < 4) return "House Load";
    if (load < 12) return "Low Load";
    return "Normal";
  }

  Color get _ledColor => PlantStatusHelper.ledColor(
        isLive: isLive,
        isShutdown: isShutdown,
      );

  @override
  Widget build(BuildContext context) {
    final Color sc = _statusColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isShutdown
                ? Colors.redAccent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _PlantFonts.cardTitle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _ledColor,
                    shape: BoxShape.circle,
                  ),
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
                    load.toStringAsFixed(1),
                    style: _PlantFonts.primaryValue.copyWith(
                      color: sc == Colors.amber ? Colors.amber : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "MW",
                    style: _PlantFonts.unitText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  sc == Colors.redAccent
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  size: 13,
                  color: sc,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _PlantFonts.statusText.copyWith(color: sc),
                    ),
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

class PlantCemsCard extends StatelessWidget {
  final String title;
  final bool isCompliant;
  final bool isLive;
  final bool isShutdown;
  final VoidCallback onTap;

  const PlantCemsCard({
    super.key,
    required this.title,
    required this.isCompliant,
    this.isLive = true,
    this.isShutdown = false,
    required this.onTap,
  });

  Color get _ledColor => PlantStatusHelper.ledColor(
        isLive: isLive,
        isShutdown: isShutdown,
      );

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        isCompliant ? Colors.greenAccent : Colors.redAccent;
    final String statusLabel = isCompliant ? "Compliant" : "Non-Compliant";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompliant
                ? AppColors.border
                : Colors.redAccent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _PlantFonts.cardTitle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _ledColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Icon(Icons.air, size: 20, color: Colors.cyanAccent),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isCompliant
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _PlantFonts.statusText.copyWith(color: statusColor),
                    ),
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

class PlantInverterCard extends StatelessWidget {
  final SolarInverter inverter;
  final VoidCallback onTap;

  const PlantInverterCard({
    super.key,
    required this.inverter,
    required this.onTap,
  });

  Color get _statusColor {
    if (inverter.isNightStandby) return const Color(0xFF38BDF8);
    return inverter.status.color;
  }

  String get _statusLabel {
    if (inverter.isNightStandby) return "Standby";
    if (inverter.status == InverterStatus.normal) return "Normal";
    return inverter.status.label;
  }

  Color get _ledColor => _statusColor;

  @override
  Widget build(BuildContext context) {
    final Color sc = _statusColor;
    final isNight = inverter.isNightStandby;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: inverter.status == InverterStatus.offline
                ? Colors.redAccent.withValues(alpha: 0.4)
                : (inverter.isNightStandby
                    ? AppColors.border
                    : AppColors.solar.withValues(alpha: 0.25)),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    inverter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _PlantFonts.inverterTitle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _ledColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${inverter.capacityKwp.toStringAsFixed(0)} kWp',
                style: _PlantFonts.capacityMeta,
              ),
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
                    isNight ? "0.0" : inverter.powerKw.toStringAsFixed(1),
                    style: _PlantFonts.primaryValue.copyWith(
                      color: isNight ? AppColors.textDim : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "kW",
                    style: _PlantFonts.unitText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isNight
                      ? Icons.nightlight_round
                      : (inverter.status == InverterStatus.normal
                          ? Icons.check_circle
                          : (inverter.status == InverterStatus.offline
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline)),
                  size: 12,
                  color: sc,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _PlantFonts.statusText.copyWith(color: sc),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${inverter.yieldTodayKwh < 10 ? inverter.yieldTodayKwh.toStringAsFixed(1) : inverter.yieldTodayKwh.toStringAsFixed(0)} kWh",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _PlantFonts.yieldMeta,
                    ),
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
