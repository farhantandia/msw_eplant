import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/plant_overview_models.dart';

/// Animated SCADA Energy Flow Widget depicting power flow from:
/// Unit 1 & Unit 2 Generators -> Busbar 20kV/70kV -> PLN Grid 150kV, AI Industrial, & House Load.
class PlantEnergyFlowWidget extends StatefulWidget {
  final PlantOverviewSnapshot snapshot;
  final void Function(String nodeTitle, String columnName, String unit)? onOpenNodeChart;

  const PlantEnergyFlowWidget({
    super.key,
    required this.snapshot,
    this.onOpenNodeChart,
  });

  @override
  State<PlantEnergyFlowWidget> createState() => _PlantEnergyFlowWidgetState();
}

class _PlantEnergyFlowWidgetState extends State<PlantEnergyFlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final u1 = s.unit1;
    final u2 = s.unit2;

    final bool u1Active = (u1.grossLoad ?? 0) > 0;
    final bool u2Active = (u2.grossLoad ?? 0) > 0;
    final bool busbarActive = (s.totalLoad ?? 0) > 0;
    final bool plnActive = (s.loadToPln ?? 0) > 0;
    final bool aiActive = (s.loadToAi ?? 0) > 0;
    final bool hlActive = (s.totalHouseLoad ?? 0) > 0;
    final double busbarLoad = (s.totalLoad ?? 0) - (s.totalHouseLoad ?? 0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PLANT ENERGY FLOW DIAGRAM',
                        style: TextStyle(
                          fontSize: AppTheme.fs13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                   
                  ],
                ),
              ),
              
            ],
          ),

          const SizedBox(height: 14),

          // 1. GENERATOR ROW (Unit 1 & Unit 2)
          Row(
            children: [
              Expanded(
                child: _buildGeneratorNode(
                  title: 'UNIT 1 GENERATOR',
                  subtitle: '11 kV - BRUSH',
                  loadVal: u1.grossLoad,
                  condition: u1.condition,
                  isActive: u1Active,
                  onTap: () => _showNodeDetailDialog(
                    context,
                    title: 'Unit 1 Turbogenerator',
                    load: u1.grossLoad,
                    condition: u1.condition,
                    tmgcr: u1.tmgcr,
                    chartColumnName: 'UNIT 1 LOAD',
                    details: 'Unit 1 power generation with 11 kV synchronous generator connected to step-up transformer feeding the 20kV / 70kV Busbar.',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGeneratorNode(
                  title: 'UNIT 2 GENERATOR',
                  subtitle: '11 kV - BRUSH',
                  loadVal: u2.grossLoad,
                  condition: u2.condition,
                  isActive: u2Active,
                  onTap: () => _showNodeDetailDialog(
                    context,
                    title: 'Unit 2 Turbogenerator',
                    load: u2.grossLoad,
                    condition: u2.condition,
                    tmgcr: u2.tmgcr,
                    chartColumnName: 'UNIT 2 LOAD',
                    details: 'Unit 2 power generation with 11 kV synchronous generator connected to step-up transformer feeding the 20kV / 70kV Busbar.',
                  ),
                ),
              ),
            ],
          ),

          // 2. INFLOW CONDUITS ANIMATION (U1 & U2 -> Busbar & Trafo 11/6.6kV)
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 32),
                painter: _InflowPipesPainter(
                  progress: _animCtrl.value,
                  u1Active: u1Active,
                  u2Active: u2Active,
                  hlActive: hlActive,
                ),
              );
            },
          ),

          // 3. CENTRAL NODES ROW (Busbar 20kV / 70kV & Trafo 11kV / 6.6kV)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildBusbarNode(
                    totalLoad: busbarLoad,
                    isActive: busbarActive,
                    onTap: () => _showNodeDetailDialog(
                      context,
                      title: 'MSW Power Busbar 20kV / 70kV',
                      load: busbarLoad,
                      condition: busbarActive ? UnitOperatingCondition.normal : UnitOperatingCondition.shutdown,
                      chartColumnName: 'TOTAL LOAD',
                      details: 'MSW Tanjung commercial export busbar system (20kV / 70kV) aggregating generation from Unit 1 and Unit 2, distributing to the PLN 70kV transmission line and PT Adaro Indonesia 20kV feeder.',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _buildTrafoNode(
                    isActive: hlActive,
                    onTap: () => _showNodeDetailDialog(
                      context,
                      title: 'Trafo 11kV / 6.6kV (Unit Aux Transformer)',
                      load: s.totalHouseLoad,
                      condition: hlActive ? UnitOperatingCondition.normal : UnitOperatingCondition.shutdown,
                      chartColumnName: 'TOTAL HOUSE LOAD',
                      details: 'Unit Auxiliary Transformer (UAT) connected directly to the 11 kV generator bus, stepping down voltage to 6.6 kV to supply internal plant auxiliary systems (House Load: BFP, ID Fan, FD Fan, CWP, ESP, and Water Treatment).',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. OUTFLOW CONDUITS ANIMATION (Busbar -> PLN & AI; Trafo 11/6.6kV -> House Load)
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 36),
                painter: _OutflowPipesPainter(
                  progress: _animCtrl.value,
                  plnActive: plnActive,
                  aiActive: aiActive,
                  hlActive: hlActive,
                ),
              );
            },
          ),

          // 5. LOAD / FEEDER DESTINATIONS ROW
          Row(
            children: [
              // PLN Export (Grid 70kV)
              Expanded(
                child: _buildDestinationNode(
                  title: 'PLN GRID',
                  feeder: '70 kV Interconnection',
                  val: s.loadToPln,
                  unit: 'MW',
                  accentColor: const Color(0xFF00C2FF),
                  icon: Icons.electrical_services_rounded,
                  isActive: plnActive,
                  onTap: () => _showNodeDetailDialog(
                    context,
                    title: 'PLN 70 kV Grid Interconnection',
                    load: s.loadToPln,
                    condition: plnActive ? UnitOperatingCondition.normal : UnitOperatingCondition.shutdown,
                    chartColumnName: 'LOAD TO PLN',
                    details: 'Commercial electricity export to PLN substation through the 70 kV transmission line under the Power Purchase Agreement (PPA).',
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // AI Industrial (Export 20kV)
              Expanded(
                child: _buildDestinationNode(
                  title: 'PT AI FEEDER',
                  feeder: 'Industrial Dedicated 20 kV',
                  val: s.loadToAi,
                  unit: 'MW',
                  accentColor: const Color(0xFFF59E0B),
                  icon: Icons.precision_manufacturing_rounded,
                  isActive: aiActive,
                  onTap: () => _showNodeDetailDialog(
                    context,
                    title: 'PT AI Dedicated Feeder',
                    load: s.loadToAi,
                    condition: aiActive ? UnitOperatingCondition.normal : UnitOperatingCondition.shutdown,
                    chartColumnName: 'LOAD TO AI',
                    details: 'Dedicated power distribution for PT AI industrial operations via 20 kV feeder directly from the plant switchyard and remote substation.',
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // House Load (Auxiliary from Trafo 11kV/6.6kV)
              Expanded(
                child: _buildDestinationNode(
                  title: 'HOUSE LOAD',
                  feeder: 'Trafo 11kV / 6.6kV',
                  val: s.totalHouseLoad,
                  unit: 'MW',
                  extraSubtitle: s.houseLoadPct != null ? '${s.houseLoadPct!.toStringAsFixed(1)}% Gross' : null,
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.home_repair_service_rounded,
                  isActive: hlActive,
                  onTap: () => _showNodeDetailDialog(
                    context,
                    title: 'Total House Load (Trafo 11kV / 6.6kV)',
                    load: s.totalHouseLoad,
                    condition: hlActive ? UnitOperatingCondition.normal : UnitOperatingCondition.shutdown,
                    chartColumnName: 'TOTAL HOUSE LOAD',
                    details: 'Internal power consumed by auxiliary plant systems (BFP, ID Fan, FD Fan, Coal Handling, Water Treatment Plant, and control systems) stepped down via Trafo 11kV / 6.6kV directly from the 11 kV generator bus.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildGeneratorNode({
    required String title,
    required String subtitle,
    required double? loadVal,
    required UnitOperatingCondition condition,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final statusColor = isActive ? condition.color : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? statusColor.withValues(alpha: 0.6) : AppColors.border,
            width: isActive ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: statusColor.withValues(alpha: 0.12),
                blurRadius: 8,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTheme.fs12,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.text : AppColors.textSub,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDim,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    PlantOverviewSnapshot.formatVal(loadVal, decimals: 1),
                    style: TextStyle(
                      fontSize: AppTheme.fs20,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.text : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'MW',
                    style: TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? statusColor : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      condition.shortLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusbarNode({
    required double? totalLoad,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final busbarColor = isActive ? const Color(0xFF38BDF8) : AppColors.border;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F2238).withValues(alpha: 0.8),
              const Color(0xFF132D4C).withValues(alpha: 0.9),
              const Color(0xFF0F2238).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: busbarColor.withValues(alpha: 0.85),
            width: 1.8,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.hub_rounded,
                size: 16,
                color: Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BUSBAR 20kV / 70kV',
                      style: TextStyle(
                        fontSize: AppTheme.fs12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Commercial Export (PLN & AI)',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        PlantOverviewSnapshot.formatVal(totalLoad, decimals: 1),
                        style: const TextStyle(
                          fontSize: AppTheme.fs18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'MW',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total Gross',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDim,
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

  Widget _buildTrafoNode({
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const accentColor = Color(0xFF10B981);
    final trafoBorderColor = isActive ? accentColor : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF062A20).withValues(alpha: 0.8),
              const Color(0xFF0B3A2C).withValues(alpha: 0.9),
              const Color(0xFF062A20).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: trafoBorderColor.withValues(alpha: 0.85),
            width: 1.8,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.change_circle_outlined,
                    size: 14,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TRAFO AUX',
                      style: TextStyle(
                        fontSize: AppTheme.fs11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '11kV ➔ 6.6kV',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 1),
            const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Step-down UAT',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textDim,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationNode({
    required String title,
    required String feeder,
    required double? val,
    required String unit,
    String? extraSubtitle,
    required Color accentColor,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? accentColor.withValues(alpha: 0.5) : AppColors.border,
            width: isActive ? 1.2 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 6,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isActive ? accentColor : AppColors.textDim,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTheme.fs11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.text : AppColors.textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              feeder,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textDim,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    style: TextStyle(
                      fontSize: AppTheme.fs17,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.text : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? accentColor : AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (extraSubtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                extraSubtitle,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNodeDetailDialog(
    BuildContext context, {
    required String title,
    required double? load,
    required UnitOperatingCondition condition,
    double? tmgcr,
    String? chartColumnName,
    required String details,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTheme.fs15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: condition.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: condition.color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          condition.label,
                          style: TextStyle(
                            fontSize: AppTheme.fs11,
                            fontWeight: FontWeight.w800,
                            color: condition.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dialogStatItem(
                          'Current Load',
                          PlantOverviewSnapshot.formatVal(load, suffix: ' MW'),
                          AppColors.primary,
                        ),
                        if (tmgcr != null)
                          _dialogStatItem(
                            'TMGCR Rating',
                            PlantOverviewSnapshot.formatVal(tmgcr, suffix: ' MW'),
                            const Color(0xFF38BDF8),
                          ),
                        _dialogStatItem(
                          'Status',
                          condition.shortLabel,
                          condition.color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: AppTheme.fs12,
                      color: AppColors.textSub,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.onOpenNodeChart != null && chartColumnName != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.show_chart_rounded, size: 16),
                        label: const Text('OPEN HISTORICAL TREND'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onOpenNodeChart!(title, chartColumnName, 'MW');
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('CLOSE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textDim),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fs15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// --- ANIMATION PAINTERS ---

/// Paints conduits and animated energy pulses from U1 & U2 down into the Central Busbar & Trafo 11kV/6.6kV
class _InflowPipesPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool u1Active;
  final bool u2Active;
  final bool hlActive;

  _InflowPipesPainter({
    required this.progress,
    required this.u1Active,
    required this.u2Active,
    required this.hlActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Generators anchor X positions (approx centers of left & right cards)
    final double u1X = w * 0.25;
    final double u2X = w * 0.75;

    // Middle row layout:
    // flex 7 (busbar) + spacing 8 + flex 4 (trafo) = 11 parts
    final double busbarRight = (w - 8) * (7 / 11);
    final double trafoLeft = busbarRight + 8;
    final double trafoCenter = trafoLeft + (w - trafoLeft) / 2;

    // Busbar infeed targets:
    final double busbarInfeedU1 = busbarRight * 0.35;
    final double busbarInfeedU2 = busbarRight * 0.75;

    final basePaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final auxBasePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Static pipe paths
    final pathU1 = Path()
      ..moveTo(u1X, 0)
      ..cubicTo(u1X, h * 0.5, busbarInfeedU1, h * 0.5, busbarInfeedU1, h);

    final pathU2 = Path()
      ..moveTo(u2X, 0)
      ..cubicTo(u2X, h * 0.5, busbarInfeedU2, h * 0.5, busbarInfeedU2, h);

    // Path 11kV generator branch to Trafo 11kV / 6.6kV
    final pathTrafo = Path()
      ..moveTo(u2X, 0)
      ..cubicTo(u2X, h * 0.4, trafoCenter, h * 0.4, trafoCenter, h);

    canvas.drawPath(pathU1, basePaint);
    canvas.drawPath(pathU2, basePaint);
    canvas.drawPath(pathTrafo, auxBasePaint);

    // Animated pulses if active
    if (u1Active) {
      _drawEnergyPulsesOnPath(canvas, pathU1, progress, AppColors.general);
    }
    if (u2Active) {
      _drawEnergyPulsesOnPath(canvas, pathU2, progress, AppColors.general);
    }
    if (hlActive && (u1Active || u2Active)) {
      _drawEnergyPulsesOnPath(canvas, pathTrafo, progress, const Color(0xFF10B981));
    }
  }

  void _drawEnergyPulsesOnPath(Canvas canvas, Path path, double t, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;

    final pulsePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    const int pulseCount = 3;
    for (int i = 0; i < pulseCount; i++) {
      final double distance = ((t + (i / pulseCount)) % 1.0) * length;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3.5, pulsePaint);
        // Inner bright dot
        canvas.drawCircle(tangent.position, 1.8, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InflowPipesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.u1Active != u1Active ||
        oldDelegate.u2Active != u2Active ||
        oldDelegate.hlActive != hlActive;
  }
}

/// Paints conduits and animated energy pulses from Central Busbar to PLN & AI, and Trafo 11kV/6.6kV to House Load
class _OutflowPipesPainter extends CustomPainter {
  final double progress;
  final bool plnActive;
  final bool aiActive;
  final bool hlActive;

  _OutflowPipesPainter({
    required this.progress,
    required this.plnActive,
    required this.aiActive,
    required this.hlActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Middle row layout:
    final double busbarRight = (w - 8) * (7 / 11);
    final double trafoLeft = busbarRight + 8;
    final double trafoCenter = trafoLeft + (w - trafoLeft) / 2;

    // Bottom destinations anchor positions (approx centers of 3 columns)
    final double colWidth = (w - 16) / 3;
    final double plnX = colWidth * 0.5;
    final double aiX = colWidth + 8 + colWidth * 0.5;
    final double hlX = (colWidth + 8) * 2 + colWidth * 0.5;

    final basePaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final auxBasePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Path from Busbar 20kV / 70kV -> PLN GRID (70kV)
    final pathPln = Path()
      ..moveTo(plnX, 0)
      ..lineTo(plnX, h);

    // Path from Busbar 20kV / 70kV -> PT AI FEEDER (20kV)
    final pathAi = Path()
      ..moveTo(aiX, 0)
      ..lineTo(aiX, h);

    // Path from TRAFO 11kV / 6.6kV -> HOUSE LOAD (6.6kV)
    final pathHl = Path()
      ..moveTo(trafoCenter, 0)
      ..lineTo(hlX, h);

    canvas.drawPath(pathPln, basePaint);
    canvas.drawPath(pathAi, basePaint);
    canvas.drawPath(pathHl, auxBasePaint);

    if (plnActive) {
      _drawEnergyPulsesOnPath(canvas, pathPln, progress, const Color(0xFF00C2FF));
    }
    if (aiActive) {
      _drawEnergyPulsesOnPath(canvas, pathAi, progress, const Color(0xFFF59E0B));
    }
    if (hlActive) {
      _drawEnergyPulsesOnPath(canvas, pathHl, progress, const Color(0xFF10B981));
    }
  }

  void _drawEnergyPulsesOnPath(Canvas canvas, Path path, double t, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;

    final pulsePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    const int pulseCount = 3;
    for (int i = 0; i < pulseCount; i++) {
      final double distance = ((t + (i / pulseCount)) % 1.0) * length;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3.5, pulsePaint);
        // Inner bright dot
        canvas.drawCircle(tangent.position, 1.8, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OutflowPipesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.plnActive != plnActive ||
        oldDelegate.aiActive != aiActive ||
        oldDelegate.hlActive != hlActive;
  }
}
