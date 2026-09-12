import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/models/okr_models.dart';
import 'package:msw_eplant/widgets/role_strip.dart';
import 'package:msw_eplant/widgets/menu_grid.dart';

/// Test widget isolating the mini status card (Total Generation, 4-grid, Total House Load)
class TestMiniStatusCard extends StatelessWidget {
  final double u1Load;
  final double u2Load;
  final double plnLoad;
  final double aiLoad;
  final double? explicitHouseLoad;
  final String lastUpdate;
  final bool isLive;
  final int decimalPlaces;

  const TestMiniStatusCard({
    super.key,
    required this.u1Load,
    required this.u2Load,
    required this.plnLoad,
    required this.aiLoad,
    this.explicitHouseLoad,
    required this.lastUpdate,
    required this.isLive,
    this.decimalPlaces = 1,
  });

  @override
  Widget build(BuildContext context) {
    final double totalGross = (u1Load + u2Load).clamp(0.0, 999.0);
    final double totalNet = plnLoad + aiLoad;
    double houseLoad = explicitHouseLoad ?? 0.0;
    if (houseLoad <= 0.0 && totalGross > 0.0) {
      if (totalGross >= totalNet) {
        houseLoad = totalGross - totalNet;
      }
    }
    final double houseLoadPct = totalGross > 0 ? (houseLoad / totalGross * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Plant Status & Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLANT STATUS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (lastUpdate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Last update: $lastUpdate',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSub),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isLive ? AppColors.general : AppColors.danger).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isLive ? AppColors.general : AppColors.danger).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.general : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLive ? 'LIVE' : 'NOT UPDATED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isLive ? AppColors.general : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Gross Generation Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL GENERATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSub,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              totalGross.toStringAsFixed(decimalPlaces),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'MW (Gross)',
                              style: TextStyle(fontSize: 14, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (totalGross > 4.0 ? AppColors.general : AppColors.danger).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        totalGross > 4.0 ? 'Operating' : 'Low / Offline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: totalGross > 4.0 ? AppColors.general : AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4-item Grid: Unit 1, Unit 2, Load PLN, Load AI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metricCell(
                        label: 'Unit 1',
                        value: u1Load.toStringAsFixed(decimalPlaces),
                        unit: 'MW',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCell(
                        label: 'Unit 2',
                        value: u2Load.toStringAsFixed(decimalPlaces),
                        unit: 'MW',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _metricCell(
                        label: 'Load PLN',
                        value: plnLoad.toStringAsFixed(decimalPlaces),
                        unit: 'MW',
                        color: AppColors.general,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCell(
                        label: 'Load AI',
                        value: aiLoad.toStringAsFixed(decimalPlaces),
                        unit: 'MW',
                        color: AppColors.maintenance,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total House Load Highlight Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.purple.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.power_outlined,
                    size: 18,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL HOUSE LOAD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              houseLoad.toStringAsFixed(decimalPlaces),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'MW',
                              style: TextStyle(fontSize: 14, color: AppColors.textSub),
                            ),
                            if (houseLoadPct > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${houseLoadPct.toStringAsFixed(1)}% Aux)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 16, color: AppColors.text, letterSpacing: 0.4),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1),
                ),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Test widget isolating the NPHR card
class TestNphrCard extends StatelessWidget {
  final double nphr1;
  final double nphr2;
  final VoidCallback? onTap;

  const TestNphrCard({
    super.key,
    required this.nphr1,
    required this.nphr2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'NPHR (NET HEAT RATE)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kurva NPHR',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NPHR UNIT 1',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    nphr1 > 0 ? nphr1.toStringAsFixed(0) : '-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'kCal/kWh',
                                    style: TextStyle(fontSize: 14, color: AppColors.textSub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NPHR UNIT 2',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    nphr2 > 0 ? nphr2.toStringAsFixed(0) : '-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'kCal/kWh',
                                    style: TextStyle(fontSize: 14, color: AppColors.textSub),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}

/// Test widget isolating the weather strip
/// Test widget isolating the compact weather badge placed beside greeting
class TestWeatherBadge extends StatelessWidget {
  final String temp;
  final String desc;
  final VoidCallback? onTap;

  const TestWeatherBadge({
    super.key,
    required this.temp,
    required this.desc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.48,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$temp\u00B0C',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 13, color: AppColors.textDim),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tanjung \u2022 $desc',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


void main() {
  group('HomePage Overflow & Layout Verification', () {
    final screenSizes = [
      const Size(320, 640),  // Extra-compact screen (entry-level Android)
      const Size(360, 740),  // Standard Android
      const Size(390, 844),  // iPhone 14
      const Size(412, 915),  // Pixel 7
      const Size(600, 1024), // Tablet / Foldable
    ];

    final textScalers = [
      const TextScaler.linear(1.0),
      const TextScaler.linear(1.3),
      const TextScaler.linear(1.5),
    ];

    for (final size in screenSizes) {
      for (final scaler in textScalers) {
        testWidgets('Zero overflow on ${size.width}x${size.height} with scale ${scaler.scale(1.0)}',
            (WidgetTester tester) async {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: scaler,
                ),
                child: Scaffold(
                  backgroundColor: AppColors.bg,
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // Greeting and Weather Badge Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Selamat Malam,',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSub),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'MAINTENANCE',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const TestWeatherBadge(
                                temp: '32.5',
                                desc: 'Hujan deras disertai angin kencang dan petir di wilayah Tanjung',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini status card with realistic plant generation values
                        const TestMiniStatusCard(
                          u1Load: 26.4,
                          u2Load: 25.8,
                          plnLoad: 38.2,
                          aiLoad: 9.2,
                          lastUpdate: '05 Sep 2026, 20:00',
                          isLive: true,
                        ),
                        const SizedBox(height: 12),
                        // NPHR card
                        TestNphrCard(
                          nphr1: 2410,
                          nphr2: 2395,
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),
                        // MenuGrid with all items
                        MenuGrid(items: MenuGrid.forRole(UserRole.maintenance, {})),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // If any RenderFlex overflowed, tester.takeException() will catch it
          expect(tester.takeException(), isNull,
              reason: 'RenderFlex overflow occurred on size $size with scaler $scaler');

          // Verify text content is found
          expect(find.text('Selamat Malam,'), findsOneWidget);
          expect(find.text('MAINTENANCE'), findsOneWidget);
          expect(find.text('PLANT STATUS'), findsOneWidget);
          expect(find.text('TOTAL GENERATION'), findsOneWidget);
          expect(find.text('TOTAL HOUSE LOAD'), findsOneWidget);
          expect(find.text('NPHR (NET HEAT RATE)'), findsOneWidget);
          expect(find.text('Kurva NPHR'), findsOneWidget);
          expect(find.text('CFPP'), findsOneWidget);
          expect(find.text('Hazard Report'), findsOneWidget);

          // Reset physical size
          addTearDown(tester.view.resetPhysicalSize);
        });
      }
    }

    testWidgets('Total House Load calculates correctly with fallback and explicit values',
        (WidgetTester tester) async {
      // Test 1: Fallback calculation: Gross = 26.0 + 26.0 = 52.0 MW. Net = 38.0 + 9.0 = 47.0 MW.
      // House load = 52.0 - 47.0 = 5.0 MW (9.6% Aux)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestMiniStatusCard(
              u1Load: 26.0,
              u2Load: 26.0,
              plnLoad: 38.0,
              aiLoad: 9.0,
              lastUpdate: 'Live',
              isLive: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('(9.6% Aux)'), findsOneWidget);
      expect(find.text('52.0'), findsOneWidget); // Gross total
    });

    testWidgets('NphrCard tap callback triggers properly',
        (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestNphrCard(
              nphr1: 2450,
              nphr2: 2410,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kurva NPHR'));
      expect(tapped, isTrue);
    });

    testWidgets('MenuGrid cards have strictly uniform box height and width across all items',
        (WidgetTester tester) async {
      final items = MenuGrid.forRole(UserRole.maintenance, {});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MenuGrid(items: items),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all InkWell widgets (one per card)
      final inkWells = find.descendant(
        of: find.byType(MenuGrid),
        matching: find.byType(InkWell),
      );
      final count = inkWells.evaluate().length;
      expect(count, greaterThanOrEqualTo(7));

      final firstSize = tester.getSize(inkWells.at(0));
      expect(firstSize.height, equals(98.0));

      for (int i = 0; i < count; i++) {
        final size = tester.getSize(inkWells.at(i));
        expect(size.height, equals(98.0),
            reason: 'Card $i height (${size.height}) is not uniform with 98.0');
        expect(size.width, equals(firstSize.width),
            reason: 'Card $i width (${size.width}) is not uniform with first card (${firstSize.width})');
      }
    });

    testWidgets('MenuGrid uses professional vector IconData rather than text emojis',
        (WidgetTester tester) async {
      final items = MenuGrid.forRole(UserRole.maintenance, {});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MenuGrid(items: items),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify professional vector icons exist
      expect(find.byIcon(Icons.factory_outlined), findsOneWidget);
      expect(find.byIcon(Icons.solar_power_outlined), findsOneWidget);
      expect(find.byIcon(Icons.insights_outlined), findsNothing); // Removed from homepage per user request
      expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byIcon(Icons.track_changes_outlined), findsOneWidget);
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Verify no emojis are rendered
      expect(find.text('🏭'), findsNothing);
      expect(find.text('☀️'), findsNothing);
      expect(find.text('📊'), findsNothing);
      expect(find.text('⚠️'), findsNothing);
      expect(find.text('📦'), findsNothing);
      expect(find.text('🎯'), findsNothing);
      expect(find.text('🔧'), findsNothing);
      expect(find.text('🤖'), findsNothing);
    });

    testWidgets('MenuGrid tap callback fires on user tap',
        (WidgetTester tester) async {
      bool plantTapped = false;
      final items = MenuGrid.forRole(UserRole.operation, {
        'plant': () => plantTapped = true,
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MenuGrid(items: items),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CFPP'));
      expect(plantTapped, isTrue);
    });

    testWidgets('MenuGrid displays badge count cleanly',
        (WidgetTester tester) async {
      final items = MenuGrid.forRole(UserRole.maintenance, {});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MenuGrid(items: items),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('WeatherBadge beside greeting displays compact info and handles tap',
        (WidgetTester tester) async {
      bool weatherTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Selamat Pagi, OPERATOR'),
                  ),
                  TestWeatherBadge(
                    temp: '32.0',
                    desc: 'Cerah',
                    onTap: () => weatherTapped = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('32.0\u00B0C'), findsOneWidget);
      expect(find.text('Tanjung \u2022 Cerah'), findsOneWidget);

      await tester.tap(find.byType(TestWeatherBadge));
      expect(weatherTapped, isTrue);
    });

    test('All roles provide professional Material IconData', () {
      expect(UserRole.operation.iconData, Icons.bolt_rounded);
      expect(UserRole.maintenance.iconData, Icons.handyman_outlined);
      expect(UserRole.general.iconData, Icons.factory_outlined);
    });

    test('All OKR statuses provide professional Material IconData', () {
      expect(KrStatus.onTrack.iconData, Icons.check_circle_outline_rounded);
      expect(KrStatus.onProgress.iconData, Icons.sync_rounded);
      expect(KrStatus.behind.iconData, Icons.warning_amber_rounded);
    });

    testWidgets('RoleStrip renders Material Icons instead of raw emojis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: RoleStrip(
              role: UserRole.operation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for Icon widgets with correct IconData
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      // Verify no raw emojis rendered as Text
      expect(find.text('⚡'), findsNothing);
      expect(find.text('🔧'), findsNothing);
      expect(find.text('🏭'), findsNothing);
    });
  });
}


