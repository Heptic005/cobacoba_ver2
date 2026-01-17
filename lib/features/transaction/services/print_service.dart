import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
// Note: we provide a lightweight preview dialog that builds PDF bytes
// and allows the user to open or save them to local storage.

// Lightweight helpers for stub PDF builder (avoid calling class-private helpers)
String _slib_s(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v == null) return '';
  final str = v.toString().trim();
  if (str.length > 200) return str.substring(0, 200);
  return str;
}

String _slib_sPref(Map<String, Object?> m, List<String> keys) {
  for (final k in keys) {
    final v = _slib_s(m, k);
    if (v.isNotEmpty) return v;
  }
  return '-';
}

/// Print service interface — abstracts printing for testability and platform-specific implementations
abstract class PrintService {
  Future<void> print(String content);
  bool isAvailable();

  /// Build slip PDF bytes from an existing transaction map (no extra fetches).
  Future<Uint8List> buildSlipPdf(
    Map<String, Object?> tx, {
    PdfPageFormat format,
    Uint8List? dakaraLogo,
    Uint8List? userLogo,
  });

  /// Send slip to printer (uses printing package under the hood).
  Future<void> printSlip(Map<String, Object?> tx);

  /// Export/share slip PDF.
  Future<void> exportSlipPdf(Map<String, Object?> tx);
}

/// Stub implementation for testing and development
class PrintServiceStub implements PrintService {
  @override
  Future<void> print(String content) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  bool isAvailable() {
    return false; // stub not connected to real printer
  }

