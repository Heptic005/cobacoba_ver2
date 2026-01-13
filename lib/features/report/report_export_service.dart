import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show MissingPluginException, rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';

import 'package:dakara_weighbridge/Pages/report/report_models.dart';
import 'report_preview.dart';
import 'package:dakara_weighbridge/Pages/report/report_widgets.dart';

// Shared tabular preview defaults
const List<String> _kTabularHeaders = ['No Ticket','Plat','Driver','Produk','Supplier','Customer','Tanggal','Bruto','Tara','Netto','Total'];
const List<bool> _kTabularNumeric = [false,false,false,false,false,false,false,true,true,true,true];

String _fmtNum(num v) => NumberFormat.decimalPattern('id_ID').format(v);
String _fmtCurrency(num v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

/// Service untuk export dan cetak report transaksi (PDF, Excel, CSV) tanpa akses DB.
class ReportExportService {
  ReportExportService._();
  static final ReportExportService instance = ReportExportService._();

  static const Duration _cacheTtl = Duration(minutes: 10);
  static const int _maxBytes = 20 * 1024 * 1024; // 20MB guard

  /// Build PDF di isolate agar UI tidak nge-jank.
  Future<Uint8List> buildReportPdf(
    List<ReportRowData> rows, {
    required Map<String, Object?> meta,
    double? pageWidth,
    double? pageHeight,
  }) async {
    pageWidth ??= PdfPageFormat.a4.width;
    pageHeight ??= PdfPageFormat.a4.height;
    final mapped = rows
        .map((r) => {
              'noTicket': r.noTicket,
              'vehiclePlate': r.vehiclePlate,
              'driverName': r.driverName,
              'productName': r.productName,
              'supplierName': r.supplierName,
              'customerName': r.customerName,
              'formattedDate': r.formattedDate,
              'bruto': r.bruto,
              'tare': r.tare,
              'netto': r.netto,
              'totalPrice': r.totalPrice,
            })
        .toList();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    final payload = _PdfPayload(rows: mapped, meta: meta, pageWidth: pageWidth, pageHeight: pageHeight, logoBytes: logoBytes);
    return await compute<_PdfPayload, Uint8List>(_buildReportPdfIsolate, payload);
  }

  Future<void> printReportPdf(List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    final bytes = await buildReportPdf(rows, meta: meta);
    if (bytes.lengthInBytes > _maxBytes) {
      throw Exception('Ukuran PDF terlalu besar (>20MB)');
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> exportReportPdf(List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    final bytes = await buildReportPdf(rows, meta: meta);
    if (bytes.lengthInBytes > _maxBytes) {
      throw Exception('Ukuran PDF terlalu besar (>20MB)');
    }
    final path = await _saveBytesWithFallback(bytes, _suggestFile(meta, 'pdf'));
    if (path == null) return;
  }

  /// Show PDF preview dialog with Open/Save/Print actions.
  Future<void> previewReportPdf(BuildContext context, List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk preview')));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
            child: PdfPreviewDialogBody(
              rows: rows,
              meta: meta,
              parentContext: context,
              buildPdf: (r, m) => buildReportPdf(r, meta: m),
              readCache: (k) => _readCache(k),
              writeCache: (k, b) => _writeCache(k, b),
              saveBytes: (b, name) => _saveBytesWithFallback(b, name),
              cacheKey: (m, r) => _cacheKey(m, r),
              suggestFile: (m, ext) => _suggestFile(m, ext),
              maxBytes: _maxBytes,
            ),
          ),
        );
      },
    );
  }

  Future<String> buildReportXlsx(List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets[excel.getDefaultSheet()]!;

    sheet.appendRow(_kTabularHeaders);
    for (final r in rows) {
      sheet.appendRow([
        r.noTicket,
        r.vehiclePlate,
        r.driverName,
        r.productName,
        r.supplierName,
        r.customerName,
        r.formattedDate,
        r.bruto,
        r.tare,
        r.netto,
        r.totalPrice,
      ]);
    }

    final fileBytes = excel.encode()!;
    final path = await _saveBytesWithFallback(Uint8List.fromList(fileBytes), _suggestFile(meta, 'xlsx'));
    return path ?? '';
  }

  Future<String> buildReportCsv(List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    final List<List<dynamic>> data = [
      ['No Ticket', 'Plat', 'Driver', 'Produk', 'Supplier', 'Customer', 'Tanggal', 'Bruto', 'Tara', 'Netto', 'Total'],
      ...rows.map((r) => [
            r.noTicket,
            r.vehiclePlate,
            r.driverName,
            r.productName,
            r.supplierName,
            r.customerName,
            r.formattedDate,
            r.bruto,
            r.tare,
            r.netto,
            r.totalPrice,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(data);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final path = await _saveBytesWithFallback(bytes, _suggestFile(meta, 'csv'));
    return path ?? '';
  }

  // Generic table preview used by Excel/CSV previews to avoid duplication
  Future<void> _showTabularPreview(
    BuildContext context,
    List<ReportRowData> rows,
    Map<String, Object?> meta, {
    required String title,
    required List<String> headers,
    required List<String> Function(ReportRowData r) rowValues,
    List<bool>? numericColumns,
  }) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk preview')));
      return;
    }

    const previewLimit = 200;
    final total = rows.length;
    final shown = rows.take(previewLimit).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        final vScroll = ScrollController();
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 780),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                // Header
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextWhite)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close, color: kTextGrey)),
                ]),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: Text('Menampilkan ${shown.length} dari $total baris', style: const TextStyle(color: kTextGrey))),
                const SizedBox(height: 8),
                const Divider(color: kInputBg, height: 1),
                const SizedBox(height: 8),

                // Table area: constrain to a portion of screen and allow both vertical and horizontal scrolling
                LayoutBuilder(builder: (c, constraints) {
                  final maxH = MediaQuery.of(ctx).size.height * 0.62; // occupy up to ~62% of screen height
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH, minHeight: 120),
                    child: Scrollbar(
                      controller: vScroll,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: vScroll,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(kPrimaryCyan),
                            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            dataRowColor: MaterialStateProperty.all(kCardBg),
                            headingRowHeight: 56,
                            dataRowHeight: 52,
                            columns: List.generate(headers.length, (i) {
                              return DataColumn(
                                label: ConstrainedBox(constraints: const BoxConstraints(minWidth: 80), child: Text(headers[i], style: const TextStyle(color: kTextWhite))),
                                numeric: numericColumns != null && i < numericColumns.length && numericColumns[i],
                              );
                            }),
                            rows: shown.map((r) {
                              final vals = rowValues(r);
                              return DataRow(cells: vals.map((v) => DataCell(Text(v, style: const TextStyle(color: kTextWhite), overflow: TextOverflow.ellipsis))).toList());
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),
                // Footer actions
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        if (title.toLowerCase().contains('excel')) {
                          final path = await buildReportXlsx(rows, meta: meta);
                          if (path.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel disimpan: $path')));
                        } else {
                          final path = await buildReportCsv(rows, meta: meta);
                          if (path.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV disimpan: $path')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryCyan, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        final bytes = await buildReportPdf(rows, meta: meta);
                        await Printing.sharePdf(bytes: bytes, filename: _suggestFile(meta, 'pdf'));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal share: $e')));
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Export & Share'),
                    style: OutlinedButton.styleFrom(foregroundColor: kTextWhite, backgroundColor: kCardBg, side: BorderSide(color: kInputBg)),
                  ),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  /// Show a preview dialog for Excel data (renders a scrollable table).
  Future<void> previewExcel(BuildContext context, List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    await _showTabularPreview(
      context,
      rows,
      meta,
      title: 'Preview Excel',
      headers: _kTabularHeaders,
      numericColumns: _kTabularNumeric,
      rowValues: (r) => [
        r.noTicket,
        r.vehiclePlate,
        r.driverName,
        r.productName,
        r.supplierName,
        r.customerName,
        r.formattedDate,
        _fmtNum(r.bruto),
        _fmtNum(r.tare),
        _fmtNum(r.netto),
        _fmtCurrency(r.totalPrice),
      ],
    );
  }

  /// Show a preview dialog for CSV data (renders a scrollable table view)
  Future<void> previewCsv(BuildContext context, List<ReportRowData> rows, {required Map<String, Object?> meta}) async {
    await _showTabularPreview(
      context,
      rows,
      meta,
      title: 'Preview CSV',
      headers: _kTabularHeaders,
      numericColumns: _kTabularNumeric,
      rowValues: (r) => [
        r.noTicket,
        r.vehiclePlate,
        r.driverName,
        r.productName,
        r.supplierName,
        r.customerName,
        r.formattedDate,
        _fmtNum(r.bruto),
        _fmtNum(r.tare),
        _fmtNum(r.netto),
        _fmtCurrency(r.totalPrice),
      ],
    );
  }

  /// Try `getSavePath` first; on MissingPluginException or cancel, fall back to
  /// writing into application documents directory and return the path.
  Future<String?> _saveBytesWithFallback(Uint8List bytes, String suggestedName) async {
    // Try file selector first
    try {
      // ignore: deprecated_member_use
      final path = await getSavePath(suggestedName: suggestedName);
      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      }
    } on MissingPluginException {
      // fall through to fallback
    } catch (_) {
      // if plugin exists but user cancelled or other issues, continue to fallback
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}DakaraExports');
      if (!await outDir.exists()) await outDir.create(recursive: true);
      final file = File(p.join(outDir.path, suggestedName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  // ---------- internal helpers ----------
  Future<Uint8List?> _readCache(String key) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, key));
      if (!await file.exists()) return null;
      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > _cacheTtl) {
        await file.delete();
        return null;
      }
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, key));
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // ignore cache failures
    }
  }

  String _cacheKey(Map<String, Object?> meta, List<ReportRowData> rows) {
    // Ensure meta is JSON-encodable (DateTime -> ISO string)
    final safeMeta = <String, Object?>{};
    meta.forEach((k, v) {
      if (v is DateTime) {
        safeMeta[k] = v.toIso8601String();
      } else {
        safeMeta[k] = v;
      }
    });

    final encoder = utf8.fuse(base64Url);
    final seed = jsonEncode({
      'meta': safeMeta,
      'count': rows.length,
      'first': rows.isEmpty ? null : rows.first.noTicket,
      'last': rows.isEmpty ? null : rows.last.noTicket,
    });
    return 'report_${encoder.encode(seed)}.bin'.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _suggestFile(Map<String, Object?> meta, String ext) {
    final startVal = meta['startDate'];
    final endVal = meta['endDate'];
    final start = startVal is DateTime ? DateFormat('yyyyMMdd').format(startVal) : (startVal?.toString().split(' ').first ?? 'all');
    final end = endVal is DateTime ? DateFormat('yyyyMMdd').format(endVal) : (endVal?.toString().split(' ').first ?? 'all');
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final base = 'report_${start}_${end}_$ts.$ext';
    return base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

// ---------- isolate builder ----------

class _PdfPayload {
  final List<Map<String, Object?>> rows;
  final Map<String, Object?> meta;
  final double pageWidth;
  final double pageHeight;
  final Uint8List? logoBytes;

  _PdfPayload({
    required this.rows,
    required this.meta,
    required this.pageWidth,
    required this.pageHeight,
    this.logoBytes,
  });
}

Future<Uint8List> _buildReportPdfIsolate(_PdfPayload payload) async {
  final rows = payload.rows;
  final meta = payload.meta;
  final format = PdfPageFormat(payload.pageWidth, payload.pageHeight);
  final doc = pw.Document();
  final dateFmt = DateFormat('dd MMM yyyy');
  final numFmt = NumberFormat.decimalPattern('id_ID');
  final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String metaStr(String key) {
    final v = meta[key];
    if (v == null) return '-';
    if (v is DateTime) return dateFmt.format(v);
    return v.toString();
  }

  pw.Widget header() {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Laporan Transaksi', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text('Periode: ${metaStr('startDate')} s.d. ${metaStr('endDate')}', style: const pw.TextStyle(fontSize: 11)),
      if ((meta['search'] ?? '').toString().isNotEmpty)
        pw.Text('Pencarian: ${meta['search']}', style: const pw.TextStyle(fontSize: 11)),
      pw.Text('Dicetak: ${dateFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
    ]);
  }

  // (old small helpers removed; main table builder below constructs rowsTable directly)

  // helper to wrap cell content with padding and optional alignment + background
  pw.Widget cellContainer(String text, PdfColor bg, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align, maxLines: 2, overflow: pw.TextOverflow.clip),
    );
  }

  num numVal(Map<String, Object?> r, String k) {
    final v = r[k];
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  final totalBruto = rows.fold<num>(0, (p, e) => p + numVal(e, 'bruto'));
  final totalTare = rows.fold<num>(0, (p, e) => p + numVal(e, 'tare'));
  final totalNetto = rows.fold<num>(0, (p, e) => p + numVal(e, 'netto'));
  final totalPrice = rows.fold<num>(0, (p, e) => p + numVal(e, 'totalPrice'));

  // Build a nicer, styled multi-page report with header and footer
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo image if available
            if (payload.logoBytes != null)
              pw.Container(
                width: 56,
                height: 56,
                child: pw.Image(pw.MemoryImage(payload.logoBytes!), fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 56,
                height: 56,
                decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(6), color: PdfColors.grey200),
                child: pw.Center(child: pw.Text('LOGO', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
              ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Dakara Weighbridge', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text('Jl. Contoh No.123, Kota Contoh, Telp: (021) 123-4567', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey300, thickness: 1),
              ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Dicetak: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text('Baris: ${rows.length}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ])
          ],
        ),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Halaman ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (context) {
        // table column widths (proportional) - increase Customer column to avoid wrapping
        final colWidths = <int, pw.FlexColumnWidth>{
          0: pw.FlexColumnWidth(2), // no ticket
          1: pw.FlexColumnWidth(2), // plat
          2: pw.FlexColumnWidth(2), // produk
          3: pw.FlexColumnWidth(6), // supplier (wider to avoid truncation)
          4: pw.FlexColumnWidth(3), // customer
          5: pw.FlexColumnWidth(3), // tanggal
          6: pw.FlexColumnWidth(2), // bruto
          7: pw.FlexColumnWidth(2), // tara
          8: pw.FlexColumnWidth(2), // netto
          9: pw.FlexColumnWidth(2), // total
        };

        // Build single table with header + all rows to keep columns aligned
        final rowsTable = <pw.TableRow>[];

        // header row
        rowsTable.add(pw.TableRow(children: [
          _cellHeader('No Tiket'),
          _cellHeader('Plat'),
          _cellHeader('Produk'),
          _cellHeader('Supplier'),
          _cellHeader('Customer'),
          _cellHeader('Tanggal'),
          _cellHeader('Bruto', align: pw.TextAlign.right),
          _cellHeader('Tara', align: pw.TextAlign.right),
          _cellHeader('Netto', align: pw.TextAlign.right),
          _cellHeader('Total', align: pw.TextAlign.right),
        ]));

        for (var i = 0; i < rows.length; i++) {
          final r = rows[i];
          final bg = (i % 2 == 0) ? PdfColors.grey100 : PdfColors.white;
          rowsTable.add(pw.TableRow(children: [
            cellContainer((r['noTicket'] ?? '').toString(), bg),
            cellContainer((r['vehiclePlate'] ?? '').toString(), bg),
            cellContainer((r['productName'] ?? '').toString(), bg),
            cellContainer((r['supplierName'] ?? '').toString(), bg),
            cellContainer((r['customerName'] ?? '').toString(), bg),
            cellContainer((r['formattedDate'] ?? '').toString(), bg),
            cellContainer(numFmt.format(r['bruto'] ?? 0), bg, align: pw.TextAlign.right),
            cellContainer(numFmt.format(r['tare'] ?? 0), bg, align: pw.TextAlign.right),
            cellContainer(numFmt.format(r['netto'] ?? 0), bg, align: pw.TextAlign.right),
            cellContainer(currencyFmt.format(r['totalPrice'] ?? 0), bg, align: pw.TextAlign.right),
          ]));
        }

        final table = pw.Table(
          columnWidths: colWidths,
          border: pw.TableBorder(
            top: pw.BorderSide(color: PdfColors.grey300),
            bottom: pw.BorderSide(color: PdfColors.grey300),
            left: pw.BorderSide(color: PdfColors.grey300),
            right: pw.BorderSide(color: PdfColors.grey300),
            horizontalInside: pw.BorderSide(color: PdfColors.grey300),
          ),
          children: rowsTable,
        );

        return [
          header(),
          pw.SizedBox(height: 8),
          table,
          // totals row
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(4)),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Expanded(child: pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(width: 12),
              pw.Text('${numFmt.format(totalBruto)} kg', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(width: 12),
              pw.Text('${numFmt.format(totalTare)} kg', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(width: 12),
              pw.Text('${numFmt.format(totalNetto)} kg', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(width: 12),
              pw.Text(currencyFmt.format(totalPrice), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signBox('Disetujui'),
              _signBox('Dibuat'),
            ],
          ),
        ];
      },
    ),
  );

  return doc.save();
}

pw.Widget _signBox(String label) {
  return pw.Container(
    width: 180,
    padding: const pw.EdgeInsets.all(8),
    child: pw.Column(children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      pw.SizedBox(height: 48),
      pw.Container(height: 1, color: PdfColors.grey400),
      pw.SizedBox(height: 4),
      pw.Text('(Nama / Tanda Tangan)', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
    ]),
  );
}

/// Ringkas meta info di preview
class _MetaInfo extends StatelessWidget {
  final Map<String, Object?> meta;
  final List<ReportRowData> rows;
  const _MetaInfo({required this.meta, required this.rows});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    String fmtDate(dynamic d) => d is DateTime ? dateFmt.format(d) : (d?.toString() ?? '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Periode: ${fmtDate(meta['startDate'])} s.d. ${fmtDate(meta['endDate'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
        if ((meta['search'] ?? '').toString().isNotEmpty)
          Text('Pencarian: ${meta['search']}'),
        Text('Baris: ${rows.length}'),
      ],
    );
  }
}

// header cell builder for pdf table
pw.Widget _cellHeader(String t, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    color: PdfColors.blue900,
    child: pw.Text(
      t,
      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      textAlign: align,
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    ),
  );
}