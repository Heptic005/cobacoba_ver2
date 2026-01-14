/// Report Controller
/// Tanggung jawab: Semua logic untuk halaman Report
/// - Load data dari DbHelper
/// - Client-side filter, search, sort, pagination
/// - Aggregate calculation (total, avg, revenue)
/// - Export placeholder (TODO: integrate with PrintService)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report/report_models.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report/report_perf.dart';

class ReportController {
  // State notifiers untuk UI subscribe
  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  final ValueNotifier<List<ListTransactionJson>> shown =
      ValueNotifier<List<ListTransactionJson>>([]);
  // Visible precomputed rows for fast rendering (batched)
  final ValueNotifier<List<ReportRowData>> visible =
      ValueNotifier<List<ReportRowData>>([]);
  final ValueNotifier<bool> loadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<Map<String, num>> aggregate =
      ValueNotifier<Map<String, num>>({
        'count': 0,
        'totalNetto': 0,
        'avgNetto': 0,
        'revenue': 0,
      });
  final ValueNotifier<List<ListSupplierJson>> suppliers =
      ValueNotifier<List<ListSupplierJson>>([]);
  final ValueNotifier<List<ListProductJson>> products =
      ValueNotifier<List<ListProductJson>>([]);
  final ValueNotifier<List<ListCustomerJson>> customers =
      ValueNotifier<List<ListCustomerJson>>([]);

  // Internal data + filter state
  final List<ListTransactionJson> _all = [];
  // Precomputed rows for all transactions
  final List<ReportRowData> _allRows = [];
  String _search = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _supplierId;
  int? _productId;
  int? _customerId;
  String? _plate;
  bool _sortDesc = true;

  // Batching state (default small for low-end devices)
  int _pageSize = 10; // per requirement: default 10
  int _nextIndex = 0;
  bool _hasMore = false;
  // keep legacy current page for compatibility with older UI pieces
  int _currentPage = 0;

  // Public getters for UI
  String get search => _search;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get supplierId => _supplierId;
  int? get productId => _productId;
  int? get customerId => _customerId;
  String? get plate => _plate;
  bool get sortDesc => _sortDesc;
  int get pageSize => _pageSize;
  int get currentPage => _currentPage;
  int get totalPages =>
      shown.value.isEmpty ? 1 : ((shown.value.length - 1) ~/ _pageSize) + 1;

  /// Constructor dengan optional initialData untuk testing
  ReportController({List<ListTransactionJson>? initialData}) {
    if (initialData != null) {
      _all.addAll(initialData);
      _precomputeAllRows();
      _applyFilters();
      loading.value = false;
    }
  }

  /// Load semua transaksi dari database
  Future<void> loadAll() async {
    loading.value = true;
    try {
      final tx = await DbHelper.instance.getListTransaction();
      final sup = await DbHelper.instance.getListSupplier();
      final prod = await DbHelper.instance.getListProducts();
      final cust = await DbHelper.instance.getListCustomers();

      debugPrint('Report: Loaded ${tx.length} transactions');
      debugPrint('Report: Loaded ${sup.length} suppliers');
      debugPrint('Report: Loaded ${prod.length} products');
      debugPrint('Report: Loaded ${cust.length} customers');

      _all
        ..clear()
        ..addAll(tx);
      // Precompute formatted strings for each transaction to reduce build cost
      _precomputeAllRows();
      suppliers.value = sup;
      products.value = prod;
      customers.value = cust;
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      loading.value = false;
    }
  }

  /// Set search query dan re-apply filters
  Timer? _searchDebounce;

