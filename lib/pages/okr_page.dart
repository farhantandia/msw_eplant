import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/okr_models.dart';
import 'package:msw_eplant/services/okr_service.dart';

class OkrPage extends StatefulWidget {
  const OkrPage({super.key});

  @override
  State<OkrPage> createState() => _OkrPageState();
}

class _OkrPageState extends State<OkrPage> {
  final _service = OkrService();

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final objectives = _service.currentObjectives;
    final overall = objectives.isEmpty ? 0.0 : objectives.fold<double>(0, (s, o) => s + o.progress) / objectives.length;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                _buildYearHeader(overall),
                const SizedBox(height: 10),
                ...objectives.map((obj) => _buildObjectiveCard(obj)),
                const SizedBox(height: 10),
                _buildLastUpdate(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset('asset/logo_login.png', width: 28, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OKR ${_service.currentYear}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const Text('Company Objectives & Key Results', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
            ],
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('\uD83D\uDD04', style: TextStyle(fontSize: 14))),
          ),
        ],
      ),
    );
  }

  Widget _buildYearHeader(double overall) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0x14FFFFFF), Color(0x0AC084FC)]),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PT Makmur Sejahtera Wisesa',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub),
                ),
                Text(
                  'AlamTri Geo \u00B7 ${_service.currentYear}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Overall Progress', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (overall / 100).clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.general]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${overall.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.general),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(Objective obj) {
    final color = _parseHex(obj.color);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: const BorderSide(color: AppColors.border),
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: color.withOpacity(0.15)),
                  child: Center(
                    child: Text(
                      '${obj.order}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    obj.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                ),
                Text(
                  '${obj.progress.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
          Container(
            height: 3,
            color: AppColors.border,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (obj.progress / 100).clamp(0, 1),
              child: Container(color: color),
            ),
          ),
          ...obj.keyResults.map((kr) => _buildKrItem(kr, color)),
        ],
      ),
    );
  }

  Widget _buildKrItem(KeyResult kr, Color objColor) {
    Color barColor;
    switch (kr.status) {
      case KrStatus.onTrack:
        barColor = AppColors.general;
        break;
      case KrStatus.atRisk:
        barColor = AppColors.maintenance;
        break;
      case KrStatus.behind:
        barColor = AppColors.danger;
        break;
      case KrStatus.na:
        barColor = AppColors.textDim;
        break;
    }

    String actualText;
    if (kr.type == KrType.qualitative) {
      actualText = 'Phase: ${kr.actualValue} \u00B7 Target: ${kr.target}';
    } else if (kr.type == KrType.binary) {
      actualText = 'Zero incident YTD \u2705';
    } else {
      actualText =
          'Aktual: ${kr.actualValue} \u00B7 Target: ${kr.target}${kr.targetUnit.isNotEmpty ? ' ${kr.targetUnit}' : ''}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x7F1F2D45))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.black.withOpacity(0.65),
                ),
                child: Center(
                  child: Text(
                    kr.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(kr.description, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (kr.progressPct / 100).clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${kr.progressPct.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: barColor),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.1),
                    border: Border.all(color: barColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${kr.status.icon} ${kr.status.label}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: barColor),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 3),
            child: Text(
              actualText,
              style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdate() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Terakhir diperbarui: 14 Jul 2026, 08:30 WIB \u00B7 oleh Admin MSW',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.textDim),
      ),
    );
  }
}
