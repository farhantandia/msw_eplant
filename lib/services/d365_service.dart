import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/models/warehouse_item.dart';
import 'package:msw_eplant/models/material_issue_model.dart';
import 'package:msw_eplant/models/work_order_model.dart';
import 'package:msw_eplant/models/d365_user_model.dart';

class D365Service {
  static const String _keyHistory = 'd365_material_issue_history';
  static const String _keyCustomStock = 'd365_custom_stock_map';
  static const String _keyApiUrl = 'd365_api_base_url';
  static const String _keyActiveWOCache = 'd365_active_work_orders_cache';
  static const String _keyD365UserSession = 'd365_user_session_v1';

  // Seed master data PLTU MSW
  static final List<WarehouseItem> _seedCatalog = [
    WarehouseItem(
      itemNumber: '01.001.001.0004',
      itemName: 'BEARING 6204-2RS C3 SKF',
      description: 'Deep groove ball bearing 20x47x14mm',
      unitType: 'PCS',
      availableStock: 24.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-A2 / BIN-04',
    ),
    WarehouseItem(
      itemNumber: '01.001.001.0005',
      itemName: 'BEARING 6309-2Z/C3 SKF',
      description: 'Deep groove ball bearing 45x100x25mm',
      unitType: 'PCS',
      availableStock: 12.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-A2 / BIN-05',
    ),
    WarehouseItem(
      itemNumber: '01.002.001.0012',
      itemName: 'MECHANICAL SEAL TYPE B-35MM',
      description: 'Mechanical seal for CWP pump shaft 35mm',
      unitType: 'SET',
      availableStock: 6.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-B1 / BIN-02',
    ),
    WarehouseItem(
      itemNumber: '01.003.001.0001',
      itemName: 'SYNTHETIC GEAR OIL ISO VG 320',
      description: 'Lubricant oil for coal mill gearbox',
      unitType: 'LTR',
      availableStock: 150.0,
      defaultWarehouse: 'OILSTORE',
      defaultLocation: 'LUBE-DRUM-03',
    ),
    WarehouseItem(
      itemNumber: '01.004.001.0020',
      itemName: 'HEX BOLT M16 X 70MM SS316',
      description: 'Stainless steel hexagon bolt with nut & washer',
      unitType: 'PCS',
      availableStock: 80.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-C3 / BIN-11',
    ),
    WarehouseItem(
      itemNumber: '01.005.001.0008',
      itemName: 'SPIRAL WOUND GASKET 3 INCH 150#',
      description: 'Flange gasket graphite filler SS304 inner ring',
      unitType: 'PCS',
      availableStock: 35.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-C1 / BIN-08',
    ),
    WarehouseItem(
      itemNumber: '01.006.001.0002',
      itemName: 'PRESSURE TRANSMITTER 0-25 BAR',
      description: 'Output 4-20mA HART protocol 1/2 inch NPT',
      unitType: 'UNIT',
      availableStock: 4.0,
      defaultWarehouse: 'MAINWORK',
      defaultLocation: 'RAK-E1 / BIN-01',
    ),
    WarehouseItem(
      itemNumber: '01.007.001.0015',
      itemName: 'OIL FILTER ELEMENT 10 MICRON',
      description: 'Hydraulic lube filter element cartridge',
      unitType: 'PCS',
      availableStock: 18.0,
      defaultWarehouse: 'MAINSTORE',
      defaultLocation: 'RAK-D2 / BIN-03',
    ),
    WarehouseItem(
      itemNumber: '01.008.001.0003',
      itemName: 'MCB 3 POLE 32A 10KA SCHNEIDER',
      description: 'Miniature circuit breaker 3P 32A C-curve',
      unitType: 'PCS',
      availableStock: 10.0,
      defaultWarehouse: 'MAINWORK',
      defaultLocation: 'RAK-E2 / BIN-05',
    ),
    WarehouseItem(
      itemNumber: '01.009.001.0001',
      itemName: 'HIGH TEMP GREASE EP2',
      description: 'Lithium complex grease extreme pressure',
      unitType: 'KG',
      availableStock: 45.0,
      defaultWarehouse: 'OILSTORE',
      defaultLocation: 'RAK-L1 / BIN-01',
    ),
  ];

