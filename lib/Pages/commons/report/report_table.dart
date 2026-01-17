/// Report Data Table Widget
/// Komponen tabel data transaksi untuk halaman Report

import 'dart:async';

import 'package:dakara_weighbridge/Entities/Manager/manager.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_widgets.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_models.dart';
import 'package:dakara_weighbridge/features/transaction/services/clipboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final ScrollController _scrollController = ScrollController();

  List<Widget> _buildHeaders(bool compact) {
    return [
      const _TableHeader('No. Tiket', flex: 3),
      const _TableHeader('Plat', flex: 1),
      if (!compact) const _TableHeader('Produk', flex: 1),
      const _TableHeader('Supplier', flex: 2),
      _TableHeader('Customer', flex: compact ? 1 : 2),
      const _TableHeader('Bruto (kg)', flex: 1, align: TextAlign.right),
      const _TableHeader('Tara (kg)', flex: 1, align: TextAlign.right),
      const _TableHeader('Netto (kg)', flex: 1, align: TextAlign.right),
      const _TableHeader('Total', flex: 1, align: TextAlign.right),
      const _TableHeader('Status', flex: 1, align: TextAlign.center),
      const _TableHeader('Aksi', flex: 1, align: TextAlign.center),
    ];
  }

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
    _scrollController.dispose();
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
                text:
                    _timeout
                        ? 'Memuat terlalu lama, coba cek koneksi atau ulangi'
                        : 'Sedang memuat... (cek koneksi jika >2s)',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isCompact = width < 1000;
                final isVeryNarrow = width < 700;

                final table = Container(
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
                        child: Text(
                          'Menampilkan ${list.length} hasil',
                          style: const TextStyle(
                            color: kTextGrey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isVeryNarrow)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Tampilan ringkas untuk layar kecil',
                            style: TextStyle(
                              color: kTextGrey.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (isVeryNarrow) const SizedBox(height: 8),
                      Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: kInputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            isVeryNarrow
                                ? const SizedBox.shrink()
                                : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _buildHeaders(isCompact),
                                ),
                      ),
                      Expanded(
                        child:
                            list.isEmpty
                                ? _StatePlaceholder(
                                  icon: Icons.inbox_outlined,
                                  text: 'Data tidak ditemukan',
                                )
                                : NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (n.metrics.pixels >=
                                        (n.metrics.maxScrollExtent - 200)) {
                                      // Near bottom: request more
                                      widget.controller.loadMore();
                                    }
                                    return false;
                                  },
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: !isVeryNarrow,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount:
                                          list.length +
                                          (widget.controller.hasMore ? 1 : 0),
                                      itemExtent: isVeryNarrow ? null : 72.0,
                                      itemBuilder: (_, idx) {
                                        if (idx >= list.length) {
                                          // Footer loader
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                widget.controller.loadingMore,
                                            builder:
                                                (_, loadingMore, __) => Center(
                                                  child:
                                                      loadingMore
                                                          ? const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                          )
                                                          : const SizedBox.shrink(),
                                                ),
                                          );
                                        }
                                        final row = list[idx];
                                        return RepaintBoundary(
                                          child:
                                              isVeryNarrow
                                                  ? ReportRowCardWidget(
                                                    row: row,
                                                    clipboard: widget.clipboard,
                                                    onSnack: widget.onSnack,
                                                  )
                                                  : ReportRowWidget(
                                                    row: row,
                                                    clipboard: widget.clipboard,
                                                    onSnack: widget.onSnack,
                                                    compact: isCompact,
                                                  ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                );

                return table;
              },
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Lightweight row widget using precomputed `ReportRowData`.
class ReportRowWidget extends StatefulWidget {
  final ReportRowData row;
  final dynamic clipboard;
  final Function(String) onSnack;
  final bool compact;

  const ReportRowWidget({
    super.key,
    required this.row,
    required this.clipboard,
    required this.onSnack,
    required this.compact,
  });

  @override
  State<ReportRowWidget> createState() => _ReportRowWidgetState();
}

class _ReportRowWidgetState extends State<ReportRowWidget> {
  bool _isManager = false;

  Future<void> _loadPrefsDataIsManager() async {
    final prefs = await SharedPreferences.getInstance();
    _isManager = prefs.getString('role') == 'manager';
  }