  void setSearch(String s) {
    _search = _sanitizeSearchQuery(s);
    // Debounce rapid input to avoid many filter runs
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _applyFilters();
    });
  }

  /// Sanitasi input search: buang karakter kontrol, angle brackets, dan pola script
  String _sanitizeSearchQuery(String raw) {
    var q = raw.trim();

    // Hapus karakter kontrol non-printable
    q = q.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

    // Hapus angle brackets untuk cegah HTML/script
    q = q.replaceAll(RegExp(r'[<>]'), '');

    // Hapus pola script sederhana
    q = q.replaceAll(RegExp(r'</?script>', caseSensitive: false), '');

    return q;
  }

  /// Set start date filter
  void setStartDate(DateTime? d) {
    _startDate = d;
    _applyFilters();
  }

  /// Set end date filter
  void setEndDate(DateTime? d) {
    _endDate = d;
    _applyFilters();
  }

  /// Set supplier filter
  void setSupplier(int? id) {
    _supplierId = id;
    _applyFilters();
  }

  /// Set product filter
  void setProduct(int? id) {
    _productId = id;
    _applyFilters();
  }

  void setCustomer(int? id){
    _customerId = id;
    _applyFilters();
  }

  /// Set vehicle plate filter (partial match)
  void setPlate(String? plate) {
    _plate = plate == null || plate.trim().isEmpty ? null : plate.trim();
    _applyFilters();
  }

  /// Toggle sort order (asc/desc by inTime)
  void toggleSort() {
    _sortDesc = !_sortDesc;
    _applyFilters();
  }

  /// Set page size dan reset ke halaman pertama
  void setPageSize(int size) {
    _pageSize = size;
    _resetPaging();
  }

  /// Go to next page
  void nextPage() {
    if ((_currentPage + 1) * _pageSize < shown.value.length) {
      _currentPage++;
    }
  }

  /// Go to previous page
  void prevPage() {
    if (_currentPage > 0) {
      _currentPage--;
    }
  }

  /// Get items for current page
  List<ListTransactionJson> pageItems() {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    if (start >= shown.value.length) return [];
    return shown.value.sublist(
      start,
      end > shown.value.length ? shown.value.length : end,
    );
  }

  /// Check whether more batched pages are available
  bool get hasMore => _hasMore;

  /// Trigger loading next batch for infinite scroll
  Future<void> loadMore() async {
    if (!_hasMore || loadingMore.value) return;
    loadingMore.value = true;
    final sw = Stopwatch()..start();
    // Append next batch
    final next =
        (_nextIndex + _pageSize) <= _allRows.length
            ? _allRows.sublist(_nextIndex, _nextIndex + _pageSize)
            : _allRows.sublist(_nextIndex, _allRows.length);
    final newVisible = List<ReportRowData>.from(visible.value)..addAll(next);
    _nextIndex = _nextIndex + next.length;
    _hasMore = _nextIndex < _allRows.length;
    visible.value = newVisible;
    loadingMore.value = false;
    sw.stop();
    PerfLogger.instance.record('loadMore', sw.elapsedMilliseconds);
  }

  void _resetPaging() {
    _nextIndex = 0;
    if (_allRows.isEmpty) {
      visible.value = [];
      _hasMore = false;
      return;
    }
    final end = _pageSize < _allRows.length ? _pageSize : _allRows.length;
    visible.value = _allRows.sublist(0, end);
    _nextIndex = end;
    _hasMore = _nextIndex < _allRows.length;
  }

  /// Apply all filters, sorting, dan compute aggregates
  void _applyFilters() {
    final sw = Stopwatch()..start();
    final q = _search.trim().toLowerCase();

    // Filter original _all list (lightweight operations)
    final filtered =
        _all.where((t) {
          final matchSearch =
              q.isEmpty ||
              t.noTicket.toLowerCase().contains(q) ||
              t.vehiclePlate.toLowerCase().contains(q) ||
              t.driverName.toLowerCase().contains(q) ||
              (t.productName ?? '').toLowerCase().contains(q) ||
              (t.supplierName ?? '').toLowerCase().contains(q) ||
              (t.customerName ?? '').toLowerCase().contains(q);

          final matchSupplier =
              _supplierId == null || t.supplierId == _supplierId;
          final matchProduct = _productId == null || t.productId == _productId;
          final matchCustomer = _customerId == null || t.customerId == _customerId;
            final matchPlate =
              _plate == null || _plate!.isEmpty ||
              (t.vehiclePlate ?? '').toLowerCase().contains(_plate!.toLowerCase());
          final inTime = t.inTime;
          final matchStart =
              _startDate == null ||
              inTime.isAtSameMomentAs(_startDate!) ||
              inTime.isAfter(_startDate!);
          final matchEnd =
              _endDate == null ||
              inTime.isAtSameMomentAs(_endDate!) ||
              inTime.isBefore(_endDate!.add(const Duration(days: 1)));

          return matchSearch &&
              matchSupplier &&
              matchProduct &&
              matchCustomer &&
              matchPlate &&
              matchStart &&
              matchEnd;
        }).toList();

    // Sort by inTime
    filtered.sort(
      (a, b) =>
          _sortDesc
              ? b.inTime.compareTo(a.inTime)
              : a.inTime.compareTo(b.inTime),
    );

    shown.value = filtered;
    _computeAggregate(filtered);

    // Map filtered transactions to precomputed rows (fast to render)
    _allRows
      ..clear()
      ..addAll(filtered.map((t) => _mapToRow(t)));

    // Reset batching / visible list
    _resetPaging();

    sw.stop();
    PerfLogger.instance.record('applyFilters', sw.elapsedMilliseconds);
  }

  /// Compute aggregate values dari list yang sudah difilter
  void _computeAggregate(List<ListTransactionJson> list) {
    final total = list.length;
    final totalNetto = list.fold<num>(0, (p, e) => p + e.netto);
    final avg = total == 0 ? 0.0 : totalNetto / total;
    final revenue = list.fold<num>(0, (p, e) => p + e.totalPrice);

    aggregate.value = {
      'count': total,
      'totalNetto': totalNetto,
      'avgNetto': avg,
      'revenue': revenue,
    };
  }

  /// Precompute formatted strings for all transactions currently in `_all`
  void _precomputeAllRows() {
    _allRows
      ..clear()
      ..addAll(_all.map((t) => _mapToRow(t)));
  }

  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final NumberFormat _numFmt = NumberFormat('#,##0.##');

  ReportRowData _mapToRow(ListTransactionJson t) {
    final product = t.productName ?? '';
    final supplier = t.supplierName ?? '';
    final customer = t.customerName ?? '';
    final formattedDate = _dateFmt.format(t.inTime);
    final formattedNetto = '${_numFmt.format(t.netto)} kg';
    final formattedBruto = '${_numFmt.format(t.bruto)} kg';
    final formattedTare = '${_numFmt.format(t.tare)} kg';
    final formattedTotal = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(t.totalPrice);

    return ReportRowData(
      transactionId: t.transactionId,
      noTicket: t.noTicket,
      vehiclePlate: t.vehiclePlate,
      driverName: t.driverName,
      productName: product,
      supplierName: supplier,
      customerName: customer,
      formattedDate: formattedDate,
      formattedNetto: formattedNetto,
      formattedBruto: formattedBruto,
      formattedTare: formattedTare,
      formattedTotal: formattedTotal,
      netto: t.netto,
      bruto: t.bruto,
      tare: t.tare,
      totalPrice: t.totalPrice,
      source: t,
    );
  }

  /// Export placeholder
  /// TODO: Integrate with PrintService when available
  Future<void> exportPlaceholder() async {
    // TODO: Implement actual export using PrintService
    // final printer = PrintServiceStub();
    // if (printer.isAvailable()) {
    //   await printer.print(generateReportContent());
    // }
    await Future.delayed(const Duration(milliseconds: 50)); // noop stub
  }

  String _productName(int id) {
    final p = products.value.firstWhere(
      (e) => e.productId == id,
      orElse:
          () =>
              ListProductJson(productId: id, productName: '', productCode: ''),
    );
    return p.productName ?? '';
  }

  String _supplierName(int id) {
    final s = suppliers.value.firstWhere(
      (e) => e.supplierId == id,
      orElse:
          () => ListSupplierJson(
            supplierId: id,
            supplierName: '',
            supplierAddress: '',
            supplierCity: '',
            supplierSubdistrict: '',
            supplierPostCode: '',
          ),
    );
    return s.supplierName ?? '';
  }

  String _customerName(int id) {
    final c = customers.value.firstWhere(
      (e) => e.customerId == id,
      orElse:
          () => ListCustomerJson(
            customerId: id,
            customerName: '',
            customerAddress: '',
            customerPhone: '',
          ),
    );
    return c.customerName;
  }

  /// Clear all filters dan reset ke state awal
  void clearFilters() {
    _search = '';
    _startDate = null;
    _endDate = null;
    _supplierId = null;
    _productId = null;
    _customerId = null;
    _plate = null;
    _sortDesc = true;
    _nextIndex = 0;
    _applyFilters();
  }

  /// Dispose notifiers
  void dispose() {
    loading.dispose();
    shown.dispose();
    visible.dispose();
    loadingMore.dispose();
    aggregate.dispose();
    suppliers.dispose();
    products.dispose();
    customers.dispose();
    _searchDebounce?.cancel();
  }
}
