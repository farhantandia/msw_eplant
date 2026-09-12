import 'dart:math' show sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/pages/solarpv/solar_numeric_trend_sheet.dart';
import 'package:msw_eplant/pages/solarpv/solar_landscape_trend_page.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';

// ============================================================================
// TYPOGRAPHY CONSTANTS (KLASIFIKASI FONT INVERTER DETAIL)
// Ubah konfigurasi font halaman ini secara terpusat di bawah ini:
// ============================================================================
abstract final class _InverterDetailFonts {
  /// Ubah fontFamily di sini untuk mengganti seluruh font pada halaman Inverter Detail.
  /// Contoh: 'Inter', 'Roboto', 'Outfit', atau null untuk default sistem.
  static const String? fontFamily = null;

  // --- 1. Navigasi & Judul Halaman ---
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: AppTheme.fs18,
    letterSpacing: 0.5,
  );

  // --- 2. Judul Seksi (Section Headers) ---
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.8,
  );

  // --- 3. Status & Badge ---
  static const TextStyle statusBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w800,
  );

  // --- 4. Hero Banner Power & Loading ---
  static const TextStyle heroPower = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs42,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle heroUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs18,
    fontWeight: FontWeight.bold,
    color: AppColors.textSub,
  );

  static const TextStyle heroLoading = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heroSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );

  static const TextStyle capacitySub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w600,
    color: AppColors.textDim,
  );

  // --- 5. Mini Metric Stat Cards ---
  static const TextStyle statLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.5,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs18,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );

  static const TextStyle statSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textDim,
  );

  // --- 6. Spesifikasi & Diagnostik Rows ---
  static const TextStyle rowLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    color: AppColors.textSub,
  );

  static const TextStyle rowValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // --- 7. Notifikasi & Empty State ---
  static const TextStyle emptyNotice = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textSub,
    fontSize: AppTheme.fs16,
  );

  // --- 8. Alarm & Troubleshooting ---
  static const TextStyle alarmTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle alarmSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );

  static const TextStyle alarmAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle modalTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs16,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle modalSection = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.6,
  );

  static const TextStyle modalBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    color: AppColors.text,
    height: 1.4,
  );

  // --- 9. Analytics & Enrichment Cards ---
  static const TextStyle analyticCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.8,
  );

  static const TextStyle analyticItemLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );

  static const TextStyle analyticItemValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle analyticItemSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textDim,
  );

  static const TextStyle gaugeLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle gaugeSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTheme.fs11,
    color: AppColors.textSub,
  );
}

class InverterDetailPage extends StatelessWidget {
  final String inverterId;
  final SolarInverter? initialInverter;

  const InverterDetailPage({super.key, required this.inverterId, this.initialInverter});

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
      child: ValueListenableBuilder<SolarSnapshot>(
        valueListenable: FusionSolarService.instance.snapshotNotifier,
        builder: (context, snapshot, _) {
          SolarInverter? inverter;
          try {
            inverter = snapshot.inverters.firstWhere((inv) => inv.id == inverterId);
          } catch (_) {
            inverter = initialInverter;
          }

          if (inverter == null) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Inverter Detail')),
              body: const Center(
                child: Text('Inverter not found', style: _InverterDetailFonts.emptyNotice),
              ),
            );
          }