  /// Format standard string ke format XX.XXX.XXX.XXXX
  static String formatItemNumber(String input) {
    String clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';

    StringBuffer sb = StringBuffer();
    for (int i = 0; i < clean.length && i < 12; i++) {
      if (i == 2 || i == 5 || i == 8) {
        sb.write('.');
      }
      sb.write(clean[i]);
    }
    return sb.toString();
  }

  /// Cek stok item ke D365 (via API atau Mock Master Data)
  static Future<WarehouseItem?> checkItemStock(String rawItemNumber) async {
    final cleanInput = rawItemNumber.trim();
    if (cleanInput.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final customApiUrl = prefs.getString(_keyApiUrl);

    // 1. Jika ada endpoint live D365 yang diset
    if (customApiUrl != null && customApiUrl.isNotEmpty) {
      try {
        final url = Uri.parse('$customApiUrl/items/$cleanInput');
        final response =
            await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return WarehouseItem.fromJson(data);
        }
      } catch (e) {
        debugPrint('D365 API check error: $e, fallback to internal master data');
      }
    }

    // 2. Fallback / Mock Service dengan local storage
    // Coba match dengan exact itemNumber atau formatted itemNumber
    String formatted = formatItemNumber(cleanInput);
    if (formatted.isEmpty) formatted = cleanInput;

    // Load custom stock adjustments dari prefs jika ada
    final customStockStr = prefs.getString(_keyCustomStock);
    Map<String, dynamic> stockOverrides = {};
    if (customStockStr != null) {
      try {
        stockOverrides = json.decode(customStockStr);
      } catch (_) {}
    }

    // Cari di seed catalog
    for (final item in _seedCatalog) {
      if (item.itemNumber.toLowerCase() == cleanInput.toLowerCase() ||
          item.itemNumber == formatted) {
        double currentStock = item.availableStock;
        if (stockOverrides.containsKey(item.itemNumber)) {
          currentStock =
              (stockOverrides[item.itemNumber] as num).toDouble();
        }
        return item.copyWith(availableStock: currentStock);
      }
    }

    // Jika format nomor item valid XX.XXX.XXX.XXXX tetapi belum ada di seed, buat item realistis
    if (RegExp(r'^\d{2}\.\d{3}\.\d{3}\.\d{4}$').hasMatch(cleanInput) ||
        cleanInput.length >= 10) {
      double dynamicStock = 15.0;
      if (stockOverrides.containsKey(cleanInput)) {
        dynamicStock = (stockOverrides[cleanInput] as num).toDouble();
      }
      return WarehouseItem(
        itemNumber: cleanInput,
        itemName: 'MATERIAL ITEM $cleanInput',
        description: 'Sparepart / Material terdaftar pada sistem D365',
        unitType: 'PCS',
        availableStock: dynamicStock,
        defaultWarehouse: 'Gudang Utama PLTU MSW',
        defaultLocation: 'RAK-GEN / BIN-01',
      );
    }

    return null;
  }

  /// Submit transaksi pengambilan material ke D365
  static Future<MaterialIssueRequest> submitMaterialIssue(
      MaterialIssueRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final customApiUrl = prefs.getString(_keyApiUrl);

    String journalNo =
        'JRN-D365-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // 1. Kirim ke Live D365 API jika URL dikonfigurasi
    if (customApiUrl != null && customApiUrl.isNotEmpty) {
      try {
        final url = Uri.parse('$customApiUrl/material-issues');
        final resp = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(request.toD365Payload()),
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final resData = json.decode(resp.body);
          if (resData['journalNo'] != null) {
            journalNo = resData['journalNo'].toString();
          }
        }
      } catch (e) {
        debugPrint('D365 API post error: $e, saved locally');
      }
    }

