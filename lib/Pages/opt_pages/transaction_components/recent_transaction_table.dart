import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';

//TODO: Remove Load Draft Function

enum TransactionStatusFilter { all, draft, finished }

/// Compact recent transactions table with PDF/Print actions.
class RecentTransactionTable extends StatefulWidget {
  final TextEditingController searchController;
  final bool sortDesc;
  final TransactionStatusFilter statusFilter;
  final List<ListTransactionJson> transactions;
  final List<ListSupplierJson> suppliers;
  final List<ListCustomerJson> customers;
  final List<ListProductJson> products;
  final Color cardBg;
  final Color textGrey;
  final Color primaryCyan;
  final Color inputBg;
  final ValueChanged<TransactionStatusFilter> onFilterChanged;

  final Future<void> Function(Map<String, Object?> item) onShowDetailMap;
  final Future<void> Function(Map<String, Object?> item) onPrintMap;
  final Future<void> Function(Map<String, Object?> item) onExportPdfMap;
  final Future<void> Function(ListTransactionJson tx) onContinueAuto;
  final void Function(ListTransactionJson tx) onLoadDraft;
  final void Function(String text) onCopyToClipboard;

  const RecentTransactionTable({
    super.key,
    required this.searchController,
    required this.sortDesc,
    required this.statusFilter,
    required this.transactions,
    required this.suppliers,
    required this.customers,
    required this.products,
    required this.cardBg,
    required this.textGrey,
    required this.primaryCyan,
    required this.inputBg,
    required this.onFilterChanged,
    required this.onShowDetailMap,
    required this.onPrintMap,
    required this.onExportPdfMap,
    required this.onContinueAuto,
    required this.onLoadDraft,
    required this.onCopyToClipboard,
  });

  @override
  State<RecentTransactionTable> createState() => _RecentTransactionTableState();
}

class _RecentTransactionTableState extends State<RecentTransactionTable> {
  static const int _pageSize = 8;
  int _visibleCount = _pageSize;
  bool _isSearching = false;
  Timer? _debounce;

  String _fmt(DateTime? d) => d == null ? '' : DateFormat('dd MMM HH:mm').format(d);

  String _productName(ListTransactionJson tx) {
    if (tx.productName != null && tx.productName!.isNotEmpty) return tx.productName!;
    final found = widget.products.firstWhere(
      (p) => p.productId == tx.productId,
      orElse: () => ListProductJson(productId: 0, productName: '', productCode: ''),
    );
    return found.productName;
  }

  String _supplierName(ListTransactionJson tx) {
    if (tx.supplierName != null && tx.supplierName!.isNotEmpty) return tx.supplierName!;
    final found = widget.suppliers.firstWhere(
      (s) => s.supplierId == tx.supplierId,
      orElse: () => ListSupplierJson(
        supplierName: '',
        supplierAddress: '',
        supplierCity: '',
        supplierSubdistrict: '',
        supplierPostCode: '',
      ),
    );
    return found.supplierName;
  }

  String _customerName(ListTransactionJson tx) {
    if (tx.customerName != null && tx.customerName!.isNotEmpty) return tx.customerName!;
    final found = widget.customers.firstWhere(
      (c) => c.customerId == tx.customerId,
      orElse: () => ListCustomerJson(
        customerName: '',
        customerAddress: '',
        customerPhone: '',
      ),
    );
    return found.customerName;
  }

  Map<String, Object?> _asMap(ListTransactionJson tx) {
    final map = Map<String, Object?>.from(tx.toJson());
    map['productName'] = _productName(tx);
    map['supplierName'] = _supplierName(tx);
    map['customerName'] = _customerName(tx);
    return map;
  }

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = _pageSize;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<ListTransactionJson> combined = List.of(widget.transactions);

    final query = widget.searchController.text.trim().toLowerCase();
        final filtered = combined.where((tx) {
          // Draft status only from flag to avoid misclassifying finished items.
          final isDraft = tx.isDrafted == 1;

      if (widget.statusFilter == TransactionStatusFilter.draft && !isDraft) {
        return false;
      }
      if (widget.statusFilter == TransactionStatusFilter.finished && isDraft) {
        return false;
      }

      if (!isDraft) {
        if (tx.outTime == null) return false;
        if (!tx.outTime!.isAfter(tx.inTime)) return false;
      }
      if (query.isEmpty) return true;
      final ticket = tx.noTicket.toLowerCase();
      final plate = tx.vehiclePlate.toLowerCase();
      return ticket.contains(query) || plate.contains(query);
    }).toList();

    filtered.sort((a, b) => widget.sortDesc ? b.inTime.compareTo(a.inTime) : a.inTime.compareTo(b.inTime));

