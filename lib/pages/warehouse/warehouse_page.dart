import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/material_issue_model.dart';
import 'package:msw_eplant/models/warehouse_item.dart';
import 'package:msw_eplant/models/d365_user_model.dart';
import 'package:msw_eplant/services/d365_service.dart';
import 'package:msw_eplant/pages/warehouse/material_issue_page.dart';
import 'package:msw_eplant/pages/warehouse/qr_scanner_page.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  List<MaterialIssueRequest> _history = [];
  D365UserSession? _d365User;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final list = await D365Service.getRecentIssues();
      final user = await D365Service.getSavedD365Session();
      if (mounted) {
        setState(() {
          _history = list;
          _d365User = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openNewIssue({String? initialItem}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialIssuePage(initialItemNumber: initialItem),
      ),
    );
    // Selalu perbarui session D365 dan riwayat saat kembali
    _loadHistory();
  }

  Future<void> _logoutD365() async {
    await D365Service.logoutD365();
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text('Anda telah logout dari akun D365'),
        ),
      );
    }
  }

  void _openD365LoginDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => D365LoginModal(
        onLoginSuccess: (session) {
          _loadHistory();
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

  void _scanBarcodeShortcut() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _openNewIssue(initialItem: scanned);
    }
  }

  void _showCatalogSheet() {
    final catalog = D365Service.getCatalogList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CatalogViewerModal(
        catalog: catalog,
        onSelectForIssue: (itemNumber) {
          Navigator.pop(ctx);
          _openNewIssue(initialItem: itemNumber);
        },
      ),
    );
  }

  void _showDetailDialog(MaterialIssueRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bukti Pengambilan: ${req.woNumber}',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('No Jurnal D365', req.d365JournalNo ?? '-'),
                      _buildDetailRow('Status', req.status),
                      _buildDetailRow('Gudang', req.warehouseLocation),
                      _buildDetailRow('Activity', req.activity),
                      _buildDetailRow('Cost Center', req.costCenter),
                      _buildDetailRow(
                        'Waktu',
                        DateFormat('dd MMM yyyy, HH:mm').format(req.transactionDate),
                      ),
                      _buildDetailRow('Pemohon', req.submittedBy),
                      if (req.remarks.isNotEmpty)
                        _buildDetailRow('Catatan', req.remarks),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Daftar Material yang Dikeluarkan:',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...req.items.map((line) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.itemName,
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'No: ${line.itemNumber}',
                                  style: const TextStyle(
                                      color: AppColors.textSub, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${line.quantity} ${line.unitType}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.textSub)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.darken,
          ),
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
            'Warehouse & Material',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSub),
              tooltip: 'Refresh Data',
              onPressed: _loadHistory,
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadHistory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // D365 Integration & User Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _d365User != null
                          ? AppColors.general.withOpacity(0.12)
                          : Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _d365User != null
                              ? AppColors.general.withOpacity(0.3)
                              : Colors.amber.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _d365User != null
                              ? Icons.verified_user
                              : Icons.lock_person_outlined,
                          color: _d365User != null
                              ? AppColors.general
                              : Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _d365User != null
                                    ? 'D365: ${_d365User!.displayName}'
                                    : 'Akun D365 Belum Login',
                                style: TextStyle(
                                    color: _d365User != null
                                        ? AppColors.general
                                        : Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _d365User != null
                                    ? 'Dept: ${_d365User!.department}'
                                    : 'Login diperlukan saat submit pengambilan material.',
                                style: const TextStyle(
                                    color: AppColors.textSub, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        if (_d365User != null) ...[
                          InkWell(
                            onTap: _openD365LoginDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Text(
                                'Ganti',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _logoutD365,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: _openD365LoginDialog,
                            child: const Text('Login D365',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PRIMARY ACTION: PENGAMBILAN MATERIAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.5), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.output_rounded,
                                color: AppColors.primary, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Pengambilan Material',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ambil material gudang dengan input no item atau scan barcode, lalu daftarkan pengambilan ke D365.',
                          style: TextStyle(
                              color: AppColors.textSub, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Tombol Utama Ambil Material
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                onPressed: () => _openNewIssue(),
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 18, color: Colors.black),
                                label: const Text(
                                  'Mulai Pengambilan',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Shortcut Scan QR
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                onPressed: _scanBarcodeShortcut,
                                icon: const Icon(Icons.qr_code_scanner,
                                    size: 18),
                                label: const Text(
                                  'Scan QR',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // SECONDARY ACTION: PENCARIAN KATALOG
                  _buildActionCard(
                    icon: Icons.search,
                    title: 'Search Item D365',
                    subtitle: 'Cari barang berdasarkan nama untuk cek nomor item & stok',
                    color: AppColors.purple,
                    onTap: _showCatalogSheet,
                  ),

                  const SizedBox(height: 20),

                  // SECTION: RIWAYAT PENGAMBILAN MATERIAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RIWAYAT PENGAMBILAN MATERIAL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSub,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${_history.length} Transaksi',
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  else if (_history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off,
                                color: AppColors.textDim, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada transaksi pengambilan material',
                              style: TextStyle(
                                  color: AppColors.textSub, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return _buildHistoryCard(item);
                      },
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textDim, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(MaterialIssueRequest req) {
    return InkWell(
      onTap: () => _showDetailDialog(req),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Header Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.woNumber,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(req.transactionDate),
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.general.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    req.status,
                    style: const TextStyle(
                        color: AppColors.general,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Item summary lines
            Text(
              req.items.map((e) => '${e.itemName} (${e.quantity} ${e.unitType})').join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Footer Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 13, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text(
                      req.warehouseLocation.split(' ')[0],
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 13, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text(
                      req.costCenter.split(' ')[0],
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text('Detail',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right,
                        color: AppColors.primary, size: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MODAL KATALOG MATERIAL D365
// ---------------------------------------------------------------------------
class _CatalogViewerModal extends StatefulWidget {
  final List<WarehouseItem> catalog;
  final ValueChanged<String> onSelectForIssue;

  const _CatalogViewerModal({
    required this.catalog,
    required this.onSelectForIssue,
  });

  @override
  State<_CatalogViewerModal> createState() => _CatalogViewerModalState();
}

class _CatalogViewerModalState extends State<_CatalogViewerModal> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.catalog.where((item) {
      final q = _query.toLowerCase();
      return item.itemName.toLowerCase().contains(q) ||
          item.itemNumber.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: const EdgeInsets.only(top: 60),
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
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Katalog Master Item D365',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama barang atau no item...',
                hintStyle:
                    const TextStyle(color: AppColors.textDim, fontSize: 12),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primary, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textDim, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
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
          const Divider(color: AppColors.border),
          // Catalog list / Search results
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_rounded,
                                size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cari Master Barang D365',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ketik nama barang (contoh: bearing, valve, oil) atau nomor item untuk mencari ketersediaan barang di sistem D365.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSub, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 40, color: AppColors.textDim),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada barang yang cocok dengan "$_query"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSub, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'No Item: ${item.itemNumber}',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      if (item.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                              color: AppColors.textSub,
                                              fontSize: 11),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.availableStock > 0
                                                  ? AppColors.general
                                                      .withOpacity(0.15)
                                                  : AppColors.danger
                                                      .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Stok: ${item.availableStock} ${item.unitType}',
                                              style: TextStyle(
                                                  color: item.availableStock > 0
                                                      ? AppColors.general
                                                      : AppColors.danger,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (item.defaultLocation != null)
                                            Text(
                                              item.defaultLocation!,
                                              style: const TextStyle(
                                                  color: AppColors.textDim,
                                                  fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: item.availableStock > 0
                                      ? () => widget
                                          .onSelectForIssue(item.itemNumber)
                                      : null,
                                  child: const Text('Pilih',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
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