    // 2. Simulasikan delay network D365 jika mock
    if (customApiUrl == null || customApiUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 900));
    }

    // Update stok lokal di preferences
    final customStockStr = prefs.getString(_keyCustomStock);
    Map<String, dynamic> stockOverrides = {};
    if (customStockStr != null) {
      try {
        stockOverrides = json.decode(customStockStr);
      } catch (_) {}
    }

    for (final line in request.items) {
      double current = line.availableStock;
      if (stockOverrides.containsKey(line.itemNumber)) {
        current = (stockOverrides[line.itemNumber] as num).toDouble();
      }
      double updated = (current - line.quantity).clamp(0.0, 99999.0);
      stockOverrides[line.itemNumber] = updated;
    }
    await prefs.setString(_keyCustomStock, json.encode(stockOverrides));

    // Simpan ke riwayat transaksi lokal
    final recordWithJournal = MaterialIssueRequest(
      transactionId: request.transactionId.isNotEmpty
          ? request.transactionId
          : 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      woNumber: request.woNumber,
      warehouseLocation: request.warehouseLocation,
      activity: request.activity,
      costCenter: request.costCenter,
      transactionDate: request.transactionDate,
      remarks: request.remarks,
      submittedBy: request.submittedBy,
      items: request.items,
      status: 'Posted D365',
      d365JournalNo: journalNo,
    );

    final historyList = await getRecentIssues();
    historyList.insert(0, recordWithJournal);

    final encodedList =
        historyList.take(50).map((e) => e.toJson()).toList();
    await prefs.setString(_keyHistory, json.encode(encodedList));

    return recordWithJournal;
  }

  /// Ambil riwayat pengambilan material
  static Future<List<MaterialIssueRequest>> getRecentIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.isEmpty) {
      return _generateInitialHistory();
    }
    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => MaterialIssueRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing history: $e');
      return _generateInitialHistory();
    }
  }

  /// Data riwayat awal untuk preview
  static List<MaterialIssueRequest> _generateInitialHistory() {
    return [
      MaterialIssueRequest(
        transactionId: 'TRX-1725001290',
        woNumber: 'WO-2026-0812',
        warehouseLocation: 'MAINSTORE',
        activity: 'Corrective Maintenance',
        costCenter: 'CC-PLTU-MECH-02',
        transactionDate: DateTime.now().subtract(const Duration(hours: 3)),
        remarks: 'Penggantian bearing dan mechanical seal pompa CWP 1A',
        submittedBy: 'Maintenance Team',
        status: 'Posted D365',
        d365JournalNo: 'JRN-D365-2026-4821',
        items: [
          MaterialIssueLineItem(
            itemNumber: '01.001.001.0004',
            itemName: 'BEARING 6204-2RS C3 SKF',
            quantity: 2.0,
            unitType: 'PCS',
            availableStock: 24.0,
            location: 'RAK-A2 / BIN-04',
          ),
          MaterialIssueLineItem(
            itemNumber: '01.002.001.0012',
            itemName: 'MECHANICAL SEAL TYPE B-35MM',
            quantity: 1.0,
            unitType: 'SET',
            availableStock: 6.0,
            location: 'RAK-B1 / BIN-02',
          ),
        ],
      ),
      MaterialIssueRequest(
        transactionId: 'TRX-1724982100',
        woNumber: 'WO-2026-0809',
        warehouseLocation: 'OILSTORE',
        activity: 'Preventive Maintenance',
        costCenter: 'CC-PLTU-OPR-03',
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
        remarks: 'Penambahan pelumas gearbox coal mill unit 1',
        submittedBy: 'Operation Team',
        status: 'Posted D365',
        d365JournalNo: 'JRN-D365-2026-4790',
        items: [
          MaterialIssueLineItem(
            itemNumber: '01.003.001.0001',
            itemName: 'SYNTHETIC GEAR OIL ISO VG 320',
            quantity: 25.0,
            unitType: 'LTR',
            availableStock: 150.0,
            location: 'LUBE-DRUM-03',
          ),
        ],
      ),
    ];
  }

  /// Ambil semua katalog item untuk keperluan pencarian / look up
  static List<WarehouseItem> getCatalogList() {
    return List.unmodifiable(_seedCatalog);
  }

  // =========================================================================
  // MASTER LIST D365 (FIXED MASTER DATA)
  // =========================================================================

  /// Master List Gudang (Fixed dari D365)
  static List<String> getWarehouseList() {
    return const [
      'MAINSTORE',
      'CHEMSTORE',
      'COALSTORE',
      'FUELSTORE',
      'HO-01',
      'IBT-01',
      'LAYDOWN',
      'LIMESTORE',
      'MAINWORK',
      'MSW04-01',
      'MSW05-02',
      'MSW06-03',
      'NSSTORE',
      'OILSTORE',
      'SAFETYSTORE',
      'SANDSTORE',
      'SAWDUSTSTORE',
      'WATERSTORE',
      'WOODSTORE',
    ];
  }

  /// Master List Lokasi Rak / Bin (Fixed dari D365)
  static List<String> getLocationList([String? warehouse]) {
    if (warehouse == 'OILSTORE') {
      return const [
        'LUBE-DRUM-01',
        'LUBE-DRUM-02',
        'LUBE-DRUM-03',
        'RAK-L1 / BIN-01',
        'RAK-L1 / BIN-02',
        'RAK-L2 / BIN-01',
      ];
    } else if (warehouse == 'CHEMSTORE') {
      return const [
        'CHEM-TANK-01',
        'CHEM-TANK-02',
        'RAK-CH1 / BIN-01',
        'RAK-CH1 / BIN-02',
        'DRUM-ACID-01',
      ];
    } else if (warehouse == 'MAINWORK') {
      return const [
        'RAK-E1 / BIN-01',
        'RAK-E1 / BIN-02',
        'RAK-E2 / BIN-01',
        'RAK-E2 / BIN-05',
        'WORK-BENCH-01',
      ];
    } else if (warehouse == 'SAFETYSTORE') {
      return const [
        'RAK-PPE-01',
        'RAK-PPE-02',
        'RAK-FIRE-01',
        'CABINET-SCBA-01',
      ];
    } else if (warehouse == 'LAYDOWN') {
      return const [
        'YARD-NORTH-01',
        'YARD-SOUTH-02',
        'HEAVY-STORAGE-A1',
      ];
    }
    // Default / MAINSTORE
    return const [
      'RAK-A1 / BIN-01',
      'RAK-A2 / BIN-04',
      'RAK-A2 / BIN-05',
      'RAK-B1 / BIN-01',
      'RAK-B1 / BIN-02',
      'RAK-C1 / BIN-08',
      'RAK-C3 / BIN-11',
      'RAK-D1 / BIN-01',
      'RAK-D2 / BIN-03',
      'FLOOR-BULK-01',
    ];
  }

  /// Master List Activity (86 Dimension Values Resmi dari D365)
  static List<String> getActivityList() {
    return const [
      '6100AC0000 - NON',
      '6100AC0401 - Depreciation - ROU - Land',
      '6100AC0402 - Depreciation - ROU - Buildings',
      '6100AC0403 - Depreciation - ROU - Machinery; operational equip & vehicles',
      '6100AC0404 - Depreciation - ROU - Office equipments',
      '6100AC1001 - Depreciation - Building',
      '6100AC1002 - Depreciation - Furniture',
      '6100AC1003 - Depreciation - Machine & Equipment',
      '6100AC1004 - Depreciation - Vehicle',
      '6100AC1005 - Depreciation - IT-Communication',
      '6100AC1006 - Depreciation - Plant Equipment',
      '6100AC1007 - Depreciation - Infrastructure OSBL',
      '6100AC1008 - Depreciation - Land',
      '6100AC1009 - Depreciation - Guest House (Include Fixture)',
      '6100AC1011 - ROU - Land',
      '6100AC1012 - ROU - Buildings',
      '6100AC1013 - ROU - Machinery; operational equipment & vehicles',
      '6100AC1014 - ROU - Office equipments',
      '6100AC1100 - FA - Asset Under Construction',
      '6100AC1101 - FA - Land',
      '6100AC1102 - FA - Building',
      '6100AC1103 - FA - Furniture',
      '6100AC1104 - FA - Machine & Equipment',
      '6100AC1105 - FA - Vehicle',
      '6100AC1106 - FA - IT-Communication',
      '6100AC1107 - FA - Plant Eqp',
      '6100AC1108 - FA - Infrastructure OSBL',
      '6100AC1109 - FA - Guest House (Include Fixture)',
      '6100AC1110 - FA - Non Depreciated',
      '6100AC1201 - FA Acc Depr - Building',
      '6100AC1202 - FA Acc Depr - Furniture',
      '6100AC1203 - FA Acc Depr - Machine & Equipment',
      '6100AC1204 - FA Acc Depr - Vehicle',
      '6100AC1205 - FA Acc Depr - IT-Communication',
      '6100AC1206 - FA Acc Depr - Plant Eqp',
      '6100AC1207 - FA Acc Depr - Infrastructure OSBL',
      '6100AC1208 - FA Acc Depr - Guest House (Include Fixture)',
      '6100AC1234 - Lease',
      '6100AC2011 - Coal',
      '6100AC2012 - Co-Firing',
      '6100AC2211 - Acc dep - ROU - Land',
      '6100AC2212 - Acc dep - ROU - Buildings',
      '6100AC2213 - Acc dep - ROU - Machinery; operational equipment & vehicles',
      '6100AC2214 - Acc dep - ROU - Office equipments',
      '6100AC3001 - Management Fee',
      '6100AC3002 - Guarantee Fee',
      '6100AC3991 - Accrued Expenses - Jamsostek',
      '6100AC3992 - Accrued Expenses - Supplier',
      '6100AC3993 - Accrued Expenses - Other',
      '6100AC4001 - Revenue from Power Plant - Adaro Indonesia, PT',
      '6100AC4002 - Revenue from Power Plant - PLN (Persero), PT',
      '6100AC4003 - Revenue from Power Plant - PT Saptaindra Sejati',
      '6100AC4004 - Revenue from Power Plant- PT Agri Multi Lestari',
      '6100AC4009 - Revenue from Power Plant Others',
      '6100AC4041 - Inventory - Fuel Oil',
      '6100AC4042 - Inventory - Lubricant',
      '6100AC4981 - Inventory - Sand (Bed Material)',
      '6100AC4982 - Inventory - Chemical',
      '6100AC5131 - ER - Flight',
      '6100AC5132 - ER - Accomodation',
      '6100AC5133 - ER - Transport',
      '6100AC5134 - ER - Meals',
      '6100AC5135 - ER - Others',
      '6100AC5401 - LimeStone',
      '6100AC5402 - Sand (Bed Material)',
      '6100AC5403 - Equipment Tools',
      '6100AC5404 - Other Consumables',
      '6100AC7001 - Revenue from DGOM - Adaro Indonesia, PT',
      '6100AC7002 - Revenue from DGOM - Alam Tri Abadi, PT',
      '6100AC7003 - Revenue from DGOM - Indonesia Bulk Terminal, PT',
      '6100AC7004 - Revenue from DGOM - Adaro Tirta Sarana, PT',
      '6100AC7005 - Revenue from DGOM - Others',
      '6100AC7101 - Revenue from PLTS - Adaro Indonesia, PT',
      '6100AC7901 - Revenue Others - Adaro Tirta Sarana, PT',
      '6100AC8001 - Pajak Air',
      '6100AC8002 - Pajak Penerangan Jalan',
      '6100AC8003 - Vehicle Tax',
      '6100AC8004 - Fixed Contribution',
      '6100AC8005 - Retribution Royalty',
      '6100AC8006 - Carbon Tax',
      '6100AC8007 - Land and Building Tax',
      '6100AC9901 - Interco - AI',
      '6100AC9902 - Interco - IBT',
      '6100AC9903 - Interco - ATS',
      '6100AC9904 - Interco - AP',
      '6100AC9905 - Interco - AMI',
      '6100AC9906 - Interco - APM',
    ];
  }

  /// Ekstrak kode activity dari format "6100AC5403 - Equipment Tools"
  static String extractActivityCode(String raw) {
    if (raw.contains(' - ')) {
      return raw.split(' - ')[0].trim();
    }
    return raw.trim();
  }

  /// Master List Cost Center (Fixed dari D365)
  static List<String> getCostCenterList() {
    return const [
      '6100DA300 - MSW_Operation & Maintenance',
      '6100DA301 - MSW_Operation & Performance - Operation',
      '6100DA302 - MSW_Operation & Performance - WTP',
      '6100DA303 - MSW_Operation & Performance - Plant Performance',
      '6100DB202 - MSW_Technical Services - Project & Improvement',
      '6100DB203 - MSW_Technical Services - Planning',
      '6100DB400 - MSW_Maintenance',
      '6100DB401 - MSW_Maintenance - Mechanical',
      '6100DB402 - MSW_Maintenance - Electrical, Instrument, & Control',
      '6100DB403 - MSW_Maintenance - Planning',
      '6100DB404 - MSW_Technical Maintenance - Project & Improvement',
      '6100DB405 - MSW_Technical Maintenance - Planning',
      '6100DB410 - MSW_Transmission & Distribution',
      '6100DB411 - MSW_T&D - Maintenance',
      '6100DB412 - MSW_T&D - Electrification',
      '6100DB413 - MSW_Technical Maintenance - Elektrifikasi',
      '6100DB420 - MSW_Technical Maintenance - Solar PV',
      '6100DB421 - MSW_T&D - Solar PV',
      '6100DB431 - MSW_T&D - DGOM AI',
      '6100DB432 - MSW_T&D - DGOM IBT',
      '6100DB433 - MSW_T&D - DGOM ATS',
      '6100DB441 - MSW_T&D - Planning',
      '6100DD100 - MSW_Directorate',
      '6100DD200 - MSW_Technical Support',
      '6100DD201 - MSW_Technical Services - Engineering',
      '6100DE700 - MSW_Support Services',
      '6100DE710 - MSW_Support Services - OHS',
      '6100DE720 - MSW_Support Services - QMS',
      '6100DI210 - MSW_Finance & Accounting',
      '6100DK100 - MSW_HRGA',
      '6100DK110 - MSW_HR',
      '6100DK111 - MSW_Human Resources - Site',
      '6100DK112 - MSW_Human Resources - Jakarta',
      '6100DK120 - MSW_GA',
      '6100DL600 - MSW_General Power Plant',
      '6100DN730 - MSW_Support Services - Material Management',
      '6100DN731 - MSW_Support Services - Material Management - Procurement',
      '6100DN732 - MSW_Support Services - Material Management - Inventory',
      '6100DN800 - MSW_Material Management',
    ];
  }

  /// Ekstrak kode cost center dari format "6100DB401 - MSW_Maintenance - Mechanical"
  static String extractCostCenterCode(String raw) {
    if (raw.contains(' - ')) {
      return raw.split(' - ')[0].trim();
    }
    return raw.trim();
  }

  /// Master List Employee / Request By (Default Fixed dari D365)
  static List<String> getEmployeeList() {
    return const [
      '61000003 - Executor EIC',
      '61000006 - Executor DG-PLTS',
      '61000002 - Executor MECH-W&F',
    ];
  }

  /// Ekstrak kode employee/request by dari format "61000003 - Executor EIC"
  static String extractEmployeeCode(String raw) {
    if (raw.contains(' - ')) {
      return raw.split(' - ')[0].trim();
    }
    return raw.trim();
  }

  // =========================================================================
  // DYNAMIC UNCOMPLETED WORK ORDERS (UPDATE DARI D365)
  // =========================================================================

  /// Mengambil list Work Order yang belum completed dari D365 (Bisa update setiap hari)
  static Future<List<WorkOrder>> getActiveWorkOrders({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final customApiUrl = prefs.getString(_keyApiUrl);

    // 1. Jika ada endpoint D365 terhubung
    if (customApiUrl != null && customApiUrl.isNotEmpty) {
      try {
        final url = Uri.parse('$customApiUrl/work-orders?status=active');
        final response =
            await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final woList = data
              .map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
              .toList();
          // Simpan cache lokal
          await prefs.setString(
              _keyActiveWOCache, json.encode(data));
          return woList;
        }
      } catch (e) {
        debugPrint('D365 getActiveWorkOrders error: $e, using local cache/seed');
      }
    }

    // 2. Load dari cache lokal jika tidak force refresh
    if (!forceRefresh) {
      final cachedRaw = prefs.getString(_keyActiveWOCache);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final List<dynamic> list = json.decode(cachedRaw);
          return list
              .map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

    // 3. Fallback / Seed Work Order aktif PLTU MSW yang belum completed
    final initialList = _getSeedActiveWorkOrders();
    await prefs.setString(_keyActiveWOCache,
        json.encode(initialList.map((e) => e.toJson()).toList()));
    return initialList;
  }

  static List<WorkOrder> _getSeedActiveWorkOrders() {
    return [
      WorkOrder(
        woNumber: 'WO-2026-0815',
        title: 'Overhaul Pompa CWP 1A & Penggantian Mechanical Seal',
        equipment: '10-CWP-PMP-01A (Circulating Water Pump)',
        activity: '6100AC5403 - Equipment Tools',
        costCenter: '6100DB401 - MSW_Maintenance - Mechanical',
        warehouseLocation: 'MAINSTORE',
        status: 'In Progress',
        targetDate: DateTime.now().add(const Duration(days: 2)),
      ),
      WorkOrder(
        woNumber: 'WO-2026-0818',
        title: 'Penggantian Filter & Penambahan Pelumas Gearbox Coal Mill 1B',
        equipment: '10-CML-GBX-01B (Coal Mill Gearbox)',
        activity: '6100AC4042 - Inventory - Lubricant',
        costCenter: '6100DB401 - MSW_Maintenance - Mechanical',
        warehouseLocation: 'OILSTORE',
        status: 'Open',
        targetDate: DateTime.now().add(const Duration(days: 3)),
      ),
      WorkOrder(
        woNumber: 'WO-2026-0820',
        title: 'Kalibrasi & Penggantian Pressure Transmitter Boiler Unit 1',
        equipment: '10-BLR-PT-025 (Steam Header Transmitter)',
        activity: '6100AC5403 - Equipment Tools',
        costCenter:
            '6100DB402 - MSW_Maintenance - Electrical, Instrument, & Control',
        warehouseLocation: 'MAINWORK',
        status: 'In Progress',
        targetDate: DateTime.now().add(const Duration(days: 1)),
      ),
      WorkOrder(
        woNumber: 'WO-2026-0822',
        title: 'Perbaikan Kebocoran Flange Steam Header Unit 2 & Gasket 3 Inch',
        equipment: '20-STM-HDR-01 (Main Steam Header)',
        activity: '6100AC5404 - Other Consumables',
        costCenter: '6100DB401 - MSW_Maintenance - Mechanical',
        warehouseLocation: 'MAINSTORE',
        status: 'Released',
        targetDate: DateTime.now(),
      ),
      WorkOrder(
        woNumber: 'WO-2026-0825',
        title: 'Penggantian MCB 3P 32A Panel Distribusi EIC Unit 2',
        equipment: '00-EIC-PNL-DIST-03 (Distribution Board)',
        activity: '6100AC5403 - Equipment Tools',
        costCenter:
            '6100DB402 - MSW_Maintenance - Electrical, Instrument, & Control',
        warehouseLocation: 'MAINWORK',
        status: 'In Progress',
        targetDate: DateTime.now().add(const Duration(days: 4)),
      ),
      WorkOrder(
        woNumber: 'WO-2026-0828',
        title: 'Greasing High-Temp Bearing ID Fan Unit 1',
        equipment: '10-IDF-FAN-01A (Induced Draft Fan)',
        activity: '6100AC4042 - Inventory - Lubricant',
        costCenter: '6100DB401 - MSW_Maintenance - Mechanical',
        warehouseLocation: 'OILSTORE',
        status: 'Open',
        targetDate: DateTime.now().add(const Duration(days: 5)),
      ),
    ];
  }

  // =========================================================================
  // D365 AUTHENTICATION & USER SESSION MANAGEMENT
  // =========================================================================

  /// Daftar akun D365 resmi / preset
  static final List<D365UserSession> _presetAccounts = [
    D365UserSession(
      employeeCode: '61000003',
      employeeName: 'Executor EIC',
      department: 'Electrical, Instrument, & Control',
      defaultCostCenter:
          '6100DB402 - MSW_Maintenance - Electrical, Instrument, & Control',
      loginTime: DateTime.now(),
    ),
    D365UserSession(
      employeeCode: '61000006',
      employeeName: 'Executor DG-PLTS',
      department: 'Transmission & Distribution - Solar PV',
      defaultCostCenter: '6100DB421 - MSW_T&D - Solar PV',
      loginTime: DateTime.now(),
    ),
    D365UserSession(
      employeeCode: '61000002',
      employeeName: 'Executor MECH-W&F',
      department: 'Mechanical Maintenance - Water & Fuel',
      defaultCostCenter: '6100DB401 - MSW_Maintenance - Mechanical',
      loginTime: DateTime.now(),
    ),
  ];

  /// Mengambil sesi login D365 yang tersimpan
  static Future<D365UserSession?> getSavedD365Session() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyD365UserSession);
    if (raw != null && raw.isNotEmpty) {
      try {
        return D365UserSession.fromJson(json.decode(raw));
      } catch (e) {
        debugPrint('Error parsing saved D365 session: $e');
      }
    }
    return null;
  }

  /// Login ke akun D365 (bisa preset atau custom user code)
  static Future<D365UserSession> loginD365({
    required String employeeCode,
    String? password,
    String? customName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanCode = extractEmployeeCode(employeeCode);

    // 1. Cek apakah ada di preset
    D365UserSession user;
    final foundIndex =
        _presetAccounts.indexWhere((acc) => acc.employeeCode == cleanCode);
    if (foundIndex != -1) {
      final preset = _presetAccounts[foundIndex];
      user = D365UserSession(
        employeeCode: preset.employeeCode,
        employeeName: preset.employeeName,
        department: preset.department,
        defaultCostCenter: preset.defaultCostCenter,
        loginTime: DateTime.now(),
      );
    } else {
      user = D365UserSession(
        employeeCode: cleanCode,
        employeeName: customName != null && customName.isNotEmpty
            ? customName
            : 'Employee $cleanCode',
        department: 'Plant Operations',
        defaultCostCenter: '6100DB401 - MSW_Maintenance - Mechanical',
        loginTime: DateTime.now(),
      );
    }

    // Simpan ke SharedPreferences
    await prefs.setString(_keyD365UserSession, json.encode(user.toJson()));
    return user;
  }

  /// Logout dari sesi D365
  static Future<void> logoutD365() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyD365UserSession);
  }

  /// Daftar akun preset D365
  static List<D365UserSession> getPresetD365Accounts() {
    return List.unmodifiable(_presetAccounts);
  }
}