  @override
  void initState() {
    _loadPrefsDataIsManager();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.row.source;
    final isManual = src.isManual == 1;
    final isDraft = src.isDrafted == 1;
    final statusText = isManual ? 'Manual' : (isDraft ? 'Menunggu' : 'Selesai');
    final statusColor =
        isManual ? kStatusManual : (isDraft ? kStatusMenunggu : kStatusSelesai);

    return InkWell(
      onTap:
          () => showTransactionDetailDialog(
            context,
            src,
            (id) => widget.row.supplierName,
            (id) => widget.row.productName,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kInputBg, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _ColTitle(widget.row.noTicket, widget.row.formattedDate),
            ),
            Expanded(
              flex: 1,
              child: _ColSub(widget.row.vehiclePlate, widget.row.driverName),
            ),
            if (!widget.compact)
              Expanded(
                flex: 1,
                child: Text(
                  widget.row.productName,
                  style: const TextStyle(color: kTextWhite, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(
              flex: widget.compact ? 2 : 2,
              child: Text(
                widget.row.supplierName,
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: widget.compact ? 1 : 2,
              child: Text(
                widget.row.customerName,
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.row.formattedBruto,
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.row.formattedTare,
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.row.formattedNetto,
                style: const TextStyle(color: kTextWhite, fontSize: 13),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.row.formattedTotal,
                style: const TextStyle(
                  color: kPrimaryCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: StatusBadge(text: statusText, color: statusColor),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child:
                    widget.compact
                        ? SizedBox(
                          width: 30,
                          height: 30,
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
                                widget.clipboard.copy(src.noTicket);
                                widget.onSnack('No. Tiket disalin');
                              }
                              if (v == 'copy_plate') {
                                widget.clipboard.copy(src.vehiclePlate);
                                widget.onSnack('Plat disalin');
                              }
                            },
                            itemBuilder:
                                (_) => [
                                  const PopupMenuItem(
                                    value: 'copy_ticket',
                                    child: Text(
                                      'Salin No. Tiket',
                                      style: TextStyle(color: kTextWhite),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'copy_plate',
                                    child: Text(
                                      'Salin Plat',
                                      style: TextStyle(color: kTextWhite),
                                    ),
                                  ),
                                ],
                          ),
                        )
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
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
                                      src,
                                      (id) => widget.row.supplierName,
                                      (id) => widget.row.productName,
                                    ),
                                tooltip: 'Lihat',
                              ),
                            ),
                            const SizedBox(width: 2),
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: kTextGrey,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                color: kCardBg,
                                onSelected: (v) async {
                                  if (v == 'copy_ticket') {
                                    widget.clipboard.copy(src.noTicket);
                                    widget.onSnack('No. Tiket disalin');
                                  }
                                  if (v == 'copy_plate') {
                                    widget.clipboard.copy(src.vehiclePlate);
                                    widget.onSnack('Plat disalin');
                                  }
                                  if (v == 'delete_transaction') {
                                    await Manager().deleteTransaction(
                                      transactionId: src.transactionId,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: 'copy_ticket',
                                        child: Text(
                                          'Salin No. Tiket',
                                          style: TextStyle(color: kTextWhite),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'copy_plate',
                                        child: Text(
                                          'Salin Plat',
                                          style: TextStyle(color: kTextWhite),
                                        ),
                                      ),
                                      if (_isManager)
                                        const PopupMenuItem(
                                          value: 'delete_transaction',
                                          child: Text(
                                            'Delete Transaction',
                                            style: TextStyle(color: kTextWhite),
                                          ),
                                        ),
                                    ],
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card-style row for very narrow screens.
class ReportRowCardWidget extends StatelessWidget {
  final ReportRowData row;
  final dynamic clipboard;
  final Function(String) onSnack;

  const ReportRowCardWidget({
    super.key,
    required this.row,
    required this.clipboard,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final src = row.source;
    final isManual = src.isManual == 1;
    final isDraft = src.isDrafted == 1;
    final statusText = isManual ? 'Manual' : (isDraft ? 'Menunggu' : 'Selesai');
    final statusColor =
        isManual ? kStatusManual : (isDraft ? kStatusMenunggu : kStatusSelesai);

    return InkWell(
      onTap:
          () => showTransactionDetailDialog(
            context,
            src,
            (id) => row.supplierName,
            (id) => row.productName,
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCardBg, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _ColTitle(row.noTicket, row.formattedDate)),
                const SizedBox(width: 8),
                StatusBadge(text: statusText, color: statusColor),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: kTextGrey),
                  padding: EdgeInsets.zero,
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
                  itemBuilder:
                      (_) => [
                        const PopupMenuItem(
                          value: 'copy_ticket',
                          child: Text(
                            'Salin No. Tiket',
                            style: TextStyle(color: kTextWhite),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy_plate',
                          child: Text(
                            'Salin Plat',
                            style: TextStyle(color: kTextWhite),
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ColSub(row.vehiclePlate, row.driverName),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _kv('Produk', row.productName),
                _kv('Supplier', row.supplierName),
                _kv('Customer', row.customerName),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _num('Bruto', row.formattedBruto)),
                Expanded(child: _num('Tara', row.formattedTare)),
                Expanded(child: _num('Netto', row.formattedNetto)),
                Expanded(
                  child: _num(
                    'Total',
                    row.formattedTotal,
                    valueStyle: const TextStyle(
                      color: kPrimaryCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: TextStyle(color: kTextGrey.withOpacity(0.75), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Tooltip(
            message: v,
            child: Text(
              v,
              style: const TextStyle(color: kTextWhite, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _num(String label, String value, {TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: kTextGrey.withOpacity(0.75), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: valueStyle ?? const TextStyle(color: kTextWhite, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ColTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ColTitle(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Tooltip(
        message: title,
        child: Text(
          title,
          style: const TextStyle(
            color: kPrimaryCyan,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 2),
      Tooltip(
        message: subtitle,
        child: Text(
          subtitle,
          style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _ColSub extends StatelessWidget {
  final String a;
  final String b;
  const _ColSub(this.a, this.b);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Tooltip(
        message: a,
        child: Text(
          a,
          style: const TextStyle(
            color: kTextWhite,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 2),
      Tooltip(
        message: b,
        child: Text(
          b,
          style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
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
