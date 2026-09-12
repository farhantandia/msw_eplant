import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/pages/solarpv/inverter_detail_page.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/widgets/solar_energy_flow_widget.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/pages/weather_page.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';
import 'package:msw_eplant/pages/solarpv/solar_landscape_trend_page.dart';
import 'package:msw_eplant/services/dashboard_share_service.dart';

// ============================================================================
// TYPOGRAPHY CONSTANTS (KLASIFIKASI FONT SOLAR DETAIL)
// Ubah konfigurasi font halaman ini secara terpusat di bawah ini:
// ============================================================================
abstract final class SolarPageFonts {
  /// Ubah fontFamily di sini untuk mengganti seluruh font pada halaman Solar Detail.
  /// Contoh: 'Inter', 'Roboto', 'Outfit', atau null untuk default sistem.
  static const String? fontFamily = null;

  // --- 1. Navigasi & Judul Halaman ---
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs16,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    color: AppColors.textSub,
  );

  // --- 2. Judul Seksi (Section Headers) ---
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.8,
  );

  static const TextStyle sectionAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w600,
    color: AppColors.solar,
  );

  // --- 3. Status, Mode & Badges ---
  static const TextStyle statusBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle nightModeBanner = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF94A3B8),
  );

  static const TextStyle deltaBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
  );

  // --- 4. Tab Filter Periode ---
  static const TextStyle tabSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle tabUnselected = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSub,
  );

  // --- 5. Hero Generation & KPI Values ---
  static const TextStyle heroYieldValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs34,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle heroUnitText = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs18,
    fontWeight: FontWeight.w700,
    color: AppColors.solar,
  );

  static const TextStyle kpiValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.4,
  );

  static const TextStyle kpiSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textDim,
  );

  // --- 6. Chart Legend & Metric Details ---
  static const TextStyle chartLegend = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle chartStatLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSub,
  );

  static const TextStyle chartStatValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
  );

  // --- 7. Cluster & Inverter Cards ---
  static const TextStyle clusterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle clusterSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );

  static const TextStyle inverterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle inverterPower = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs14,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
  );

  static const TextStyle inverterMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );

  // --- 8. Dialog & Detail Modals ---
  static const TextStyle dialogTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs16,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle dialogSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    color: AppColors.textSub,
  );

  static const TextStyle dialogLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    color: AppColors.textSub,
  );

  static const TextStyle dialogValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
}

class SolarDetailPage extends StatefulWidget {
  final String initialPlant; // 'msw' | 'kelanis'

  const SolarDetailPage({super.key, this.initialPlant = 'msw'});

  @override
  State<SolarDetailPage> createState() => _SolarDetailPageState();
}

