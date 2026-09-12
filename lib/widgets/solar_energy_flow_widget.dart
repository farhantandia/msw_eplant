import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/pages/weather_page.dart';

class SolarEnergyFlowWidget extends StatefulWidget {
  final SolarSnapshot snapshot;

  const SolarEnergyFlowWidget({
    super.key,
    required this.snapshot,
  });

  @override
  State<SolarEnergyFlowWidget> createState() => _SolarEnergyFlowWidgetState();
}

class _SolarEnergyFlowWidgetState extends State<SolarEnergyFlowWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SolarEnergyFlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Modulate speed based on live generation
    final kw = widget.snapshot.totalPowerKw;
    if (widget.snapshot.isNightTime || kw <= 0) {
      _animCtrl.duration = const Duration(milliseconds: 4000);
    } else if (kw > 800) {
      _animCtrl.duration = const Duration(milliseconds: 1200);
    } else {
      _animCtrl.duration = const Duration(milliseconds: 2000);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.snapshot.isNightTime;
    final totalKw = widget.snapshot.totalPowerKw;
    final irr = widget.snapshot.irradiance;
    final gridKw = widget.snapshot.gridExportKw;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(
          color: isNight ? const Color(0xFF1F2D45) : AppColors.solar.withValues(alpha: 0.4),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isNight
                ? Colors.transparent
                : AppColors.solar.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNight ? const Color(0xFF38BDF8) : const Color(0xFF00E5A0),
                  boxShadow: [
                    BoxShadow(
                      color: (isNight ? const Color(0xFF38BDF8) : const Color(0xFF00E5A0)).withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  isNight ? 'ENERGY FLOW \u00B7 NIGHT STANDBY' : 'REAL-TIME ENERGY FLOW',
                  style: TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isNight ? const Color(0xFF38BDF8) : AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Weather & Forecast',
                icon: isNight ? const Icon(Icons.nightlight_round, color: AppColors.primary) : const Icon(Icons.wb_sunny_outlined, color: AppColors.maintenance),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeatherPage()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Flow Nodes & Animated Stream
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Connecting Pipes
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _EnergyFlowStreamPainter(
                            progress: _animCtrl.value,
                            isNight: isNight,
                            hasPower: totalKw > 0,
                          ),
                        );
                      },
                    ),
                  ),

                  // 3 Nodes Row
                  Row(
                    children: [
                      // Node 1: Sun / Sky
                      Expanded(
                        child: _buildNode(
                          icon: isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          iconColor: isNight ? const Color(0xFF38BDF8) : const Color(0xFFFFB020),
                          title: isNight ? 'Moon / Sky' : 'Solar Irradiance',
                          subtitle: isNight ? '0.0 kWh/m²' : '${irr.toStringAsFixed(2)} kWh/m²',
                          accentColor: isNight ? const Color(0xFF38BDF8) : const Color(0xFFFFB020),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Node 2: Solar PV Plant (Inverters)
                      Expanded(
                        child: _buildNode(
                          icon: Icons.solar_power_rounded,
                          iconColor: AppColors.solar,
                          title: '${widget.snapshot.totalInverterCount} Inverters',
                          subtitle: isNight ? 'Standby' : '${totalKw.toStringAsFixed(1)} kW',
                          accentColor: AppColors.solar,
                          isCenterHero: true,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Node 3: Grid / Plant Bus
                      Expanded(
                        child: _buildNode(
                          icon: Icons.electric_bolt_rounded,
                          iconColor: const Color(0xFF00E5A0),
                          title: 'Grid & Aux',
                          subtitle: isNight ? '0 kW' : '${gridKw.toStringAsFixed(1)} kW',
                          accentColor: const Color(0xFF00E5A0),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // Footer Status
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    isNight ? '🌙 Standby mode' : '☀️ Inverting to Plant Grid',
                    style: TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w600,
                      color: isNight ? AppColors.textDim : const Color(0xFF00E5A0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color accentColor,
    bool isCenterHero = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF090E1A).withValues(alpha: 0.85),
        border: Border.all(
          color: isCenterHero ? accentColor.withValues(alpha: 0.6) : AppColors.border,
          width: isCenterHero ? 1.4 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isCenterHero)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTheme.fs11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fs12,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyFlowStreamPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  final bool hasPower;

  _EnergyFlowStreamPainter({
    required this.progress,
    required this.isNight,
    required this.hasPower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final leftX = size.width * 0.28;
    final rightX = size.width * 0.72;

    if (rightX <= leftX) return;

    // Background conduit pipe
    final pipePaint = Paint()
      ..color = const Color(0xFF1F2D45).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(leftX, centerY), Offset(rightX, centerY), pipePaint);

    if (isNight || !hasPower) {
      // Subtle stationary dotted pipe for standby
      return;
    }

    // Glowing energy flow line
    final flowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFB020), // Amber
          Color(0xFF00C2FF), // Cyan
          Color(0xFF00E5A0), // Green
        ],
      ).createShader(Rect.fromLTRB(leftX, 0, rightX, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(leftX, centerY), Offset(rightX, centerY), flowPaint);

    // Flowing Neon Particles
    final totalDist = rightX - leftX;
    final particlePaint = Paint()..style = PaintingStyle.fill;

    const particleCount = 5;
    for (int i = 0; i < particleCount; i++) {
      final pOffset = (progress + (i / particleCount)) % 1.0;
      final px = leftX + (pOffset * totalDist);

      // Gradient color based on position
      final color = Color.lerp(
        const Color(0xFF00C2FF),
        const Color(0xFF00E5A0),
        pOffset,
      )!;

      particlePaint.color = color.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(px, centerY), 3.5, particlePaint);

      // Outer glow
      particlePaint.color = color.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(px, centerY), 6.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyFlowStreamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isNight != isNight ||
        oldDelegate.hasPower != hasPower;
  }
}
