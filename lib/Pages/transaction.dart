import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Pages/transaction_controller.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_monitor.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/form_card.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/recent_transactions.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/header.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_details.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/main_actions.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/transaction_detail_dialog.dart';

/// Transaction page — thin UI wrapper around TransactionController.
/// All business logic lives in the controller; this widget only renders layout and wires events.
class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  late Timer _timer;
  final ValueNotifier<String> _timeNotifier = ValueNotifier('');
  late final TransactionController _controller;

  // UI-only state
  bool _isWeighIn = true;
  int? _selectedSupplier;
  int? _selectedCustomer;
  int? _selectedProduct;
  final TextEditingController _searchController = TextEditingController();

  // Styling constants
  static const Color _bgDark = Color(0xFF17181A);
  static const Color _cardBg = Color(0xFF23262B);
  static const Color _inputBg = Color(0xFF191A1C);
  static const Color _primaryCyan = Color(0xFF00E5C3);
  static const Color _textGrey = Colors.grey;
  static const Color _textWhite = Colors.white;
  static const Color _limeGreen = Color(0xFF97FF21);

  // Form controllers
  final platnomorController = TextEditingController();
  final poController = TextEditingController();
  final namasupirController = TextEditingController();
  final potonganController = TextEditingController();
  final kubikasiController = TextEditingController();
  final nocontainerController = TextEditingController();
  final suhuController = TextEditingController();
  final hargaController = TextEditingController();
  final keteranganController = TextEditingController();

  // Focus nodes
  final focusPlatnomor = FocusNode();
  final focusPO = FocusNode();
  final focusSupir = FocusNode();
  final focusPotongan = FocusNode();
  final focusKubikasi = FocusNode();
  final focusNoContainer = FocusNode();
  final focusSuhu = FocusNode();
  final focusHarga = FocusNode();
  final focusKeterangan = FocusNode();

  // Cached data from controller
  List<ListSupplierJson> _suppliers = [];
  List<ListCustomerJson> _customers = [];
  List<ListProductJson> _products = [];
  List<ListTransactionJson> _transactions = [];
  Set<String> _draftTickets = {};
  bool _isWeighing = false;
  bool _isConnected = true;
  bool _isDraftEditing = false;
  String? _currentTicketPreview;
  double _lastCapturedWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TransactionController();
    _controller.addListener(_syncFromController);
    _controller.init();
    _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _timeNotifier.dispose();
    _controller.removeListener(_syncFromController);
    _controller.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    platnomorController.dispose();
    poController.dispose();
    namasupirController.dispose();
    potonganController.dispose();
    kubikasiController.dispose();
    nocontainerController.dispose();
    suhuController.dispose();
    hargaController.dispose();
    keteranganController.dispose();
    focusPlatnomor.dispose();
    focusPO.dispose();
    focusSupir.dispose();
    focusPotongan.dispose();
    focusKubikasi.dispose();
    focusNoContainer.dispose();
    focusSuhu.dispose();
    focusHarga.dispose();
    focusKeterangan.dispose();
    _searchController.dispose();
  }

  void _syncFromController() {
    if (!mounted) return;
    setState(() {
      _suppliers = List.from(_controller.suppliers);
      _customers = List.from(_controller.customers);
      _products = List.from(_controller.products);
      _transactions = List.from(_controller.transactions);
      _isWeighing = _controller.isWeighing;
      _isConnected = _controller.isConnected;
      _draftTickets = Set.from(_controller.draftTickets);
      _isDraftEditing = _controller.isDraftEditing;
      _currentTicketPreview = _controller.currentTicketPreview;
      _lastCapturedWeight = _controller.lastCapturedWeight;
    });
  }

  // --- Event handlers ---

  Future<void> _handleSavePressed() async {
    final messenger = ScaffoldMessenger.of(context);
    
    // Detect if this is finalize (weight out on existing draft) or new draft
    if (_isDraftEditing && !_isWeighIn) {
      // This is weight out finalize - use captured tare
      if (_controller.capturedTare == null || _controller.capturedTare == 0) {
        messenger.showSnackBar(const SnackBar(content: Text('Please capture weight out first')));
        return;
      }
      
      try {
        final price = hargaController.text.isNotEmpty ? double.tryParse(hargaController.text) : null;
        await _controller.finalizeDraft(
          _controller.editingDraftTicket!,
          _controller.capturedTare!,
          priceFromForm: price,
        );
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Transaction finalized!')));
        _resetForm();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Finalize failed: $e')));
      }
      return;
    }
    
    // This is new draft (weight in)
    final ticket = _controller.generateTicket();
    final bruto = _lastCapturedWeight;

    final tx = ListTransactionJson(
      vehiclePlate: platnomorController.text.trim(),
      driverName: namasupirController.text.trim(),
      supplierId: _selectedSupplier ?? 0,
      customerId: _selectedCustomer ?? 0,
      productId: _selectedProduct ?? 0,
      cut: int.tryParse(potonganController.text) ?? 0,
      kubikasi: kubikasiController.text.isNotEmpty ? int.tryParse(kubikasiController.text) : null,
      noDO: poController.text.isNotEmpty ? poController.text : null,
      noContainer: nocontainerController.text.isNotEmpty ? int.tryParse(nocontainerController.text) : null,
      temperature: suhuController.text.isNotEmpty ? double.tryParse(suhuController.text) : null,
      price: hargaController.text.isNotEmpty ? double.tryParse(hargaController.text) : null,
      additionalInformation: keteranganController.text.isNotEmpty ? keteranganController.text : null,
      noTicket: ticket,
      inTime: DateTime.now(),
      outTime: DateTime.now(),
      totalPrice: 0.0,
      bruto: bruto,
      tare: 0.0,
      netto: 0.0,
      nettoAfterCut: 0.0,
      driverLabel: 0,
      operatorLabel: 0,
      managerLabel: 0,
      headWarehouseLabel: 0,
    );

    try {
      await _controller.saveDraftFromForm(tx);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Draft saved - ready for weight out')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _handleContinueNetto(ListTransactionJson tx) async {
    final messenger = ScaffoldMessenger.of(context);
    // Load draft into form and switch to Weight Out mode for manual capture
    _loadDraftIntoForm(tx);
    setState(() {
      _isWeighIn = false; // Switch to Weight Out mode
    });
    messenger.showSnackBar(const SnackBar(content: Text('Draft loaded - capture weight out, then SIMPAN')));
  }

  void _resetForm() {
    setState(() {
      // Clear all form fields
      platnomorController.clear();
      poController.clear();
      namasupirController.clear();
      potonganController.clear();
      kubikasiController.clear();
      nocontainerController.clear();
      suhuController.clear();
      hargaController.clear();
      keteranganController.clear();
      
      // Reset selections
      _selectedSupplier = null;
      _selectedCustomer = null;
      _selectedProduct = null;
      
      // Reset to Weigh-In mode
      _isWeighIn = true;
    });
    
    // Reset controller captured weights via controller method
    _controller.resetCapture();
  }

  void _loadDraftIntoForm(ListTransactionJson tx) {
    setState(() {
      platnomorController.text = tx.vehiclePlate;
      namasupirController.text = tx.driverName;
      poController.text = tx.noDO ?? '';
      potonganController.text = tx.cut.toString();
      kubikasiController.text = tx.kubikasi?.toString() ?? '';
      nocontainerController.text = tx.noContainer?.toString() ?? '';
      suhuController.text = tx.temperature?.toString() ?? '';
      hargaController.text = tx.price?.toString() ?? '';
      keteranganController.text = tx.additionalInformation ?? '';
      _selectedSupplier = tx.supplierId;
      _selectedCustomer = tx.customerId;
      _selectedProduct = tx.productId;
    });
    _controller.setDraftEditing(true, tx.noTicket);
  }

  void _copyToClipboard(String text) {
    _controller.copyToClipboard(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _showDetailDialogMap(Map<String, Object?> item) async {
    if (_products.isEmpty || _suppliers.isEmpty || _customers.isEmpty) {
      await _controller.loadData();
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => TransactionDetailDialog(
        itemMap: item,
        controller: _controller,
        cardBg: _cardBg,
        textGrey: _textGrey,
        primaryCyan: _primaryCyan,
        onPrint: () => _printTransactionMap(item),
      ),
    );
  }

  void _printTransactionMap(Map<String, Object?> item) {
    final navigator = Navigator.of(context);
    // TODO: integrate real printing package
    final text = _controller.buildPrintText(item);
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Print Preview'),
        content: Text(text),
        actions: [TextButton(onPressed: () => navigator.pop(), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _handleCapture() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_isConnected) {
      messenger.showSnackBar(const SnackBar(content: Text('Indicator not connected')));
      return;
    }
    try {
      if (_isWeighIn) {
        // Weigh-In: capture bruto (weight-in)
        await _controller.captureBrutoSimulated();
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Bruto captured — press SIMPAN to save draft')));
      } else {
        // Weigh-Out: capture tare (weight-out)
        await _controller.captureTareSimulated();
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Tare captured — press SIMPAN to finalize')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<void> _handleRetry() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isConnected = false);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isConnected = true);
    messenger.showSnackBar(const SnackBar(content: Text('Connection retried')));
  }

  // --- Build methods ---

  @override
  Widget build(BuildContext context) {
    // Delegate all computations to controller
    final bruto = _controller.computeBrutoDisplay();
    final tare = _controller.computeTareDisplay();
    final netto = _controller.computeNetto(bruto, tare);
    final cut = double.tryParse(potonganController.text) ?? 0.0;
    final afterCut = _controller.computeAfterCut(netto, cut);
    final price = double.tryParse(hargaController.text) ?? 0.0;
    final totalPrice = _controller.computeTotalPrice(afterCut, price);
    
    // Dynamic weight display based on current mode
    final displayWeight = _isWeighIn 
        ? (_controller.capturedBruto?.toStringAsFixed(0) ?? '0')
        : (_controller.lastCapturedWeight.toStringAsFixed(0));

    return Scaffold(
      backgroundColor: _bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const TransactionHeader(),
            const SizedBox(height: 20),
            // Top section: Weight Monitor + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: WeightMonitorCard(
                    displayWeight: displayWeight,
                    isWeighing: _isWeighing,
                    isWeighIn: _isWeighIn,
                    isConnected: _isConnected,
                    cardBg: _cardBg,
                    primaryCyan: _primaryCyan,
                    textGrey: _textGrey,
                    textWhite: _textWhite,
                    indicatorGreen: _limeGreen,
                    onToggleMode: () => setState(() => _isWeighIn = !_isWeighIn),
                    onCapture: _handleCapture,
                    onRetry: _handleRetry,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: MainActionsCard(
                    isWeighIn: _isWeighIn,
                    timeNotifier: _timeNotifier,
                    primaryCyan: _primaryCyan,
                    textGrey: _textGrey,
                    textWhite: _textWhite,
                    cardBg: _cardBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bottom section: Form + Details
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
                    onSavePressed: _handleSavePressed,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: WeightDetails(
                    bruto: '${bruto.toStringAsFixed(0)} kg',
                    tare: '${tare.toStringAsFixed(0)} kg',
                    netto: '${netto.toStringAsFixed(0)} kg',
                    afterCut: '${afterCut.toStringAsFixed(0)} kg',
                    totalPrice: 'Rp ${totalPrice.toStringAsFixed(0)}',
                    textGrey: _textGrey,
                    cardBg: _cardBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Recent Transactions
            RecentTransactions(
              searchController: _searchController,
              sortDesc: true,
              draftTickets: _draftTickets,
              transactions: _transactions,
              suppliers: _suppliers,
              customers: _customers,
              products: _products,
              cardBg: _cardBg,
              textGrey: _textGrey,
              primaryCyan: _primaryCyan,
              inputBg: _inputBg,
              onShowDetailMap: _showDetailDialogMap,
              onPrintMap: (m) async => _printTransactionMap(m),
              onContinueAuto: _handleContinueNetto,
              onLoadDraft: _loadDraftIntoForm,
              onCopyToClipboard: _copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }
}
