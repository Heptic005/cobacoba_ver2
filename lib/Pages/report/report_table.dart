/// Report Data Table Widget
/// Komponen tabel data transaksi untuk halaman Report

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/report/report_widgets.dart';
import 'package:dakara_weighbridge/Pages/report/report_models.dart';
import 'package:dakara_weighbridge/features/transaction/services/clipboard_service.dart';

/// Widget utama untuk Data Table
class ReportDataTable extends StatefulWidget {
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
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  bool _timeout = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  void _startTimeout() {
    _timer?.cancel();
    _timeout = false;
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _timeout = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.loading,
      builder: (_, loading, __) {
        final emptyShown = widget.controller.shown.value.isEmpty;
        if (!loading) {
          // stop timeout when data load resolved (success/empty)
          _timer?.cancel();
        }
        return ValueListenableBuilder<List<ReportRowData>>(
          valueListenable: widget.controller.visible,
          builder: (_, list, __) {
            if (loading) {
              return _StatePlaceholder(
                icon: Icons.hourglass_empty,
                text: _timeout
                    ? 'Memuat terlalu lama, coba cek koneksi atau ulangi'
                    : 'Sedang memuat... (cek koneksi jika >2s)',
              );
            }
            // Container selalu dirender; jika kosong, tampilkan placeholder di body
            return Container(
              height: 400,
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Menampilkan ${list.length} hasil', style: const TextStyle(color: kTextGrey, fontSize: 13)),
                  ),
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: const [
                      _TableHeader('No. Tiket', flex: 2),
                      _TableHeader('Plat', flex: 2),
                      _TableHeader('Produk', flex: 1),
                      _TableHeader('Supplier', flex: 3),
                      _TableHeader('Customer', flex: 3),
                      _TableHeader('Bruto (kg)', flex: 1, align: TextAlign.right),
                      _TableHeader('Tara (kg)', flex: 1, align: TextAlign.right),
                      _TableHeader('Netto (kg)', flex: 1, align: TextAlign.right),
                      _TableHeader('Total', flex: 1, align: TextAlign.right),
                      _TableHeader('Status', flex: 2, align: TextAlign.center),
                      _TableHeader('Aksi', flex: 1, align: TextAlign.center),
                    ]),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? _StatePlaceholder(
                            icon: Icons.inbox_outlined,
                            text: 'Data tidak ditemukan',
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.pixels >= (n.metrics.maxScrollExtent - 200)) {
                                // Near bottom: request more
                                widget.controller.loadMore();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: list.length + (widget.controller.hasMore ? 1 : 0),
                              itemExtent: 72.0,
                              itemBuilder: (_, idx) {
                                if (idx >= list.length) {
                                  // Footer loader
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: widget.controller.loadingMore,
                                    builder: (_, loadingMore, __) => Center(
                                      child: loadingMore
                                          ? const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }
                                final row = list[idx];
                                return RepaintBoundary(
                                  child: ReportRowWidget(
                                    row: row,
                                    clipboard: widget.clipboard,
                                    onSnack: widget.onSnack,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
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
        style: TextStyle(
          color: kTextGrey.withOpacity(0.9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        textAlign: align,
      ),
    );
  }
}

/// Lightweight row widget using precomputed `ReportRowData`.
class ReportRowWidget extends StatelessWidget {
  final ReportRowData row;
  final dynamic clipboard;
  final Function(String) onSnack;

  const ReportRowWidget({super.key, required this.row, required this.clipboard, required this.onSnack});

  @override
  Widget build(BuildContext context) {
    final src = row.source;
    final isManual = src.isManual == 1;
    final isDraft = src.isDrafted == 1;
    final statusText = isManual ? 'Manual' : (isDraft ? 'Menunggu' : 'Selesai');
    final statusColor = isManual ? kStatusManual : (isDraft ? kStatusMenunggu : kStatusSelesai);

    return InkWell(
      onTap: () => showTransactionDetailDialog(context, src, (id) => row.supplierName, (id) => row.productName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kInputBg, width: 1))),
        child: Row(children: [
          Expanded(flex: 2, child: _ColTitle(row.noTicket, row.formattedDate)),
          Expanded(flex: 2, child: _ColSub(row.vehiclePlate, row.driverName)),
          Expanded(flex: 1, child: Text(row.productName, style: const TextStyle(color: kTextWhite, fontSize: 13))),
          Expanded(flex: 3, child: Text(row.supplierName, style: const TextStyle(color: kTextWhite, fontSize: 13))),
          Expanded(flex: 3, child: Text(row.customerName, style: const TextStyle(color: kTextWhite, fontSize: 13))),
          Expanded(flex: 1, child: Text(row.formattedBruto, style: const TextStyle(color: kTextWhite, fontSize: 13), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(row.formattedTare, style: const TextStyle(color: kTextWhite, fontSize: 13), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(row.formattedNetto, style: const TextStyle(color: kTextWhite, fontSize: 13), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(row.formattedTotal, style: const TextStyle(color: kPrimaryCyan, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Center(child: StatusBadge(text: statusText, color: statusColor))),
          Expanded(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: const Icon(Icons.visibility, size: 16, color: kTextGrey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => showTransactionDetailDialog(context, src, (id) => row.supplierName, (id) => row.productName),
                      tooltip: 'Lihat',
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16, color: kTextGrey),
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      color: kCardBg,
                      onSelected: (v) {
                        if (v == 'copy_ticket') {
                          clipboard.copy(src.noTicket);
                          onSnack('No. Tiket disalin');
                        }
                        if (v == 'copy_plate') {
                          clipboard.copy(src.vehiclePlate);
                          onSnack('Plat disalin');
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'copy_ticket', child: Text('Salin No. Tiket', style: TextStyle(color: kTextWhite))),
                        const PopupMenuItem(value: 'copy_plate', child: Text('Salin Plat', style: TextStyle(color: kTextWhite))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ColTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ColTitle(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: kPrimaryCyan, fontWeight: FontWeight.w600, fontSize: 13)),
    const SizedBox(height: 2),
    Text(subtitle, style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 11)),
  ]);
}

class _ColSub extends StatelessWidget {
  final String a;
  final String b;
  const _ColSub(this.a, this.b);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(a, style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w500, fontSize: 13)),
    const SizedBox(height: 2),
    Text(b, style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 11)),
  ]);
}

class _StatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatePlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: kTextGrey),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: kTextGrey)),
          ],
        ),
      ),
    );
  }
}


