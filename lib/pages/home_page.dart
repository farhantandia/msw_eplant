import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/pages/maintenance_page.dart';
import 'package:msw_eplant/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/services/weather_service.dart';
import 'package:msw_eplant/pages/weather_page.dart';
import 'package:msw_eplant/pages/plant_page.dart';
import 'package:msw_eplant/pages/analytics_page.dart';
import 'package:msw_eplant/pages/okr_page.dart';
import 'package:msw_eplant/pages/logsheet/logsheet_page.dart';
import 'package:msw_eplant/widgets/role_strip.dart';
import 'package:msw_eplant/widgets/menu_grid.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  final UserRole role;
  final VoidCallback onSwitchRole;

  const HomePage({super.key, required this.role, required this.onSwitchRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weatherData;

  final DatabaseReference _table1Ref = FirebaseDatabase.instance.ref("excel_data/table1");
  final DatabaseReference _table2Ref = FirebaseDatabase.instance.ref("excel_data/table2");
  final DatabaseReference _nphrRef = FirebaseDatabase.instance.ref("excel_data/nphr");
  final DatabaseReference _cems1Ref = FirebaseDatabase.instance.ref("excel_data/cems1");
  final DatabaseReference _cems2Ref = FirebaseDatabase.instance.ref("excel_data/cems2");
  StreamSubscription? _t1Sub, _t2Sub, _nphrSub, _c1Sub, _c2Sub;

  List<List> _table1Data = [];
  List<List> _table2Data = [];
  List<List> _nphrData = [];
  List<List> _cems1Data = [];
  List<List> _cems2Data = [];
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
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadWeather();
    _setupStreams();
  }

  @override
  void dispose() {
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
    _t1Sub = _table1Ref.onValue.listen((e) => _onData(e, (v) => _table1Data = v));
    _t2Sub = _table2Ref.onValue.listen((e) => _onData(e, (v) => _table2Data = v));
    _nphrSub = _nphrRef.onValue.listen((e) => _onData(e, (v) => _nphrData = v));
    _c1Sub = _cems1Ref.onValue.listen((e) => _onData(e, (v) => _cems1Data = v));
    _c2Sub = _cems2Ref.onValue.listen((e) => _onData(e, (v) => _cems2Data = v));
  }

  void _onData(event, Function(List<List>) setter) {
    if (event.snapshot.value == null) return;
    final values = _parseToList(event.snapshot.value);
    if (values.length > 1 && mounted) {
      setState(() {
        setter(values);
        _checkLoading();
       
    final rawString = _table1Data.last[0].toString();
  _lastUpdate = formatDateTime(rawString);

  _lastUpdateRaw = DateTime.tryParse(rawString)?.toLocal();
  if (_lastUpdateRaw != null) {
    final diff = DateTime.now().difference(_lastUpdateRaw!);
    _isLive = diff.inMinutes < 60; // < 1 jam dianggap LIVE
  } else {
    _isLive = false;
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
    final idx = header.indexOf(label);
    if (idx != -1 && idx < record.length) {
      return double.tryParse(record[idx].toString()) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roleColor(widget.role.label);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat pagi' : (hour < 17 ? 'Selamat siang' : 'Selamat malam');
    final roleName = widget.role == UserRole.operation
        ? 'Operator Shift I'
        : widget.role == UserRole.maintenance
        ? 'Maintenance Engineer!'
        : 'Guest / Karyawan MSW';
    final shiftInfo = widget.role == UserRole.operation
        ? 'Shift I \u00B7 07:00\u201315:00'
        : widget.role == UserRole.maintenance
        ? '12 Jun 2026'
        : 'View only';

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
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(color),
                RoleStrip(role: widget.role, subtitle: shiftInfo),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
                      const SizedBox(height: 2),
                      Text(
                        roleName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                if (_loadingData)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else ...[
                  _buildWeatherWidget(),
                  const SizedBox(height: 12),
                  _buildMiniStatus(),
                  const SizedBox(height: 16),
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
    );
  }

  Widget _buildTopBar(Color roleColor) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, left: 16, right: 16, bottom: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('asset/logo_login.png', width: 34, height: 34, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Text(
            'MSW ePlant',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
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
          //       child: const Center(child: Text('\uD83D\uDD14', style: TextStyle(fontSize: 14))),
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

  Widget _buildMiniStatus() {
    double u1Load = _getVal(_t1Header, _t1Last, "UNIT 1 LOAD");
    double u2Load = _getVal(_t2Header, _t2Last, "UNIT 2 LOAD");
    double plnLoad = _getVal(_t1Header, _t1Last, "LOAD TO PLN");
    double aiLoad = _getVal(_t1Header, _t1Last, "LOAD TO AI");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
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
                    if (_lastUpdate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Last update: $_lastUpdate',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSub),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: _isLive ? AppColors.general : AppColors.danger, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                     Text(
                      _isLive ? 'LIVE' : 'NOT UPDATED',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: _isLive ? AppColors.general : AppColors.danger, // opsional: warna beda saat tidak update
  ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.0,
            children: [
              _miniCell('Unit 1', '${u1Load.toStringAsFixed(_decimalPlaces)}', 'MW', AppColors.primary),
              _miniCell('Unit 2', '${u2Load.toStringAsFixed(_decimalPlaces)}', 'MW', AppColors.primary),
              _miniCell('Load PLN', '${plnLoad.toStringAsFixed(_decimalPlaces)}', 'MW', AppColors.general),
              _miniCell('Load AI', '${aiLoad.toStringAsFixed(_decimalPlaces)}', 'MW', AppColors.maintenance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCell(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.1)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 18, color: AppColors.text, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
            ],
          ),
        ],
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/$icon@2x.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, size: 30, color: Colors.amber),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temp\u00B0C Tanjung, S.Kal',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                Text('$desc (Tap for detail)', style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 0.6),
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
      ).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka form. Silakan coba lagi.')));
    }
  }

  Widget _buildMenuGrid() {
    final nav = <String, VoidCallback>{
      'plant': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantPage())),
      // 'cems': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CemsPage())),
      'solar': () => _showComingSoon('Solar PV'),
      'analytics': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage())),
      'hazard': () => _openHazardReport(),
      'warehouse': () => _showComingSoon('Warehouse'),
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
        backgroundColor: Colors.black.withOpacity(0.65),
      ),
    );
  }
}
