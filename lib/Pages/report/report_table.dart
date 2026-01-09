/// Report Data Table Widget
/// Komponen tabel data transaksi untuk halaman Report

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/report/report_widgets.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/features/transaction/services/clipboard_service.dart';

/// Widget utama untuk Data Table
class ReportDataTable extends StatelessWidget {
  final ReportController controller;
  final ClipboardServiceImpl clipboard;
  final String Function(int) getSupplierName;
  final String Function(int) getProductName;
  final String Function(int) getCustomerName;
  final Function(String) onSnack;

  const ReportDataTable({
    super.key,
    required this.controller,
    required this.clipboard,
    required this.getSupplierName,
    required this.getProductName,
    required this.getCustomerName,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ListTransactionJson>>(
      valueListenable: controller.shown,
      builder: (_, list, __) {
        if (list.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: kTextGrey),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada data',
                    style: TextStyle(fontSize: 16, color: kTextGrey),
                  ),
                ],
              ),
            ),
          );
        }

        final pageItems = controller.pageItems();
        return Container(
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Menampilkan ${pageItems.length} hasil',
                  style: const TextStyle(color: kTextGrey, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kInputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _TableHeader('Nomor Tiket', flex: 2),
                    _TableHeader('Plat Nomor', flex: 2),
                    _TableHeader('Produk', flex: 1),
                    _TableHeader('Supplier', flex: 2),
                    _TableHeader('Customer', flex: 2),
                    _TableHeader('Bruto', flex: 1, align: TextAlign.right),
                    _TableHeader('Tara', flex: 1, align: TextAlign.right),
                    _TableHeader(
                      'Setelah Potongan',
                      flex: 1,
                      align: TextAlign.right,
                    ),
                    _TableHeader('Total', flex: 1, align: TextAlign.right),
                    _TableHeader('Status', flex: 2, align: TextAlign.center),
                    _TableHeader('Aksi', flex: 1, align: TextAlign.center),
                  ],
                ),
              ),
              ...pageItems.map(
                (t) => TableRow(
                  transaction: t,
                  clipboard: clipboard,
                  getSupplierName: getSupplierName,
                  getProductName: getProductName,
                  getCustomerName: getCustomerName,
                  onSnack: onSnack,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Table header widget
class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _TableHeader(this.text, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: kTextGrey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: align,
      ),
    );
  }
}

/// Table row widget untuk setiap transaksi
class TableRow extends StatelessWidget {
  final ListTransactionJson transaction;
  final ClipboardServiceImpl clipboard;
  final String Function(int) getSupplierName;
  final String Function(int) getProductName;
  final String Function(int) getCustomerName;
  final Function(String) onSnack;

  const TableRow({
    super.key,
    required this.transaction,
    required this.clipboard,
    required this.getSupplierName,
    required this.getProductName,
    required this.getCustomerName,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final isManual = transaction.isManual == 1;
    final isDraft = transaction.isDrafted == 1;
    final afterCut = transaction.nettoAfterCut;

    final statusText = isManual ? 'Manual' : (isDraft ? 'Menunggu' : 'Selesai');
    final statusColor =
        isManual ? kStatusManual : (isDraft ? kStatusMenunggu : kStatusSelesai);

    return InkWell(
      onTap:
          () => showTransactionDetailDialog(
            context,
            transaction,
            getSupplierName,
            getProductName,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kInputBg, width: 1)),
        ),
        child: Row(
          children: [
            // Nomor Tiket + Tanggal
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.noTicket,
                    style: const TextStyle(
                      color: kPrimaryCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateTimeFullFormat.format(transaction.inTime),
                    style: TextStyle(
                      color: kTextGrey.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Plat Nomor + Driver
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.vehiclePlate,
                    style: const TextStyle(
                      color: kTextWhite,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.driverName,
                    style: TextStyle(
                      color: kTextGrey.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Produk
            Expanded(
              flex: 1,
              child: Text(
                getProductName(transaction.productId),
                style: const TextStyle(color: kTextWhite, fontSize: 13),
              ),
            ),
            // Supplier
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getSupplierName(transaction.supplierId),
                    style: const TextStyle(color: kTextWhite, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PT',
                    style: TextStyle(
                      color: kTextGrey.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Customer
            Expanded(
              flex: 2,
              child: Text(
                getCustomerName(transaction.customerId),
                style: const TextStyle(color: kTextWhite, fontSize: 13),
              ),
            ),
            // Bruto
            Expanded(
              flex: 1,
              child: Text(
                '${weightFormat.format(transaction.bruto)} kg',
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
            // Tara
            Expanded(
              flex: 1,
              child: Text(
                '${weightFormat.format(transaction.tare)} kg',
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
            // Setelah Potongan
            Expanded(
              flex: 1,
              child: Text(
                '${weightFormat.format(afterCut)} kg',
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
            // Total
            Expanded(
              flex: 1,
              child: Text(
                currencyFormat.format(transaction.totalPrice),
                style: const TextStyle(
                  color: kPrimaryCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: StatusBadge(text: statusText, color: statusColor),
                ),
              ),
            ),
            // Aksi
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        size: 16,
                        color: kTextGrey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => showTransactionDetailDialog(
                            context,
                            transaction,
                            getSupplierName,
                            getProductName,
                          ),
                      tooltip: 'Lihat',
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 16,
                        color: kTextGrey,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      color: kCardBg,
                      onSelected: (v) {
                        if (v == 'copy_ticket') {
                          clipboard.copy(transaction.noTicket);
                          onSnack('No. Tiket disalin');
                        }
                        if (v == 'copy_plate') {
                          clipboard.copy(transaction.vehiclePlate);
                          onSnack('Plat disalin');
                        }
                      },
                      itemBuilder:
                          (_) => [
                            PopupMenuItem(
                              value: 'copy_ticket',
                              child: Text(
                                'Salin No. Tiket',
                                style: TextStyle(color: kTextWhite),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copy_plate',
                              child: Text(
                                'Salin Plat',
                                style: TextStyle(color: kTextWhite),
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
      ),
    );
  }
}

/// Pagination widget
class ReportPagination extends StatelessWidget {
  final ReportController controller;
  final VoidCallback onUpdate;

  const ReportPagination({
    super.key,
    required this.controller,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ListTransactionJson>>(
      valueListenable: controller.shown,
      builder: (_, list, __) {
        final total = controller.totalPages;
        final current = controller.currentPage;
        final start = list.isEmpty ? 0 : current * controller.pageSize + 1;
        final end =
            list.isEmpty
                ? 0
                : ((current + 1) * controller.pageSize > list.length
                    ? list.length
                    : (current + 1) * controller.pageSize);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menampilkan $start - $end dari ${list.length}',
                style: const TextStyle(color: kTextGrey, fontSize: 13),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: kTextGrey),
                    onPressed:
                        current > 0
                            ? () {
                              controller.prevPage();
                              onUpdate();
                            }
                            : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kInputBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${current + 1} / $total',
                      style: const TextStyle(color: kTextWhite, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: kTextGrey),
                    onPressed:
                        current < total - 1
                            ? () {
                              controller.nextPage();
                              onUpdate();
                            }
                            : null,
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Per halaman:',
                    style: TextStyle(color: kTextGrey, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: kInputBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: controller.pageSize,
                        dropdownColor: kCardBg,
                        style: const TextStyle(color: kTextWhite, fontSize: 13),
                        items:
                            [10, 20, 50, 100]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            controller.setPageSize(v);
                            onUpdate();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
