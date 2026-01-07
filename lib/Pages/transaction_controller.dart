import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';

/// TransactionController — single source of truth for transaction feature.
/// Holds all business logic, data, and state. UI widgets only render and wire events.
class TransactionController extends ChangeNotifier {
  final DbHelper _db = DbHelper.instance;

  List<ListSupplierJson> suppliers = [];
  List<ListCustomerJson> customers = [];
  List<ListProductJson> products = [];
  List<ListTransactionJson> transactions = [];

  bool isWeighIn = true;
  bool isWeighing = false;
  bool isConnected = true;
  int ticketCounter = 1;
  final Set<String> draftTickets = {};
  String? editingDraftTicket;
  bool isDraftEditing = false;
  double lastCapturedWeight = 0.0;
  String? currentTicketPreview;

  // Captured weights for different stages
  double? capturedBruto;
  double? capturedTare;
  bool isJustReset = false; // Track if just reset to show 0 values

  Future<void> init() async {
    await loadData();
  }

  /// Reset captured weights to initial state
  void resetCapture() {
    capturedBruto = null;
    capturedTare = null;
    lastCapturedWeight = 0.0;
    currentTicketPreview = null;
    isJustReset = true; // Set flag to show 0 values
    developer.log('Captured weights reset to initial state', name: 'TransactionController');
    notifyListeners();
  }

  Future<void> loadData() async {
    suppliers = await _db.getListSupplier();
    customers = await _db.getListCustomers();
    products = await _db.getListProducts();
    transactions = await _db.getListTransaction();

    // init ticket counter from existing transactions
    try {
      final last = transactions.isNotEmpty ? transactions.last.noTicket : null;
      if (last != null) {
        // try to parse trailing number
        final parts = last.split('-');
        final n = int.tryParse(parts.isNotEmpty ? parts.last : '0') ?? 0;
        ticketCounter = n + 1;
      }
    } catch (_) {}
    notifyListeners();
  }

