/// Halaman Laporan (UI)
///
/// Keterangan:
/// - Mengambil data transaksi melalui `ReportController`.
/// - Menampilkan ringkasan, kontrol filter, daftar transaksi, dan paginasi.
/// - Desain mengikuti tema dark dari halaman Transaction.
/// - Fitur ekspor saat ini masih placeholder.

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/report/report_widgets.dart';
import 'package:dakara_weighbridge/Pages/report/report_filter_bar.dart';
import 'package:dakara_weighbridge/Pages/report/report_table.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/features/transaction/services/clipboard_service.dart';
import 'package:dakara_weighbridge/features/report/report_export_service.dart';
import 'package:dakara_weighbridge/Pages/report/report_models.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final ReportController controller;
  final clipboard = ClipboardServiceImpl();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = ReportController();
    _init();
  }

  Future<void> _init() async {
    await controller.loadAll();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? controller.startDate : controller.endDate) ??
          DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder:
          (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: kPrimaryCyan,
                surface: kCardBg,
              ),
            ),
            child: child!,
          ),
    );
    if (d != null) {
      isStart ? controller.setStartDate(d) : controller.setEndDate(d);
      setState(() {});
    }
  }

  Future<void> _onExport() async {
    final rows = List<ReportRowData>.from(controller.visible.value);
    if (rows.isEmpty) return _snack('Tidak ada data untuk diekspor');

    await showModalBottomSheet(
      context: context,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: kPrimaryCyan),
              title: const Text('Export PDF', style: TextStyle(color: kTextWhite)),
              onTap: () async {
                Navigator.of(context).pop();
                await ReportExportService.instance.previewReportPdf(context, rows, meta: _meta());
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: kPrimaryCyan),
              title: const Text('Export Excel (.xlsx)', style: TextStyle(color: kTextWhite)),
              onTap: () async {
                Navigator.of(context).pop();
                await ReportExportService.instance.previewExcel(context, rows, meta: _meta());
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on, color: kPrimaryCyan),
              title: const Text('Export CSV', style: TextStyle(color: kTextWhite)),
              onTap: () async {
                Navigator.of(context).pop();
                await ReportExportService.instance.previewCsv(context, rows, meta: _meta());
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _onPrint() async {
    final rows = List<ReportRowData>.from(controller.visible.value);
    if (rows.isEmpty) return _snack('Tidak ada data untuk dicetak');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cetak Laporan', style: TextStyle(color: kTextWhite, fontWeight: FontWeight.w600, fontSize: 18)),
        content: Text('Cetak ${rows.length} baris sesuai filter saat ini?', style: TextStyle(color: kTextGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text('Batal', style: TextStyle(color: kTextGrey))),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text('Cetak', style: TextStyle(color: kPrimaryCyan))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ReportExportService.instance.printReportPdf(rows, meta: _meta());
      _snack('Mengirim ke printer...');
    } catch (e) {
      _snack('Gagal mencetak: $e');
    }
  }

  Map<String, Object?> _meta() {
    return {
      'startDate': controller.startDate,
      'endDate': controller.endDate,
      'search': controller.search,
      'count': controller.visible.value.length,
    };
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: kCardBg,
      duration: const Duration(seconds: 2),
    ),
  );

  String _getSupplierName(int id) {
    final list = controller.suppliers.value;
    return list
        .firstWhere(
          (s) => s.supplierId == id,
          orElse:
              () => ListSupplierJson(
                supplierId: id,
                supplierName: '-',
                supplierAddress: '',
                supplierCity: '',
                supplierSubdistrict: '',
                supplierPostCode: '',
              ),
        )
        .supplierName;
  }

  String _getProductName(int id) {
    final list = controller.products.value;
    return list
        .firstWhere(
          (p) => p.productId == id,
          orElse:
              () => ListProductJson(
                productId: id,
                productName: '-',
                productCode: '',
              ),
        )
        .productName;
  }

  String _getCustomerName(int id) {
    final list = controller.customers.value;
    return list
        .firstWhere(
          (c) => c.customerId == id,
          orElse:
              () => ListCustomerJson(
                customerId: id,
                customerName: '-',
                customerAddress: '',
                customerPhone: '',
              ),
        )
        .customerName;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (sheetContext) => FilterSheet(
            controller: controller,
            getSupplierName: _getSupplierName,
            getProductName: _getProductName,
            onClear: () {
              controller.clearFilters();
              searchController.clear();
              Navigator.of(sheetContext).pop();
              if (mounted) setState(() {});
            },
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: controller.loading,
          builder: (_, loading, __) {
            return Stack(
              children: [
                // Main content kept mounted to avoid header jumping
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      ReportControls(
                        controller: controller,
                        searchController: searchController,
                        onPickStartDate: () => _pickDate(true),
                        onPickEndDate: () => _pickDate(false),
                        onShowFilter: _showFilterSheet,
                        onExport: _onExport,
                        onPrint: _onPrint,
                      ),
                      const SizedBox(height: 16),
                      ReportDataTable(
                        controller: controller,
                        clipboard: clipboard,
                        getSupplierName: _getSupplierName,
                        getProductName: _getProductName,
                        getCustomerName: _getCustomerName,
                        onSnack: _snack,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (loading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Center(
                        child: CircularProgressIndicator(color: kPrimaryCyan),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Header: Judul dan subjudul
  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Laporan',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: kTextWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 5),
      const Text(
        'Semua Transaksi',
        style: TextStyle(fontSize: 14, color: kTextGrey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  // Summary Cards: 4 kartu metrik di atas
  Widget _buildSummaryCards() => ValueListenableBuilder<Map<String, num>>(
    valueListenable: controller.aggregate,
    builder:
        (_, agg, __) => Row(
          children: [
            SummaryCard(
              icon: Icons.receipt_long,
              value: '${agg['count']}',
              label: 'Total Transaksi',
              color: kPrimaryCyan,
            ),
            const SizedBox(width: 16),
            SummaryCard(
              icon: Icons.scale,
              value: formatWeight(agg['totalNetto'] ?? 0),
              label: 'Total Berat',
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            SummaryCard(
              icon: Icons.analytics_outlined,
              value: formatWeight(agg['avgNetto'] ?? 0),
              label: 'Rata-rata Berat',
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            SummaryCard(
              icon: Icons.trending_up,
              value: currencyFormat.format(agg['revenue'] ?? 0),
              label: 'Total Pendapatan',
              color: kPrimaryCyan,
            ),
          ],
        ),
  );
}
