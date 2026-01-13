import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';

/// Compact recent transactions table with PDF/Print actions.
class RecentTransactionTable extends StatelessWidget {
  final TextEditingController searchController;
  final bool sortDesc;
  final Set<String> draftTickets;
  final List<ListTransactionJson> transactions;
  final List<ListSupplierJson> suppliers;
  final List<ListCustomerJson> customers;
  final List<ListProductJson> products;
  final Color cardBg;
  final Color textGrey;
  final Color primaryCyan;
  final Color inputBg;

  final Future<void> Function(Map<String, Object?> item) onShowDetailMap;
  final Future<void> Function(Map<String, Object?> item) onPrintMap;
  final Future<void> Function(Map<String, Object?> item) onExportPdfMap;
  final Future<void> Function(ListTransactionJson tx) onContinueAuto;
  final void Function(ListTransactionJson tx) onLoadDraft;
  final void Function(String text) onCopyToClipboard;

  static final ListTransactionJson _staticSample = ListTransactionJson(
    transactionId: 9999,
    vehiclePlate: 'B 1234 XX',
    driverName: 'Static Driver',
    supplierId: 0,
    customerId: 0,
    productId: 0,
    cut: 0,
    kubikasi: 0,
    noDO: 'DO-001',
    noContainer: 0,
    temperature: 0,
    price: 0,
    additionalInformation: 'Sample data',
    noTicket: 'SAMPLE-RECENT',
    inTime: DateTime.now().subtract(const Duration(hours: 3)),
    outTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    totalPrice: 0,
    bruto: 18000,
    tare: 7000,
    netto: 11000,
    nettoAfterCut: 11000,
    driverLabel: 0,
    operatorLabel: 0,
    managerLabel: 0,
    headWarehouseLabel: 0,
    isDrafted: 0,
    isManual: 0,
    supplierName: 'Sample Supplier',
    customerName: 'Sample Customer',
    productName: 'Sample Product',
  );

  const RecentTransactionTable({
    super.key,
    required this.searchController,
    required this.sortDesc,
    required this.draftTickets,
    required this.transactions,
    required this.suppliers,
    required this.customers,
    required this.products,
    required this.cardBg,
    required this.textGrey,
    required this.primaryCyan,
    required this.inputBg,
    required this.onShowDetailMap,
    required this.onPrintMap,
    required this.onExportPdfMap,
    required this.onContinueAuto,
    required this.onLoadDraft,
    required this.onCopyToClipboard,
  });

  String _fmt(DateTime? d) => d == null ? '' : DateFormat('dd MMM HH:mm').format(d);

  String _productName(ListTransactionJson tx) {
    if (tx.productName != null && tx.productName!.isNotEmpty) return tx.productName!;
    final found = products.firstWhere(
      (p) => p.productId == tx.productId,
      orElse: () => ListProductJson(productId: 0, productName: '', productCode: ''),
    );
    return found.productName;
  }

  String _supplierName(ListTransactionJson tx) {
    if (tx.supplierName != null && tx.supplierName!.isNotEmpty) return tx.supplierName!;
    final found = suppliers.firstWhere(
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
    final found = customers.firstWhere(
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
  Widget build(BuildContext context) {
    final List<ListTransactionJson> combined = List.of(transactions);
    final hasStatic = combined.any((e) => e.noTicket == _staticSample.noTicket);
    if (!hasStatic) combined.add(_staticSample);

    final query = searchController.text.trim().toLowerCase();
    final filtered = combined.where((tx) {
      if (tx.outTime == null) return false;
      if (!tx.outTime!.isAfter(tx.inTime)) return false;
      if (query.isEmpty) return true;
      final ticket = tx.noTicket.toLowerCase();
      final plate = tx.vehiclePlate.toLowerCase();
      return ticket.contains(query) || plate.contains(query);
    }).toList();

    filtered.sort(
      (a, b) => sortDesc ? b.inTime.compareTo(a.inTime) : a.inTime.compareTo(b.inTime),
    );

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
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
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Sort by time',
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(sortDesc ? Icons.arrow_downward : Icons.arrow_upward, color: textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('No matching completed transactions', style: TextStyle(color: textGrey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: textGrey.withAlpha((0.12 * 255).round())),
              itemBuilder: (ctx, i) {
                final tx = filtered[i];
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
                                          color: Colors.greenAccent,
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
                      PopupMenuButton<String>(
                        color: cardBg,
                        icon: Icon(Icons.more_vert, color: textGrey),
                        onSelected: (value) async {
                          final map = _asMap(tx);
                          if (value == 'copy') {
                            onCopyToClipboard(tx.noTicket);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket copied')),
                            );
                          } else if (value == 'detail') {
                            await onShowDetailMap(map);
                          } else if (value == 'print') {
                            await onPrintMap(map);
                          } else if (value == 'pdf') {
                            await onExportPdfMap(map);
                          } else if (value == 'continue') {
                            await onContinueAuto(tx);
                          } else if (value == 'loadDraft') {
                            onLoadDraft(tx);
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
                          if (isDraft)
                            PopupMenuItem(
                              value: 'continue',
                              child: Text('Continue Netto', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                            ),
                          if (isDraft)
                            PopupMenuItem(
                              value: 'loadDraft',
                              child: Text('Load Draft', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()))),
                            ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Product', prodName),
                          _infoRow('Supplier', supName),
                          _infoRow('Customer', custName),
                          _infoRow('In - Out', '$inTime - $outTime'),
                          _infoRow('No. DO', tx.noDO ?? '-'),
                          _infoRow('Notes', tx.additionalInformation ?? '-'),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
              style: TextStyle(color: textGrey.withAlpha((0.75 * 255).round()), fontSize: 12),
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
}