  @override
  Future<Uint8List> buildSlipPdf(
    Map<String, Object?> tx, {
    PdfPageFormat format = PdfPageFormat.a4,
    Uint8List? dakaraLogo,
    Uint8List? userLogo,
  }) async {
    // Fallback: minimal PDF to keep interface working without real assets.
    final doc = pw.Document();
    final Map<String, Object?> data = Map<String, Object?>.from(tx);
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Slip Transaksi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Ticket: ${_slib_s(data, 'noTicket')}'),
                pw.Text('Vehicle: ${_slib_s(data, 'vehiclePlate')}'),
                pw.Text('Driver: ${_slib_s(data, 'driverName')}'),
                pw.Text('Product: ${_slib_sPref(data, ['productName', 'ProductName'])}'),
                pw.SizedBox(height: 12),
                pw.Text('Bruto: ${_slib_s(data, 'bruto')} | Tare: ${_slib_s(data, 'tare')} | Netto: ${_slib_s(data, 'netto')}'),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  @override
  Future<void> printSlip(Map<String, Object?> tx) async {
    final bytes = await buildSlipPdf(tx);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> exportSlipPdf(Map<String, Object?> tx) async {
    final bytes = await buildSlipPdf(tx);
    await Printing.sharePdf(bytes: bytes, filename: 'slip.pdf');
  }
}

/// Real PDF builder for slip transactions (formal layout with logos and sections).
class DakaraSlipPdfBuilder {
  /// Build formal slip PDF (A4 default, optional 80mm thermal).
  static Future<Uint8List> build(
    Map<String, Object?> tx, {
    PdfPageFormat format = PdfPageFormat.a4,
    Uint8List? dakaraLogo,
    Uint8List? userLogo,
  }) async {
    final data = Map<String, Object?>.from(tx);
    final now = DateTime.now();
    final dateFmt = DateFormat('dd MMM yyyy HH:mm');
    final doc = pw.Document();

    final pw.ImageProvider? dakaraImg = dakaraLogo != null ? pw.MemoryImage(dakaraLogo) : null;
    final pw.ImageProvider? userImg = userLogo != null ? pw.MemoryImage(userLogo) : null;

    pw.Widget logoBox(pw.ImageProvider? img, String fallback) {
      if (img != null) {
        return pw.Container(
          width: 60,
          height: 60,
          child: pw.Image(img, fit: pw.BoxFit.contain),
        );
      }
      return pw.Container(
        width: 60,
        height: 60,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Text(fallback, style: const pw.TextStyle(fontSize: 10)),
      );
    }

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 90, child: pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10))),
            pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value, style: const pw.TextStyle(fontSize: 11))),
          ],
        ),
      );
    }

    String fmtDateStr(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      return dateFmt.format(dt);
    }

    String numStr(String key) {
      final v = data[key];
      if (v == null) return '-';
      if (v is num) return v.toStringAsFixed(2);
      return v.toString();
    }

    final sections = <pw.Widget>[
      // Header
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          logoBox(dakaraImg, 'Dakara'),
          pw.Column(
            children: [
              pw.Text('Slip Transaksi', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('No: ${_s(data, 'noTicket')}', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          logoBox(userImg, 'User'),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      // Meta
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tanggal Cetak: ${dateFmt.format(now)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('User: ${_s(data, 'printedBy') ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 12),
      // Info utama
      row('No. Ticket', _s(data, 'noTicket') ?? '-'),
      row('Plat/Vehicle', _s(data, 'vehiclePlate') ?? '-'),
      row('Driver', _s(data, 'driverName') ?? '-'),
      row('Product', _sPref(data, ['productName', 'ProductName'])),
      row('Supplier', _sPref(data, ['supplierName', 'SupplierName'])),
      row('Customer', _sPref(data, ['customerName', 'CustomerName'])),
      row('In - Out', '${fmtDateStr(_s(data, 'inTime'))} - ${fmtDateStr(_s(data, 'outTime'))}'),
      row('No. DO', _s(data, 'noDO') ?? '-'),
      if ((_s(data, 'additionalInformation') ?? '').toString().isNotEmpty)
        row('Notes', _s(data, 'additionalInformation') ?? '-'),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      // Berat ringkasan
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _metric('Bruto (kg)', numStr('bruto')),
          _metric('Tare (kg)', numStr('tare')),
          _metric('Netto (kg)', numStr('netto')),
          _metric('After Cut (kg)', numStr('nettoAfterCut')),
          _metric('Total', numStr('totalPrice')),
        ],
      ),
      pw.SizedBox(height: 16),
      // Signature area (2 columns x 2 rows)
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _signBox('Operator'),
                pw.SizedBox(height: 12),
                _signBox('Supir'),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              children: [
                _signBox('Manager'),
                pw.SizedBox(height: 12),
                _signBox('KTU'),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.grey300),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Printed by Dakara Weighbridge', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ),
    ];

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: sections),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _metric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _signBox(String role) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
      child: pw.Column(
        children: [
          pw.Text(role, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
          pw.SizedBox(height: 40),
          pw.Container(height: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text('(Nama / Tanda Tangan)', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static String _s(Map<String, Object?> m, String key) {
    final v = m[key];
    if (v == null) return '';
    final str = v.toString().trim();
    if (str.length > 200) return str.substring(0, 200);
    return str;
  }

  static String _sPref(Map<String, Object?> m, List<String> keys) {
    for (final k in keys) {
      final v = _s(m, k);
      if (v.isNotEmpty) return v;
    }
    return '-';
  }
}

/// Show an interactive PDF preview for a transaction map.
/// Shows a lightweight preview dialog and provides Open and Save buttons.
Future<void> showPdfPreview(BuildContext context, Map<String, Object?> tx,
    {PdfPageFormat format = PdfPageFormat.a4, Uint8List? dakaraLogo, Uint8List? userLogo}) async {
  final ticket = (tx['noTicket'] ?? '-').toString();
  final plate = (tx['vehiclePlate'] ?? '-').toString();
  final driver = (tx['driverName'] ?? '-').toString();
  final product = ((tx['productName'] ?? tx['ProductName']) ?? '-').toString();
  String _fmtDt(dynamic v) {
    if (v == null) return '-';
    if (v is DateTime) return DateFormat('dd MMM yyyy HH:mm').format(v);
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) return DateFormat('dd MMM yyyy HH:mm').format(dt);
    // fallback: remove microseconds and replace 'T' with space
    return s.replaceAll('T', ' ').replaceFirst(RegExp(r'\.\d+'), '');
  }

  final inTime = _fmtDt(tx['inTime']);
  final outTime = _fmtDt(tx['outTime']);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
          child: Column(
            children: [
              // Header with actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black12,
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Preview Slip - $ticket',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    TextButton.icon(
                      onPressed: () async {
                        // Build PDF and open share/viewer
                        final bytes = await DakaraSlipPdfBuilder.build(tx, format: format, dakaraLogo: dakaraLogo, userLogo: userLogo);
                        await Printing.sharePdf(bytes: bytes, filename: 'slip-${ticket.isNotEmpty ? ticket : DateTime.now().millisecondsSinceEpoch}.pdf');
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        // Build PDF with progress indicator
                        try {
                          showDialog(
                            context: ctx,
                            barrierDismissible: false,
                            builder: (_) => const Dialog(child: Padding(padding: EdgeInsets.all(24), child: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Mempersiapkan PDF...')]))),
                          );
                          final bytes = await DakaraSlipPdfBuilder.build(tx, format: format, dakaraLogo: dakaraLogo, userLogo: userLogo);
                          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();

                          final kb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
                          final estPages = (bytes.lengthInBytes / 15000).ceil().clamp(1, 9999);

                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              title: const Text('Konfirmasi Cetak'),
                              content: Text('Cetak approx $estPages halaman (~$kb KB)?\nLanjutkan ke printer?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Cetak')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(const SnackBar(content: Text('Mengirim ke printer...')));
                            await Printing.layoutPdf(onLayout: (_) async => bytes);
                          }
                        } catch (e) {
                          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cetak gagal: $e')));
                        }
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final bytes = await DakaraSlipPdfBuilder.build(tx, format: format, dakaraLogo: dakaraLogo, userLogo: userLogo);
                          final suggested = 'slip-${ticket.isNotEmpty ? ticket : DateTime.now().millisecondsSinceEpoch}.pdf';
                          final String? path = await getSavePath(suggestedName: suggested);
                          if (path == null) return; // cancelled
                          final file = File(path);
                          await file.writeAsBytes(bytes);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File tersimpan')));
                        } catch (e) {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simpan gagal: $e')));
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              // Body: Flutter-rendered slip preview (mirrors PDF layout)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      width: 560,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with logos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              dakaraLogo != null
                                  ? Image.memory(dakaraLogo, width: 60, height: 60, fit: BoxFit.contain)
                                  : Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: const Text('Dakara')),
                              Column(
                                children: [
                                  const Text('Slip Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('No: $ticket', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              userLogo != null
                                  ? Image.memory(userLogo, width: 60, height: 60, fit: BoxFit.contain)
                                  : Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: const Text('User')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Meta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tanggal Cetak: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
                              Text('User: ${_slib_s(tx, 'printedBy') ?? '-'}'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          // Info rows
                          _infoRow('No. Ticket', ticket),
                          _infoRow('Plat/Vehicle', plate),
                          _infoRow('Driver', driver),
                          _infoRow('Product', _slib_sPref(tx, ['productName', 'ProductName'])),
                          _infoRow('Supplier', _slib_sPref(tx, ['supplierName', 'SupplierName'])),
                          _infoRow('Customer', _slib_sPref(tx, ['customerName', 'CustomerName'])),
                          _infoRow('In - Out', '${inTime} - ${outTime}'),
                          _infoRow('No. DO', _slib_s(tx, 'noDO')),
                          if ((_slib_s(tx, 'additionalInformation') ?? '').isNotEmpty) _infoRow('Notes', _slib_s(tx, 'additionalInformation')),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Metrics
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            _metricBox('Bruto (kg)', _numStrPreview(tx, 'bruto')),
                            _metricBox('Tare (kg)', _numStrPreview(tx, 'tare')),
                            _metricBox('Netto (kg)', _numStrPreview(tx, 'netto')),
                            _metricBox('After Cut (kg)', _numStrPreview(tx, 'nettoAfterCut')),
                          ],),
                          const SizedBox(height: 16),
                          // Signatures (2 columns x 2 rows)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                child: Column(
                                  children: [
                                    _signPreviewBox('Operator'),
                                    SizedBox(height: 12),
                                    _signPreviewBox('Supir'),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _signPreviewBox('Manager'),
                                    SizedBox(height: 12),
                                    _signPreviewBox('KTU'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          Align(alignment: Alignment.centerRight, child: Text('Printed by Dakara Weighbridge', style: TextStyle(fontSize: 10, color: Colors.grey.shade700))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper widgets for Flutter preview
Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
        Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

Widget _metricBox(String label, String value) {
  return Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
    ],
  );
}

class _signPreviewBox extends StatelessWidget {
  const _signPreviewBox(this.role);
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(role, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
          const SizedBox(height: 40),
          Container(height: 1, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('(Nama / Tanda Tangan)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

String _numStrPreview(Map<String, Object?> data, String key) {
  final v = data[key];
  if (v == null) return '-';
  if (v is num) return v.toStringAsFixed(2);
  return v.toString();
}
