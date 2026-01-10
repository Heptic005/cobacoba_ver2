/// Report Controller
/// Tanggung jawab: Semua logic untuk halaman Report
/// - Load data dari DbHelper
/// - Client-side filter, search, sort, pagination
/// - Aggregate calculation (total, avg, revenue)
/// - Export placeholder (TODO: integrate with PrintService)

import 'package:flutter/foundation.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';

class ReportController {
  // State notifiers untuk UI subscribe
  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  final ValueNotifier<List<ListTransactionJson>> shown =
      ValueNotifier<List<ListTransactionJson>>([]);
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
  String _search = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _supplierId;
  int? _productId;
  bool _sortDesc = true;

  // Pagination state
  int _pageSize = 20;
  int _currentPage = 0;

  // Public getters for UI
  String get search => _search;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get supplierId => _supplierId;
  int? get productId => _productId;
  bool get sortDesc => _sortDesc;
  int get pageSize => _pageSize;
  int get currentPage => _currentPage;
  int get totalPages =>
      shown.value.isEmpty ? 1 : ((shown.value.length - 1) ~/ _pageSize) + 1;

  /// Constructor dengan optional initialData untuk testing
  ReportController({List<ListTransactionJson>? initialData}) {
    if (initialData != null) {
      _all.addAll(initialData);
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
  void setSearch(String s) {
    _search = s;
    _applyFilters();
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

  /// Toggle sort order (asc/desc by inTime)
  void toggleSort() {
    _sortDesc = !_sortDesc;
    _applyFilters();
  }

  /// Set page size dan reset ke halaman pertama
  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 0;
    // No need to re-filter, just notify
    shown.value = List.from(shown.value);
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

  /// Apply all filters, sorting, dan compute aggregates
  void _applyFilters() {
    final q = _search.trim().toLowerCase();

    final list =
        _all.where((t) {
          // Search filter: case-insensitive pada noTicket, vehiclePlate, driverName
          final matchSearch =
              q.isEmpty ||
              t.noTicket.toLowerCase().contains(q) ||
              t.vehiclePlate.toLowerCase().contains(q) ||
              t.driverName.toLowerCase().contains(q) ||
              _productName(t.productId).toLowerCase().contains(q) ||
              _supplierName(t.supplierId).toLowerCase().contains(q) ||
              _customerName(t.customerId).toLowerCase().contains(q);

          // Supplier filter
          final matchSupplier =
              _supplierId == null || t.supplierId == _supplierId;

          // Product filter
          final matchProduct = _productId == null || t.productId == _productId;

          // Date range filter (inclusive)
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
              matchStart &&
              matchEnd;
        }).toList();

    // Sort by inTime
    list.sort((a, b) {
      return _sortDesc
          ? b.inTime.compareTo(a.inTime)
          : a.inTime.compareTo(b.inTime);
    });

    shown.value = list;
    _currentPage = 0;

    debugPrint('Report: After filter, showing ${list.length} transactions');

    _computeAggregate(list);
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
    _sortDesc = true;
    _currentPage = 0;
    _applyFilters();
  }

  /// Dispose notifiers
  void dispose() {
    loading.dispose();
    shown.dispose();
    aggregate.dispose();
    suppliers.dispose();
    products.dispose();
    customers.dispose();
  }
}
