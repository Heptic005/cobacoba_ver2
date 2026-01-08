import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';

class RecentTransactions extends StatelessWidget {
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
  final Future<void> Function(ListTransactionJson tx) onContinueAuto;
  final void Function(ListTransactionJson tx) onLoadDraft;
  final void Function(String text) onCopyToClipboard;

  const RecentTransactions({
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
    required this.onContinueAuto,
    required this.onLoadDraft,
    required this.onCopyToClipboard,
  });

  String _formatShortDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) return DateFormat('dd MMM HH:mm').format(dt);
      return raw;
    } catch (e) {
      return raw;
    }
  }

  DateTime? _parseDateMaybe(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is double) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(s);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _productNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final p = products.firstWhere((e) => e.productId == id, orElse: () => ListProductJson(productId: 0, productName: '', productCode: ''));
      return p.productName;
    } catch (_) {
      return '';
    }
  }

  String _supplierNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final s = suppliers.firstWhere((e) => e.supplierId == id, orElse: () => ListSupplierJson(supplierName: '', supplierAddress: '', supplierCity: '', supplierSubdistrict: '', supplierPostCode: ''));
      return s.supplierName;
    } catch (_) {
      return '';
    }
  }

  String _customerNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final c = customers.firstWhere((e) => e.customerId == id, orElse: () => ListCustomerJson(customerName: '', customerAddress: '', customerPhone: ''));
      return c.customerName;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textGrey.withAlpha((0.12 * 255).round()), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Sort by time',
                child: IconButton(
                  onPressed: () {
                    // parent should toggle sort; but widget is stateless so we do nothing here
                  },
                  icon: Icon(sortDesc ? Icons.arrow_downward : Icons.arrow_upward, color: textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ListTransactionJson>>(
            future: DbHelper.instance.getListTransaction(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final rawItems = snapshot.data!;
                final query = searchController.text.trim().toLowerCase();
                final items = rawItems.where((it) {
                  if (query.isEmpty) return true;
                  final ticket = (it.noTicket.toString().toLowerCase());
                  final plate = (it.vehiclePlate).toString().toLowerCase();
                  return ticket.contains(query) || plate.contains(query);
                }).toList();

                items.sort((a, b) {
                  DateTime? da = _parseDateMaybe(a.inTime);
                  DateTime? dbt = _parseDateMaybe(b.inTime);
                  if (da == null && dbt == null) return 0;
                  if (da == null) return sortDesc ? 1 : -1;
                  if (dbt == null) return sortDesc ? -1 : 1;
                  return sortDesc ? dbt.compareTo(da) : da.compareTo(dbt);
                });

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(color: textGrey.withAlpha((0.12 * 255).round())),
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    final plate = it.vehiclePlate;
                    final brutoNum = it.bruto;
                    final nettoNum = it.netto;
                    final afterCutNum = it.nettoAfterCut;
                    final bruto = brutoNum.toDouble();
                    final netto = nettoNum.toDouble();
                    final afterCut = afterCutNum.toDouble();
                    final intimeRaw = it.inTime.toString();
                    final intime = _formatShortDate(intimeRaw);
                    final outtime = it.outTime != null ? _formatShortDate(it.outTime.toString()) : null;
                    final noTicket = it.noTicket;
                    final driver = it.driverName;
                    final productName = _productNameFromId(it.productId);
                    final supplierName = _supplierNameFromId(it.supplierId);
                    final customerName = _customerNameFromId(it.customerId);
                    final cut = it.cut.toString();
                    final doNo = it.noDO;
                    final container = it.noContainer?.toString();
                    final temp = it.temperature?.toString();
                    final price = it.price?.toString();
                    final notes = it.additionalInformation;

                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(vertical: 4),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(noTicket, style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  if (draftTickets.contains(noTicket)) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryCyan, borderRadius: BorderRadius.circular(12)), child: const Text('DRAFT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11))),
                                ]),
                                const SizedBox(height: 6),
                                Text(plate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('$driver • ${productName.isNotEmpty ? productName : '-'}', style: TextStyle(color: textGrey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(outtime != null ? '$intime → $outtime' : '$intime • In progress', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()), fontSize: 11)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: cardBg,
                            icon: Icon(Icons.more_vert, color: textGrey),
                            onSelected: (v) async {
                              if (v == 'copy') {
                                onCopyToClipboard(noTicket);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket copied')));
                              } else if (v == 'detail') {
                                await onShowDetailMap(it.toJson());
                              } else if (v == 'print') {
                                await onPrintMap(it.toJson());
                              } else if (v == 'continue') {
                                await onContinueAuto(it);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'copy', child: Text('Copy ticket', style: TextStyle(color: Colors.white))),
                              PopupMenuItem(value: 'detail', child: Text('Detail', style: TextStyle(color: Colors.white))),
                              PopupMenuItem(value: 'print', child: Text('Print', style: TextStyle(color: Colors.white))),
                              if (draftTickets.contains(noTicket)) PopupMenuItem(value: 'continue', child: Text('Continue Netto', style: TextStyle(color: Colors.white))),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${bruto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('Bruto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${netto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('Netto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${afterCut.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('After cut', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                        ],
                      ),
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (supplierName.isNotEmpty) Text('Supplier: $supplierName', style: TextStyle(color: textGrey)) else if (it.supplierId != 0) Text('Supplier: ${it.supplierId}', style: TextStyle(color: textGrey)),
                          if (customerName.isNotEmpty) Text('Customer: $customerName', style: TextStyle(color: textGrey)) else if (it.customerId != 0) Text('Customer: ${it.customerId}', style: TextStyle(color: textGrey)),
                          if (doNo != null && doNo.isNotEmpty) Text('No DO: $doNo', style: TextStyle(color: textGrey)),
                          if (container != null) Text('No Container: $container', style: TextStyle(color: textGrey)),
                          Text('Potongan: $cut %', style: TextStyle(color: textGrey)),
                          if (price != null) Text('Harga/kg: $price', style: TextStyle(color: textGrey)),
                          if (temp != null) Text('Suhu: $temp', style: TextStyle(color: textGrey)),
                          if (notes != null && notes.isNotEmpty) Text('Keterangan: ${notes.length > 100 ? "${notes.substring(0, 100)}..." : notes}', style: TextStyle(color: textGrey)),
                          const SizedBox(height: 8),
                          Row(children: [
                            (() {
                              final dl = it.driverLabel;
                              final ol = it.operatorLabel;
                              final ml = it.managerLabel;
                              final hl = it.headWarehouseLabel;
                              bool has(dynamic v) => v == 1 || v == true || v?.toString() == '1';
                              final icons = <Widget>[];
                              if (has(dl)) icons.add(Icon(Icons.person, color: primaryCyan, size: 16));
                              if (has(ol)) icons.addAll([const SizedBox(width: 6), Icon(Icons.admin_panel_settings, color: primaryCyan, size: 16)]);
                              if (has(ml)) icons.addAll([const SizedBox(width: 6), Icon(Icons.verified_user, color: primaryCyan, size: 16)]);
                              if (has(hl)) icons.addAll([const SizedBox(width: 6), Icon(Icons.home_work, color: primaryCyan, size: 16)]);
                              return Row(mainAxisSize: MainAxisSize.min, children: icons);
                            })()
                          ])
                        ])
                      ],
                    );
                  },
                );
              }

              final query = searchController.text.trim().toLowerCase();
              final List<ListTransactionJson> filtered = transactions.where((tx) {
                if (query.isEmpty) return true;
                final ticket = tx.noTicket.toLowerCase();
                final plate = tx.vehiclePlate.toLowerCase();
                return ticket.contains(query) || plate.contains(query);
              }).toList();
              filtered.sort((a, b) => sortDesc ? b.inTime.compareTo(a.inTime) : a.inTime.compareTo(b.inTime));

              if (filtered.isEmpty) {
                return Padding(padding: const EdgeInsets.all(20.0), child: Center(child: Text('No matching transactions', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round())))));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(color: textGrey.withAlpha((0.12 * 255).round())),
                itemBuilder: (ctx, i) {
                  final tx = filtered[i];
                  final intime = DateFormat('dd MMM HH:mm').format(tx.inTime);
                  final outtime = (tx.outTime != null && tx.outTime!.isAfter(tx.inTime)) ? DateFormat('dd MMM HH:mm').format(tx.outTime!) : null;
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(vertical: 4),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    title: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Text(tx.noTicket, style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700)), const SizedBox(width: 8), if (draftTickets.contains(tx.noTicket)) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryCyan, borderRadius: BorderRadius.circular(12)), child: const Text('DRAFT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11))) ]),
                        const SizedBox(height: 6),
                        Text(tx.vehiclePlate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${tx.driverName} • ${_productNameFromId(tx.productId)}', style: TextStyle(color: textGrey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(outtime != null ? '$intime → $outtime' : '$intime • In progress', style: TextStyle(color: textGrey.withAlpha((0.9 * 255).round()), fontSize: 11)),
                      ])),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${tx.bruto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('Bruto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${tx.netto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('Netto', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${tx.nettoAfterCut.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('After cut', style: TextStyle(color: textGrey.withAlpha((0.7 * 255).round()), fontSize: 10))]),
                      PopupMenuButton<String>(
                        color: cardBg,
                        icon: Icon(Icons.more_vert, color: textGrey),
                        onSelected: (v) {
                          if (v == 'copy') {
                            onCopyToClipboard(tx.noTicket);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket copied')));
                          } else if (v == 'detail') {
                            onShowDetailMap(tx.toJson());
                          } else if (v == 'print') {
                            onPrintMap(tx.toJson());
                          } else if (v == 'continue') {
                            onLoadDraft(tx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loaded draft for Continue Netto')));
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'copy', child: Text('Copy ticket', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'detail', child: Text('Detail', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'print', child: Text('Print', style: TextStyle(color: Colors.white))),
                          if (draftTickets.contains(tx.noTicket)) PopupMenuItem(value: 'continue', child: Text('Continue Netto', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ]),
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Supplier: ${_supplierNameFromId(tx.supplierId)}', style: TextStyle(color: textGrey)),
                        Text('Customer: ${_customerNameFromId(tx.customerId)}', style: TextStyle(color: textGrey)),
                        if (tx.noDO != null) Text('No DO: ${tx.noDO}', style: TextStyle(color: textGrey)),
                        if (tx.noContainer != null) Text('No Container: ${tx.noContainer}', style: TextStyle(color: textGrey)),
                        Text('Potongan: ${tx.cut} %', style: TextStyle(color: textGrey)),
                        if (tx.price != null) Text('Harga/kg: ${tx.price}', style: TextStyle(color: textGrey)),
                        if (tx.temperature != null) Text('Suhu: ${tx.temperature}', style: TextStyle(color: textGrey)),
                        if (tx.additionalInformation != null) Text('Keterangan: ${tx.additionalInformation}', style: TextStyle(color: textGrey)),
                      ])
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
