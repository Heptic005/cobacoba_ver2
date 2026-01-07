import 'dart:async';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_monitor.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/form_card.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/recent_transactions.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:flutter/services.dart';

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  late Timer _timer;
  final ValueNotifier<String> _timeNotifier = ValueNotifier('');
  Color limeGreen = const Color(0xFF97FF21);
  bool _isWeighIn = true;
  String _displayWeight = '0';
  bool _isWeighing = false;
  bool _isConnected = true;
  int _ticketCounter = 1;
  final Set<String> _draftTickets = {}; // store noTicket for drafts
  String? _editingDraftTicket;
  bool _isDraftEditing = false;
  double _lastCapturedWeight = 0.0;
  String? _currentTicketPreview;

  // Colors based on design
  final Color _bgDark = const Color(0xFF1E2126);
  final Color _cardBg = const Color(0xFF2B2E33);
  final Color _primaryCyan = const Color(0xFF00E5FF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFFBFC9D6);
  final Color _inputBg = const Color(0xFF383C42);

  final platnomorController = TextEditingController();
  final poController = TextEditingController();
  final namasupirController = TextEditingController();
  final potonganController = TextEditingController();
  final kubikasiController = TextEditingController();
  final nocontainerController = TextEditingController();
  final suhuController = TextEditingController();
  final hargaController = TextEditingController();
  final keteranganController = TextEditingController();

  // Recent transactions controls
  final TextEditingController _searchController = TextEditingController();
  bool _sortDesc = true; // sort by inTime desc by default

  // Transactions list backed by DB
  // Removed sample/mock transactions; UI uses `_transactions` populated from DB.
  // paging
  int _currentPage = 0;
  static const int _pageSize = 5;

  final focusPlatnomor = FocusNode();
  final focusPO = FocusNode();
  final focusSupir = FocusNode();
  final focusPotongan = FocusNode();
  final focusKubikasi = FocusNode();
  final focusNoContainer = FocusNode();
  final focusSuhu = FocusNode();
  final focusHarga = FocusNode();
  final focusKeterangan = FocusNode();

  // Mock Data Lists
  List<ListSupplierJson> _suppliers = [];
  List<ListCustomerJson> _customers = [];
  List<ListProductJson> _products = [];
  List<ListTransactionJson> _transactions = [];

  // Selected Values for Dropdowns
  int? _selectedSupplier;
  int? _selectedCustomer;
  int? _selectedProduct;

  Future<void> loadData() async {
    _suppliers = await DbHelper.instance.getListSupplier();
    _customers = await DbHelper.instance.getListCustomers();
    _products = await DbHelper.instance.getListProducts();
    _transactions = await DbHelper.instance.getListTransaction();
  }

  @override
  void initState() {
    super.initState();
    _timeNotifier.value = _formatDateTime(DateTime.now());
    _initAsync();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _timeNotifier.value = _formatDateTime(DateTime.now());
    });
    // ticket counter will be initialized in _initAsync after DB load
  }

  @override
  void dispose() {
    _timer.cancel();
    platnomorController.dispose();
    poController.dispose();
    namasupirController.dispose();
    potonganController.dispose();
    kubikasiController.dispose();
    nocontainerController.dispose();
    suhuController.dispose();
    hargaController.dispose();
    keteranganController.dispose();
    _searchController.dispose();
    focusPlatnomor.dispose();
    focusPO.dispose();
    focusSupir.dispose();
    focusPotongan.dispose();
    focusKubikasi.dispose();
    focusNoContainer.dispose();
    focusSuhu.dispose();
    focusHarga.dispose();
    focusKeterangan.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  // Clock updates are handled via _timeNotifier to avoid rebuilding whole page

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void _setWeightFromIndicator() {
    setState(() {
      _displayWeight = '0';
    });
  }

  String _formatShortDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) return DateFormat('dd MMM HH:mm').format(dt);
      return raw;
    } catch (e) {
      return raw;
    }
  }

  DateTime? _parseDateMaybe(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is double) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(s);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  int? _intFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String _supplierNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final s = _suppliers.firstWhere((e) => e.supplierId == id, orElse: () => ListSupplierJson(supplierName: '', supplierAddress: '', supplierCity: '', supplierSubdistrict: '', supplierPostCode: ''));
      return s.supplierName;
    } catch (_) {
      return '';
    }
  }

  String _customerNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final c = _customers.firstWhere((e) => e.customerId == id, orElse: () => ListCustomerJson(customerName: '', customerAddress: '', customerPhone: ''));
      return c.customerName;
    } catch (_) {
      return '';
    }
  }

  String _productNameFromId(int? id) {
    if (id == null || id == 0) return '';
    try {
      final p = _products.firstWhere((e) => e.productId == id, orElse: () => ListProductJson(productId: 0, productName: '', productCode: ''));
      return p.productName;
    } catch (_) {
      return '';
    }
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  String _generateTicket() {
    final now = DateTime.now();
    final ymd = DateFormat('yyyyMMdd').format(now);
    final seq = _ticketCounter.toString().padLeft(4, '0');
    return '$ymd-$seq';
  }

  void _loadDraftIntoForm(ListTransactionJson tx) {
    platnomorController.text = tx.vehiclePlate;
    namasupirController.text = tx.driverName;
    _selectedSupplier = (tx.supplierId > 0) ? tx.supplierId : null;
    _selectedCustomer = (tx.customerId > 0) ? tx.customerId : null;
    _selectedProduct = (tx.productId > 0) ? tx.productId : null;
    potonganController.text = tx.cut.toString();
    kubikasiController.text = tx.kubikasi?.toString() ?? '';
    poController.text = tx.noDO ?? '';
    nocontainerController.text = tx.noContainer?.toString() ?? '';
    suhuController.text = tx.temperature?.toString() ?? '';
    hargaController.text = tx.price?.toString() ?? '';
    keteranganController.text = tx.additionalInformation ?? '';
    _isDraftEditing = true;
    _editingDraftTicket = tx.noTicket;
    _currentTicketPreview = tx.noTicket;
    // set mode to weigh out
    _isWeighIn = false;
    setState(() {});
  }

  Future<void> _initAsync() async {
    await loadData();
    if (!mounted) return;
    setState(() {
      final maxId = _transactions.isNotEmpty ? _transactions.map((t) => t.transactionId).fold<int>(0, (p, e) => e > p ? e : p) : 0;
      _ticketCounter = (maxId > 0) ? (maxId + 1) : (_transactions.length + 1);
    });
  }

  Future<void> _handleSavePressed() async {
    if (_isDraftEditing) {
      if (_editingDraftTicket != null && _lastCapturedWeight > 0) {
        _finalizeDraft(_editingDraftTicket!, _lastCapturedWeight);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture tare to finalize Netto')));
      }
      return;
    }

    if (_isWeighIn) {
      final ticket = _generateTicket();
      final brutoVal = _lastCapturedWeight > 0 ? _lastCapturedWeight : double.tryParse(_displayWeight) ?? 0.0;
      final draft = ListTransactionJson(
        vehiclePlate: platnomorController.text.isEmpty ? 'Unknown' : platnomorController.text,
        driverName: namasupirController.text.isEmpty ? 'Unknown' : namasupirController.text,
        supplierId: _selectedSupplier ?? 0,
        customerId: _selectedCustomer ?? 0,
        productId: _selectedProduct ?? 0,
        cut: int.tryParse(potonganController.text) ?? 0,
        kubikasi: int.tryParse(kubikasiController.text),
        noDO: poController.text.isEmpty ? null : poController.text,
        noContainer: nocontainerController.text.isEmpty ? null : int.tryParse(nocontainerController.text),
        temperature: double.tryParse(suhuController.text),
        price: double.tryParse(hargaController.text),
        additionalInformation: keteranganController.text.isEmpty ? null : keteranganController.text,
        noTicket: ticket,
        inTime: DateTime.now(),
        outTime: DateTime.fromMillisecondsSinceEpoch(0),
        totalPrice: (double.tryParse(hargaController.text) ?? 0.0) * brutoVal,
        bruto: brutoVal,
        tare: 0.0,
        netto: brutoVal,
        nettoAfterCut: brutoVal - ((int.tryParse(potonganController.text) ?? 0) / 100 * brutoVal),
        driverLabel: 1,
        operatorLabel: 0,
        managerLabel: 0,
        headWarehouseLabel: 0,
      );

      try {
        final insertedId = await DbHelper.instance.addTransaction(draft);
        final persisted = ListTransactionJson(
          vehiclePlate: draft.vehiclePlate,
          driverName: draft.driverName,
          supplierId: draft.supplierId,
          customerId: draft.customerId,
          productId: draft.productId,
          cut: draft.cut,
          kubikasi: draft.kubikasi,
          noDO: draft.noDO,
          noContainer: draft.noContainer,
          temperature: draft.temperature,
          price: draft.price,
          additionalInformation: draft.additionalInformation,
          noTicket: draft.noTicket,
          inTime: draft.inTime,
          outTime: draft.outTime,
          totalPrice: draft.totalPrice,
          bruto: draft.bruto,
          tare: draft.tare,
          netto: draft.netto,
          nettoAfterCut: draft.nettoAfterCut,
          driverLabel: draft.driverLabel,
          transactionId: insertedId,
          operatorLabel: draft.operatorLabel,
          managerLabel: draft.managerLabel,
          headWarehouseLabel: draft.headWarehouseLabel,
        );

        setState(() {
          _transactions.insert(0, persisted);
          _draftTickets.add(ticket);
          _currentTicketPreview = ticket;
          _ticketCounter++;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved (Bruto)')));
        });
      } on Exception catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed saving draft: $e')));
      }
      return;
    }

    // For non-weigh-in saves (SIMPAN KELUAR), original logic remains in-place elsewhere.
  }

  Future<void> _finalizeDraft(String ticket, double capturedValue) async {
    final idx = _transactions.indexWhere((e) => e.noTicket == ticket);
    if (idx == -1) return;
    final old = _transactions[idx];
    final bruto = old.bruto;
    final tare = capturedValue; // captured while finishing netto
    final netto = (bruto - tare) < 0 ? 0.0 : (bruto - tare);
    final nettoAfterCut = netto - ((old.cut / 100) * netto);
    final price = old.price ?? 0.0;
    final totalPrice = price * nettoAfterCut;

    final updated = ListTransactionJson(
      vehiclePlate: old.vehiclePlate,
      driverName: old.driverName,
      supplierId: (old as dynamic).supplierId ?? 0,
      customerId: (old as dynamic).customerId ?? 0,
      productId: (old as dynamic).productId ?? 0,
      cut: old.cut,
      kubikasi: old.kubikasi,
      noDO: old.noDO,
      noContainer: old.noContainer,
      temperature: old.temperature,
      price: old.price,
      additionalInformation: old.additionalInformation,
      noTicket: old.noTicket,
      inTime: old.inTime,
      outTime: DateTime.now(),
      totalPrice: totalPrice,
      bruto: bruto,
      tare: tare,
      netto: netto,
      nettoAfterCut: nettoAfterCut,
      driverLabel: old.driverLabel,
      transactionId: old.transactionId > 0 ? old.transactionId : _ticketCounter,
      operatorLabel: old.operatorLabel,
      managerLabel: old.managerLabel,
      headWarehouseLabel: old.headWarehouseLabel,
    );
    try {
      await DbHelper.instance.updateTransaction(updated);
      setState(() {
        _transactions[idx] = updated;
        _draftTickets.remove(ticket);
        _editingDraftTicket = null;
        _isDraftEditing = false;
        _currentTicketPreview = null;
        _ticketCounter = (_ticketCounter <= 0) ? 1 : _ticketCounter + 1;
        // after finalizing, reset UI to weigh-in and clear captured weights
        _isWeighIn = true;
        _isWeighing = false;
        _lastCapturedWeight = 0.0;
        _displayWeight = '0';
        // clear form
        platnomorController.clear();
        namasupirController.clear();
        _selectedSupplier = null;
        _selectedCustomer = null;
        _selectedProduct = null;
        potonganController.clear();
        kubikasiController.clear();
        poController.clear();
        nocontainerController.clear();
        suhuController.clear();
        hargaController.clear();
        keteranganController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Netto finalized')));
      });
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed finalizing: $e')));
    }
  }

  Future<void> _continueNettoAndMaybeAuto(ListTransactionJson tx) async {
    // Basic required fields check
    final hasRequired = tx.vehiclePlate.isNotEmpty && tx.driverName.isNotEmpty && _productNameFromId(tx.productId).isNotEmpty && _supplierNameFromId(tx.supplierId).isNotEmpty && _customerNameFromId(tx.customerId).isNotEmpty;
    if (!hasRequired) {
      // load into form for user to complete
      _loadDraftIntoForm(tx);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete required fields before finalizing')));
      return;
    }

    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indicator not connected')));
      // still load into form
      _loadDraftIntoForm(tx);
      return;
    }

    // Auto-capture tare (simulate) and load draft into edit mode for weigh-out.
    setState(() => _isWeighing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    final captured = 50 + DateTime.now().second % 30; // simulate tare
    _lastCapturedWeight = captured.toDouble();
    _displayWeight = _lastCapturedWeight.toStringAsFixed(0);
    setState(() => _isWeighing = false);

    // validate price and cut before allowing finalize; if invalid, open form for edit
    if (tx.price == null || tx.price == 0.0) {
      _loadDraftIntoForm(tx);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price missing or zero — complete price before finalizing')));
      return;
    }
    if (tx.cut < 0 || tx.cut > 100) {
      _loadDraftIntoForm(tx);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Potongan must be between 0 and 100')));
      return;
    }

    // Load draft into form and keep editing mode; user must press SIMPAN KELUAR to finalize
    _loadDraftIntoForm(tx);
    _editingDraftTicket = tx.noTicket;
    _currentTicketPreview = tx.noTicket;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tare captured — press SIMPAN KELUAR to finalize')));
    // Keep captured tare visible and stay in weigh-out edit mode so user can review and press SIMPAN KELUAR
    setState(() {
      _isWeighIn = false;
      // leave _lastCapturedWeight and _displayWeight as captured
    });
  }

  Widget _detailRow(String label, String value) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showDetailDialogMap(Map<String, Object?> item) async {
    final pid = _intFrom(item['productId']);
    final sid = _intFrom(item['supplierId']);
    final cid = _intFrom(item['customerId']);

    if ((_products.isEmpty && pid != null) || (_suppliers.isEmpty && sid != null) || (_customers.isEmpty && cid != null)) {
      await loadData();
      if (!mounted) return;
      setState(() {});
    }

    final intime = _formatShortDate(item['inTime']?.toString());
    final outtimeRaw = item['outTime']?.toString();
    final outtime = (outtimeRaw != null && outtimeRaw.isNotEmpty) ? _formatShortDate(outtimeRaw) : null;

    final productName = (item['productName'] ?? item['ProductName'])?.toString().trim().isNotEmpty == true
      ? (item['productName'] ?? item['ProductName']).toString()
      : _productNameFromId(pid);
    final supplierName = (item['supplierName'] ?? item['SupplierName'])?.toString().trim().isNotEmpty == true
      ? (item['supplierName'] ?? item['SupplierName']).toString()
      : _supplierNameFromId(sid);
    final customerName = (item['customerName'] ?? item['CustomerName'])?.toString().trim().isNotEmpty == true
      ? (item['customerName'] ?? item['CustomerName']).toString()
      : _customerNameFromId(cid);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(builder: (context, constraints) {
                final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
                return Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _textGrey.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['noTicket']?.toString() ?? 'Detail', style: TextStyle(color: _primaryCyan, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Divider(color: _textGrey.withValues(alpha: 0.12)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            runSpacing: 10,
                            spacing: 20,
                            children: [
                              _detailRow('Plate', item['vehiclePlate']?.toString() ?? '-'),
                              _detailRow('Driver', item['driverName']?.toString() ?? '-'),
                              _detailRow('Product', productName.isNotEmpty ? productName : '-'),
                              _detailRow('Supplier', supplierName.isNotEmpty ? supplierName : '-'),
                              _detailRow('Customer', customerName.isNotEmpty ? customerName : '-'),
                              _detailRow('In', intime),
                              _detailRow('Out', outtime ?? '-'),
                              _detailRow('Bruto', '${item['bruto'] ?? 0} kg'),
                              _detailRow('Tare', '${item['tare'] ?? 0} kg'),
                              _detailRow('Netto', '${item['netto'] ?? 0} kg'),
                              _detailRow('After cut', '${item['nettoAfterCut'] ?? item['netto'] ?? 0} kg'),
                              if (item['additionalInformation'] != null) _detailRow('Notes', item['additionalInformation']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Close', style: TextStyle(color: _textGrey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _printTransactionMap(item);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryCyan, foregroundColor: Colors.black),
                            child: const Text('Print'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Future<void> _printTransactionMap(Map<String, Object?> item) async {
    final pid = _intFrom(item['productId']);
    final sid = _intFrom(item['supplierId']);
    final cid = _intFrom(item['customerId']);

    if ((_products.isEmpty && pid != null) || (_suppliers.isEmpty && sid != null) || (_customers.isEmpty && cid != null)) {
      await loadData();
      if (!mounted) return;
      setState(() {});
    }

    final sb = StringBuffer();
    sb.writeln('Ticket: ${item['noTicket'] ?? ''}');
    sb.writeln('Plate: ${item['vehiclePlate'] ?? ''}');
    sb.writeln('Driver: ${item['driverName'] ?? ''}');
    final pName = (item['productName'] ?? item['ProductName'])?.toString().isNotEmpty == true
      ? (item['productName'] ?? item['ProductName']).toString()
      : _productNameFromId(pid);
    final sName = (item['supplierName'] ?? item['SupplierName'])?.toString().isNotEmpty == true
      ? (item['supplierName'] ?? item['SupplierName']).toString()
      : _supplierNameFromId(sid);
    final cName = (item['customerName'] ?? item['CustomerName'])?.toString().isNotEmpty == true
      ? (item['customerName'] ?? item['CustomerName']).toString()
      : _customerNameFromId(cid);
    sb.writeln('Product: $pName');
    sb.writeln('Supplier: $sName');
    sb.writeln('Customer: $cName');
    sb.writeln('Bruto: ${item['bruto'] ?? ''} kg');
    // placeholder for real print integration
    showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Print'), content: Text(sb.toString()), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]));
  }

  void _printTransactionList(ListTransactionJson tx) {
    final sb = StringBuffer();
    sb.writeln('Ticket: ${tx.noTicket}');
    sb.writeln('Plate: ${tx.vehiclePlate}');
    sb.writeln('Driver: ${tx.driverName}');
    sb.writeln('Product: ${_productNameFromId(tx.productId)}');
    sb.writeln('Bruto: ${tx.bruto} kg');
    showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Print'), content: Text(sb.toString()), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]));
  }

  void _showDetailDialogList(ListTransactionJson tx) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final intime = DateFormat('dd MMM yyyy HH:mm').format(tx.inTime);
        final outtime = tx.outTime.isAfter(tx.inTime) ? DateFormat('dd MMM yyyy HH:mm').format(tx.outTime) : null;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(builder: (context, constraints) {
                final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
                return Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _textGrey.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.noTicket, style: TextStyle(color: _primaryCyan, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Divider(color: _textGrey.withValues(alpha: 0.12)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            runSpacing: 10,
                            spacing: 20,
                            children: [
                              _detailRow('Plate', tx.vehiclePlate),
                              _detailRow('Driver', tx.driverName),
                              _detailRow('Product', _productNameFromId(tx.productId)),
                              _detailRow('Supplier', _supplierNameFromId(tx.supplierId)),
                              _detailRow('Customer', _customerNameFromId(tx.customerId)),
                              _detailRow('In', intime),
                              _detailRow('Out', outtime ?? '-'),
                              _detailRow('Bruto', '${tx.bruto} kg'),
                              _detailRow('Tare', '${tx.tare} kg'),
                              _detailRow('Netto', '${tx.netto} kg'),
                              _detailRow('After cut', '${tx.nettoAfterCut} kg'),
                              if (tx.additionalInformation != null) _detailRow('Notes', tx.additionalInformation ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Close', style: TextStyle(color: _textGrey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _printTransactionList(tx);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryCyan, foregroundColor: Colors.black),
                            child: const Text('Print'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // HEADER
            _buildHeader(),
            const SizedBox(height: 20),

            // TOP SECTION: Weight Monitor + Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildWeightMonitorCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildMainActions()),
              ],
            ),
            const SizedBox(height: 20),

            // BOTTOM SECTION: Form + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TransactionFormCard(
                    platnomorController: platnomorController,
                    poController: poController,
                    namasupirController: namasupirController,
                    potonganController: potonganController,
                    kubikasiController: kubikasiController,
                    nocontainerController: nocontainerController,
                    suhuController: suhuController,
                    hargaController: hargaController,
                    keteranganController: keteranganController,
                    focusPlatnomor: focusPlatnomor,
                    focusPO: focusPO,
                    focusSupir: focusSupir,
                    focusPotongan: focusPotongan,
                    focusKubikasi: focusKubikasi,
                    focusNoContainer: focusNoContainer,
                    focusSuhu: focusSuhu,
                    focusHarga: focusHarga,
                    focusKeterangan: focusKeterangan,
                    suppliers: _suppliers,
                    customers: _customers,
                    products: _products,
                    selectedSupplier: _selectedSupplier,
                    selectedCustomer: _selectedCustomer,
                    selectedProduct: _selectedProduct,
                    isWeighing: _isWeighing,
                    isDraftEditing: _isDraftEditing,
                    currentTicketPreview: _currentTicketPreview,
                    cardBg: _cardBg,
                    primaryCyan: _primaryCyan,
                    textGrey: _textGrey,
                    inputBg: _inputBg,
                    onSelectSupplier: (v) => setState(() => _selectedSupplier = v),
                    onSelectCustomer: (v) => setState(() => _selectedCustomer = v),
                    onSelectProduct: (v) => setState(() => _selectedProduct = v),
                    onSavePressed: () async => _handleSavePressed(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildWeightDetails()),
              ],
            ),
            const SizedBox(height: 30),
            // RECENT TRANSACTIONS
            RecentTransactions(
              searchController: _searchController,
              sortDesc: _sortDesc,
              draftTickets: _draftTickets,
              transactions: _transactions,
              suppliers: _suppliers,
              customers: _customers,
              products: _products,
              cardBg: _cardBg,
              textGrey: _textGrey,
              primaryCyan: _primaryCyan,
              inputBg: _inputBg,
              onShowDetailMap: (m) async => _showDetailDialogMap(m),
              onPrintMap: (m) async => _printTransactionMap(m),
              onContinueAuto: (tx) async => _continueNettoAndMaybeAuto(tx),
              onLoadDraft: (tx) => _loadDraftIntoForm(tx),
              onCopyToClipboard: (t) => _copyToClipboard(t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMonitorCard() {
    return WeightMonitorCard(
      displayWeight: _displayWeight,
      isWeighing: _isWeighing,
      isWeighIn: _isWeighIn,
      isConnected: _isConnected,
      cardBg: _cardBg,
      primaryCyan: _primaryCyan,
      textGrey: _textGrey,
      textWhite: _textWhite,
      indicatorGreen: limeGreen,
      onToggleMode: () => setState(() => _isWeighIn = !_isWeighIn),
      onCapture: () async {
        if (!_isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indicator not connected')));
          return;
        }
        setState(() {
          _isWeighing = true;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        _lastCapturedWeight = 100 + DateTime.now().second % 50;

        if (_isDraftEditing && _editingDraftTicket != null) {
          final capturedTare = _lastCapturedWeight.toDouble();
          final idx = _transactions.indexWhere((e) => e.noTicket == _editingDraftTicket);
          if (idx != -1) {
            final old = _transactions[idx];
            final bruto = old.bruto;
            final tare = capturedTare;
            final netto = (bruto - tare) < 0 ? 0.0 : (bruto - tare);
            final nettoAfterCut = netto - ((old.cut / 100) * netto);
            final price = old.price ?? double.tryParse(hargaController.text) ?? 0.0;
            final totalPrice = price * nettoAfterCut;

            final updated = ListTransactionJson(
              vehiclePlate: old.vehiclePlate,
              driverName: old.driverName,
              supplierId: (old as dynamic).supplierId ?? 0,
              customerId: (old as dynamic).customerId ?? 0,
              productId: (old as dynamic).productId ?? 0,
              cut: old.cut,
              kubikasi: old.kubikasi,
              noDO: old.noDO,
              noContainer: old.noContainer,
              temperature: old.temperature,
              price: old.price,
              additionalInformation: old.additionalInformation,
              noTicket: old.noTicket,
              inTime: old.inTime,
              outTime: old.outTime,
              totalPrice: totalPrice,
              bruto: bruto,
              tare: tare,
              netto: netto,
              nettoAfterCut: nettoAfterCut,
              driverLabel: (old.driverLabel is int) ? old.driverLabel : ((old.driverLabel == true) ? 1 : 0),
              transactionId: old.transactionId,
              operatorLabel: (old.operatorLabel is int) ? old.operatorLabel : ((old.operatorLabel == true) ? 1 : 0),
              managerLabel: (old.managerLabel is int) ? old.managerLabel : ((old.managerLabel == true) ? 1 : 0),
              headWarehouseLabel: (old.headWarehouseLabel is int) ? old.headWarehouseLabel : ((old.headWarehouseLabel == true) ? 1 : 0),
            );

            setState(() {
              _transactions[idx] = updated;
              _displayWeight = _lastCapturedWeight.toStringAsFixed(0);
              _isWeighing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tare captured — press SIMPAN KELUAR to finalize')));
          } else {
            setState(() {
              _displayWeight = _lastCapturedWeight.toStringAsFixed(0);
              _isWeighing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tare captured — press SIMPAN KELUAR to finalize')));
          }
          return;
        }

        setState(() {
          _displayWeight = _lastCapturedWeight.toStringAsFixed(0);
          _isWeighing = false;
        });
      },
      onRetry: () async {
        setState(() => _isConnected = false);
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isConnected = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection retried')));
      },
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "PT. Dakara Prima Internasional",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AbsorbPointer(
          absorbing: true,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isWeighIn = true),
            icon: _isWeighIn ? const Icon(Icons.check, size: 20) : const SizedBox.shrink(),
            label: const Text("Timbang Masuk"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isWeighIn ? _primaryCyan : Colors.transparent,
              foregroundColor: _isWeighIn ? Colors.black : Colors.white,
              elevation: 0,
              side: _isWeighIn ? BorderSide.none : BorderSide(color: _textGrey.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AbsorbPointer(
          absorbing: true,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isWeighIn = false),
            icon: !_isWeighIn ? const Icon(Icons.check, size: 20) : const SizedBox.shrink(),
            label: const Text("Timbang Keluar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isWeighIn ? Colors.white : Colors.transparent,
              foregroundColor: !_isWeighIn ? Colors.black : Colors.white,
              elevation: 0,
              side: !_isWeighIn ? BorderSide.none : BorderSide(color: _textGrey.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF23262B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _textGrey.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _timeNotifier,
                builder: (ctx, val, _) => Text(
                  val,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now()),
                style: TextStyle(color: _textGrey),
              ),
              const SizedBox(height: 8),
              Divider(color: _textGrey.withValues(alpha: 0.12)),
              const SizedBox(height: 8),
              Text('Indicator : GST-9000', style: TextStyle(color: _textGrey)),
              Text('Connected to PORT1', style: TextStyle(color: _textGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          if (_currentTicketPreview != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _textGrey.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Text('Ticket: ', style: TextStyle(color: _textGrey, fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(_currentTicketPreview!, style: TextStyle(color: _primaryCyan, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isDraftEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryCyan,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('DRAFT', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: platnomorController,
                  label: "Plat Nomor",
                  hint: "B 1234 ABC",
                  focus: focusPlatnomor,
                  nextFocus: focusSupir,
                  textCapital: TextCapitalization.characters,
                  prefixIcon: Icons.local_shipping_outlined,
                  context: context,
                  enabled: !_isWeighing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextInput(
                  controller: namasupirController,
                  label: "Nama Supir",
                  focus: focusSupir,
                  nextFocus: focusPotongan,
                  prefixIcon: Icons.person_outline,
                  context: context,
                  enabled: !_isWeighing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Supplier",
                  value: _selectedSupplier,
                  items: _suppliers,
                  prefixIcon: Icons.store_mall_directory_outlined,
                  onChanged: (val) => setState(() => _selectedSupplier = val),
                  enabled: !_isWeighing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: "Customer",
                  value: _selectedCustomer,
                  items: _customers,
                  prefixIcon: Icons.business_outlined,
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  enabled: !_isWeighing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Barang",
                  value: _selectedProduct,
                  items: _products,
                  prefixIcon: Icons.category_outlined,
                  onChanged: (val) => setState(() => _selectedProduct = val),
                  enabled: !_isWeighing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextInput(
                  controller: poController,
                  label: "Nomor DO / PO",
                  focus: focusPO,
                  nextFocus: focusNoContainer,
                  prefixIcon: Icons.description_outlined,
                  context: context,
                  enabled: !_isWeighing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: potonganController,
                  label: "Potongan (%)",
                  hint: "0",
                  focus: focusPotongan,
                  nextFocus: focusKubikasi,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.percent,
                  context: context,
                  enabled: !_isWeighing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextInput(
                  controller: kubikasiController,
                  label: "Kubikasi (opt)",
                  hint: "0",
                  focus: focusKubikasi,
                  nextFocus: focusPO,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers,
                  context: context,
                  enabled: !_isWeighing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: nocontainerController,
                  label: "No Container (opt)",
                  hint: "max 20 chars",
                  focus: focusNoContainer,
                  nextFocus: focusSuhu,
                  maxLength: 20,
                  prefixIcon: Icons.inventory_2_outlined,
                  context: context,
                  enabled: !_isWeighing && !_isDraftEditing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextInput(
                  controller: suhuController,
                  label: "Suhu (opt)",
                  hint: "°C",
                  focus: focusSuhu,
                  nextFocus: focusHarga,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.thermostat_outlined,
                  context: context,
                  enabled: !_isWeighing && !_isDraftEditing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: hargaController,
                  label: "Harga / kg (opt)",
                  hint: "0",
                  focus: focusHarga,
                  nextFocus: focusKeterangan,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  context: context,
                  enabled: !_isWeighing && !_isDraftEditing,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),

            _buildTextInput(
            controller: keteranganController,
            label: "Keterangan (Manual) (opt)",
            hint: "Catatan...",
            focus: focusKeterangan,
            maxLength: 500,
            prefixIcon: Icons.note_outlined,
            context: context,
            enabled: !_isWeighing,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_isDraftEditing) {
                  if (_editingDraftTicket != null && _lastCapturedWeight > 0) {
                    _finalizeDraft(_editingDraftTicket!, _lastCapturedWeight);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture tare to finalize Netto')));
                  }
                  return;
                }

                // If in weigh-in mode, treat Save as creating a draft (Bruto)
                if (_isWeighIn) {
                  final ticket = _generateTicket();
                  final brutoVal = _lastCapturedWeight > 0 ? _lastCapturedWeight : double.tryParse(_displayWeight) ?? 0.0;
                  // Build transaction object using IDs for FK columns
                  final draft = ListTransactionJson(
                    vehiclePlate: platnomorController.text.isEmpty ? 'Unknown' : platnomorController.text,
                    driverName: namasupirController.text.isEmpty ? 'Unknown' : namasupirController.text,
                    supplierId: _selectedSupplier ?? 0,
                    customerId: _selectedCustomer ?? 0,
                    productId: _selectedProduct ?? 0,
                    cut: int.tryParse(potonganController.text) ?? 0,
                    kubikasi: int.tryParse(kubikasiController.text),
                    noDO: poController.text.isEmpty ? null : poController.text,
                    noContainer: nocontainerController.text.isEmpty ? null : int.tryParse(nocontainerController.text),
                    temperature: double.tryParse(suhuController.text),
                    price: double.tryParse(hargaController.text),
                    additionalInformation: keteranganController.text.isEmpty ? null : keteranganController.text,
                    noTicket: ticket,
                    inTime: DateTime.now(),
                    outTime: DateTime.fromMillisecondsSinceEpoch(0),
                    totalPrice: (double.tryParse(hargaController.text) ?? 0.0) * brutoVal,
                    bruto: brutoVal,
                    tare: 0.0,
                    netto: brutoVal,
                    nettoAfterCut: brutoVal - ((int.tryParse(potonganController.text) ?? 0) / 100 * brutoVal),
                    driverLabel: 1,
                    operatorLabel: 0,
                    managerLabel: 0,
                    headWarehouseLabel: 0,
                  );

                  try {
                    final insertedId = await DbHelper.instance.addTransaction(draft);
                    final persisted = ListTransactionJson(
                      vehiclePlate: draft.vehiclePlate,
                      driverName: draft.driverName,
                      supplierId: draft.supplierId,
                      customerId: draft.customerId,
                      productId: draft.productId,
                      cut: draft.cut,
                      kubikasi: draft.kubikasi,
                      noDO: draft.noDO,
                      noContainer: draft.noContainer,
                      temperature: draft.temperature,
                      price: draft.price,
                      additionalInformation: draft.additionalInformation,
                      noTicket: draft.noTicket,
                      inTime: draft.inTime,
                      outTime: draft.outTime,
                      totalPrice: draft.totalPrice,
                      bruto: draft.bruto,
                      tare: draft.tare,
                      netto: draft.netto,
                      nettoAfterCut: draft.nettoAfterCut,
                      driverLabel: draft.driverLabel,
                      transactionId: insertedId,
                      operatorLabel: draft.operatorLabel,
                      managerLabel: draft.managerLabel,
                      headWarehouseLabel: draft.headWarehouseLabel,
                    );

                    setState(() {
                      _transactions.insert(0, persisted);
                      _draftTickets.add(ticket);
                      _currentTicketPreview = ticket;
                      _ticketCounter++;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved (Bruto)')));
                    });
                  } on Exception catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed saving draft: $e')));
                  }
                  return;
                }

                // Save logic placeholder for normal save (e.g., SIMPAN KELUAR)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              child: Text(_isWeighIn ? "SIMPAN MASUK" : "SIMPAN KELUAR"),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWeightDetails() {
    final bruto = _computeBrutoDisplay();
    final tare = _computeTareDisplay();
    final netto = (bruto - tare) < 0 ? 0.0 : (bruto - tare);
    final afterCut = _computeAfterCut(netto);
    final totalPrice = _computeTotalPrice(afterCut);

    return Column(
      children: [
        _buildDetailCard("Bruto", '${bruto.toStringAsFixed(0)} kg'),
        const SizedBox(height: 16),
        _buildDetailCard("Tara", '${tare.toStringAsFixed(0)} kg'),
        const SizedBox(height: 16),
        _buildDetailCard("Netto", '${netto.toStringAsFixed(0)} kg'),
        const SizedBox(height: 12),
        _buildDetailCard("After cut", '${afterCut.toStringAsFixed(0)} kg'),
        const SizedBox(height: 12),
        _buildDetailCard("Total Price", 'Rp ${totalPrice.toStringAsFixed(0)}'),
      ],
    );
  }

  double _computeBrutoDisplay() {
    if (_isDraftEditing && _editingDraftTicket != null) {
      final d = _transactions.firstWhere((e) => e.noTicket == _editingDraftTicket, orElse: () => _transactions.isNotEmpty ? _transactions.first : ListTransactionJson(
            vehiclePlate: '',
            driverName: '',
            supplierId: 0,
            customerId: 0,
            productId: 0,
            cut: 0,
            noTicket: '',
            inTime: DateTime.now(),
            outTime: DateTime.fromMillisecondsSinceEpoch(0),
            totalPrice: 0.0,
            bruto: 0.0,
            tare: 0.0,
            netto: 0.0,
            nettoAfterCut: 0.0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
          ));
      return d.bruto;
    }
    // if last captured exists and currently in weigh-in, treat as bruto
    if (_lastCapturedWeight > 0 && _isWeighIn) return _lastCapturedWeight;
    return 0.0;
  }

  double _computeTareDisplay() {
    if (_isDraftEditing && _editingDraftTicket != null) {
      final d = _transactions.firstWhere(
        (e) => e.noTicket == _editingDraftTicket,
        orElse: () => _transactions.isNotEmpty
          ? _transactions.first
          : ListTransactionJson(
                      vehiclePlate: '',
                      driverName: '',
                      supplierId: 0,
                      customerId: 0,
                      productId: 0,
                      cut: 0,
                      noTicket: '',
                      inTime: DateTime.now(),
                      outTime: DateTime.fromMillisecondsSinceEpoch(0),
                      totalPrice: 0.0,
                      bruto: 0.0,
                      tare: 0.0,
                      netto: 0.0,
                      nettoAfterCut: 0.0,
                      driverLabel: 0,
                      operatorLabel: 0,
                      managerLabel: 0,
                      headWarehouseLabel: 0,
                    ),
      );
      return d.tare;
    }
    // if last captured exists and currently in weigh-out, treat as tare
    if (_lastCapturedWeight > 0 && !_isWeighIn) return _lastCapturedWeight;
    return 0.0;
  }

  double _computeAfterCut(double netto) {
    final cutPct = double.tryParse(potonganController.text) ?? 0.0;
    return netto - ((cutPct / 100.0) * netto);
  }

  double _computeTotalPrice(double afterCut) {
    final price = double.tryParse(hargaController.text) ?? 0.0;
    return price * afterCut;
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF23262B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textGrey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _textGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required BuildContext context,
    required String label,
    String? hint,
    FocusNode? focus,
    FocusNode? nextFocus,
    TextCapitalization textCapital = TextCapitalization.none,
    Widget? suffixIcon,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focus,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapital,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textGrey),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, color: _textGrey) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryCyan, width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
          onFieldSubmitted: (v) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
        ),
      ],
    );
  }

  


  Widget _buildDropdown({
    required String label,
    required List items,
    required Function(int?) onChanged,
    int? value,
    String? hint,
    IconData? prefixIcon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: value,
          onTap: () {},
          items: items.map((item) {
            int id = 0;
            String labelText = item.toString();
            if (item is ListSupplierJson) {
              id = item.supplierId;
              labelText = item.supplierName;
            } else if (item is ListCustomerJson) {
              id = item.customerId;
              labelText = item.customerName;
            } else if (item is ListProductJson) {
              id = item.productId;
              labelText = item.productName;
            } else if (item is String) {
              labelText = item;
            }
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                labelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          dropdownColor: _inputBg, // Ensure dropdown popup matches input bg
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ), // Selected text color
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textGrey),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, color: _textGrey) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryCyan, width: 1.5),
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, color: _textGrey),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _textGrey.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // Search and sort controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search ticket or plate',
                    hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: _inputBg,
                    prefixIcon: Icon(Icons.search, color: _textGrey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Sort by time',
                child: IconButton(
                  onPressed: () => setState(() => _sortDesc = !_sortDesc),
                  icon: Icon(_sortDesc ? Icons.arrow_downward : Icons.arrow_upward, color: _textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ListTransactionJson>>(
            future: DbHelper.instance.getListTransaction(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              }

              // If DB returned data, render it
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final rawItems = snapshot.data!;
                // Filter by search
                final query = _searchController.text.trim().toLowerCase();
                final items = rawItems.where((it) {
                  if (query.isEmpty) return true;
                  final ticket = (it.noTicket.toString().toLowerCase());
                  final plate = (it.vehiclePlate).toString().toLowerCase();
                  return ticket.contains(query) || plate.contains(query);
                }).toList();
                // Sort by inTime
                items.sort((a, b) {
                  DateTime? da = _parseDateMaybe(a.inTime);
                  DateTime? dbt = _parseDateMaybe(b.inTime);
                  if (da == null && dbt == null) return 0;
                  if (da == null) return _sortDesc ? 1 : -1;
                  if (dbt == null) return _sortDesc ? -1 : 1;
                  return _sortDesc ? dbt.compareTo(da) : da.compareTo(dbt);
                });

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(color: _textGrey.withValues(alpha: 0.12)),
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    final plate = it.vehiclePlate?.toString() ?? '-';
                    final brutoNum = (it.bruto ?? 0);
                    final nettoNum = (it.netto ?? 0);
                    final afterCutNum = (it.nettoAfterCut ?? it.netto ?? 0);
                    final bruto = brutoNum is num ? brutoNum.toDouble() : double.tryParse(brutoNum.toString()) ?? 0.0;
                    final netto = nettoNum is num ? nettoNum.toDouble() : double.tryParse(nettoNum.toString()) ?? 0.0;
                    final afterCut = afterCutNum is num ? afterCutNum.toDouble() : double.tryParse(afterCutNum.toString()) ?? 0.0;
                    final intimeRaw = it.inTime?.toString();
                    final outtimeRaw = it.outTime?.toString();
                    final intime = _formatShortDate(intimeRaw);
                    final outtime = (outtimeRaw != null && outtimeRaw.trim().isNotEmpty) ? _formatShortDate(outtimeRaw) : null;
                    final noTicket = it.noTicket?.toString() ?? '';
                    final driver = it.driverName?.toString() ?? '';
                    final productName = _productNameFromId(it.productId);
                    final supplierName = _supplierNameFromId(it.supplierId);
                    final customerName = _customerNameFromId(it.customerId);
                    final cut = it.cut?.toString();
                    final doNo = it.noDO?.toString();
                    final container = it.noContainer?.toString();
                    final temp = it.temperature?.toString();
                    final price = it.price != null ? it.price.toString() : null;
                    final notes = it.additionalInformation?.toString();

                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(vertical: 4),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Row(
                        children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(noTicket, style: TextStyle(color: _primaryCyan, fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 8),
                                      if (_draftTickets.contains(noTicket))
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: _primaryCyan, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('DRAFT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(plate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('$driver • ${productName.isNotEmpty ? productName : '-'}', style: TextStyle(color: _textGrey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(outtime != null ? '$intime → $outtime' : '$intime • In progress', style: TextStyle(color: _textGrey.withValues(alpha: 0.9), fontSize: 11)),
                                ],
                              ),
                            ),
                          // per-row actions
                          PopupMenuButton<String>(
                            color: _cardBg,
                            icon: Icon(Icons.more_vert, color: _textGrey),
                            onSelected: (v) async {
                              if (v == 'copy') {
                                _copyToClipboard(noTicket);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket copied')));
                              } else if (v == 'detail') {
                                _showDetailDialogMap(it.toJson());
                              } else if (v == 'print') {
                                _printTransactionMap(it.toJson());
                              } else if (v == 'continue') {
                                // convert map to model and attempt auto finalize
                                final inTimeParsed = _parseDateMaybe(it.inTime) ?? DateTime.now();
                                final outTimeParsed = _parseDateMaybe(it.outTime) ?? DateTime.fromMillisecondsSinceEpoch(0);
                                final temp = it.temperature != null ? double.tryParse(it.temperature.toString()) : null;
                                final priceVal = it.price != null ? double.tryParse(it.price.toString()) : null;
                                final kub = it.kubikasi != null ? int.tryParse(it.kubikasi.toString()) : null;
                                final noContainerVal = it.noContainer != null ? int.tryParse(it.noContainer.toString()) : null;
                                final brutoVal = bruto;
                                final nettoVal = netto;
                                final afterVal = afterCut;
                                final supplierIdVal = it.supplierId != null ? int.tryParse(it.supplierId.toString()) ?? 0 : 0;
                                final customerIdVal = it.customerId != null ? int.tryParse(it.customerId.toString()) ?? 0 : 0;
                                final productIdVal = it.productId != null ? int.tryParse(it.productId.toString()) ?? 0 : 0;
                                int mapBoolToInt(dynamic v) {
                                  if (v == null) return 0;
                                  if (v is int) return v;
                                  if (v is bool) return v ? 1 : 0;
                                  final s = v.toString().toLowerCase();
                                  if (s == '1' || s == 'true') return 1;
                                  return 0;
                                }
                                final model = ListTransactionJson(
                                  vehiclePlate: plate,
                                  driverName: driver,
                                  supplierId: supplierIdVal,
                                  customerId: customerIdVal,
                                  productId: productIdVal,
                                  cut: int.tryParse(it.cut?.toString() ?? '0') ?? 0,
                                  kubikasi: kub,
                                  noDO: doNo,
                                  noContainer: noContainerVal,
                                  temperature: temp,
                                  price: priceVal,
                                  additionalInformation: notes,
                                  noTicket: noTicket,
                                  inTime: inTimeParsed,
                                  outTime: outTimeParsed,
                                  totalPrice: double.tryParse(it.totalPrice?.toString() ?? '0') ?? 0.0,
                                  bruto: brutoVal,
                                  tare: double.tryParse(it.tare?.toString() ?? '0') ?? 0.0,
                                  netto: nettoVal,
                                  nettoAfterCut: afterVal,
                                  driverLabel: mapBoolToInt(it.driverLabel),
                                  transactionId: int.tryParse(it.transactionId?.toString() ?? '0') ?? 0,
                                  operatorLabel: mapBoolToInt(it.operatorLabel),
                                  managerLabel: mapBoolToInt(it.managerLabel),
                                  headWarehouseLabel: mapBoolToInt(it.headWarehouseLabel),
                                );
                                await _continueNettoAndMaybeAuto(model);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'copy', child: Text('Copy ticket', style: TextStyle(color: Colors.white))),
                              PopupMenuItem(value: 'detail', child: Text('Detail', style: TextStyle(color: Colors.white))),
                              PopupMenuItem(value: 'print', child: Text('Print', style: TextStyle(color: Colors.white))),
                              if (_draftTickets.contains(noTicket)) PopupMenuItem(value: 'continue', child: Text('Continue Netto', style: TextStyle(color: Colors.white))),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${bruto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Bruto', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${netto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Netto', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${afterCut.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('After cut', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            if (supplierName.isNotEmpty) Text('Supplier: $supplierName', style: TextStyle(color: _textGrey))
                            else if (it.supplierId != 0) Text('Supplier: ${it.supplierId}', style: TextStyle(color: _textGrey)),
                            if (customerName.isNotEmpty) Text('Customer: $customerName', style: TextStyle(color: _textGrey))
                            else if (it.customerId != 0) Text('Customer: ${it.customerId}', style: TextStyle(color: _textGrey)),
                            if (doNo != null) Text('No DO: $doNo', style: TextStyle(color: _textGrey)),
                            if (container != null) Text('No Container: $container', style: TextStyle(color: _textGrey)),
                            if (cut != null) Text('Potongan: $cut %', style: TextStyle(color: _textGrey)),
                            if (price != null) Text('Harga/kg: $price', style: TextStyle(color: _textGrey)),
                            if (temp != null) Text('Suhu: $temp', style: TextStyle(color: _textGrey)),
                            if (notes != null) Text('Keterangan: ${notes.length > 100 ? notes.substring(0, 100) + "..." : notes}', style: TextStyle(color: _textGrey)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                (() {
                                  final dl = it.driverLabel;
                                  final ol = it.operatorLabel;
                                  final ml = it.managerLabel;
                                  final hl = it.headWarehouseLabel  ;
                                  bool has(dynamic v) => v == 1 || v == true || v?.toString() == '1';
                                  final icons = <Widget>[];
                                  if (has(dl)) icons.add(Icon(Icons.person, color: _primaryCyan, size: 16));
                                  if (has(ol)) icons.addAll([const SizedBox(width: 6), Icon(Icons.admin_panel_settings, color: _primaryCyan, size: 16)]);
                                  if (has(ml)) icons.addAll([const SizedBox(width: 6), Icon(Icons.verified_user, color: _primaryCyan, size: 16)]);
                                  if (has(hl)) icons.addAll([const SizedBox(width: 6), Icon(Icons.home_work, color: _primaryCyan, size: 16)]);
                                  return Row(mainAxisSize: MainAxisSize.min, children: icons);
                                })(),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              }

              // Fallback to sample static data (apply same search + sort logic)
              final query = _searchController.text.trim().toLowerCase();
              final List<ListTransactionJson> filtered = _transactions.where((tx) {
                if (query.isEmpty) return true;
                final ticket = tx.noTicket.toLowerCase();
                final plate = tx.vehiclePlate.toLowerCase();
                return ticket.contains(query) || plate.contains(query);
              }).toList();
              filtered.sort((a, b) => _sortDesc ? b.inTime.compareTo(a.inTime) : a.inTime.compareTo(b.inTime));

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(child: Text('No matching transactions', style: TextStyle(color: _textGrey.withValues(alpha: 0.9)))),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(color: _textGrey.withValues(alpha: 0.12)),
                itemBuilder: (ctx, i) {
                  final tx = filtered[i];
                  final intime = DateFormat('dd MMM HH:mm').format(tx.inTime);
                  final outtime = tx.outTime.isAfter(tx.inTime) ? DateFormat('dd MMM HH:mm').format(tx.outTime) : null;
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(vertical: 4),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(tx.noTicket, style: TextStyle(color: _primaryCyan, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  if (_draftTickets.contains(tx.noTicket))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: _primaryCyan, borderRadius: BorderRadius.circular(12)),
                                      child: const Text('DRAFT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(tx.vehiclePlate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${tx.driverName} • ${_productNameFromId(tx.productId)}', style: TextStyle(color: _textGrey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(outtime != null ? '$intime → $outtime' : '$intime • In progress', style: TextStyle(color: _textGrey.withValues(alpha: 0.9), fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${tx.bruto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Bruto', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${tx.netto.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Netto', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${tx.nettoAfterCut.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('After cut', style: TextStyle(color: _textGrey.withValues(alpha: 0.7), fontSize: 10)),
                          ],
                        ),
                        PopupMenuButton<String>(
                          color: _cardBg,
                          icon: Icon(Icons.more_vert, color: _textGrey),
                          onSelected: (v) {
                            if (v == 'copy') {
                              _copyToClipboard(tx.noTicket);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket copied')));
                            } else if (v == 'detail') {
                              _showDetailDialogList(tx);
                            } else if (v == 'print') {
                              _printTransactionList(tx);
                            } else if (v == 'continue') {
                              _loadDraftIntoForm(tx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loaded draft for Continue Netto')));
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'copy', child: Text('Copy ticket', style: TextStyle(color: Colors.white))),
                            PopupMenuItem(value: 'detail', child: Text('Detail', style: TextStyle(color: Colors.white))),
                            PopupMenuItem(value: 'print', child: Text('Print', style: TextStyle(color: Colors.white))),
                            if (_draftTickets.contains(tx.noTicket)) PopupMenuItem(value: 'continue', child: Text('Continue Netto', style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Supplier: ${_supplierNameFromId(tx.supplierId)}', style: TextStyle(color: _textGrey)),
                          Text('Customer: ${_customerNameFromId(tx.customerId)}', style: TextStyle(color: _textGrey)),
                          if (tx.noDO != null) Text('No DO: ${tx.noDO}', style: TextStyle(color: _textGrey)),
                          if (tx.noContainer != null) Text('No Container: ${tx.noContainer}', style: TextStyle(color: _textGrey)),
                          Text('Potongan: ${tx.cut} %', style: TextStyle(color: _textGrey)),
                          if (tx.price != null) Text('Harga/kg: ${tx.price}', style: TextStyle(color: _textGrey)),
                          if (tx.temperature != null) Text('Suhu: ${tx.temperature}', style: TextStyle(color: _textGrey)),
                          if (tx.additionalInformation != null) Text('Keterangan: ${tx.additionalInformation}', style: TextStyle(color: _textGrey)),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
