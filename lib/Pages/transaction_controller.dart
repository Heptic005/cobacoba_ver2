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
import 'package:dakara_weighbridge/Entities/Operator/operator.dart';

/// TransactionController — single source of truth for transaction feature.
/// Holds all business logic, data, and state. UI widgets only render and wire events.
class TransactionController extends ChangeNotifier {
  final DbHelper _db = DbHelper.instance;
  final Operator _operator = Operator();

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
  // map noTicket -> transactionId returned by Operator.addBrutoTransaction
  final Map<String, int> _ticketToId = {};
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
    developer.log(
      'Captured weights reset to initial state',
      name: 'TransactionController',
    );
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
    developer.log(
      'Capturing bruto (weight-in)...',
      name: 'TransactionController',
    );
    isWeighing = true;
    isJustReset = false; // Clear reset flag when capturing new weight
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    // simulate weight read
    capturedBruto =
        (5000 + (DateTime.now().millisecondsSinceEpoch % 2000)).toDouble();
    lastCapturedWeight = capturedBruto!;
    isWeighing = false;
    developer.log(
      'Bruto captured: ${capturedBruto!.toStringAsFixed(2)} kg',
      name: 'TransactionController',
    );
    notifyListeners();
  }

  /// Capture tare (weight-out) — simulates reading from scale hardware
  Future<void> captureTareSimulated() async {
    developer.log(
      'Capturing tare (weight-out)...',
      name: 'TransactionController',
    );
    isWeighing = true;
    isJustReset = false; // Clear reset flag when capturing new weight
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    // simulate a weight read
    capturedTare =
        (3000 + (DateTime.now().millisecondsSinceEpoch % 1000)).toDouble();
    lastCapturedWeight = capturedTare!;
    isWeighing = false;
    developer.log(
      'Tare captured: ${capturedTare!.toStringAsFixed(2)} kg',
      name: 'TransactionController',
    );
    notifyListeners();
  }

  Future<void> saveDraftFromForm(ListTransactionJson tx) async {
    // delegate creation to Operator for role-check and reuse
    final insertedId = await _operator.addBrutoTransaction(
      vehiclePlate: tx.vehiclePlate,
      driverName: tx.driverName,
      supplierId: tx.supplierId,
      customerId: tx.customerId,
      productId: tx.productId,
      cut: tx.cut,
      kubikasi: tx.kubikasi,
      noDo: tx.noDO,
      noContainer: tx.noContainer,
      temperature: tx.temperature,
      price: tx.price,
      additionalInformation: tx.additionalInformation,
      bruto: tx.bruto,
    );
    if (insertedId > 0) {
      transactions = await _db.getListTransaction();
      final newTx = transactions.firstWhere(
        (e) => e.transactionId == insertedId,
        orElse: () => transactions.isNotEmpty ? transactions.last : tx,
      );
      draftTickets.add(newTx.noTicket);
      editingDraftTicket = newTx.noTicket;
      isDraftEditing = true;
      // store mapping from ticket to inserted id
      _ticketToId[newTx.noTicket] = insertedId;
      notifyListeners();
    } else {
      throw Exception('Permission denied or insert failed');
    }
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
      final idx = transactions.indexWhere(
        (e) => e.noTicket == editingDraftTicket,
      );
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
    // capture recent tare
    if (capturedTare != null) return capturedTare!;
    if (isDraftEditing && editingDraftTicket != null) {
      final idx = transactions.indexWhere(
        (e) => e.noTicket == editingDraftTicket,
      );
      if (idx != -1) return transactions[idx].tare.toDouble();
    }
    // If captured, return captured tare

    return lastCapturedWeight;
  }

  /// Capture bruto for a ticket: reuse simulated capture, then persist via Operator
  Future<void> captureBrutoForTicket(String ticket) async {
    developer.log(
      'captureBrutoForTicket: $ticket',
      name: 'TransactionController',
    );
    isWeighing = true;
    notifyListeners();
    await captureBrutoSimulated();
    final value = capturedBruto ?? lastCapturedWeight;

    // prefer stored mapping for transactionId
    int? txId = _ticketToId[ticket];
    if (txId == null) {
      // try to find existing transaction with non-zero id
      final idx = transactions.indexWhere(
        (e) => e.noTicket == ticket && e.transactionId != 0,
      );
      if (idx != -1) txId = transactions[idx].transactionId;
    }

    if (txId == null) {
      // No persisted draft exists yet — keep bruto in memory and require user to Save draft
      capturedBruto = value;
      lastCapturedWeight = value;
      isWeighing = false;
      notifyListeners();
      throw Exception(
        'Draft not saved. Press SIMPAN to create draft before finalizing.',
      );
    }

    // If txId exists, we consider bruto already stored in DB from saveDraftFromForm.
    // Do not create or update bruto here to avoid duplicate rows — UI should save draft.
    transactions = await _db.getListTransaction();
    isWeighing = false;
    notifyListeners();
  }

  /// Capture tare for a ticket: reuse simulated capture, compute totals, then finalize via Operator
  Future<void> captureTareForTicket(String ticket) async {
    developer.log(
      'captureTareForTicket: $ticket',
      name: 'TransactionController',
    );
    isWeighing = true;
    notifyListeners();
    await captureTareSimulated();
    final tareVal = capturedTare ?? lastCapturedWeight;

    final idx = transactions.indexWhere((e) => e.noTicket == ticket);
    if (idx == -1) {
      isWeighing = false;
      notifyListeners();
      throw Exception('Ticket not found');
    }
    final old = transactions[idx];
    final bruto = old.bruto.toDouble();
    final netto = computeNetto(bruto, tareVal);
    final after = computeAfterCut(netto, old.cut.toDouble());
    final price = old.price ?? 0.0;
    final totalPrice = computeTotalPrice(after, price);

    // resolve transactionId: prefer stored mapping
    int? txId = _ticketToId[ticket] ?? old.transactionId;
    if (txId == 0) txId = null;
    if (txId == null) {
      isWeighing = false;
      notifyListeners();
      throw Exception('Transaction id missing; save draft first');
    }

    final rows = await _operator.addNettoTransaction(
      transactionId: txId,
      kubikasi: old.kubikasi,
      noDo: old.noDO,
      noContainer: old.noContainer,
      temperature: old.temperature,
      price: old.price,
      additionalInformation: old.additionalInformation,
      tare: tareVal,
      nettoAfterCut: after,
    );
    if (rows <= 0) {
      isWeighing = false;
      notifyListeners();
      throw Exception('Failed to finalize transaction');
    }

    transactions = await _db.getListTransaction();
    draftTickets.remove(ticket);
    editingDraftTicket = null;
    isDraftEditing = false;
    isWeighing = false;
    notifyListeners();
  }

  Future<void> finalizeDraft(
    String ticket,
    double capturedTare, {
    double? priceFromForm,
  }) async {
    developer.log(
      'Finalizing draft: $ticket with tare: $capturedTare',
      name: 'TransactionController',
    );
    final idx = transactions.indexWhere((e) => e.noTicket == ticket);
    if (idx == -1) throw Exception('Draft not found');
    final old = transactions[idx];
    final bruto = old.bruto.toDouble();
    final tare = capturedTare;
    final netto = computeNetto(bruto, tare);
    final after = computeAfterCut(netto, old.cut.toDouble());
    final price = old.price ?? priceFromForm ?? 0.0;
    final totalPrice = computeTotalPrice(after, price);

    // prefer mapping if present
    int? txId =
        _ticketToId[ticket] ??
        (old.transactionId != 0 ? old.transactionId : null);
    if (txId == null) {
      // fallback: create then finalize via addNettoTransaction
      final newId = await _operator.addBrutoTransaction(
        vehiclePlate: old.vehiclePlate,
        driverName: old.driverName,
        supplierId: old.supplierId,
        customerId: old.customerId,
        productId: old.productId,
        cut: old.cut,
        bruto: bruto,
      );
      if (newId <= 0)
        throw Exception('Failed to create transaction for finalize');
      txId = newId;
    }

    final rows = await _operator.addNettoTransaction(
      transactionId: txId,
      kubikasi: old.kubikasi,
      noDo: old.noDO,
      noContainer: old.noContainer,
      temperature: old.temperature,
      price: old.price,
      additionalInformation: old.additionalInformation,
      tare: tare,
      nettoAfterCut: after,
    );
    if (rows <= 0) throw Exception('Finalize failed');

    transactions = await _db.getListTransaction();
    draftTickets.remove(ticket);
    editingDraftTicket = null;
    isDraftEditing = false;
    developer.log(
      'Draft finalized: netto=$netto, afterCut=$after, totalPrice=$totalPrice',
      name: 'TransactionController',
    );
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
    developer.log(
      'Copying to clipboard: ${text.length} chars',
      name: 'TransactionController',
    );
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

    final pName =
        (item['productName'] ?? item['ProductName'])?.toString().isNotEmpty ==
                true
            ? (item['productName'] ?? item['ProductName']).toString()
            : productNameFromId(pid);
    final sName =
        (item['supplierName'] ?? item['SupplierName'])?.toString().isNotEmpty ==
                true
            ? (item['supplierName'] ?? item['SupplierName']).toString()
            : supplierNameFromId(sid);
    final cName =
        (item['customerName'] ?? item['CustomerName'])?.toString().isNotEmpty ==
                true
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
