import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_widgets.dart';
import 'package:printing/printing.dart';

import 'package:dakara_weighbridge/Pages/commons/report/report_models.dart';

/// Lightweight PDF preview dialog body. All external side-effects are passed
/// as callbacks so this file does not need to import `report_export_service.dart`.
class PdfPreviewDialogBody extends StatefulWidget {
  final List<ReportRowData> rows;
  final Map<String, Object?> meta;
  final BuildContext parentContext;

  final Future<Uint8List> Function(
    List<ReportRowData> rows,
    Map<String, Object?> meta,
  )
  buildPdf;
  final Future<Uint8List?> Function(String key) readCache;
  final Future<void> Function(String key, Uint8List bytes) writeCache;
  final Future<String?> Function(Uint8List bytes, String suggestedName)
  saveBytes;
  final String Function(Map<String, Object?> meta, List<ReportRowData> rows)
  cacheKey;
  final String Function(Map<String, Object?> meta, String ext) suggestFile;
  final int maxBytes;

  const PdfPreviewDialogBody({
    required this.rows,
    required this.meta,
    required this.parentContext,
    required this.buildPdf,
    required this.readCache,
    required this.writeCache,
    required this.saveBytes,
    required this.cacheKey,
    required this.suggestFile,
    required this.maxBytes,
    super.key,
  });

  @override
  State<PdfPreviewDialogBody> createState() => _PdfPreviewDialogBodyState();
}

class _PdfPreviewDialogBodyState extends State<PdfPreviewDialogBody> {
  bool loading = true;
  bool exceeded = false;
  Uint8List? bytes;
  int? sizeKb;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    try {
      final key = widget.cacheKey(widget.meta, widget.rows);
      final cached = await widget.readCache(key);
      if (cached != null) {
        bytes = cached;
      } else {
        bytes = await widget.buildPdf(widget.rows, widget.meta);
        if (bytes != null) await widget.writeCache(key, bytes!);
      }
      if (bytes != null && bytes!.lengthInBytes > widget.maxBytes)
        exceeded = true;
      sizeKb = bytes == null ? null : (bytes!.lengthInBytes / 1024).ceil();
    } catch (_) {
      bytes = null;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child:
              loading
                  ? const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : exceeded
                  ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Ukuran PDF melebihi 20MB, kurangi filter atau jumlah data.',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  )
                  : bytes == null
                  ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Gagal membangun PDF. Coba lagi.',
                      style: const TextStyle(color: kTextGrey),
                    ),
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Preview Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kTextWhite,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: kTextGrey,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(color: kInputBg, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                Container(
                                  width: 140,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: kInputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 44,
                                          color: kPrimaryCyan,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'PDF',
                                          style: TextStyle(color: kTextWhite),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _MetaInfoLocal(
                                    meta: widget.meta,
                                    rows: widget.rows,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Ukuran: ${sizeKb ?? '-'} KB',
                              style: const TextStyle(
                                color: kTextGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Actions
                      SizedBox(
                        width: 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  () => Printing.sharePdf(
                                    bytes: bytes!,
                                    filename: widget.suggestFile(
                                      widget.meta,
                                      'pdf',
                                    ),
                                  ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryCyan,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final path = await widget.saveBytes(
                                  bytes!,
                                  widget.suggestFile(widget.meta, 'pdf'),
                                );
                                if (path == null) return;
                                if (widget.parentContext.mounted)
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text('PDF disimpan: $path'),
                                    ),
                                  );
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kInputBg,
                                foregroundColor: kTextWhite,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (c) => AlertDialog(
                                        backgroundColor: kCardBg,
                                        title: const Text(
                                          'Konfirmasi Cetak',
                                          style: TextStyle(color: kTextWhite),
                                        ),
                                        content: Text(
                                          'Cetak dokumen (${sizeKb ?? '-'} KB)?',
                                          style: const TextStyle(
                                            color: kTextGrey,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(c).pop(false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(c).pop(true),
                                            child: const Text('Cetak'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true)
                                  await Printing.layoutPdf(
                                    onLayout: (_) async => bytes!,
                                  );
                              },
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: kPrimaryCyan.withOpacity(0.14),
                                ),
                                foregroundColor: kPrimaryCyan,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

// Local copy of MetaInfo to keep preview file self-contained
class _MetaInfoLocal extends StatelessWidget {
  final Map<String, Object?> meta;
  final List<ReportRowData> rows;
  const _MetaInfoLocal({required this.meta, required this.rows});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    String fmtDate(dynamic d) =>
        d is DateTime ? dateFmt.format(d) : (d?.toString() ?? '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Periode: ${fmtDate(meta['startDate'])} s.d. ${fmtDate(meta['endDate'])}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if ((meta['search'] ?? '').toString().isNotEmpty)
          Text('Pencarian: ${meta['search']}'),
        Text('Baris: ${rows.length}'),
      ],
    );
  }
}
