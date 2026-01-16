// filepath: lib/Pages/report/report_models.dart
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

/// Lightweight precomputed row model for fast UI rendering
class ReportRowData {
  final int transactionId;
  final String noTicket;
  final String vehiclePlate;
  final String driverName;
  final String productName;
  final String supplierName;
  final String customerName;
  final String formattedDate;
  final String formattedNetto;
  final String formattedBruto;
  final String formattedTare;
  final String formattedTotal;
  final double netto;
  final double bruto;
  final double tare;
  final double totalPrice;

  /// Keep source object for dialogs or actions that need it
  final ListTransactionJson source;

  ReportRowData({
    required this.transactionId,
    required this.noTicket,
    required this.vehiclePlate,
    required this.driverName,
    required this.productName,
    required this.supplierName,
    required this.customerName,
    required this.formattedDate,
    required this.formattedNetto,
    required this.formattedBruto,
    required this.formattedTare,
    required this.formattedTotal,
    required this.netto,
    required this.bruto,
    required this.tare,
    required this.totalPrice,
    required this.source,
  });
}
