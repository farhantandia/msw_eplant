import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/pages/maintenance/maintenance_page.dart';
import 'package:msw_eplant/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/services/weather_service.dart';
import 'package:msw_eplant/pages/weather_page.dart';
import 'package:msw_eplant/pages/plant_page.dart';
import 'package:msw_eplant/pages/analytics_page.dart';
import 'package:msw_eplant/pages/okr/okr_page.dart';
import 'package:msw_eplant/pages/nphr_page.dart';
import 'package:msw_eplant/pages/chart_page.dart';
import 'package:msw_eplant/pages/logsheet/logsheet_page.dart';
import 'package:msw_eplant/pages/warehouse/warehouse_page.dart';
import 'package:msw_eplant/widgets/menu_grid.dart';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_service.dart';
import 'package:msw_eplant/pages/solarpv/solar_detail_page.dart';
import 'package:msw_eplant/pages/plant/plant_overview_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final UserRole role;
  final VoidCallback onSwitchRole;

  const HomePage({super.key, required this.role, required this.onSwitchRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weatherData;

  DatabaseReference? _overviewRef;
  DatabaseReference? _table1Ref;
  DatabaseReference? _table2Ref;
  DatabaseReference? _nphrRef;
  DatabaseReference? _cems1Ref;
  DatabaseReference? _cems2Ref;
  StreamSubscription? _overviewSub, _t1Sub, _t2Sub, _nphrSub, _c1Sub, _c2Sub;

  List<List> _overviewData = [];
  List<List> _table1Data = [];
  List<List> _table2Data = [];
  List<List> _nphrData = [];
  List<List> _cems1Data = [];
  List<List> _cems2Data = [];
  List<String> get _overviewHeader =>
      _overviewData.isNotEmpty ? _overviewData.first.cast<String>() : [];
  List get _overviewLast => _overviewData.length > 1 ? _overviewData.last : [];
  List<String> get _t1Header =>
      _table1Data.isNotEmpty ? _table1Data.first.cast<String>() : [];
  List<String> get _t2Header =>
      _table2Data.isNotEmpty ? _table2Data.first.cast<String>() : [];
  List get _t1Last => _table1Data.length > 1 ? _table1Data.last : [];
  List get _t2Last => _table2Data.length > 1 ? _table2Data.last : [];
  bool _loadingData = true;
  int _decimalPlaces = 1;
  String _lastUpdate = '';
  DateTime? _lastUpdateRaw;
  
  bool _isLive = false;
  final PageController _plantPageCtrl = PageController();
  int _activePlantIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadWeather();
    _setupStreams();
    FusionSolarService.instance.init();
  }

  @override
  void dispose() {
    _plantPageCtrl.dispose();
    _overviewSub?.cancel();
    _t1Sub?.cancel();
    _t2Sub?.cancel();
    _nphrSub?.cancel();
    _c1Sub?.cancel();
    _c2Sub?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _decimalPlaces = prefs.getInt('decimal_places') ?? 1);
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.fetchWeather();
    if (mounted) setState(() => _weatherData = data);
  }

  void _setupStreams() {
    try {
      final rtdb = FirebaseDatabase.instance;
      _overviewRef = rtdb.ref("excel_data/overview");
      _table1Ref = rtdb.ref("excel_data/table1");
      _table2Ref = rtdb.ref("excel_data/table2");
      _nphrRef = rtdb.ref("excel_data/nphr");
      _cems1Ref = rtdb.ref("excel_data/cems1");
      _cems2Ref = rtdb.ref("excel_data/cems2");

      _overviewSub = _overviewRef?.onValue.listen((e) => _onData(e, (v) => _overviewData = v));
      _t1Sub = _table1Ref?.onValue.listen((e) => _onData(e, (v) => _table1Data = v));
      _t2Sub = _table2Ref?.onValue.listen((e) => _onData(e, (v) => _table2Data = v));
      _nphrSub = _nphrRef?.onValue.listen((e) => _onData(e, (v) => _nphrData = v));
      _c1Sub = _cems1Ref?.onValue.listen((e) => _onData(e, (v) => _cems1Data = v));
      _c2Sub = _cems2Ref?.onValue.listen((e) => _onData(e, (v) => _cems2Data = v));
    } catch (e) {
      debugPrint("Firebase RTDB stream setup skipped: $e");
      _loadingData = false;
    }
  }

  void _onData(event, Function(List<List>) setter) {
    if (event.snapshot.value == null) return;
    final values = _parseToList(event.snapshot.value);
    if (values.length > 1 && mounted) {
      setState(() {
        setter(values);
        _checkLoading();

        final dateList = _table1Data.length > 1 && _table1Data.last.isNotEmpty
            ? _table1Data
            : (_table2Data.length > 1 && _table2Data.last.isNotEmpty ? _table2Data : null);
        if (dateList != null) {
          final rawString = dateList.last[0].toString();
          _lastUpdate = formatDateTime(rawString);

          _lastUpdateRaw = DateTime.tryParse(rawString)?.toLocal();
          if (_lastUpdateRaw != null) {
            final diff = DateTime.now().difference(_lastUpdateRaw!);
            _isLive = diff.inMinutes < 60; // < 1 jam dianggap LIVE
          } else {
            _isLive = false;
          }
        }
      });
    }
  }

  List<List> _parseToList(dynamic data) {
    if (data is List) return List<List>.from(data.map((e) => List.from(e)));
    if (data is Map) return List<List>.from(data.values.map((e) => List.from(e)));
    return [];
  }

  void _checkLoading() {
    if (_table1Data.length > 1 &&
        _table2Data.length > 1 &&
        _nphrData.length > 1 &&
        _cems1Data.length > 1 &&
        _cems2Data.length > 1) {
      _loadingData = false;
    }
  }

  Future<void> _handleRefresh() async {
    await _loadWeather();
    await _loadSettings();
  }

  double _getVal(List<String> header, List record, String label) {
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

  void _openChart({
    required String columnName,
    required int columnIndex,
    required List<String> header,
    required List<dynamic> fullData,
    required String unit,
    double? thresholdValue,
  }) {
    if (fullData.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No telemetry data available for trend')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartPage(
          columnName: columnName,
          columnIndex: columnIndex,
          header: header,
          fullData: fullData,
          unit: unit,
          date: _lastUpdate,
          thresholdValue: thresholdValue,
        ),
      ),
    );
  }

  void _openTotalGenerationChart() {
    if (_table1Data.length <= 1) return;
    final u1Idx = _t1Header.indexOf("UNIT 1 LOAD");
    int u2Idx = _t2Header.indexOf("UNIT 2 LOAD");
    if (u2Idx == -1) {
      u2Idx = _t2Header.indexWhere((h) => h.trim().toUpperCase() == "UNIT 2 LOAD");
    }
    if (u2Idx == -1) {
      u2Idx = _t2Header.indexWhere((h) {
        final s = h.trim().toUpperCase();
        return s == "UNIT2 LOAD" || s == "LOAD" || (s.contains("UNIT 2") && s.contains("LOAD"));
      });
    }

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
    _openChart(
      columnName: 'TOTAL GENERATION',
      columnIndex: 1,
      header: ['DATETIME', 'TOTAL GENERATION'],
      fullData: fullData,
      unit: 'MW',
    );
  }

  void _openHouseLoadChart() {
    if (_overviewData.length > 1) {
      int ovHlIdx = _overviewHeader.indexOf("TOTAL HOUSE LOAD");
      if (ovHlIdx == -1) ovHlIdx = _overviewHeader.indexOf("HOUSE LOAD");
      if (ovHlIdx != -1) {
        _openChart(
          columnName: 'TOTAL HOUSE LOAD',
          columnIndex: ovHlIdx,
          header: _overviewHeader,
          fullData: _overviewData,
          unit: 'MW',
        );
        return;
      }
    }

    if (_table1Data.length <= 1) return;
    int hlIdx = _t1Header.indexOf("TOTAL HOUSE LOAD");
    if (hlIdx == -1) hlIdx = _t1Header.indexOf("HOUSE LOAD");

    if (hlIdx != -1) {
      _openChart(
        columnName: 'TOTAL HOUSE LOAD',
        columnIndex: hlIdx,
        header: _t1Header,
        fullData: _table1Data,
        unit: 'MW',
      );
      return;
    }

    final u1Idx = _t1Header.indexOf("UNIT 1 LOAD");
    int u2Idx = _t2Header.indexOf("UNIT 2 LOAD");
    if (u2Idx == -1) {
      u2Idx = _t2Header.indexWhere((h) => h.trim().toUpperCase() == "UNIT 2 LOAD");
    }
    if (u2Idx == -1) {
      u2Idx = _t2Header.indexWhere((h) {
        final s = h.trim().toUpperCase();
        return s == "UNIT2 LOAD" || s == "LOAD" || (s.contains("UNIT 2") && s.contains("LOAD"));
      });
    }
    final plnIdx = _t1Header.indexOf("LOAD TO PLN");
    final aiIdx = _t1Header.indexOf("LOAD TO AI");

    List<dynamic> fullData = [
      ['DATETIME', 'TOTAL HOUSE LOAD']
    ];
    for (int i = 1; i < _table1Data.length; i++) {
      final dtStr = _table1Data[i][0].toString();
      final u1 = (u1Idx != -1 && u1Idx < _table1Data[i].length)
          ? (double.tryParse(_table1Data[i][u1Idx].toString()) ?? 0.0)
          : 0.0;
      final u2 = (i < _table2Data.length && u2Idx != -1 && u2Idx < _table2Data[i].length)
          ? (double.tryParse(_table2Data[i][u2Idx].toString()) ?? 0.0)
          : 0.0;
      final pln = (plnIdx != -1 && plnIdx < _table1Data[i].length)
          ? (double.tryParse(_table1Data[i][plnIdx].toString()) ?? 0.0)
          : 0.0;
      final ai = (aiIdx != -1 && aiIdx < _table1Data[i].length)
          ? (double.tryParse(_table1Data[i][aiIdx].toString()) ?? 0.0)
          : 0.0;
      final gross = u1 + u2;
      final net = pln + ai;
      final hl = (gross >= net) ? (gross - net) : 0.0;
      fullData.add([dtStr, hl]);
    }
    _openChart(
      columnName: 'TOTAL HOUSE LOAD',
      columnIndex: 1,
      header: ['DATETIME', 'TOTAL HOUSE LOAD'],
      fullData: fullData,
      unit: 'MW',
    );
  }

  void _openUnit1Chart() {
    final idx = _t1Header.indexOf("UNIT 1 LOAD");
    if (idx != -1 && _table1Data.length > 1) {
      _openChart(
        columnName: 'UNIT 1 LOAD',
        columnIndex: idx,
        header: _t1Header,
        fullData: _table1Data,
        unit: 'MW',
      );
    }
  }

  void _openUnit2Chart() {
    if (_table2Data.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Unit 2 telemetry data available for trend')),
      );
      return;
    }

    int idx = _t2Header.indexOf("UNIT 2 LOAD");
    if (idx == -1) {
      idx = _t2Header.indexWhere((h) => h.trim().toUpperCase() == "UNIT 2 LOAD");
    }
    if (idx == -1) {
      idx = _t2Header.indexWhere((h) {
        final s = h.trim().toUpperCase();
        return s == "UNIT2 LOAD" || s == "LOAD" || (s.contains("UNIT 2") && s.contains("LOAD"));
      });
    }
    if (idx == -1) {
      idx = _t2Header.indexWhere((h) {
        final s = h.trim().toUpperCase();
        return s.contains("LOAD") || s.contains("MW") || s.contains("GROSS");
      });
    }
    if (idx == -1 && _t2Header.isNotEmpty) {
      idx = _t2Header.length > 1 ? 1 : 0;
    }

    bool firstColIsDate = false;
    try {
      final sample = _table2Data[1][0].toString();
      firstColIsDate = DateTime.tryParse(sample) != null ||
          DateTime.tryParse(sample.replaceAll(' ', 'T')) != null;
    } catch (_) {}

    List<dynamic> fullData;
    if (firstColIsDate && idx != -1) {
      fullData = _table2Data;
      _openChart(
        columnName: 'UNIT 2 LOAD',
        columnIndex: idx,
        header: _t2Header,
        fullData: fullData,
        unit: 'MW',
      );
    } else {
      fullData = [
        ['DATETIME', 'UNIT 2 LOAD']
      ];
      final targetIdx = idx != -1 ? idx : 0;
      for (int i = 1; i < _table2Data.length; i++) {
        String dtStr;
        if (i < _table1Data.length && _table1Data[i].isNotEmpty) {
          dtStr = _table1Data[i][0].toString();
        } else {
          dtStr = DateTime.now().subtract(Duration(hours: _table2Data.length - i)).toIso8601String();
        }
        final row = _table2Data[i];
        double val = 0.0;
        if (targetIdx < row.length) {
          val = double.tryParse(row[targetIdx].toString()) ?? 0.0;
        } else if (row.isNotEmpty) {
          val = double.tryParse(row.last.toString()) ?? 0.0;
        }
        fullData.add([dtStr, val]);
      }

      _openChart(
        columnName: 'UNIT 2 LOAD',
        columnIndex: 1,
        header: ['DATETIME', 'UNIT 2 LOAD'],
        fullData: fullData,
        unit: 'MW',
      );
    }
  }

  void _openPlnLoadChart() {
    if (_overviewData.length > 1) {
      final idx = _overviewHeader.indexOf("LOAD TO PLN");
      if (idx != -1) {
        _openChart(
          columnName: 'LOAD TO PLN',
          columnIndex: idx,
          header: _overviewHeader,
          fullData: _overviewData,
          unit: 'MW',
        );
        return;
      }
    }
    final idx = _t1Header.indexOf("LOAD TO PLN");
    if (idx != -1 && _table1Data.length > 1) {
      _openChart(
        columnName: 'LOAD TO PLN',
        columnIndex: idx,
        header: _t1Header,
        fullData: _table1Data,
        unit: 'MW',
      );
    }
  }

  void _openAiLoadChart() {
    if (_overviewData.length > 1) {
      final idx = _overviewHeader.indexOf("LOAD TO AI");
      if (idx != -1) {
        _openChart(
          columnName: 'LOAD TO AI',
          columnIndex: idx,
          header: _overviewHeader,
          fullData: _overviewData,
          unit: 'MW',
        );
        return;
      }
    }
    final idx = _t1Header.indexOf("LOAD TO AI");
    if (idx != -1 && _table1Data.length > 1) {
      _openChart(
        columnName: 'LOAD TO AI',
        columnIndex: idx,
        header: _t1Header,
        fullData: _table1Data,
        unit: 'MW',
      );
    }
  }

  void _openNphrChart(int unitNum) {
    if (_nphrData.length <= 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NphrPage()));
      return;
    }
    final colIdx = unitNum == 1 ? 0 : 1;
    final colName = 'NPHR UNIT $unitNum';

    bool firstColIsDate = false;
    try {
      DateTime.parse(_nphrData[1][0].toString());
      firstColIsDate = true;
    } catch (_) {}

    List<dynamic> fullData;
    if (firstColIsDate) {
      fullData = _nphrData;
    } else {
      fullData = [
        ['DATETIME', colName]
      ];
      for (int i = 1; i < _nphrData.length; i++) {
        String dtStr;
        if (i < _table1Data.length && _table1Data[i].isNotEmpty) {
          dtStr = _table1Data[i][0].toString();
        } else {
          dtStr = DateTime.now().subtract(Duration(hours: _nphrData.length - i)).toIso8601String();
        }
        final row = _nphrData[i];
        double val = 0.0;
        if (colIdx < row.length) {
          val = double.tryParse(row[colIdx].toString()) ?? 0.0;
        }
        fullData.add([dtStr, val]);
      }
    }

    _openChart(
      columnName: colName,
      columnIndex: firstColIsDate ? colIdx : 1,
      header: ['DATETIME', colName],
      fullData: fullData,
      unit: 'kCal/kWh',
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roleColor(widget.role.label);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final roleName = widget.role == UserRole.operation
        ? 'Plant Operator!'
        : widget.role == UserRole.maintenance
        ? 'Maintenance Engineer!'
        : 'MSW Warrior';
   

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pinned Appbar & Greeting Header (Non-scrolling)
            _buildFixedHeader(color, greeting, roleName),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loadingData)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        )
                      else ...[
                        _buildPlantCarousel(),
                        const SizedBox(height: 10),
                        _buildSectionLabel('Menu'),
                        const SizedBox(height: 8),
                        _buildMenuGrid(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader(Color roleColor, String greeting, String roleName) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: topPadding + 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(roleColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(fontSize: AppTheme.fs13, color: AppColors.textSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleName,
                        style: const TextStyle(fontSize: AppTheme.fs15, fontWeight: FontWeight.w800, color: AppColors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildWeatherWidget(),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
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
        ],
      ),
    );
  }

  Widget _buildTopBar(Color roleColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('asset/logo_login.png', width: 34, height: 34, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Text(
            'MSW ePlant',
            style: TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const Spacer(),
          // Stack(
          //   children: [
          //     Container(
          //       width: 34,
          //       height: 34,
          //       decoration: BoxDecoration(
          //         color: Colors.black.withOpacity(0.65),
          //         border: Border.all(color: AppColors.border),
          //         borderRadius: BorderRadius.circular(9),
          //       ),
          //       child: const Center(child: Text('\uD83D\uDD14', style: TextStyle(fontSize: AppTheme.fs14))),
          //     ),
          //     Positioned(
          //       top: 4,
          //       right: 4,
          //       child: Container(
          //         width: 8,
          //         height: 8,
          //         decoration: BoxDecoration(
          //           color: AppColors.danger,
          //           shape: BoxShape.circle,
          //           border: Border.all(color: AppColors.bg, width: 1.5),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildPlantCarousel() {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final carouselHeight = (350.0 * (textScale > 1.0 ? textScale.clamp(1.0, 1.25) : 1.0)).clamp(350.0, 420.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView(
            controller: _plantPageCtrl,
            onPageChanged: (idx) {
              if (mounted) setState(() => _activePlantIndex = idx);
            },
            children: [
              // Slide 0: CFPP 2x30MW (Mini Status + NPHR Card)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniStatus(),
                  const SizedBox(height: 5),
                  _buildNphrCard(),
                ],
              ),

              // Slide 1: Solar PV Plant (868 kWp: MSW 400 + Kelanis 468)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSolarPlantCard(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildPlantCarouselDots(),
      ],
    );
  }

  Widget _buildPlantCarouselDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _buildDot(0, 'CFPP 2x30MW')),
          const SizedBox(width: 8),
          Flexible(child: _buildDot(1, 'SOLAR PV 868 kWp')),
        ],
      ),
    );
  }

  Widget _buildDot(int index, String label) {
    final isSelected = _activePlantIndex == index;
    final dotAccent = index == 1 ? AppColors.solar : AppColors.primary;
    return GestureDetector(
      onTap: () {
        _plantPageCtrl.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? dotAccent.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? dotAccent.withValues(alpha: 0.6) : AppColors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSelected ? 8 : 6,
              height: isSelected ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? dotAccent : AppColors.textDim,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: dotAccent.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: AppTheme.fs12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? dotAccent : AppColors.textDim,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarPlantCard() {
    return ValueListenableBuilder<SolarSnapshot>(
      valueListenable: FusionSolarService.instance.snapshotNotifier,
      builder: (context, solar, _) {
        final isNight = solar.isNightTime;
        final msw = solar.mswSnapshot;
        final kelanis = solar.kelanisSnapshot;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            border: Border.all(
              color: isNight
                  ? const Color(0xFF1F2D45)
                  : AppColors.solar.withValues(alpha: 0.45),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isNight
                    ? Colors.transparent
                    : AppColors.solar.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SolarDetailPage(initialPlant: 'msw')),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header: Solar PV Status & Live Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isNight ? Icons.nightlight_round : Icons.solar_power_rounded,
                                    size: 15,
                                    color: isNight ? const Color(0xFF38BDF8) : AppColors.solar,
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'SOLAR PV PLANT STATUS',
                                        style: TextStyle(
                                          fontSize: AppTheme.fs14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Capacity 868 kWp \u00B7 ${DateFormat("dd MMM yyyy, HH:mm").format(solar.timestamp)}',
                                style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.textSub),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isNight ? const Color(0xFF38BDF8) : AppColors.general).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (isNight ? const Color(0xFF38BDF8) : AppColors.general).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isNight ? const Color(0xFF38BDF8) : AppColors.general,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isNight ? 'STANDBY' : 'LIVE',
                                style: TextStyle(
                                  fontSize: AppTheme.fs11,
                                  fontWeight: FontWeight.w700,
                                  color: isNight ? const Color(0xFF38BDF8) : AppColors.general,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Total Generation Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
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
                                    'TOTAL SOLAR GENERATION',
                                    style: TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSub,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        solar.effectiveYieldTodayKwh.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: AppTheme.fs22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.text,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'kWh Today',
                                        style: TextStyle(
                                          fontSize: AppTheme.fs12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.solar,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isNight ? const Color(0xFF38BDF8) : AppColors.solar).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isNight ? const Color(0xFF38BDF8) : AppColors.solar).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              isNight ? '0 kW Idle' : '${solar.totalPowerKw.toStringAsFixed(0)} kW Live',
                              style: TextStyle(
                                fontSize: AppTheme.fs12,
                                fontWeight: FontWeight.w800,
                                color: isNight ? const Color(0xFF38BDF8) : AppColors.solar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Two Plant Badges (MSW 400 kWp & Kelanis 468 kWp) side-by-side
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        // Plant MSW
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SolarDetailPage(initialPlant: 'msw')),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.solar.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          'PLTS MSW',
                                          style: TextStyle(
                                            fontSize: AppTheme.fs11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.solar,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.solar.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '400 kWp',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.solar),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isNight ? '0.0 kW' : '${msw.totalPowerKw.toStringAsFixed(1)} kW',
                                    style: const TextStyle(fontSize: AppTheme.fs15, fontWeight: FontWeight.w900, color: AppColors.text),
                                  ),
                                  Text(
                                    '${msw.effectiveYieldTodayKwh < 10 ? msw.effectiveYieldTodayKwh.toStringAsFixed(1) : msw.effectiveYieldTodayKwh.toStringAsFixed(0)} kWh \u00B7 ${msw.onlineInverterCount}/${msw.totalInverterCount} Online',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Plant Kelanis
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SolarDetailPage(initialPlant: 'kelanis')),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          'PLTS KELANIS',
                                          style: TextStyle(
                                            fontSize: AppTheme.fs11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFFB300),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '468 kWp',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFFFB300)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isNight ? '0.0 kW' : '${kelanis.totalPowerKw.toStringAsFixed(1)} kW',
                                    style: const TextStyle(fontSize: AppTheme.fs15, fontWeight: FontWeight.w900, color: AppColors.text),
                                  ),
                                  Text(
                                    '${kelanis.effectiveYieldTodayKwh < 10 ? kelanis.effectiveYieldTodayKwh.toStringAsFixed(1) : kelanis.effectiveYieldTodayKwh.toStringAsFixed(0)} kWh \u00B7 ${kelanis.onlineInverterCount}/${kelanis.totalInverterCount} Online',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Metric Cells (MSW Irr, MSW PR, Kelanis Irr, Kelanis PR)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        _solarMetricCell(
                          title: 'MSW Irr',
                          val: msw.irradiance.toStringAsFixed(2),
                          unit: 'kWh/m\u00B2',
                          color: const Color(0xFFFFB020),
                        ),
                        const SizedBox(width: 5),
                        _solarMetricCell(
                          title: 'MSW PR',
                          val: msw.performanceRatio.toStringAsFixed(1),
                          unit: '%',
                          color: AppColors.general,
                        ),
                        const SizedBox(width: 5),
                        _solarMetricCell(
                          title: 'Kelanis Irr',
                          val: kelanis.irradiance.toStringAsFixed(2),
                          unit: 'kWh/m\u00B2',
                          color: const Color(0xFFFFB020),
                        ),
                        const SizedBox(width: 5),
                        _solarMetricCell(
                          title: 'Kelanis PR',
                          val: kelanis.performanceRatio.toStringAsFixed(1),
                          unit: '%',
                          color: AppColors.general,
                        ),
                      ],
                    ),
                  ),

                  // 5. Bottom Energy Flow Indicator
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface2.withValues(alpha: 0.35),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isNight
                                ? 'Night Standby (0 kW Grid)'
                                : '${solar.gridExportKw.toStringAsFixed(1)} kW Injected to Grid',
                            style: const TextStyle(fontSize: AppTheme.fs12, fontWeight: FontWeight.w700, color: AppColors.text),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${solar.houseLoadOffsetPct.toStringAsFixed(1)}% House Load',
                          style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w800, color: AppColors.general),
                        ),
                      ],
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

  Widget _solarMetricCell({
    required String title,
    required String val,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.4),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                val,
                style: const TextStyle(fontSize: AppTheme.fs17, fontWeight: FontWeight.w900, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                unit,
                style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: AppColors.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMiniStatus() {
    final double u1Load = _getVal(_t1Header, _t1Last, "UNIT 1 LOAD");
    final double u2Load = _getVal(_t2Header, _t2Last, "UNIT 2 LOAD");
    final double totalGross = (u1Load + u2Load).clamp(0.0, 999.0);

    // Read PLN and AI from overview first, fallback to table1
    double plnLoad = _getVal(_overviewHeader, _overviewLast, "LOAD TO PLN");
    if (plnLoad == 0.0) {
      plnLoad = _getVal(_t1Header, _t1Last, "LOAD TO PLN");
    }
    double aiLoad = _getVal(_overviewHeader, _overviewLast, "LOAD TO AI");
    if (aiLoad == 0.0) {
      aiLoad = _getVal(_t1Header, _t1Last, "LOAD TO AI");
    }
    final double totalNet = plnLoad + aiLoad;

    // Read House Load from overview first, fallback to table1
    double houseLoad = _getVal(_overviewHeader, _overviewLast, "TOTAL HOUSE LOAD");
    if (houseLoad <= 0.0) {
      houseLoad = _getVal(_overviewHeader, _overviewLast, "HOUSE LOAD");
    }
    if (houseLoad <= 0.0) {
      houseLoad = _getVal(_t1Header, _t1Last, "TOTAL HOUSE LOAD");
    }
    if (houseLoad <= 0.0) {
      houseLoad = _getVal(_t1Header, _t1Last, "HOUSE LOAD");
    }
    if (houseLoad <= 0.0 && totalGross > 0.0) {
      if (totalGross >= totalNet) {
        houseLoad = totalGross - totalNet;
      }
    }
    final double houseLoadPct = totalGross > 0 ? (houseLoad / totalGross * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Plant Status & Live indicator (Tappable to PlantOverviewDetailPage)
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlantOverviewDetailPage()),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.factory_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'PLANT STATUS',
                                  style: TextStyle(
                                    fontSize: AppTheme.fs14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _lastUpdate.isNotEmpty
                              ? 'Capacity 2x30 MW \u00B7 $_lastUpdate'
                              : 'Capacity 2x30 MW \u00B7 Unit 1 & 2',
                          style: const TextStyle(fontSize: AppTheme.fs12, color: AppColors.textSub),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_isLive ? AppColors.general : AppColors.danger).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (_isLive ? AppColors.general : AppColors.danger).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isLive ? AppColors.general : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLive ? 'LIVE' : 'NOT UPDATED',
                          style: TextStyle(
                            fontSize: AppTheme.fs11,
                            fontWeight: FontWeight.w700,
                            color: _isLive ? AppColors.general : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total Gross Generation Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: _openTotalGenerationChart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'GENERATION',
                                  style: TextStyle(
                                    fontSize: AppTheme.fs11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSub,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      totalGross.toStringAsFixed(_decimalPlaces),
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.08),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: _openHouseLoadChart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'TOTAL HOUSE LOAD',
                                  style: TextStyle(
                                    fontSize: AppTheme.fs11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSub,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      houseLoad.toStringAsFixed(_decimalPlaces),
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
                                    if (houseLoadPct > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${houseLoadPct.toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                          fontSize: AppTheme.fs11,
                                          color: AppColors.textSub,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4-item Metric Row (Unit 1, Unit 2, Load PLN, Load AI) in 1 row of 4 columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                _metricCell(
                  label: 'Unit 1',
                  value: u1Load.toStringAsFixed(_decimalPlaces),
                  unit: 'MW',
                  color: AppColors.primary,
                  onTap: _openUnit1Chart,
                ),
                const SizedBox(width: 5),
                _metricCell(
                  label: 'Unit 2',
                  value: u2Load.toStringAsFixed(_decimalPlaces),
                  unit: 'MW',
                  color: AppColors.primary,
                  onTap: _openUnit2Chart,
                ),
                const SizedBox(width: 5),
                _metricCell(
                  label: 'Load PLN',
                  value: plnLoad.toStringAsFixed(_decimalPlaces),
                  unit: 'MW',
                  color: AppColors.general,
                  onTap: _openPlnLoadChart,
                ),
                const SizedBox(width: 5),
                _metricCell(
                  label: 'Load AI',
                  value: aiLoad.toStringAsFixed(_decimalPlaces),
                  unit: 'MW',
                  color: AppColors.maintenance,
                  onTap: _openAiLoadChart,
                ),
              ],
            ),
          ),

          // Bottom Energy Export / Efficiency Indicator
          Container(
            margin: const EdgeInsets.fromLTRB(8, 2, 8, 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface2.withValues(alpha: 0.35),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Net Output: ${totalNet.toStringAsFixed(_decimalPlaces)} MW',
                    style: const TextStyle(fontSize: AppTheme.fs12, fontWeight: FontWeight.w700, color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(totalGross > 0 ? (totalNet / totalGross * 100) : 0).toStringAsFixed(1)}% Export',
                  style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w800, color: AppColors.general),
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
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: AppTheme.fs17, fontWeight: FontWeight.w900, color: AppColors.text),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    unit,
                    style: const TextStyle(fontSize: AppTheme.fs11, fontWeight: FontWeight.w600, color: AppColors.textDim),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNphrCard() {
    double nphr1 = 0.0;
    double nphr2 = 0.0;
    if (_nphrData.length > 1 && _nphrData.last.isNotEmpty) {
      nphr1 = double.tryParse(_nphrData.last[0].toString())?.clamp(0, double.infinity) ?? 0.0;
      if (_nphrData.last.length > 1) {
        nphr2 = double.tryParse(_nphrData.last[1].toString())?.clamp(0, double.infinity) ?? 0.0;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NphrPage()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.primary, size: 15),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'NET PLANT HEAT RATE',
                          style: TextStyle(
                            fontSize: AppTheme.fs12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NPHR Curve',
                              style: TextStyle(
                                fontSize: AppTheme.fs11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 13, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openNphrChart(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'UNIT 1',
                                style: TextStyle(
                                  fontSize: AppTheme.fs11,
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
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
                                    nphr1 > 0 ? nphr1.toStringAsFixed(0) : '-',
                                    style: const TextStyle(
                                      fontSize: AppTheme.fs18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'kCal/kWh',
                                    style: TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openNphrChart(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'UNIT 2',
                                style: TextStyle(
                                  fontSize: AppTheme.fs11,
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
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
                                    nphr2 > 0 ? nphr2.toStringAsFixed(0) : '-',
                                    style: const TextStyle(
                                      fontSize: AppTheme.fs18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'kCal/kWh',
                                    style: TextStyle(
                                      fontSize: AppTheme.fs11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildWeatherWidget() {
    String temp = "32.0";
    String desc = "Cerah";
    String icon = "01d";
    if (_weatherData != null) {
      try {
        temp = _weatherData!['main']['temp'].toStringAsFixed(_decimalPlaces);
        desc = _weatherData!['weather'][0]['main'];
        icon = _weatherData!['weather'][0]['icon'];
      } catch (_) {}
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.48,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage())),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/$icon.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, size: 20, color: Colors.amber),
                ),
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
                                fontSize: AppTheme.fs13,
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
                          fontSize: AppTheme.fs11,
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
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 0.6),
      ),
    );
  }

  Future<void> _openHazardReport() async {
    final url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSfI2lnY6aPm7mfI9eN0Rpw1e3XjKVuvXlUzBik-g-gZZNgLvw/viewform',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open form. Please try again.')));
    }
  }

  Widget _buildMenuGrid() {
    final nav = <String, VoidCallback>{
      'cfpp': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantOverviewDetailPage())),
      'plant': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantOverviewDetailPage())),
      // 'cems': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CemsPage())),
      'solar': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarDetailPage())),
      'analytics': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage())),
      'hazard': () => _openHazardReport(),
      'warehouse': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehousePage())),
      'okr': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OkrPage())),
    };
    if (widget.role == UserRole.maintenance) {
      nav['maintenance'] = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenancePage()));
      nav['ai'] = () => _showComingSoon('MSW AI');
    }
    if (widget.role == UserRole.operation) {
      nav['logsheet'] = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsheetPage()));
    }
    final items = MenuGrid.forRole(widget.role, nav);
    return MenuGrid(items: items);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature \u2014 dalam pengembangan', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withValues(alpha: 0.65),
      ),
    );
  }
}
