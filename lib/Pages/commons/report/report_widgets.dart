/// Report Page Widgets
/// Helper widgets untuk modularisasi ReportPage

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';

// Warna tema (mapping ke AppThemes agar konsisten lintas halaman)
const Color kBgDark = AppThemes.bgDark;
const Color kCardBg = AppThemes.cardBg;
const Color kInputBg = AppThemes.inputBg;
const Color kPrimaryCyan = AppThemes.primaryCyan;
const Color kTextGrey = Color(0xFF9E9E9E);
const Color kTextWhite = AppThemes.textWhite;
const Color kStatusSelesai = AppThemes.primaryCyan;
const Color kStatusMenunggu = AppThemes.statusPending;
const Color kStatusManual = AppThemes.statusManual;

// Formatters
final currencyFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final weightFormat = NumberFormat.decimalPattern('id_ID');
final dateTimeFullFormat = DateFormat('dd MMM yyyy, HH:mm');
final dateShortFormat = DateFormat('dd/MM/yy');

/// Helper format berat dengan unit yang sesuai
String formatWeight(num value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}t';
  return '${weightFormat.format(value)} kg';
}

/// Summary Card Widget
class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: kTextGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Detail Dialog
void showTransactionDetailDialog(
  BuildContext context,
  ListTransactionJson t,
  String Function(int) getSupplierName,
  String Function(int) getProductName,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (dialogContext) => Dialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextWhite,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kTextGrey),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const Divider(color: kInputBg),
                const SizedBox(height: 12),
                _DetailRow(label: 'No. Tiket', value: t.noTicket),
                _DetailRow(label: 'Plat Nomor', value: t.vehiclePlate),
                _DetailRow(label: 'Nama Supir', value: t.driverName),
                _DetailRow(
                  label: 'Supplier',
                  value: getSupplierName(t.supplierId),
                ),
                _DetailRow(label: 'Produk', value: getProductName(t.productId)),
                const Divider(color: kInputBg, height: 24),
                _DetailRow(
                  label: 'Bruto',
                  value: '${weightFormat.format(t.bruto)} kg',
                ),
                _DetailRow(
                  label: 'Tara',
                  value: '${weightFormat.format(t.tare)} kg',
                ),
                _DetailRow(
                  label: 'Netto',
                  value: '${weightFormat.format(t.netto)} kg',
                ),
                _DetailRow(label: 'Potongan', value: '${t.cut} kg'),
                _DetailRow(
                  label: 'Setelah Potongan',
                  value: '${weightFormat.format(t.nettoAfterCut)} kg',
                ),
                const Divider(color: kInputBg, height: 24),
                _DetailRow(
                  label: 'Total Harga',
                  value: currencyFormat.format(t.totalPrice),
                  valueColor: kPrimaryCyan,
                ),
                _DetailRow(
                  label: 'Waktu Masuk',
                  value: dateTimeFullFormat.format(t.inTime),
                ),
                if (t.outTime != null)
                  _DetailRow(
                    label: 'Waktu Keluar',
                    value: dateTimeFullFormat.format(t.outTime!),
                  ),
              ],
            ),
          ),
        ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextGrey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? kTextWhite,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