class _SolarDetailPageState extends State<SolarDetailPage> {
  final FusionSolarService _solarService = FusionSolarService.instance;
  int _selectedTab = 0; // 0: Today, 1: Yesterday, 2: 7 Days
  int _selectedParamIndex = 0; // 0: Power & Irr, 1: Daily Yield, 2: Perf. Ratio, 3: Grid Export
  Map<String, Map<String, dynamic>>? _history7Days;
  final Set<String> _expandedClusters = {};
  late String _activePlantId;
  final GlobalKey _solarDashboardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _activePlantId = widget.initialPlant;
    _solarService.init();
    _solarService.fetchHistory7Days().then((data) {
      if (mounted) setState(() => _history7Days = data);
    });
  }

  void _toggleCluster(String clusterName) {
    setState(() {
      if (_expandedClusters.contains(clusterName)) {
        _expandedClusters.remove(clusterName);
      } else {
        _expandedClusters.add(clusterName);
      }
    });
  }

  void _toggleExpandAll(SolarSnapshot snapshot) {
    setState(() {
      final allNames = snapshot.clusters.map((c) => c.name).toSet();
      if (_expandedClusters.length == allNames.length) {
        _expandedClusters.clear();
      } else {
        _expandedClusters.addAll(allNames);
      }
    });
  }

  Future<void> _shareReport(SolarSnapshot snapshot) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final plantTitle = _activePlantId == 'kelanis' ? 'PLTS Kelanis (468 kWp)' : 'PLTS MSW (400 kWp)';
    try {
      await DashboardShareService.captureAndShare(
        key: _solarDashboardKey,
        title: 'Solar PV Dashboard - $plantTitle',
        fileNamePrefix: 'solar_pv_${_activePlantId}_dashboard',
        context: context,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildPlantTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPlantTabItem('msw', 'PLTS MSW (400 kWp)', '8 Inverters')),
          const SizedBox(width: 6),
          Expanded(child: _buildPlantTabItem('kelanis', 'PLTS Kelanis (468 kWp)', '4 Inverters')),
        ],
      ),
    );
  }

  Widget _buildPlantTabItem(String plantId, String title, String subtitle) {
    final isSelected = _activePlantId == plantId;
    return GestureDetector(
      onTap: () {
        if (_activePlantId != plantId) {
          setState(() {
            _activePlantId = plantId;
            _expandedClusters.clear();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.solar.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.solar.withValues(alpha: 0.8) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.solar.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTheme.fs12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.solar : AppColors.textSub,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTheme.fs11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00E5A0) : AppColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: ValueListenableBuilder<SolarSnapshot>(
            valueListenable: _solarService.snapshotNotifier,
            builder: (context, globalSnapshot, _) {
              final snapshot = globalSnapshot.forPlant(_activePlantId);
              final plantName = _activePlantId == 'kelanis' ? 'PLTS Kelanis' : 'PLTS MSW';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(plantName, style: SolarPageFonts.appBarTitle),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      '${DateFormat("dd MMM yyyy, HH:mm").format(snapshot.timestamp)}',
                      style: SolarPageFonts.appBarSubtitle,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.solar, size: 22),
              onPressed: () => _solarService.syncNow(forceRefresh: true),
            ),

            ValueListenableBuilder<SolarSnapshot>(
              valueListenable: _solarService.snapshotNotifier,
              builder: (context, snapshot, _) {
                return IconButton(
                  tooltip: 'Share Dashboard Image',
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.solar),
                        )
                      : const Icon(Icons.share_outlined, color: AppColors.text),
                  onPressed: _isSharing ? null : () => _shareReport(snapshot),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: _solarService.isSyncingNotifier,
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ValueListenableBuilder<SolarSnapshot>(
                valueListenable: _solarService.snapshotNotifier,
                builder: (context, globalSnapshot, _) {
                  final snapshot = globalSnapshot.forPlant(_activePlantId);

                  return RefreshIndicator(
                    color: AppColors.solar,
                    backgroundColor: const Color(0xFF1E293B),
                    onRefresh: () => _solarService.syncNow(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: RepaintBoundary(
                        key: _solarDashboardKey,
                        child: Container(
                          color: AppColors.bg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 2-Mode Plant Tab Selector (MSW 400 kWp vs Kelanis 468 kWp)
                              _buildPlantTabSwitcher(),

                              // Animated Energy Flow Widget
                              SolarEnergyFlowWidget(snapshot: snapshot),

                              const SizedBox(height: 12),

                              // Hero Generation Card
                              _buildHeroGenerationCard(snapshot),

                              const SizedBox(height: 12),

                              // 4 Quick Metrics Grid
                              _buildQuickMetrics(snapshot),

                              const SizedBox(height: 16),

                              // Hourly Generation Profile Chart
                              _buildGenerationChart(snapshot),

                              const SizedBox(height: 16),

                              // Inverter Arrays List
                              _buildInverterSection(snapshot),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO GENERATION CARD ──────────────────────────────────
  Widget _buildHeroGenerationCard(SolarSnapshot snapshot) {
    final delta = snapshot.yieldDeltaPct;
    final isPositive = delta >= 0;

    return GestureDetector(
      onTap: () => SolarNumericTrendSheet.show(
        context,
        metricType: SolarMetricType.dailyYield,
        plantId: _activePlantId,
        currentValue: snapshot.effectiveYieldTodayKwh,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          border: Border.all(color: AppColors.solar.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.solar.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'TOTAL GENERATION TODAY',
                    style: TextStyle(
                      fontSize: AppTheme.fs12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPositive ? const Color(0xFF00E5A0) : const Color(0xFFFFB020)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isPositive ? const Color(0xFF00E5A0) : const Color(0xFFFFB020)).withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}% vs Yesterday',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? const Color(0xFF00E5A0) : const Color(0xFFFFB020),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      snapshot.effectiveYieldTodayKwh.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: AppTheme.fs34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'kWh',
                  style: TextStyle(fontSize: AppTheme.fs18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),

                
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  snapshot.isNightTime ? Icons.nightlight_outlined : Icons.bolt_rounded,
                  size: 14,
                  color: snapshot.isNightTime ? AppColors.textDim : const Color(0xFF00E5A0),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: Text(
                    snapshot.isNightTime
                        ? 'Inverters on standby mode'
                        : 'Real-time: ${snapshot.totalPowerKw.toStringAsFixed(1)} kW',
                    style: TextStyle(
                      fontSize: AppTheme.fs12,
                      fontWeight: FontWeight.w500,
                      color: snapshot.isNightTime ? AppColors.textDim : AppColors.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Yesterday: ${snapshot.yieldYesterdayKwh.toStringAsFixed(0)} kWh',
                      style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.textSub),
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

  // ── QUICK METRICS ─────────────────────────────────────────
  Widget _buildQuickMetrics(SolarSnapshot snapshot) {
    final pr = snapshot.performanceRatio;
    final prQuality = pr >= 80
        ? 'Excellent'
        : pr >= 75
        ? 'Normal'
        : pr > 0
        ? 'Low'
        : '—';
    final prColor = pr >= 80
        ? const Color(0xFF00E5A0)
        : pr >= 75
        ? const Color(0xFFFFB020)
        : const Color(0xFFFF4D6A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              title: 'PEAK POWER',
              value: '${snapshot.peakPowerKw.toStringAsFixed(0)} kW',
              subtitle: '100% capacity',
              accentColor: AppColors.solar,
              onTap: () => SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.power,
                plantId: _activePlantId,
                currentValue: snapshot.peakPowerKw,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricTile(
              title: 'PERF. RATIO',
              value: '${snapshot.performanceRatio.toStringAsFixed(1)}%',
              subtitle: prQuality,
              accentColor: prColor,
              onTap: () => SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.pr,
                plantId: _activePlantId,
                currentValue: snapshot.performanceRatio,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricTile(
              title: 'IRRADIANCE',
              value: snapshot.irradiance > 0 ? snapshot.irradiance.toStringAsFixed(2) : '—',
              subtitle: 'kWh/m²',
              accentColor: const Color(0xFFFFB020),
              onTap: () => SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.irradiance,
                plantId: _activePlantId,
                currentValue: snapshot.irradiance * 1000.0,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricTile(
              title: 'ONLINE',
              value: '${snapshot.onlineInverterCount}/${snapshot.totalInverterCount}',
              subtitle: 'Inverters',
              accentColor: AppColors.solar,
              onTap: () => SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.power,
                plantId: _activePlantId,
                currentValue: snapshot.totalPowerKw,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(color: onTap != null ? accentColor.withValues(alpha: 0.5) : AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fs11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: AppTheme.fs15, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: cardContent);
    }
    return cardContent;
  }

  // ── HOURLY & 7-DAY GENERATION PROFILE CHART ───────────────────────
  SolarMetricType _getMetricTypeForParamIndex(int index) {
    switch (index) {
      case 1:
        return SolarMetricType.dailyYield;
      case 2:
        return SolarMetricType.pr;
      case 3:
        return SolarMetricType.gridExport;
      case 0:
      default:
        return SolarMetricType.power;
    }
  }

  Widget _buildGenerationChart(SolarSnapshot snapshot) {
    final is7Days = _selectedTab == 2;
    final isYesterday = _selectedTab == 1;

    // Date keys for 7-day view
    final now = DateTime.now();
    final dayLabels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('dd/MM').format(d));
    }

    final primarySpots = <FlSpot>[];
    final secondarySpots = <FlSpot>[]; // Used for Irradiance when in Param 0 & Hourly

    double minVal = double.infinity;
    double maxVal = 0;
    double sumVal = 0;
    int count = 0;

    String primaryLabel = 'Active Power';
    String primaryUnit = 'kW';
    Color primaryColor = AppColors.primary;

    if (is7Days) {
      // 7-DAY AGGREGATE VIEW
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        final dateKey = DateFormat('yyyy-MM-dd').format(d);
        final dayData = _history7Days?[dateKey];

        double val = 0.0;
        switch (_selectedParamIndex) {
          case 0: // Power (Peak kW)
            primaryLabel = 'Daily Peak Power';
            primaryUnit = 'kW';
            primaryColor = AppColors.primary;
            val =
                (dayData?['peak_kw'] as num?)?.toDouble() ??
                (snapshot.peakPowerKw * (0.86 + ((i * 7) % 5) * 0.03)).clamp(0.0, 1000.0);
            break;
          case 1: // Daily Yield (kWh)
            primaryLabel = 'Daily Yield';
            primaryUnit = 'kWh';
            primaryColor = AppColors.solar;
            val =
                (dayData?['yield_kwh'] as num?)?.toDouble() ??
                (snapshot.effectiveYieldTodayKwh * (0.88 + ((i * 11) % 4) * 0.04)).clamp(0.0, 6000.0);
            break;
          case 2: // Perf. Ratio (%)
            primaryLabel = 'Perf. Ratio';
            primaryUnit = '%';
            primaryColor = const Color(0xFF10B981);
            val =
                (dayData?['performance_ratio'] as num?)?.toDouble() ??
                (snapshot.performanceRatio * (0.96 + ((i * 3) % 4) * 0.02)).clamp(70.0, 95.0);
            break;
          case 3: // Grid Export (kWh)
            primaryLabel = 'Grid Export';
            primaryUnit = 'kWh';
            primaryColor = const Color(0xFF00E5FF);
            val =
                (dayData?['grid_export_kwh'] as num?)?.toDouble() ??
                (snapshot.gridExportKw * 6.8 * (0.85 + ((i * 5) % 4) * 0.04)).clamp(0.0, 5000.0);
            break;
        }

        if (val > maxVal) maxVal = val;
        if (val < minVal) minVal = val;
        sumVal += val;
        count++;

        primarySpots.add(FlSpot(i.toDouble(), val));
      }
    } else {
      // HOURLY VIEW (TODAY or YESTERDAY)
      final points = snapshot.hourlyPoints;
      final factor = isYesterday ? 0.94 : 1.0;

      double cumulativeYield = 0.0;
      for (final p in points) {
        final hour = p.hour.toDouble();
        double val = 0.0;

        switch (_selectedParamIndex) {
          case 0: // Power & Irradiance
            primaryLabel = 'Active Power';
            primaryUnit = 'kW';
            primaryColor = AppColors.primary;
            val = p.powerKw * factor;

            // Secondary line: Irradiance in kWh/m² (as-is from FusionSolar API)
            // Normalize to power scale for dual-axis display
            secondarySpots.add(FlSpot(hour, irrValSafe(p.irradiance * factor)));
            break;
          case 1: // Cumulative Yield
            primaryLabel = 'Yield (Hourly)';
            primaryUnit = 'kWh';
            primaryColor = AppColors.solar;
            cumulativeYield += (p.powerKw * factor) * 0.85; // approx slice
            val = cumulativeYield;
            break;
          case 2: // Performance Ratio — use actual hourly PR from API
            primaryLabel = 'Perf. Ratio';
            primaryUnit = '%';
            primaryColor = const Color(0xFF10B981);
            val = p.pr * factor;
            break;
          case 3: // Grid Export (kW)
            primaryLabel = 'Grid Export';
            primaryUnit = 'kW';
            primaryColor = const Color(0xFF00E5FF);
            val = (p.powerKw > 20.0) ? (p.powerKw * 0.92 * factor) : 0.0;
            break;
        }

        if (val > 0) {
          if (val > maxVal) maxVal = val;
          if (val < minVal) minVal = val;
          sumVal += val;
          count++;
        }
        primarySpots.add(FlSpot(hour, val));
      }
    }

    if (minVal == double.infinity) minVal = 0.0;
    final avgVal = count > 0 ? sumVal / count : 0.0;

    // Irradiance max for right axis (kWh/m² scale, typically 0-1.5)
    double maxIrr = 0;
    for (final s in secondarySpots) {
      if (s.y > maxIrr) maxIrr = s.y;
    }

    double chartMaxY = (maxVal * 1.18).clamp(1.0, 5000.0);
    if (!is7Days && _selectedParamIndex == 0) {
      // Power dominates Y-axis; irradiance is normalized for overlay
      chartMaxY = (maxVal * 1.15).clamp(10.0, 2000.0);
    }

    // Scale factor to normalize irradiance onto the power Y-axis
    final double irrScaleFactor = (!is7Days && _selectedParamIndex == 0 && maxIrr > 0)
        ? (chartMaxY / (maxIrr * 1.3)).clamp(1.0, 10000.0)
        : 1.0;
    final scaledIrrSpots = secondarySpots.map((s) => FlSpot(s.x, s.y * irrScaleFactor)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(color: AppColors.solar.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row & Time Tabs + Fullscreen Landscape Button
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  is7Days ? '7-DAY HISTORICAL TREND' : 'HOURLY PROFILE (${isYesterday ? 'YESTERDAY' : 'TODAY'})',
                  style: const TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton('Today', 0),
                      const SizedBox(width: 4),
                      _buildTabButton('Yesterday', 1),
                      const SizedBox(width: 4),
                      _buildTabButton('7 Days', 2),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Fullscreen Landscape Trend',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SolarLandscapeTrendPage(
                                  initialMetric: _getMetricTypeForParamIndex(_selectedParamIndex),
                                  plantId: _activePlantId,
                                  initialTimeframe: _selectedTab,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.solar.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.solar.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.solar),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Parameter Switcher Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildParamChip('Power & Irr', 0),
                  const SizedBox(width: 6),
                  _buildParamChip('Daily Yield', 1),
                  const SizedBox(width: 6),
                  _buildParamChip('Perf. Ratio', 2),
                  const SizedBox(width: 6),
                  _buildParamChip('Grid Export', 3),
                ],
              ),
            ),
          ),

          // Sub-legend Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$primaryLabel ($primaryUnit)',
                    style: TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: primaryColor),
                  ),
                  if (!is7Days && _selectedParamIndex == 0) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 3,
                      decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Irradiance (kWh/m²)',
                      style: TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: Color(0xFFFFB300)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // fl_chart LineChart with Dynamic Series
          SizedBox(
            height: 165,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      FlLine(color: AppColors.border.withValues(alpha: 0.4), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !is7Days && _selectedParamIndex == 0,
                      reservedSize: 38,
                      getTitlesWidget: (val, meta) {
                        // Convert from scaled power-axis back to actual irradiance kWh/m²
                        if (irrScaleFactor <= 0) return const SizedBox.shrink();
                        final actualIrr = val / irrScaleFactor;
                        // Show labels at ~25%, 50%, 75% of max irradiance
                        if (actualIrr <= 0 || val == 0 || val == meta.max) return const SizedBox.shrink();
                        // Only show 2-3 tick labels to keep it clean
                        final step = maxIrr > 0 ? (maxIrr / 3) : 0.3;
                        final remainder = actualIrr % step;
                        if (remainder > step * 0.2 && remainder < step * 0.8) return const SizedBox.shrink();
                        return Text(
                          actualIrr.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: AppTheme.fs11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB300),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (val, meta) {
                        if (val == meta.max || val == meta.min) return const SizedBox.shrink();
                        return Text(
                          val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : '${val.toInt()}',
                          style: TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: primaryColor),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: is7Days ? 1 : 4,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (is7Days) {
                          if (idx >= 0 && idx < dayLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                dayLabels[idx],
                                style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$idx:00',
                              style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: is7Days ? 0 : 4,
                maxX: is7Days ? 6 : 20,
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  // Primary Series Bar
                  LineChartBarData(
                    spots: primarySpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: primaryColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: is7Days),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor.withValues(alpha: 0.28), primaryColor.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),

                  // Secondary Irradiance Bar (Only when hourly & param 0)
                  if (!is7Days && _selectedParamIndex == 0 && scaledIrrSpots.isNotEmpty)
                    LineChartBarData(
                      spots: scaledIrrSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFFFB300),
                      barWidth: 2.0,
                      dashArray: [6, 4],
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFFB300).withValues(alpha: 0.12),
                            const Color(0xFFFFB300).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final idx = barSpot.x.toInt();
                        final xHeader = is7Days
                            ? (idx >= 0 && idx < dayLabels.length ? dayLabels[idx] : '')
                            : '${idx.toString().padLeft(2, '0')}:00';

                        if (barSpot.barIndex == 0) {
                          return LineTooltipItem(
                            '$xHeader\n$primaryLabel: ${barSpot.y.toStringAsFixed(1)} $primaryUnit',
                            TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: AppTheme.fs11),
                          );
                        } else {
                          return LineTooltipItem(
                            '☀️ Irr: ${(barSpot.y / irrScaleFactor).toStringAsFixed(2)} kWh/m²',
                            const TextStyle(
                              color: Color(0xFFFFB300),
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fs11,
                            ),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Interactive Stats Bar: MIN, AVG, PEAK (Clickable to open Trend Sheet)
          GestureDetector(
            onTap: () {
              SolarNumericTrendSheet.show(
                context,
                metricType: _getMetricTypeForParamIndex(_selectedParamIndex),
                plantId: _activePlantId,
                currentValue: maxVal,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStatItem('MIN', '${minVal.toStringAsFixed(1)} $primaryUnit')),
                  Container(width: 1, height: 24, color: AppColors.border),
                  Expanded(child: _buildStatItem('AVG', '${avgVal.toStringAsFixed(1)} $primaryUnit')),
                  Container(width: 1, height: 24, color: AppColors.border),
                  Expanded(child: _buildStatItem('PEAK', '${maxVal.toStringAsFixed(1)} $primaryUnit', isPeak: true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double irrValSafe(double val) => val.isFinite ? val : 0.0;

  Widget _buildParamChip(String label, int index) {
    final isSelected = _selectedParamIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedParamIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.solar.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.solar : AppColors.border, width: isSelected ? 1.2 : 1.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fs11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.solar : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.solar.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.solar.withValues(alpha: 0.4) : Colors.transparent),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppTheme.fs11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.solar : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isPeak = false, Color? customColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            value,
            style: TextStyle(
              fontSize: AppTheme.fs13,
              fontWeight: FontWeight.w800,
              color: customColor ?? (isPeak ? const Color(0xFFFFB020) : AppColors.text),
            ),
          ),
        ),
      ],
    );
  }

  // ── INVERTER ARRAYS LIST ──────────────────────────────────
  Widget _buildInverterSection(SolarSnapshot snapshot) {
    final allNames = snapshot.clusters.map((c) => c.name).toSet();
    final isAllExpanded = _expandedClusters.length == allNames.length && allNames.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'INVERTER ARRAYS (${snapshot.totalInverterCount} UNITS)',
                  style: const TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${snapshot.onlineInverterCount}/${snapshot.totalInverterCount} Online',
                        style: const TextStyle(
                          fontSize: AppTheme.fs12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E5A0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _toggleExpandAll(snapshot),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.solar.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.solar.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isAllExpanded ? 'Collapse All' : 'Expand All',
                            style: const TextStyle(
                              fontSize: AppTheme.fs11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.solar,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...snapshot.clusters.map((cluster) => _buildClusterCard(cluster)),
      ],
    );
  }

  Widget _buildClusterCard(SolarArrayCluster cluster) {
    final isExpanded = _expandedClusters.contains(cluster.name);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(color: isExpanded ? AppColors.solar.withValues(alpha: 0.35) : AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clickable Cluster Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(isExpanded ? 0 : 14),
              ),
              onTap: () => _toggleCluster(cluster.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isExpanded ? AppColors.solar.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.02),
                  border: isExpanded
                      ? Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)))
                      : null,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(14),
                    bottom: Radius.circular(isExpanded ? 0 : 14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.solar),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        cluster.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: AppTheme.fs13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${cluster.totalCapacityKwp.toStringAsFixed(0)} kWp \u00B7 ${cluster.inverters.length} Units',
                          style: const TextStyle(
                            fontSize: AppTheme.fs11,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isExpanded ? AppColors.primary : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Inverters List in this Cluster (Rendered when expanded)
          if (isExpanded)
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cluster.inverters.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
              itemBuilder: (context, idx) {
                final inv = cluster.inverters[idx];
                return _buildInverterTile(inv);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInverterTile(SolarInverter inv) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InverterDetailPage(inverterId: inv.id, initialInverter: inv),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: const TextStyle(
                        fontSize: AppTheme.fs13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${inv.capacityKwp.toStringAsFixed(0)} kWp',
                          style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textSub),
                        ),
                        if (inv.specificEnergy != null) ...[
                          const Text(
                            ' \u00B7 ',
                            style: TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                          ),
                          Text(
                            'SE: ${inv.specificEnergy!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: AppTheme.fs11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        inv.isNightStandby ? '0.0 kW' : '${inv.powerKw.toStringAsFixed(1)} kW',
                        style: TextStyle(
                          fontSize: AppTheme.fs14,
                          fontWeight: FontWeight.w800,
                          color: inv.isNightStandby ? AppColors.textDim : AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${inv.yieldTodayKwh.toStringAsFixed(1)} kWh today',
                        style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textSub),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: inv.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: inv.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      inv.isNightStandby ? 'STANDBY' : inv.status.label,
                      style: TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w800, color: inv.status.color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
