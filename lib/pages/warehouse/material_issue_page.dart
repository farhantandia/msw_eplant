import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/material_issue_model.dart';
import 'package:msw_eplant/models/warehouse_item.dart';
import 'package:msw_eplant/models/work_order_model.dart';
import 'package:msw_eplant/models/d365_user_model.dart';
import 'package:msw_eplant/services/d365_service.dart';
import 'package:msw_eplant/pages/warehouse/qr_scanner_page.dart';

class MaterialIssuePage extends StatefulWidget {
  final String? initialItemNumber;

  const MaterialIssuePage({super.key, this.initialItemNumber});

  @override
  State<MaterialIssuePage> createState() => _MaterialIssuePageState();
}

class _MaterialIssuePageState extends State<MaterialIssuePage> {
  final _formKey = GlobalKey<FormState>();

  // Header Controllers
  final _woController = TextEditingController();
  final _remarksController = TextEditingController();
  late String _selectedWarehouse;
  late String _selectedLocation;
  late String _selectedActivity;
  late String _selectedCostCenter;
  late String _selectedEmployee;
  final _manualEmployeeController = TextEditingController();
  bool _isManualEmployee = false;
  final DateTime _transactionDate = DateTime.now();
  WorkOrder? _selectedWorkOrder;
  D365UserSession? _currentD365User;

  // Multi-Item list
  final List<MaterialIssueLineItem> _items = [];
  bool _isSubmitting = false;

  late List<String> _warehouseOptions;
  late List<String> _locationOptions;
  late List<String> _activityOptions;
  late List<String> _costCenterOptions;
  late List<String> _employeeOptions;