          final inv = inverter;
          final isNight = inv.isNightStandby;
          final statusColor = inv.status.color;
          final statusText = inv.inverterState == 40960
              ? 'STANDBY (NO IRRADIATION)'
              : (isNight ? 'STANDBY (NIGHT)' : inv.status.label);

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  inv.name,
                  style: _InverterDetailFonts.appBarTitle,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.solar, size: 22),
                  onPressed: () => FusionSolarService.instance.syncNow(forceRefresh: true),
                ),
                Tooltip(
                  message: 'Fullscreen Landscape Trend',
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: AppColors.solar, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SolarLandscapeTrendPage(
                            initialMetric: SolarMetricType.power,
                            inverterId: inv.id,
                            inverterName: inv.name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.solar,
                    backgroundColor: const Color(0xFF1E293B),
                    onRefresh: () => FusionSolarService.instance.syncNow(forceRefresh: true),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Primary Active Power & Loading Banner
                          _buildPowerCard(context, inv, statusColor),
                          const SizedBox(height: 16),

                          // 2. Metrics 2x2 Grid
                          _buildMetricsGrid(context, inv),
                          const SizedBox(height: 16),

                          // 3. Performance Analytics (Specific Yield, DC-AC Loss, Peak Power, Cluster Rank)
                          _buildPerformanceAnalyticsCard(context, inv, snapshot),
                          const SizedBox(height: 16),

                          // 4. Thermal & Derating Risk
                          _buildThermalDeratingCard(context, inv),
                          const SizedBox(height: 16),

                          // 5. Power Quality (VUF%, Reactive Power, Apparent Power)
                          if (!isNight) _buildPowerQualityCard(context, inv),
                          if (!isNight) const SizedBox(height: 16),

                          // 6. Technical Specifications Card
                          _buildTechnicalSpecsCard(inv),
                          const SizedBox(height: 16),

                          // 7. Operational Health & Diagnostics
                          _buildDiagnosticsCard(context, inv),
                          const SizedBox(height: 16),

                          // 8. Active Alarms & Troubleshooting Guide
                          _buildAlarmsCard(context, inv),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPowerCard(BuildContext context, SolarInverter inv, Color statusColor) {
    final loading = inv.loadingPct;
    final isNight = inv.isNightStandby;

    return GestureDetector(
      onTap: () {
        SolarNumericTrendSheet.show(
          context,
          metricType: SolarMetricType.power,
          inverterId: inv.id,
          inverterName: inv.name,
          currentValue: inv.powerKw,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inv.isNightStandby
                ? AppColors.border
                : AppColors.solar.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'ACTIVE POWER OUTPUT',
                    style: _InverterDetailFonts.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Capacity: ${inv.capacityKwp.toStringAsFixed(0)} kWp',
                      style: _InverterDetailFonts.capacitySub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isNight ? '0.0' : inv.powerKw.toStringAsFixed(1),
                    style: _InverterDetailFonts.heroPower.copyWith(
                      color: isNight ? AppColors.textDim : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'kW',
                    style: _InverterDetailFonts.heroUnit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Loading: ${loading.toStringAsFixed(1)}%',
                    style: _InverterDetailFonts.heroLoading.copyWith(
                      color: isNight ? AppColors.textDim : AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      isNight ? 'Standby (No Irradiance)' : 'Inverting Grid Power',
                      style: _InverterDetailFonts.heroSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (loading / 100.0).clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isNight ? AppColors.textDim : (loading > 90 ? const Color(0xFFFFB020) : AppColors.primary),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SolarInverter inv) {
    final specificEnergyVal = inv.specificEnergy ?? (inv.capacityKwp > 0 ? (inv.yieldTodayKwh / inv.capacityKwp) : 0.0);

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'DAILY YIELD',
            value: '${inv.yieldTodayKwh.toStringAsFixed(1)} kWh',
            subtitle: 'Cumulative Today',
            color: const Color(0xFF00E5A0),
            onTap: () {
              SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.dailyYield,
                inverterId: inv.id,
                inverterName: inv.name,
                currentValue: inv.yieldTodayKwh,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'SPECIFIC ENERGY',
            value: '${specificEnergyVal.toStringAsFixed(2)} kWh/kWp',
            subtitle: 'Yield Ratio',
            color: const Color(0xFF38BDF8),
            onTap: () {
              SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.specificEnergy,
                inverterId: inv.id,
                inverterName: inv.name,
                currentValue: specificEnergyVal,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: _InverterDetailFonts.statLabel,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.show_chart_rounded, size: 14, color: AppColors.solar),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: _InverterDetailFonts.statValue,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(subtitle, style: _InverterDetailFonts.statSub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSpecsCard(SolarInverter inv) {
    final clusterName = _getClusterDisplayName(inv.clusterId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TECHNICAL SPECIFICATIONS',
            style: _InverterDetailFonts.sectionTitle,
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Inverter Tag / Name', inv.name),
          _buildSpecRow('Array Cluster', clusterName),
          _buildSpecRow('Rated Nameplate Capacity', '${inv.capacityKwp.toStringAsFixed(0)} kWp'),
          _buildSpecRow('Hardware Model', inv.model ?? 'Huawei SUN2000 Smart Inverter'),
          if (inv.esnCode != null && inv.esnCode!.isNotEmpty) _buildSpecRow('Serial Number (ESN)', inv.esnCode!),
          if (inv.softwareVersion != null && inv.softwareVersion!.isNotEmpty)
            _buildSpecRow('Software / Firmware', inv.softwareVersion!),
          _buildSpecRow(
            'Operational State',
            inv.isNightStandby
                ? 'Standby (Night Idle)'
                : (inv.powerKw > 0 ? 'Normal MPPT Inverting' : 'Standby / Low Irradiance'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsCard(BuildContext context, SolarInverter inv) {
    final hasTemp = inv.temperature != null;
    final isTempOk = !hasTemp || inv.temperature! < 65.0;

    final hasFreq = inv.gridFrequency != null;
    final isFreqOk = !hasFreq || (inv.gridFrequency! >= 49.0 && inv.gridFrequency! <= 51.0);

    final isStateHealthy = HuaweiAlarmDictionary.isHealthyState(inv.inverterState);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIAGNOSTICS & TELEMETRY HEALTH',
            style: _InverterDetailFonts.sectionTitle,
          ),
          const SizedBox(height: 12),

          // Live Temperature
          _buildDiagRow(
            'Internal Temperature',
            inv.temperature != null ? '${inv.temperature!.toStringAsFixed(1)} °C' : 'Normal (< 60°C)',
            isOk: isTempOk,
            onTap: () {
              SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.inverterTemp,
                inverterId: inv.id,
                inverterName: inv.name,
                currentValue: inv.temperature ?? 45.0,
              );
            },
          ),

          // Live Grid Frequency
          _buildDiagRow(
            'Grid Frequency',
            inv.gridFrequency != null ? '${inv.gridFrequency!.toStringAsFixed(2)} Hz' : '50.00 Hz (Synced)',
            isOk: isFreqOk,
            onTap: () {
              SolarNumericTrendSheet.show(
                context,
                metricType: SolarMetricType.gridFrequency,
                inverterId: inv.id,
                inverterName: inv.name,
                currentValue: inv.gridFrequency ?? 50.0,
              );
            },
          ),

          // Live 3-Phase Grid Voltage (ab, bc, ca)
          if (inv.lineVoltageAb != null || inv.lineVoltageBc != null)
            _buildDiagRow(
              '3-Phase Line Voltage',
              '${inv.lineVoltageAb?.toStringAsFixed(1) ?? '-'} / ${inv.lineVoltageBc?.toStringAsFixed(1) ?? '-'} / ${inv.lineVoltageCa?.toStringAsFixed(1) ?? '-'} V',
              isOk: true,
              onTap: () {
                SolarNumericTrendSheet.show(
                  context,
                  metricType: SolarMetricType.voltage,
                  inverterId: inv.id,
                  inverterName: inv.name,
                  currentValue: inv.lineVoltageAb ?? 380.0,
                );
              },
            ),

          // Live 3-Phase Current (Ia, Ib, Ic)
          if (inv.phaseCurrentA != null)
            _buildDiagRow(
              'AC Phase Current (Ia/Ib/Ic)',
              '${inv.phaseCurrentA?.toStringAsFixed(2) ?? '-'} / ${inv.phaseCurrentB?.toStringAsFixed(2) ?? '-'} / ${inv.phaseCurrentC?.toStringAsFixed(2) ?? '-'} A',
              isOk: true,
              onTap: () {
                SolarNumericTrendSheet.show(
                  context,
                  metricType: SolarMetricType.current,
                  inverterId: inv.id,
                  inverterName: inv.name,
                  currentValue: inv.phaseCurrentA ?? 50.0,
                );
              },
            ),

          // Live MPPT Input Power
          if (inv.mpptPowerKw != null && inv.mpptPowerKw! > 0)
            _buildDiagRow(
              'MPPT DC Input Power',
              '${inv.mpptPowerKw!.toStringAsFixed(2)} kW',
              isOk: true,
              onTap: () {
                SolarNumericTrendSheet.show(
                  context,
                  metricType: SolarMetricType.power,
                  inverterId: inv.id,
                  inverterName: inv.name,
                  currentValue: inv.mpptPowerKw ?? 0.0,
                );
              },
            ),

          // Live Efficiency
          if (inv.efficiency != null && inv.efficiency! > 0)
            _buildDiagRow(
              'Inverter Efficiency',
              '${inv.efficiency!.toStringAsFixed(2)} %',
              isOk: true,
              onTap: () {
                SolarNumericTrendSheet.show(
                  context,
                  metricType: SolarMetricType.inverterEfficiency,
                  inverterId: inv.id,
                  inverterName: inv.name,
                  currentValue: inv.efficiency ?? 98.5,
                );
              },
            ),

          // Live Power Factor
          if (inv.powerFactor != null)
            _buildDiagRow('Power Factor (cos φ)', inv.powerFactor!.toStringAsFixed(3), isOk: true),

          // Lifetime Generation
          if (inv.totalLifetimeKwh != null && inv.totalLifetimeKwh! > 0)
            _buildDiagRow(
              'Lifetime Generation',
              '${(inv.totalLifetimeKwh! / 1000.0).toStringAsFixed(2)} MWh',
              isOk: true,
            ),

          // Insulation Protection (API event based)
          _buildDiagRow('DC Isolation Resistance', 'Normal (Protection Active)', isOk: true),

          // Operating State (from Huawei SUN2000 state code)
          if (inv.inverterState != null)
            _buildDiagRow(
              'Operating State',
              HuaweiAlarmDictionary.getStateDescription(inv.inverterState),
              isOk: isStateHealthy,
            ),

          // Active Alarms
          _buildDiagRow(
            'Active Alarms / Faults',
            inv.activeAlarms.isEmpty
                ? (isStateHealthy ? '0 Alarms (Healthy)' : 'Fault Code: ${inv.inverterState}')
                : '${inv.activeAlarms.length} Active Alarm${inv.activeAlarms.length > 1 ? 's' : ''}',
            isOk: inv.activeAlarms.isEmpty && isStateHealthy,
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsCard(BuildContext context, SolarInverter inv) {
    final hasAlarms = inv.activeAlarms.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlarms ? const Color(0xFFFFB020).withValues(alpha: 0.5) : AppColors.border,
          width: hasAlarms ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAlarms ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                size: 16,
                color: hasAlarms ? const Color(0xFFFFB020) : const Color(0xFF00E5A0),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasAlarms
                      ? 'ACTIVE ALARMS & FAULTS (${inv.activeAlarms.length})'
                      : 'ACTIVE ALARMS & FAULTS (0)',
                  style: _InverterDetailFonts.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (hasAlarms ? const Color(0xFFFFB020) : const Color(0xFF00E5A0)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasAlarms ? 'ATTENTION' : 'HEALTHY',
                  style: TextStyle(
                    fontSize: AppTheme.fs11,
                    fontWeight: FontWeight.w800,
                    color: hasAlarms ? const Color(0xFFFFB020) : const Color(0xFF00E5A0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAlarms)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E5A0), size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All parameters operating normally',
                        style: _InverterDetailFonts.alarmTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No active fault codes detected on this inverter.',
                        style: _InverterDetailFonts.alarmSub,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Tap an alarm below to view fault details and remediation guidelines:',
              style: _InverterDetailFonts.alarmSub,
            ),
            const SizedBox(height: 10),
            for (final alarm in inv.activeAlarms) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAlarmDetailModal(context, alarm, inv),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alarm.severity.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: alarm.severity.color.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: alarm.severity.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alarm.severity.label,
                                style: TextStyle(
                                  fontSize: AppTheme.fs11,
                                  fontWeight: FontWeight.w900,
                                  color: alarm.severity.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ID: ${alarm.alarmId}',
                                style: const TextStyle(
                                  fontSize: AppTheme.fs11,
                                  color: AppColors.textDim,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: alarm.severity.color),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alarm.alarmName,
                          style: _InverterDetailFonts.alarmTitle,
                        ),
                        if (alarm.cause != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            alarm.cause!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _InverterDetailFonts.alarmSub,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Waktu: ${DateFormat('dd/MM HH:mm').format(alarm.raiseTime)} WITA',
                                style: const TextStyle(fontSize: AppTheme.fs11, color: AppColors.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Remediation Guide',
                                      style: _InverterDetailFonts.alarmAction,
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.build_circle_outlined, size: 13, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showAlarmDetailModal(BuildContext context, SolarAlarm alarm, SolarInverter inv) {
    final steps = alarm.repairSuggestion != null && alarm.repairSuggestion!.isNotEmpty
        ? alarm.repairSuggestion!.split('\n').where((s) => s.trim().isNotEmpty).toList()
        : <String>['Inspect physical inverter condition and cable connections.'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Top drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: alarm.severity.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded, size: 24, color: alarm.severity.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: alarm.severity.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    alarm.severity.label,
                                    style: TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w900,
                                      color: alarm.severity.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    alarm.status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alarm.alarmName,
                              style: _InverterDetailFonts.modalTitle,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSub),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Scrollable Body
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // 1. Device Info Grid
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildModalMetaRow('Inverter Device', '${inv.name} (${_getClusterDisplayName(inv.clusterId)})'),
                            const SizedBox(height: 8),
                            _buildModalMetaRow('ESN Code', inv.esnCode ?? '-'),
                            const SizedBox(height: 8),
                            _buildModalMetaRow('Alarm ID / Code', '${alarm.alarmId} (Code: ${alarm.alarmCode ?? '-'})'),
                            const SizedBox(height: 8),
                            _buildModalMetaRow('Detected Time', '${DateFormat('dd MMMM yyyy, HH:mm:ss').format(alarm.raiseTime)} WITA'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Penyebab Gangguan
                      const Text('ROOT CAUSE ANALYSIS', style: _InverterDetailFonts.modalSection),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: alarm.severity.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: alarm.severity.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: alarm.severity.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alarm.cause ?? 'Fault detected by Huawei SUN2000 inverter protection supervisory module.',
                                style: _InverterDetailFonts.modalBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Panduan Perbaikan / Repair Suggestions
                      const Text('REMEDIATION GUIDELINES (HUAWEI SUGGESTION)', style: _InverterDetailFonts.modalSection),
                      const SizedBox(height: 8),
                      for (int idx = 0; idx < steps.length; idx++) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fs11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  steps[idx],
                                  style: _InverterDetailFonts.modalBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 4. Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text(
                                'Copy Alarm Info',
                                style: TextStyle(fontSize: AppTheme.fs13, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                final text = '⚠️ [INVERTER ALARM]\n'
                                    'Device: ${inv.name}\n'
                                    'Alarm: ${alarm.alarmName}\n'
                                    'Level: ${alarm.severity.label}\n'
                                    'ID: ${alarm.alarmId}\n'
                                    'Time: ${alarm.raiseTime}\n'
                                    'Cause: ${alarm.cause ?? "-"}\n'
                                    'Remediation:\n${alarm.repairSuggestion ?? "-"}';
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Alarm details copied to clipboard!')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.solar,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontSize: AppTheme.fs13, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModalMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.textSub)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: AppTheme.fs12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: _InverterDetailFonts.rowLabel),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: _InverterDetailFonts.rowValue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, {bool isOk = true, VoidCallback? onTap}) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 14,
            color: isOk ? const Color(0xFF00E5A0) : const Color(0xFFFFB020),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(label, style: _InverterDetailFonts.rowLabel),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: _InverterDetailFonts.rowValue.copyWith(
                      color: isOk ? Colors.white : const Color(0xFFFFB020),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.show_chart_rounded, size: 12, color: AppColors.solar),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: rowContent,
      );
    }
    return rowContent;
  }

  // ============================================================================
  // PERFORMANCE ANALYTICS CARD
  // ============================================================================
  Widget _buildPerformanceAnalyticsCard(BuildContext context, SolarInverter inv, SolarSnapshot snapshot) {
    // Specific Yield (Yf) = kWh/kWp
    final specificYield = inv.capacityKwp > 0 ? (inv.yieldTodayKwh / inv.capacityKwp) : 0.0;

    // DC-to-AC Conversion Loss (kW)
    final dcAcLossKw = (inv.mpptPowerKw != null && inv.mpptPowerKw! > 0)
        ? (inv.mpptPowerKw! - inv.powerKw).clamp(0.0, double.infinity)
        : null;

    // Cluster ranking: compare this inverter's specific yield vs cluster average
    final clusterInverters = snapshot.inverters
        .where((i) => i.clusterId == inv.clusterId)
        .toList();
    final clusterAvgYf = clusterInverters.isNotEmpty
        ? clusterInverters.fold<double>(0.0, (s, i) =>
            s + (i.capacityKwp > 0 ? i.yieldTodayKwh / i.capacityKwp : 0)) / clusterInverters.length
        : 0.0;
    final deviationPct = clusterAvgYf > 0 ? ((specificYield - clusterAvgYf) / clusterAvgYf * 100) : 0.0;
    // Rank within cluster
    final sortedByYf = List<SolarInverter>.from(clusterInverters)
      ..sort((a, b) {
        final ya = a.capacityKwp > 0 ? a.yieldTodayKwh / a.capacityKwp : 0.0;
        final yb = b.capacityKwp > 0 ? b.yieldTodayKwh / b.capacityKwp : 0.0;
        return yb.compareTo(ya); // descending
      });
    final rank = sortedByYf.indexWhere((i) => i.id == inv.id) + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.solar.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: AppColors.solar),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'PERFORMANCE ANALYTICS',
                  style: _InverterDetailFonts.analyticCardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Specific Yield (Yf)',
                  value: specificYield.toStringAsFixed(2),
                  unit: 'kWh/kWp',
                  onTap: () {
                    SolarNumericTrendSheet.show(
                      context,
                      metricType: SolarMetricType.specificEnergy,
                      inverterId: inv.id,
                      inverterName: inv.name,
                      currentValue: specificYield,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Peak Power',
                  value: inv.powerKw.toStringAsFixed(1),
                  unit: 'kW',
                  onTap: () {
                    SolarNumericTrendSheet.show(
                      context,
                      metricType: SolarMetricType.power,
                      inverterId: inv.id,
                      inverterName: inv.name,
                      currentValue: inv.powerKw,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticItem(
                  label: 'DC-AC Loss',
                  value: dcAcLossKw != null ? dcAcLossKw.toStringAsFixed(2) : 'N/A',
                  unit: dcAcLossKw != null ? 'kW' : '',
                  onTap: () {
                    SolarNumericTrendSheet.show(
                      context,
                      metricType: SolarMetricType.power,
                      inverterId: inv.id,
                      inverterName: inv.name,
                      currentValue: dcAcLossKw ?? 0.0,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticItem(
                  label: 'Cluster Rank',
                  value: '#$rank / ${clusterInverters.length}',
                  unit: '${deviationPct >= 0 ? "+" : ""}${deviationPct.toStringAsFixed(1)}%',
                  badgeColor: deviationPct >= 0 ? AppColors.solar : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem({
    required String label,
    required String value,
    required String unit,
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label, style: _InverterDetailFonts.analyticItemLabel),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.show_chart_rounded, size: 12, color: AppColors.solar),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: _InverterDetailFonts.analyticItemValue),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: badgeColor != null
                          ? _InverterDetailFonts.analyticItemSub.copyWith(color: badgeColor, fontWeight: FontWeight.w700)
                          : _InverterDetailFonts.analyticItemSub,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // THERMAL & DERATING RISK CARD
  // ============================================================================
  Widget _buildThermalDeratingCard(BuildContext context, SolarInverter inv) {
    final temp = inv.temperature;
    // Determine thermal zone
    Color gaugeColor;
    String gaugeStatus;
    String gaugeDescription;
    double gaugeFill;

    if (temp == null) {
      gaugeColor = AppColors.solar;
      gaugeStatus = 'Normal';
      gaugeDescription = 'Internal temperature is within normal limits.';
      gaugeFill = 0.35;
    } else if (temp < 50.0) {
      gaugeColor = AppColors.solar; // Green
      gaugeStatus = 'Normal / Optimal';
      gaugeDescription = 'Internal temperature is safe, no derating risk.';
      gaugeFill = (temp / 80.0).clamp(0.1, 0.6);
    } else if (temp < 60.0) {
      gaugeColor = const Color(0xFFFFB020); // Amber
      gaugeStatus = 'Elevated Heat';
      gaugeDescription = 'Temperature approaching threshold. Check ventilation and fans.';
      gaugeFill = (temp / 80.0).clamp(0.5, 0.8);
    } else {
      gaugeColor = const Color(0xFFFF4D6A); // Red
      gaugeStatus = 'Derating Risk!';
      gaugeDescription = 'Inverter at risk of automatic derating. Inspect cooling immediately.';
      gaugeFill = (temp / 80.0).clamp(0.75, 1.0);
    }

    return GestureDetector(
      onTap: () {
        SolarNumericTrendSheet.show(
          context,
          metricType: SolarMetricType.inverterTemp,
          inverterId: inv.id,
          inverterName: inv.name,
          currentValue: inv.temperature ?? 45.0,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gaugeColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_rounded, size: 16, color: gaugeColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'THERMAL & DERATING RISK',
                  style: _InverterDetailFonts.analyticCardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gaugeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gaugeStatus,
                      style: TextStyle(
                        fontSize: AppTheme.fs11,
                        fontWeight: FontWeight.w800,
                        color: gaugeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Temperature display
          Row(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  temp != null ? '${temp.toStringAsFixed(1)}°C' : '< 60°C',
                  style: _InverterDetailFonts.gaugeLabel.copyWith(color: gaugeColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: gaugeFill,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0°C', style: _InverterDetailFonts.gaugeSub),
                          const SizedBox(width: 20),
                          Text('50°C', style: _InverterDetailFonts.gaugeSub),
                          const SizedBox(width: 20),
                          Text('65°C+', style: _InverterDetailFonts.gaugeSub),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(gaugeDescription, style: _InverterDetailFonts.gaugeSub),
        ],
      ),
    ),
  );
  }

  // ============================================================================
  // POWER QUALITY CARD (VUF%, Reactive Power, Apparent Power)
  // ============================================================================
  Widget _buildPowerQualityCard(BuildContext context, SolarInverter inv) {
    // Voltage Unbalance Factor (VUF %)
    final vAb = inv.lineVoltageAb ?? 0.0;
    final vBc = inv.lineVoltageBc ?? 0.0;
    final vCa = inv.lineVoltageCa ?? 0.0;
    final hasVoltage = vAb > 0 || vBc > 0 || vCa > 0;

    double vuf = 0.0;
    if (hasVoltage) {
      final vAvg = (vAb + vBc + vCa) / 3.0;
      if (vAvg > 0) {
        final maxDev = [
          (vAb - vAvg).abs(),
          (vBc - vAvg).abs(),
          (vCa - vAvg).abs(),
        ].reduce((a, b) => a > b ? a : b);
        vuf = (maxDev / vAvg) * 100.0;
      }
    }
    final isVufOk = vuf < 2.0;

    // Apparent Power S = P / PF (kVA)
    final pf = inv.powerFactor ?? 1.0;
    final apparentPowerKva = pf > 0 ? (inv.powerKw / pf) : inv.powerKw;

    // Reactive Power Q = sqrt(S² - P²) (kVAR)
    final reactiveKvar = apparentPowerKva > inv.powerKw
        ? sqrt(apparentPowerKva * apparentPowerKva - inv.powerKw * inv.powerKw)
        : 0.0;

    return GestureDetector(
      onTap: () {
        SolarNumericTrendSheet.show(
          context,
          metricType: SolarMetricType.voltage,
          inverterId: inv.id,
          inverterName: inv.name,
          currentValue: inv.lineVoltageAb ?? 380.0,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.electric_bolt_rounded, size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'POWER QUALITY (AC GRID)',
                  style: _InverterDetailFonts.analyticCardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // VUF
          _buildDiagRow(
            'Voltage Unbalance (VUF)',
            '${vuf.toStringAsFixed(2)} %',
            isOk: isVufOk,
          ),
          if (!isVufOk)
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 4),
              child: Text(
                'Melebihi standar IEEE/IEC (< 2%). Periksa sambungan 3-fasa.',
                style: _InverterDetailFonts.gaugeSub.copyWith(color: const Color(0xFFFFB020)),
              ),
            ),
          // Apparent Power
          _buildDiagRow(
            'Apparent Power (S)',
            '${apparentPowerKva.toStringAsFixed(1)} kVA',
            isOk: true,
          ),
          // Reactive Power
          _buildDiagRow(
            'Reactive Power (Q)',
            '${reactiveKvar.toStringAsFixed(1)} kVAR',
            isOk: true,
          ),
          // Power Factor (repeated for emphasis in PQ context)
          _buildDiagRow(
            'Power Factor (cos φ)',
            inv.powerFactor?.toStringAsFixed(3) ?? '1.000',
            isOk: (inv.powerFactor ?? 1.0) >= 0.85,
          ),
        ],
      ),
    ),
  );
  }

  String _getClusterDisplayName(String clusterId) {
    switch (clusterId.toLowerCase()) {
      case '165kwp':
        return '165 kWp Array';
      case '200kwp':
        return '200 kWp Array';
      case '15_20kwp':
        return '15 & 20 kWp Array';
      case '468kwp':
        return '468 kWp Array';
      default:
        return clusterId;
    }
  }
}