    final showing = filtered.take(_visibleCount).toList();

    final cardBg = widget.cardBg;
    final textGrey = widget.textGrey;
    final inputBg = widget.inputBg;
    final primaryCyan = widget.primaryCyan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textGrey.withAlpha((0.12 * 255).round()), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildStatusFilters(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search ticket or plate',
                    hintStyle: TextStyle(color: textGrey.withAlpha((0.6 * 255).round())),
                    filled: true,
                    fillColor: inputBg,
                    prefixIcon: Icon(Icons.search, color: textGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Sort by time',
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(widget.sortDesc ? Icons.arrow_downward : Icons.arrow_upward, color: textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSearching)
            // simple skeletons
            Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(children: [
                    Expanded(
                      child: Container(height: 56, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8))),
                    ),
                  ]),
                ),
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('No matching transactions', style: TextStyle(color: textGrey)),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: showing.length,
                  separatorBuilder: (_, __) => Divider(color: textGrey.withAlpha((0.12 * 255).round())),
                  itemBuilder: (ctx, i) {
                    final tx = showing[i];
                        final isDraft = tx.isDrafted == 1;
                    final inTime = _fmt(tx.inTime);
                    final outTime = _fmt(tx.outTime);
                    final prodName = _productName(tx);
                    final supName = _supplierName(tx);
                    final custName = _customerName(tx);

                    return ExpansionTile(
                      key: PageStorageKey<String>('recent-${tx.noTicket}'),
                      tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      collapsedIconColor: textGrey,
                      iconColor: textGrey,
                      initiallyExpanded: false,
                      maintainState: false,
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tx.noTicket,
                                      style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    isDraft
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: primaryCyan,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'DRAFT',
                                              style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppThemes.statusFinished,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'FINISHED',
                                              style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tx.vehiclePlate,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tx.driverName} - $prodName',
                                  style: TextStyle(color: textGrey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$inTime - $outTime',
                                  style: TextStyle(color: textGrey.withAlpha((0.85 * 255).round()), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${tx.bruto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Bruto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${tx.netto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Netto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${tx.nettoAfterCut.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('After cut', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDraft ? primaryCyan.withOpacity(0.2) : AppThemes.statusFinished.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDraft ? primaryCyan : AppThemes.statusFinished,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isDraft ? 'DRAFT' : 'FINISHED',
                              style: TextStyle(
                                color: isDraft ? primaryCyan : AppThemes.statusFinished,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: cardBg,
                            icon: Icon(Icons.more_vert, color: textGrey),
                            onSelected: (value) async {
                              final map = _asMap(tx);
                              if (value == 'copy') {
                                widget.onCopyToClipboard(tx.noTicket);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket copied')),
                                );
                              } else if (value == 'detail') {
                                await widget.onShowDetailMap(map);
                              } else if (value == 'print') {
                                await widget.onPrintMap(map);
                              } else if (value == 'pdf') {
                                await widget.onExportPdfMap(map);
                              } else if (value == 'continue') {
                                await widget.onContinueAuto(tx);
                              } else if (value == 'loadDraft') {
                                widget.onLoadDraft(tx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Draft loaded')),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pdf',
                                child: Text('PDF', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                              ),
                              PopupMenuItem(
                                value: 'print',
                                child: Text('Print', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy ticket', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                              ),
                              PopupMenuItem(
                                value: 'detail',
                                child: Text('Detail', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Product: $prodName', style: TextStyle(color: textGrey)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: Text('Supplier: ${supName.isEmpty ? '-' : supName}', style: TextStyle(color: textGrey))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Customer: ${custName.isEmpty ? '-' : custName}', style: TextStyle(color: textGrey))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                if (filtered.length > showing.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _visibleCount = (_visibleCount + _pageSize).clamp(0, filtered.length);
                          });
                        },
                        child: const Text('Load more'),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: widget.textGrey.withAlpha((0.75 * 255).round()), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _statusChip(TransactionStatusFilter.all, 'All', widget.textGrey),
        _statusChip(TransactionStatusFilter.draft, 'Draft', widget.primaryCyan),
        _statusChip(TransactionStatusFilter.finished, 'Finished', AppThemes.statusFinished),
      ],
    );
  }

  Widget _statusChip(TransactionStatusFilter filter, String label, Color accent) {
    final isSelected = widget.statusFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.black : widget.textGrey,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => widget.onFilterChanged(filter),
      selectedColor: accent.withOpacity(0.24),
      backgroundColor: widget.inputBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: isSelected ? accent : widget.textGrey.withAlpha((0.45 * 255).round()), width: 0.8),
    );
  }
}
