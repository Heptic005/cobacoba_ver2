import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Pages/transaction_controller.dart';

/// Reusable dialog for showing transaction details.
class TransactionDetailDialog extends StatelessWidget {
  final Map<String, Object?>? itemMap;
  final ListTransactionJson? itemTx;
  final TransactionController controller;
  final Color cardBg;
  final Color textGrey;
  final Color primaryCyan;
  final VoidCallback? onPrint;

  const TransactionDetailDialog({
    super.key,
    this.itemMap,
    this.itemTx,
    required this.controller,
    required this.cardBg,
    required this.textGrey,
    required this.primaryCyan,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    // Determine source: itemTx takes priority if provided
    final bool fromTx = itemTx != null;

    String ticket = '';
    String plate = '';
    String driver = '';
    String productName = '';
    String supplierName = '';
    String customerName = '';
    String intime = '';
    String? outtime;
    String bruto = '';
    String tare = '';
    String netto = '';
    String afterCut = '';
    String? notes;

    if (fromTx) {
      final tx = itemTx!;
      ticket = tx.noTicket;
      plate = tx.vehiclePlate;
      driver = tx.driverName;
      productName = controller.productNameFromId(tx.productId);
      supplierName = controller.supplierNameFromId(tx.supplierId);
      customerName = controller.customerNameFromId(tx.customerId);
      intime = DateFormat('dd MMM yyyy HH:mm').format(tx.inTime);
      outtime = tx.outTime.isAfter(tx.inTime) ? DateFormat('dd MMM yyyy HH:mm').format(tx.outTime) : null;
      bruto = '${tx.bruto} kg';
      tare = '${tx.tare} kg';
      netto = '${tx.netto} kg';
      afterCut = '${tx.nettoAfterCut} kg';
      notes = tx.additionalInformation;
    } else if (itemMap != null) {
      final item = itemMap!;
      final pid = controller.intFrom(item['productId']);
      final sid = controller.intFrom(item['supplierId']);
      final cid = controller.intFrom(item['customerId']);

      ticket = item['noTicket']?.toString() ?? '';
      plate = item['vehiclePlate']?.toString() ?? '-';
      driver = item['driverName']?.toString() ?? '-';

      productName = (item['productName'] ?? item['ProductName'])?.toString().trim().isNotEmpty == true
          ? (item['productName'] ?? item['ProductName']).toString()
          : controller.productNameFromId(pid);
      supplierName = (item['supplierName'] ?? item['SupplierName'])?.toString().trim().isNotEmpty == true
          ? (item['supplierName'] ?? item['SupplierName']).toString()
          : controller.supplierNameFromId(sid);
      customerName = (item['customerName'] ?? item['CustomerName'])?.toString().trim().isNotEmpty == true
          ? (item['customerName'] ?? item['CustomerName']).toString()
          : controller.customerNameFromId(cid);

      intime = controller.formatShortDate(item['inTime']?.toString());
      final outtimeRaw = item['outTime']?.toString();
      outtime = (outtimeRaw != null && outtimeRaw.isNotEmpty) ? controller.formatShortDate(outtimeRaw) : null;

      bruto = '${item['bruto'] ?? 0} kg';
      tare = '${item['tare'] ?? 0} kg';
      netto = '${item['netto'] ?? 0} kg';
      afterCut = '${item['nettoAfterCut'] ?? item['netto'] ?? 0} kg';
      notes = item['additionalInformation']?.toString();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LayoutBuilder(builder: (context, constraints) {
            final maxHeight = MediaQuery.of(context).size.height * 0.8;
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textGrey.withAlpha((0.08 * 255).round())),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.isNotEmpty ? ticket : 'Detail', style: TextStyle(color: primaryCyan, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Divider(color: textGrey.withAlpha((0.12 * 255).round())),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        runSpacing: 10,
                        spacing: 20,
                        children: [
                          _detailRow('Plate', plate),
                          _detailRow('Driver', driver),
                          _detailRow('Product', productName.isNotEmpty ? productName : '-'),
                          _detailRow('Supplier', supplierName.isNotEmpty ? supplierName : '-'),
                          _detailRow('Customer', customerName.isNotEmpty ? customerName : '-'),
                          _detailRow('In', intime),
                          _detailRow('Out', outtime ?? '-'),
                          _detailRow('Bruto', bruto),
                          _detailRow('Tare', tare),
                          _detailRow('Netto', netto),
                          _detailRow('After cut', afterCut),
                          if (notes != null && notes.isNotEmpty) _detailRow('Notes', notes),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close', style: TextStyle(color: textGrey)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPrint?.call();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.black),
                        child: const Text('Print'),
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