  String generateTicket() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(now);
    final ticket = 'T-$dateStr-${ticketCounter.toString().padLeft(4, '0')}';
    ticketCounter++;
    currentTicketPreview = ticket;
    notifyListeners();
    return ticket;
  }

  /// Capture bruto (weight-in) — simulates reading from scale hardware
  Future<void> captureBrutoSimulated() async {
    developer.log('Capturing bruto (weight-in)...', name: 'TransactionController');
    isWeighing = true;
    isJustReset = false; // Clear reset flag when capturing new weight
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    // simulate weight read
    capturedBruto = (5000 + (DateTime.now().millisecondsSinceEpoch % 2000)).toDouble();
    lastCapturedWeight = capturedBruto!;
    isWeighing = false;
    developer.log('Bruto captured: ${capturedBruto!.toStringAsFixed(2)} kg', name: 'TransactionController');
    notifyListeners();
  }

  /// Capture tare (weight-out) — simulates reading from scale hardware
  Future<void> captureTareSimulated() async {
    developer.log('Capturing tare (weight-out)...', name: 'TransactionController');
    isWeighing = true;
    isJustReset = false; // Clear reset flag when capturing new weight
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    // simulate a weight read
    capturedTare = (3000 + (DateTime.now().millisecondsSinceEpoch % 1000)).toDouble();
    lastCapturedWeight = capturedTare!;
    isWeighing = false;
    developer.log('Tare captured: ${capturedTare!.toStringAsFixed(2)} kg', name: 'TransactionController');
    notifyListeners();
  }

  Future<void> saveDraftFromForm(ListTransactionJson tx) async {
    await _db.addTransaction(tx);
    transactions = await _db.getListTransaction();
    draftTickets.add(tx.noTicket);
    editingDraftTicket = tx.noTicket;
    isDraftEditing = true;
    notifyListeners();
  }

  double computeAfterCut(double netto, double cutPct) {
    if (cutPct <= 0) return netto;
    final after = netto - ((cutPct / 100.0) * netto);
    return after < 0 ? 0.0 : after;
  }

  double computeTotalPrice(double afterCut, double price) {
    return afterCut * price;
  }

  /// Compute netto from bruto and tare
  double computeNetto(double bruto, double tare) {
    final netto = bruto - tare;
    return netto < 0 ? 0.0 : netto;
  }

  double computeBrutoDisplay() {
    // If just reset, show 0
    if (isJustReset) return 0.0;
    // If draft editing, return bruto from transaction
    if (isDraftEditing && editingDraftTicket != null) {
      final idx = transactions.indexWhere((e) => e.noTicket == editingDraftTicket);
      if (idx != -1) return transactions[idx].bruto.toDouble();
    }
    // If captured, return captured bruto
    if (capturedBruto != null) return capturedBruto!;
    // Default 0 if no capture yet
    return 0.0;
  }

  double computeTareDisplay() {
    // If just reset, show 0
    if (isJustReset) return 0.0;
    if (isDraftEditing && editingDraftTicket != null) {
      final idx = transactions.indexWhere((e) => e.noTicket == editingDraftTicket);
      if (idx != -1) return transactions[idx].tare.toDouble();
    }
    // If captured, return captured tare
    if (capturedTare != null) return capturedTare!;
    return lastCapturedWeight;
  }

  Future<void> finalizeDraft(String ticket, double capturedTare, {double? priceFromForm}) async {
    developer.log('Finalizing draft: $ticket with tare: $capturedTare', name: 'TransactionController');
    final idx = transactions.indexWhere((e) => e.noTicket == ticket);
    if (idx == -1) throw Exception('Draft not found');
    final old = transactions[idx];
    final bruto = old.bruto.toDouble();
    final tare = capturedTare;
    final netto = computeNetto(bruto, tare);
    final after = computeAfterCut(netto, old.cut.toDouble());
    final price = old.price ?? priceFromForm ?? 0.0;
    final totalPrice = computeTotalPrice(after, price);

    final updated = ListTransactionJson(
      vehiclePlate: old.vehiclePlate,
      driverName: old.driverName,
      supplierId: old.supplierId,
      customerId: old.customerId,
      productId: old.productId,
      cut: old.cut,
      kubikasi: old.kubikasi,
      noDO: old.noDO,
      noContainer: old.noContainer,
      temperature: old.temperature,
      price: price,
      additionalInformation: old.additionalInformation,
      noTicket: old.noTicket,
      inTime: old.inTime,
      outTime: DateTime.now(),
      totalPrice: totalPrice,
      bruto: bruto,
      tare: tare,
      netto: netto,
      nettoAfterCut: after,
      driverLabel: old.driverLabel,
      transactionId: old.transactionId,
      operatorLabel: old.operatorLabel,
      managerLabel: old.managerLabel,
      headWarehouseLabel: old.headWarehouseLabel,
    );

    await _db.updateTransaction(updated);
    transactions = await _db.getListTransaction();
    draftTickets.remove(ticket);
    editingDraftTicket = null;
    isDraftEditing = false;
    developer.log('Draft finalized: netto=$netto, afterCut=$after, totalPrice=$totalPrice', name: 'TransactionController');
    notifyListeners();
  }

  Future<void> continueNettoAndMaybeAuto(ListTransactionJson txFromList) async {
    // validate
    if (!isConnected) throw Exception('Indicator not connected');
    // simulate capture then finalize
    await captureTareSimulated();
    final captured = lastCapturedWeight;
    await finalizeDraft(txFromList.noTicket, captured);
  }

  void setDraftEditing(bool editing, [String? ticket]) {
    isDraftEditing = editing;
    editingDraftTicket = ticket;
    notifyListeners();
  }

  // --- Helper methods for name lookup ---
  int? intFrom(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String productNameFromId(dynamic id) {
    if (id == null) return '';
    for (final e in products) {
      if (e.productId == id || e.productId.toString() == id.toString()) {
        return e.productName;
      }
    }
    return '';
  }

  String supplierNameFromId(dynamic id) {
    if (id == null) return '';
    for (final e in suppliers) {
      if (e.supplierId == id || e.supplierId.toString() == id.toString()) {
        return e.supplierName;
      }
    }
    return '';
  }

  String customerNameFromId(dynamic id) {
    if (id == null) return '';
    for (final e in customers) {
      if (e.customerId == id || e.customerId.toString() == id.toString()) {
        return e.customerName;
      }
    }
    return '';
  }

  String formatShortDate(String? s) {
    if (s == null || s.isEmpty) return '-';
    try {
      final dt = DateTime.parse(s);
      return DateFormat('dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return s;
    }
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy HH:mm').format(dt);
  }

  String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String formatTime(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }

  // --- Clipboard helper ---
  void copyToClipboard(String text) {
    developer.log('Copying to clipboard: ${text.length} chars', name: 'TransactionController');
    Clipboard.setData(ClipboardData(text: text));
  }

  // --- Print text builder (TODO: integrate real printing) ---
  String buildPrintText(Map<String, Object?> item) {
    final pid = intFrom(item['productId']);
    final sid = intFrom(item['supplierId']);
    final cid = intFrom(item['customerId']);

    final sb = StringBuffer();
    sb.writeln('Ticket: ${item['noTicket'] ?? ''}');
    sb.writeln('Plate: ${item['vehiclePlate'] ?? ''}');
    sb.writeln('Driver: ${item['driverName'] ?? ''}');

    final pName = (item['productName'] ?? item['ProductName'])?.toString().isNotEmpty == true
        ? (item['productName'] ?? item['ProductName']).toString()
        : productNameFromId(pid);
    final sName = (item['supplierName'] ?? item['SupplierName'])?.toString().isNotEmpty == true
        ? (item['supplierName'] ?? item['SupplierName']).toString()
        : supplierNameFromId(sid);
    final cName = (item['customerName'] ?? item['CustomerName'])?.toString().isNotEmpty == true
        ? (item['customerName'] ?? item['CustomerName']).toString()
        : customerNameFromId(cid);

    sb.writeln('Product: $pName');
    sb.writeln('Supplier: $sName');
    sb.writeln('Customer: $cName');
    sb.writeln('Bruto: ${item['bruto'] ?? ''} kg');
    sb.writeln('Tare: ${item['tare'] ?? ''} kg');
    sb.writeln('Netto: ${item['netto'] ?? ''} kg');
    sb.writeln('After Cut: ${item['nettoAfterCut'] ?? item['netto'] ?? ''} kg');
    return sb.toString();
  }

  String buildPrintTextFromTx(ListTransactionJson tx) {
    final sb = StringBuffer();
    sb.writeln('Ticket: ${tx.noTicket}');
    sb.writeln('Plate: ${tx.vehiclePlate}');
    sb.writeln('Driver: ${tx.driverName}');
    sb.writeln('Product: ${productNameFromId(tx.productId)}');
    sb.writeln('Supplier: ${supplierNameFromId(tx.supplierId)}');
    sb.writeln('Customer: ${customerNameFromId(tx.customerId)}');
    sb.writeln('Bruto: ${tx.bruto} kg');
    sb.writeln('Tare: ${tx.tare} kg');
    sb.writeln('Netto: ${tx.netto} kg');
    sb.writeln('After Cut: ${tx.nettoAfterCut} kg');
    return sb.toString();
  }
}