  @override
  void initState() {
    super.initState();
    _initD365MasterData();
    _loadD365Session();
    if (widget.initialItemNumber != null && widget.initialItemNumber!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAddItemDialog(prefillItemNumber: widget.initialItemNumber);
      });
    }
  }

  Future<void> _loadD365Session() async {
    final session = await D365Service.getSavedD365Session();
    if (mounted) {
      setState(() {
        _currentD365User = session;
        if (session != null) {
          _selectedEmployee = session.displayName;
          if (!_employeeOptions.contains(_selectedEmployee)) {
            _employeeOptions.insert(0, _selectedEmployee);
          }
          // Otomatis pasang cost center bawaan akun D365 jika tersedia
          final matchingCC = _costCenterOptions.firstWhere(
            (c) =>
                c == session.defaultCostCenter ||
                c.startsWith(session.defaultCostCenter) ||
                session.defaultCostCenter.startsWith(c.split(' - ')[0]),
            orElse: () => '',
          );
          if (matchingCC.isNotEmpty) {
            _selectedCostCenter = matchingCC;
          }
        }
      });
    }
  }

  void _openD365LoginDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => D365LoginModal(
        onLoginSuccess: (session) {
          setState(() {
            _currentD365User = session;
            _selectedEmployee = session.displayName;
            if (!_employeeOptions.contains(_selectedEmployee)) {
              _employeeOptions.insert(0, _selectedEmployee);
            }
            // Update cost center jika matching
            final matchingCC = _costCenterOptions.firstWhere(
              (c) =>
                  c == session.defaultCostCenter ||
                  c.startsWith(session.defaultCostCenter) ||
                  session.defaultCostCenter.startsWith(c.split(' - ')[0]),
              orElse: () => '',
            );
            if (matchingCC.isNotEmpty) {
              _selectedCostCenter = matchingCC;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.general,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Login D365 Berhasil: ${session.displayName}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logoutD365() async {
    await D365Service.logoutD365();
    if (mounted) {
      setState(() {
        _currentD365User = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text('Anda telah logout dari akun D365'),
        ),
      );
    }
  }

  void _initD365MasterData() {
    _warehouseOptions = D365Service.getWarehouseList();
    _selectedWarehouse = _warehouseOptions.first;
    _locationOptions = D365Service.getLocationList(_selectedWarehouse);
    _selectedLocation = _locationOptions.first;
    _activityOptions = D365Service.getActivityList();
    _selectedActivity = _activityOptions.first;
    _costCenterOptions = D365Service.getCostCenterList();
    _selectedCostCenter = _costCenterOptions.first;
    _employeeOptions = [...D365Service.getEmployeeList(), '+ Input Manual / Kode Lainnya...'];
    _selectedEmployee = _employeeOptions.first;
  }

  void _openWorkOrderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WorkOrderPickerModal(
        selectedWoNumber: _woController.text.trim(),
        onWorkOrderSelected: (wo) {
          setState(() {
            _selectedWorkOrder = wo;
            _woController.text = wo.woNumber;

            // Auto-select corresponding activity & cost center & warehouse if matching
            final matchingAct = _activityOptions.firstWhere(
              (a) =>
                  a == wo.activity ||
                  a.startsWith(wo.activity) ||
                  wo.activity.startsWith(a.split(' - ')[0]),
              orElse: () => '',
            );
            if (matchingAct.isNotEmpty) {
              _selectedActivity = matchingAct;
            }
            final matchingCC = _costCenterOptions.firstWhere(
              (c) => c == wo.costCenter || c.startsWith(wo.costCenter) || wo.costCenter.startsWith(c.split(' - ')[0]),
              orElse: () => '',
            );
            if (matchingCC.isNotEmpty) {
              _selectedCostCenter = matchingCC;
            }
            if (_warehouseOptions.contains(wo.warehouseLocation)) {
              _selectedWarehouse = wo.warehouseLocation;
              _locationOptions = D365Service.getLocationList(_selectedWarehouse);
              if (!_locationOptions.contains(_selectedLocation)) {
                _selectedLocation = _locationOptions.first;
              }
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _woController.dispose();
    _remarksController.dispose();
    _manualEmployeeController.dispose();
    super.dispose();
  }

  /// Membuka Modal Tambah Item (Input Manual / Scan Barcode)
  void _openAddItemDialog({String? prefillItemNumber}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddItemModal(
        prefillItemNumber: prefillItemNumber,
        onItemAdded: (newItem) {
          setState(() {
            // Cek apakah item sudah ada di daftar, jika ada gabungkan qty atau update
            int existingIndex = _items.indexWhere((it) => it.itemNumber == newItem.itemNumber);
            if (existingIndex != -1) {
              final existing = _items[existingIndex];
              double combinedQty = (existing.quantity + newItem.quantity).clamp(1.0, newItem.availableStock);
              _items[existingIndex] = existing.copyWith(quantity: combinedQty);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    'Kuantitas untuk ${newItem.itemName} diperbarui menjadi $combinedQty ${newItem.unitType}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              );
            } else {
              _items.add(newItem);
            }
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() {
      _items.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Item ${removed.itemName} dihapus dari daftar'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            setState(() {
              _items.insert(index, removed);
            });
          },
        ),
      ),
    );
  }

  void _editItemQuantity(int index) {
    final item = _items[index];
    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Ubah Quantity (${item.unitType})',
          style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: const TextStyle(color: AppColors.textSub, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Maksimal stok D365: ${item.availableStock} ${item.unitType}',
              style: const TextStyle(color: AppColors.general, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Jumlah (${item.unitType})',
                labelStyle: const TextStyle(color: AppColors.textSub),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              double? newQty = double.tryParse(qtyController.text);
              if (newQty != null && newQty > 0) {
                if (newQty > item.availableStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Kuantitas melebihi stok tersedia (${item.availableStock} ${item.unitType})'),
                    ),
                  );
                  return;
                }
                setState(() {
                  _items[index] = item.copyWith(quantity: newQty);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitToD365() async {
    // 1. Cek apakah user sudah login ke akun D365
    if (_currentD365User == null) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.amber, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Login D365 Diperlukan',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Untuk mendaftarkan pengambilan material ke sistem D365, Anda harus login ke akun Microsoft Dynamics 365 terlebih dahulu untuk mendapatkan kode user resmi.',
            style: TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Login Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (shouldLogin == true) {
        _openD365LoginDialog();
      }
      return;
    }

    if (_woController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Nomor Work Order (WO) wajib diisi!')),
      );
      return;
    }

    final effectiveEmployee = _isManualEmployee
        ? _manualEmployeeController.text.trim()
        : _selectedEmployee;

    if (effectiveEmployee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Request By / Employee wajib diisi!')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Belum ada item barang yang dipilih! Tambahkan minimal 1 item.'),
        ),
      );
      return;
    }

    // Tampilkan konfirmasi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Pengambilan',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data pengambilan material akan didaftarkan ke sistem Microsoft Dynamics 365.',
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('No WO', _woController.text.trim()),
                  _buildReviewItem('Request By', effectiveEmployee),
                  _buildReviewItem('Kode Employee D365', D365Service.extractEmployeeCode(effectiveEmployee)),
                  _buildReviewItem('Lokasi Gudang', _selectedWarehouse),
                  _buildReviewItem('Activity', D365Service.extractActivityCode(_selectedActivity)),
                  _buildReviewItem('Cost Center', D365Service.extractCostCenterCode(_selectedCostCenter)),
                  _buildReviewItem('Jumlah Item', '${_items.length} Macam Barang'),
                  _buildReviewItem('Total Kuantitas', '${_items.fold(0.0, (sum, it) => sum + it.quantity)} Unit'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kirim ke D365', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final request = MaterialIssueRequest(
        transactionId: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
        woNumber: _woController.text.trim().toUpperCase(),
        warehouseLocation: _selectedWarehouse,
        activity: _selectedActivity,
        costCenter: _selectedCostCenter,
        transactionDate: _transactionDate,
        remarks: _remarksController.text.trim(),
        submittedBy: effectiveEmployee,
        items: List.from(_items),
      );

      final result = await D365Service.submitMaterialIssue(request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(backgroundColor: AppColors.danger, content: Text('Gagal mengirim ke D365: $e')));
      }
    }
  }

  void _showSuccessDialog(MaterialIssueRequest result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.general, width: 1.5),
        ),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.general, size: 48),
            SizedBox(height: 8),
            Text(
              'Pengambilan Berhasil!',
              style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Transaksi material issue telah tercatat di D365',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('No Jurnal D365', result.d365JournalNo ?? '-'),
                  _buildReviewItem('No Work Order', result.woNumber),
                  _buildReviewItem('Request By', result.submittedBy),
                  _buildReviewItem('Kode Employee D365', result.submittedByCode),
                  _buildReviewItem('Status', result.status),
                  _buildReviewItem('Total Item', '${result.items.length} Jenis Material'),
                  _buildReviewItem('Waktu Transaksi', DateFormat('dd MMM yyyy, HH:mm').format(result.transactionDate)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.general,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Kembali ke warehouse dashboard
            },
            child: const Text('Kembali ke Warehouse', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _items.fold(0.0, (sum, it) => sum + it.quantity);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pengambilan Material',
            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              tooltip: 'Scan Barcode Material',
              onPressed: () async {
                final scanned = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerPage()),
                );
                if (scanned != null && scanned.isNotEmpty) {
                  _openAddItemDialog(prefillItemNumber: scanned);
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // D365 AUTHENTICATION / SESSION STATUS CARD
                  _buildD365SessionCard(),
                  const SizedBox(height: 16),

                  // SECTION 1: HEADER FORM PENGAMBILAN
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'DATA WORK ORDER & LOKASI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // NO WORK ORDER
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Nomor Work Order (No WO) *',
                                controller: _woController,
                                hint: 'Ketik No WO atau pilih dari D365',
                                icon: Icons.assignment_outlined,
                                textCapitalization: TextCapitalization.characters,
                                onChanged: (val) {
                                  if (_selectedWorkOrder != null && _selectedWorkOrder!.woNumber != val) {
                                    setState(() => _selectedWorkOrder = null);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.18),
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _openWorkOrderPicker,
                                icon: const Icon(Icons.format_list_bulleted, size: 18),
                                label: const Text(
                                  'List WO',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_selectedWorkOrder != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedWorkOrder!.title,
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Equipment: ${_selectedWorkOrder!.equipment}',
                                        style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface2,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Status: ${_selectedWorkOrder!.status}',
                                              style: const TextStyle(
                                                color: AppColors.general,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '(Auto-set Activity & Cost Center)',
                                            style: TextStyle(color: AppColors.textDim, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // WAREHOUSE LOCATION & LOKASI RAK
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildDropdownField(
                                label: 'Gudang (Warehouse) *',
                                value: _selectedWarehouse,
                                items: _warehouseOptions,
                                icon: Icons.store_mall_directory_outlined,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedWarehouse = val;
                                      _locationOptions = D365Service.getLocationList(val);
                                      if (!_locationOptions.contains(_selectedLocation)) {
                                        _selectedLocation = _locationOptions.first;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildDropdownField(
                                label: 'Lokasi Rak / Bin',
                                value: _selectedLocation,
                                items: _locationOptions,
                                icon: Icons.grid_view_outlined,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedLocation = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ACTIVITY
                        _buildDropdownField(
                          label: 'Activity (Aktivitas Pekerjaan) *',
                          value: _selectedActivity,
                          items: _activityOptions,
                          icon: Icons.engineering_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedActivity = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // COST CENTER
                        _buildDropdownField(
                          label: 'Cost Center *',
                          value: _selectedCostCenter,
                          items: _costCenterOptions,
                          icon: Icons.account_balance_wallet_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCostCenter = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // REQUEST BY / EMPLOYEE NAME
                        if (!_isManualEmployee) ...[
                          _buildDropdownField(
                            label: 'Request By / Employee Name *',
                            value: _selectedEmployee,
                            items: _employeeOptions,
                            icon: Icons.person_outline,
                            onChanged: (val) {
                              if (val != null) {
                                if (val == '+ Input Manual / Kode Lainnya...') {
                                  setState(() {
                                    _isManualEmployee = true;
                                    _manualEmployeeController.text = '';
                                  });
                                } else {
                                  setState(() => _selectedEmployee = val);
                                }
                              }
                            },
                          ),
                        ] else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Request By / Employee (Manual) *',
                                    style: TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isManualEmployee = false;
                                        _selectedEmployee = _employeeOptions.first;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.list_alt, size: 14, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pilih dari List',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _manualEmployeeController,
                                onChanged: (val) => setState(() {}),
                                style: const TextStyle(color: AppColors.text, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: 61000003 atau 61000003 - Nama',
                                  hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 18),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Badge Helper: Kode yang dikirim ke D365
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Kode D365 dikirim: ${D365Service.extractEmployeeCode(_isManualEmployee
                                    ? _manualEmployeeController.text.trim().isEmpty
                                          ? "-"
                                          : _manualEmployeeController.text.trim()
                                    : _selectedEmployee)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // TANGGAL SAAT INI (AUTO-SET)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSub),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tanggal Transaksi',
                                          style: TextStyle(color: AppColors.textDim, fontSize: 10),
                                        ),
                                        Text(
                                          DateFormat('dd MMM yyyy, HH:mm').format(_transactionDate),
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // REMARKS
                        _buildInputField(
                          label: 'Catatan / Remarks',
                          controller: _remarksController,
                          hint: 'Keterangan keperluan pengambilan material...',
                          icon: Icons.comment_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SECTION 2: DAFTAR ITEM (MULTI-ITEM LIST)
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.general.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2, color: AppColors.general, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'DAFTAR ITEM BARANG',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.general,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${_items.length} Item',
                                style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // LIST ITEM CARDS
                        if (_items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: AppColors.textDim.withOpacity(0.6),
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Belum ada material yang ditambahkan',
                                  style: TextStyle(color: AppColors.textSub, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tekan tombol di bawah untuk input manual atau scan barcode',
                                  style: TextStyle(color: AppColors.textDim, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = _items[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Number badge
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName,
                                            style: const TextStyle(
                                              color: AppColors.text,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'No Item: ${item.itemNumber}',
                                            style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Qty: ${item.quantity} ${item.unitType}',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Stok: ${item.availableStock} ${item.unitType}',
                                                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Actions
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                                      tooltip: 'Ubah Quantity',
                                      onPressed: () => _editItemQuantity(idx),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                      tooltip: 'Hapus Item',
                                      onPressed: () => _removeItem(idx),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 14),

                        // TOMBOL TAMBAH ITEM
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          onPressed: () => _openAddItemDialog(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            '+ Tambah Item Barang',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 3: SUBMIT BUTTON & SUMMARY
                  if (_items.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Pengambilan', style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                              Text(
                                '${_items.length} Item ($totalQty Unit)',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: _isSubmitting ? null : _submitToD365,
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Memproses ke D365...',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Submit Pengambilan Material',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildD365SessionCard() {
    if (_currentD365User == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_person_outlined,
                      color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum Terhubung Akun D365',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Perlu login ke Microsoft Dynamics 365 terlebih dahulu untuk mendapatkan kode user otentik.',
                        style: TextStyle(color: AppColors.textSub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: _openD365LoginDialog,
                icon: const Icon(Icons.login, size: 16, color: Colors.black),
                label: const Text(
                  'Login ke Akun D365 Sekarang',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.general.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.general.withOpacity(0.4), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.general.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user,
                color: AppColors.general, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.general.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🟢 D365 TERHUBUNG',
                        style: TextStyle(
                            color: AppColors.general,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: _openD365LoginDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              'Ganti Akun',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _logoutD365,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_currentD365User!.employeeCode} - ${_currentD365User!.employeeName}',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentD365User!.department,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              menuMaxHeight: 350,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              items: items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opt,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// MODAL DIALOG UNTUK MENAMBAH ITEM (MANUAL / SCAN BARCODE + CEK D365)
// ---------------------------------------------------------------------------
class _AddItemModal extends StatefulWidget {
  final String? prefillItemNumber;
  final ValueChanged<MaterialIssueLineItem> onItemAdded;

  const _AddItemModal({this.prefillItemNumber, required this.onItemAdded});

  @override
  State<_AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<_AddItemModal> {
  final _itemNumberController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  bool _isChecking = false;
  WarehouseItem? _verifiedItem;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefillItemNumber != null && widget.prefillItemNumber!.isNotEmpty) {
      _itemNumberController.text = D365Service.formatItemNumber(widget.prefillItemNumber!);
      _checkD365Stock();
    }
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // Format text saat user mengetik manual nomor item
  void _onItemNumberChanged(String val) {
    // Otomatis format nomor item saat diketik
    final formatted = D365Service.formatItemNumber(val);
    if (formatted != val) {
      _itemNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_verifiedItem != null) {
      setState(() {
        _verifiedItem = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _checkD365Stock() async {
    final rawNumber = _itemNumberController.text.trim();
    if (rawNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan atau scan nomor item terlebih dahulu!';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _verifiedItem = null;
    });

    try {
      final item = await D365Service.checkItemStock(rawNumber);
      if (item == null) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Item "$rawNumber" tidak ditemukan di sistem D365!';
        });
      } else if (item.availableStock <= 0) {
        setState(() {
          _isChecking = false;
          _verifiedItem = item;
          _errorMessage = 'Stok item ${item.itemName} habis (0 ${item.unitType})!';
        });
      } else {
        setState(() {
          _isChecking = false;
          _verifiedItem = item;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = 'Gagal menghubungi D365 API: $e';
      });
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _itemNumberController.text = D365Service.formatItemNumber(scanned);
      });
      _checkD365Stock();
    }
  }

  void _submitItem() {
    if (_verifiedItem == null) return;
    double? qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Masukkan kuantitas pengambilan yang valid (> 0)!'),
        ),
      );
      return;
    }

    if (qty > _verifiedItem!.availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Kuantitas ($qty ${_verifiedItem!.unitType}) melebihi stok tersedia (${_verifiedItem!.availableStock} ${_verifiedItem!.unitType})!',
          ),
        ),
      );
      return;
    }

    final lineItem = MaterialIssueLineItem(
      itemNumber: _verifiedItem!.itemNumber,
      itemName: _verifiedItem!.itemName,
      quantity: qty,
      unitType: _verifiedItem!.unitType, // Otomatis dari D365
      availableStock: _verifiedItem!.availableStock,
      location: _verifiedItem!.defaultLocation,
    );

    widget.onItemAdded(lineItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.textDim, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Item Material',
                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step 1: Input Nomor Item (Manual / Scan Barcode)
              const Text(
                '1. Masukkan No Item atau Scan Barcode',
                style: TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemNumberController,
                      keyboardType: TextInputType.number,
                      onChanged: _onItemNumberChanged,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                      decoration: InputDecoration(
                        hintText: '01.001.001.0004',
                        hintStyle: const TextStyle(color: AppColors.textDim, letterSpacing: 0),
                        prefixIcon: const Icon(Icons.pin, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Scan Barcode
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _scanBarcode,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 18),
                        SizedBox(width: 4),
                        Text('Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tombol Cek D365
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface2,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isChecking ? null : _checkD365Stock,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                        )
                      : const Icon(Icons.search, size: 16),
                  label: Text(
                    _isChecking ? 'Mengecek ke D365...' : 'Cek Stok D365',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // Verified Item Information Card
              if (_verifiedItem != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _verifiedItem!.availableStock > 0
                          ? AppColors.general.withOpacity(0.6)
                          : AppColors.danger.withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _verifiedItem!.itemName,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_verifiedItem!.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _verifiedItem!.description,
                                    style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Stock Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _verifiedItem!.availableStock > 0
                                  ? AppColors.general.withOpacity(0.2)
                                  : AppColors.danger.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stok: ${_verifiedItem!.availableStock} ${_verifiedItem!.unitType}',
                              style: TextStyle(
                                color: _verifiedItem!.availableStock > 0 ? AppColors.general : AppColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 14, color: AppColors.textDim),
                          const SizedBox(width: 4),
                          Text(
                            'Unit Type: ${_verifiedItem!.unitType} (dari D365)',
                            style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                          ),
                          const Spacer(),
                          if (_verifiedItem!.defaultLocation != null) ...[
                            const Icon(Icons.place_outlined, size: 14, color: AppColors.textDim),
                            const SizedBox(width: 4),
                            Text(
                              _verifiedItem!.defaultLocation!,
                              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Step 2: Input Quantity (Hanya jika stok > 0)
                if (_verifiedItem!.availableStock > 0) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '2. Jumlah Material yang Diambil',
                    style: TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Counter Minus
                      IconButton.outlined(
                        style: IconButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                        onPressed: () {
                          double cur = double.tryParse(_qtyController.text) ?? 1;
                          if (cur > 1) {
                            _qtyController.text = (cur - 1).toStringAsFixed(0);
                          }
                        },
                        icon: const Icon(Icons.remove, color: AppColors.text, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            suffixText: _verifiedItem!.unitType,
                            suffixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Counter Plus
                      IconButton.outlined(
                        style: IconButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                        onPressed: () {
                          double cur = double.tryParse(_qtyController.text) ?? 0;
                          if (cur < _verifiedItem!.availableStock) {
                            _qtyController.text = (cur + 1).toStringAsFixed(0);
                          }
                        },
                        icon: const Icon(Icons.add, color: AppColors.text, size: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Button Tambahkan ke Daftar
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.general,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submitItem,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(
                        'Tambahkan ${_verifiedItem!.itemName.split(' ')[0]} ke Form',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MODAL SELECTOR WORK ORDER AKTIF DARI D365
// ---------------------------------------------------------------------------
class _WorkOrderPickerModal extends StatefulWidget {
  final String? selectedWoNumber;
  final ValueChanged<WorkOrder> onWorkOrderSelected;

  const _WorkOrderPickerModal({this.selectedWoNumber, required this.onWorkOrderSelected});

  @override
  State<_WorkOrderPickerModal> createState() => _WorkOrderPickerModalState();
}

class _WorkOrderPickerModalState extends State<_WorkOrderPickerModal> {
  final _searchController = TextEditingController();
  List<WorkOrder> _workOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkOrders({bool refresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final list = await D365Service.getActiveWorkOrders(forceRefresh: refresh);
      if (mounted) {
        setState(() {
          _workOrders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _workOrders.where((wo) {
      final q = _searchQuery.toLowerCase();
      return wo.woNumber.toLowerCase().contains(q) ||
          wo.title.toLowerCase().contains(q) ||
          wo.equipment.toLowerCase().contains(q) ||
          wo.costCenter.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      margin: const EdgeInsets.only(top: 50),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.textDim, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Work Order D365',
                      style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textSub, size: 20),
                      tooltip: 'Refresh WO dari D365',
                      onPressed: () => _loadWorkOrders(refresh: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSub),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Info Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan list WO aktif (belum completed) yang terdaftar di D365.',
                    style: TextStyle(color: AppColors.textSub, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari No WO, Judul, atau Equipment...',
                hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textDim, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // List Work Orders
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, color: AppColors.textDim, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tidak ada Work Order aktif di D365'
                              : 'Work Order "$_searchQuery" tidak ditemukan',
                          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final wo = filtered[index];
                      final isSelected =
                          widget.selectedWoNumber != null &&
                          widget.selectedWoNumber!.toUpperCase() == wo.woNumber.toUpperCase();

                      return InkWell(
                        onTap: () {
                          widget.onWorkOrderSelected(wo);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      wo.woNumber,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: wo.status == 'In Progress'
                                          ? AppColors.primary.withOpacity(0.15)
                                          : wo.status == 'Released'
                                          ? AppColors.danger.withOpacity(0.15)
                                          : AppColors.general.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      wo.status,
                                      style: TextStyle(
                                        color: wo.status == 'In Progress'
                                            ? AppColors.primary
                                            : wo.status == 'Released'
                                            ? AppColors.danger
                                            : AppColors.general,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                wo.title,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Equipment: ${wo.equipment}',
                                style: const TextStyle(color: AppColors.textSub, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.engineering_outlined, size: 13, color: AppColors.textDim),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${wo.activity} · ${wo.costCenter.split(' ')[0]}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Modal Login Akun Microsoft Dynamics 365
class D365LoginModal extends StatefulWidget {
  final ValueChanged<D365UserSession> onLoginSuccess;

  const D365LoginModal({super.key, required this.onLoginSuccess});

  @override
  State<D365LoginModal> createState() => _D365LoginModalState();
}

class _D365LoginModalState extends State<D365LoginModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _employeeCodeController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeCodeController.dispose();
    _employeeNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePresetLogin(D365UserSession preset) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final session = await D365Service.loginD365(
        employeeCode: preset.employeeCode,
      );
      if (mounted) {
        widget.onLoginSuccess(session);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal login ke D365: $e';
        });
      }
    }
  }

  Future<void> _handleManualLogin() async {
    final code = _employeeCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Kode Employee D365 wajib diisi!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final session = await D365Service.loginD365(
        employeeCode: code,
        customName: _employeeNameController.text.trim().isNotEmpty
            ? _employeeNameController.text.trim()
            : null,
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        widget.onLoginSuccess(session);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal login ke D365: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = D365Service.getPresetD365Accounts();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.vpn_key_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login Akun D365',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Microsoft Dynamics 365 SCM',
                              style: TextStyle(
                                  color: AppColors.textDim, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSub),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textDim,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.badge_outlined, size: 16),
                  text: 'Akun Executor',
                ),
                Tab(
                  icon: Icon(Icons.person_add_alt_1_outlined, size: 16),
                  text: 'Akun Lainnya / Manual',
                ),
              ],
            ),
          ),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PRESET EXECUTORS
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: presets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final acc = presets[index];
                          return InkWell(
                            onTap: () => _handlePresetLogin(acc),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.15),
                                    child: const Icon(Icons.engineering,
                                        color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                acc.employeeCode,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              acc.employeeName,
                                              style: const TextStyle(
                                                color: AppColors.text,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          acc.department,
                                          style: const TextStyle(
                                              color: AppColors.textSub,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: AppColors.textDim),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // TAB 2: MANUAL / CUSTOM ACCOUNT
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masukkan Akun Karyawan D365',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gunakan Employee Number resmi yang terdaftar pada sistem D365 PLTU MSW.',
                        style:
                            TextStyle(color: AppColors.textDim, fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _employeeCodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Employee ID / Kode User D365 *',
                          labelStyle: const TextStyle(
                              color: AppColors.textSub, fontSize: 12),
                          hintText: 'Contoh: 61000003',
                          hintStyle: const TextStyle(
                              color: AppColors.textDim, fontSize: 12),
                          prefixIcon: const Icon(Icons.badge_outlined,
                              color: AppColors.primary, size: 18),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _employeeNameController,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap / Jabatan (Opsional)',
                          labelStyle: const TextStyle(
                              color: AppColors.textSub, fontSize: 12),
                          hintText: 'Contoh: Executor Shift A',
                          hintStyle: const TextStyle(
                              color: AppColors.textDim, fontSize: 12),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColors.primary, size: 18),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'PIN / Password D365',
                          labelStyle: const TextStyle(
                              color: AppColors.textSub, fontSize: 12),
                          hintText: 'Masukkan PIN D365 Anda',
                          hintStyle: const TextStyle(
                              color: AppColors.textDim, fontSize: 12),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.primary, size: 18),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _handleManualLogin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(Icons.login, size: 18),
                          label: Text(
                            _isLoading ? 'Memvalidasi...' : 'Masuk ke Akun D365',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
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
}

