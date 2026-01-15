import 'dart:async';
import 'package:dakara_weighbridge/Entities/Operator/operator.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/dashboard.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/add_netto_transaction_form.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/weight_monitor.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/add_bruto_transaction_form_card.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/recent_transaction_table.dart';
import 'package:dakara_weighbridge/features/transaction/services/clipboard_service.dart';
import 'package:dakara_weighbridge/features/transaction/services/print_service.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/header.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/main_actions.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/transaction_detail_dialog.dart';

/// Transaction page — thin UI wrapper around TransactionController.
/// All business logic lives in the controller; this widget only renders layout and wires events.
/// TODO : Make Weight Detail and Recent Transaction
class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  /// Main Actions Items
  final ValueNotifier<String> _timeNotifier = ValueNotifier('');
  late Timer _timer;
  bool _isWeightIn = true;

  /// Load Data
  bool _isLoaded = false;

  /// Form Card Items
  /// Text Controller
  final _platNomorController = TextEditingController();
  final _namaSupirController = TextEditingController();
  final _noDoController = TextEditingController();
  final _kubikasiController = TextEditingController();
  final _potonganController = TextEditingController();
  final _noContainerController = TextEditingController();
  final _suhuController = TextEditingController();
  final _hargaController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _supplierController = TextEditingController();
  final _customerController = TextEditingController();
  final _productController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _brutoController = TextEditingController();
  final _tareController = TextEditingController();
  final _nettoController = TextEditingController();

  /// Focus Node
  final _focusPlatNomor = FocusNode();
  final _focusNoDo = FocusNode();
  final _focusSupir = FocusNode();
  final _focusPotongan = FocusNode();
  final _focusKubikasi = FocusNode();
  final _focusNoContainer = FocusNode();
  final _focusSuhu = FocusNode();
  final _focusHarga = FocusNode();
  final _focusKeterangan = FocusNode();

  /// U-I Needs
  int? _selectedSupplierId;
  int? _selectedProductId;
  int? _selectedCustomerId;

  /// Recent transactions
  final TextEditingController _recentSearchController = TextEditingController();
  bool _recentSortDesc = true;
  Set<String> _draftTickets = {};
  List<ListTransactionJson> _recentTransactions = [];

  /// Services
  final PrintService _printService = PrintServiceStub();
  final ClipboardService _clipboardService = ClipboardServiceImpl();

  /// Data
  List<ListSupplierJson> _suppliers = [];
  List<ListProductJson> _products = [];
  List<ListCustomerJson> _customers = [];

  /// Weight From Serial and Status For First Weighing
  double? _capturedWeight;
  bool _isBruto = true;

  /// Connection Status From Serial
  bool _isConnected = false;

  /// Weight In or Weight Out
  void _onToggleButtonTimbang(bool mode) {
    setState(() {
      _isWeightIn = mode;
      _resetForm();
    });
  }

  /// Connection Status From Serial
  void _onToggleButtonConnection(bool isConnected) {
    OperatorDashboard.isConnected.value = isConnected;
    setState(() {
      _isConnected = isConnected;
    });
  }

  /// Captured Weight If Any Data Come From Connected Serial
  void _onWeightCaptured(double weight, bool isBruto) {
    setState(() {
      _capturedWeight = weight;
      _isBruto = isBruto;
    });
  }

  /// Load Needed Data For Transaction Form
  Future<void> _loadSupplierProductCustomerData() async {
    _suppliers = await DbHelper.instance.getListSupplier();
    _products = await DbHelper.instance.getListProducts();
    _customers = await DbHelper.instance.getListCustomers();
  }

  Future<void> _loadRecentTransactions() async {
    final items = await DbHelper.instance.getListTransaction();
    setState(() {
      _recentTransactions = items.where((e) => e.isDrafted == 0).toList();
      _draftTickets =
          items.where((e) => e.isDrafted == 1).map((e) => e.noTicket).toSet();
    });
  }

  /// Save Transaction
  Future<void> _handleSavePressed() async {
    final operator = Operator();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final price =
          _hargaController.text.isNotEmpty
              ? double.tryParse(_hargaController.text)
              : 0.0;
      final suhu =
          _suhuController.text.isNotEmpty
              ? double.tryParse(_suhuController.text)
              : 0.0;
      final cut =
          _potonganController.text.isNotEmpty
              ? int.tryParse(_potonganController.text)
              : 0;
      final kubikasi =
          _kubikasiController.text.isNotEmpty
              ? int.tryParse(_kubikasiController.text)
              : 0;
      final noContainer =
          _noContainerController.text.isNotEmpty
              ? int.tryParse(_noContainerController.text)
              : 0;
      final _weight = double.tryParse(_capturedWeight!.toStringAsFixed(2));

      if (_isWeightIn) {
        operator.addBrutoTransaction(
          vehiclePlate: _platNomorController.text,
          driverName: _namaSupirController.text,
          supplierId: _selectedSupplierId!,
          customerId: _selectedCustomerId!,
          productId: _selectedProductId!,
          cut: cut!,
          bruto: _weight!,
          kubikasi: kubikasi,
          noDo: _noDoController.text,
          noContainer: noContainer,
          temperature: suhu,
          price: price,
          additionalInformation: _keteranganController.text,
          isBruto: _isBruto,
        );
      } else {
        operator.addNettoTransaction(
          transactionId: int.tryParse(_transactionIdController.text)!,
          kubikasi: kubikasi,
          additionalInformation: _keteranganController.text,
          weight: _weight!,
        );
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction finalized!')),
      );
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Finalize failed: $e')));
    }
    return;
  }

  /// Reset All Form
  void _resetForm() {
    setState(() {
      /// clear Weight
      _capturedWeight = null;

      // Clear all form fields
      _platNomorController.clear();
      _noDoController.clear();
      _namaSupirController.clear();
      _potonganController.clear();
      _kubikasiController.clear();
      _noContainerController.clear();
      _suhuController.clear();
      _hargaController.clear();
      _keteranganController.clear();
      _supplierController.clear();
      _customerController.clear();
      _productController.clear();
      _brutoController.clear();
      _tareController.clear();
      _nettoController.clear();

      // Reset selections
      _selectedSupplierId = null;
      _selectedCustomerId = null;
      _selectedProductId = null;
    });
  }

  Future<void> _handleShowDetailMap(Map<String, Object?> item) async {
    if (!mounted) return;
    final Map<String, Object?> safe = Map<String, Object?>.from(item);
    await showDialog(
      context: context,
      builder: (ctx) {
        String fmtDate(String? raw) {
          if (raw == null || raw.isEmpty) return '-';
          final dt = DateTime.tryParse(raw);
          if (dt == null) return raw;
          return DateFormat('dd MMM yyyy HH:mm').format(dt);
        }

        Widget info(String label, String value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppThemes.textGrey.withAlpha((0.8 * 255).round()),
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? '-' : value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final ticket = (safe['noTicket'] ?? '').toString();
        final plate = (safe['vehiclePlate'] ?? '-').toString();
        final driver = (safe['driverName'] ?? '-').toString();
        final productName =
            (safe['productName'] ?? safe['ProductName'] ?? '').toString();
        final supplierName =
            (safe['supplierName'] ?? safe['SupplierName'] ?? '').toString();
        final customerName =
            (safe['customerName'] ?? safe['CustomerName'] ?? '').toString();
        final inTime = safe['inTime']?.toString();
        final outTime = safe['outTime']?.toString();
        final bruto = (safe['bruto'] ?? '').toString();
        final tare = (safe['tare'] ?? '').toString();
        final netto = (safe['netto'] ?? '').toString();
        final afterCut =
            (safe['nettoAfterCut'] ?? safe['netto'] ?? '').toString();
        final notes = (safe['additionalInformation'] ?? '').toString();

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppThemes.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppThemes.textGrey.withAlpha((0.12 * 255).round()),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticket.isNotEmpty ? 'Detail $ticket' : 'Detail',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.close, color: AppThemes.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: AppThemes.textGrey.withAlpha((0.12 * 255).round()),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      runSpacing: 8,
                      spacing: 32,
                      children: [
                        info('Plate', plate),
                        info('Driver', driver),
                        info('Product', productName),
                        info('Supplier', supplierName),
                        info('Customer', customerName),
                        info('In Time', fmtDate(inTime)),
                        info('Out Time', fmtDate(outTime)),
                        info('Bruto (kg)', bruto),
                        info('Tare (kg)', tare),
                        info('Netto (kg)', netto),
                        info('After Cut (kg)', afterCut),
                        if (notes.isNotEmpty) info('Notes', notes),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: AppThemes.textGrey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePrintMap(Map<String, Object?> item) async {
    final messenger = ScaffoldMessenger.of(context);
    await _printService.print(
      'Print ticket: ${item['noTicket'] ?? ''}\n${item.toString()}',
    );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Print diproses (stub)')),
    );
  }

  Future<void> _handleExportPdfMap(Map<String, Object?> item) async {
    // Show interactive PDF preview to the user (builds PDF from the provided map only)
    try {
      await showPdfPreview(context, item);
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Preview gagal: $e')));
    }
    final messenger = ScaffoldMessenger.of(context);
    await _printService.print(
      'Export PDF ticket: ${item['noTicket'] ?? ''}\n${item.toString()}',
    );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Export PDF diproses (stub)')),
    );
  }

  Future<void> _handleContinueAuto(ListTransactionJson tx) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Lanjutkan transaksi ${tx.noTicket}')),
    );
  }

  void _handleLoadDraft(ListTransactionJson tx) {
    setState(() {
      _isWeightIn = false;
      _platNomorController.text = tx.vehiclePlate;
      _noDoController.text = tx.noDO ?? '';
      _namaSupirController.text = tx.driverName;
      _potonganController.text = tx.cut.toString();
      _kubikasiController.text = (tx.kubikasi ?? 0).toString();
      _noContainerController.text = (tx.noContainer ?? 0).toString();
      _suhuController.text = (tx.temperature ?? 0).toString();
      _hargaController.text = (tx.price ?? 0).toString();
      _keteranganController.text = tx.additionalInformation ?? '';
      _selectedSupplierId = tx.supplierId;
      _selectedCustomerId = tx.customerId;
      _selectedProductId = tx.productId;
      _transactionIdController.text = tx.transactionId.toString();
    });
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Draft ${tx.noTicket} dimuat')),
    );
  }

  Future<void> _handleCopy(String text) async {
    await _clipboardService.copy(text);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Ticket disalin')));
  }

  @override
  void initState() {
    super.initState();

    /// Connection Status
    _isConnected = SerialService().isConnected;

    /// Captured Weight
    _capturedWeight = null;

    /// Get Current Time
    _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    });

    _recentSearchController.addListener(() => setState(() {}));

    /// Load Data before Widget Building
    _loadSupplierProductCustomerData().then((_) {
      setState(() => _isLoaded = true);
    });
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    /// Dispose All Controller
    _platNomorController.dispose();
    _namaSupirController.dispose();
    _noDoController.dispose();
    _kubikasiController.dispose();
    _potonganController.dispose();
    _noContainerController.dispose();
    _suhuController.dispose();
    _hargaController.dispose();
    _keteranganController.dispose();
    _supplierController.dispose();
    _customerController.dispose();
    _productController.dispose();
    _recentSearchController.dispose();
    _transactionIdController.dispose();
    _brutoController.dispose();
    _tareController.dispose();
    _nettoController.dispose();

    // /// Serial Close Connection
    // SerialService().disconnect();

    _timer.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid =
        _isWeightIn
            ? (_selectedSupplierId != null) &&
                (_selectedCustomerId != null) &&
                (_selectedProductId != null) &&
                _platNomorController.text.trim().isNotEmpty &&
                _namaSupirController.text.trim().isNotEmpty &&
                _capturedWeight != null
            : _platNomorController.text.trim().isNotEmpty &&
                _namaSupirController.text.trim().isNotEmpty &&
                _capturedWeight != null;

    return Scaffold(
      backgroundColor: AppThemes.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            const TransactionHeader(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: WeightMonitorCard(
                    isWeighIn: _isWeightIn,
                    cardBg: AppThemes.cardBg,
                    primaryCyan: AppThemes.primaryCyan,
                    textGrey: AppThemes.textGrey,
                    textWhite: AppThemes.textWhite,
                    onCaptured: _onWeightCaptured,
                    isBruto: _isBruto,
                    isConnected: _isConnected,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: MainActionsCard(
                    timeNotifier: _timeNotifier,
                    primaryCyan: AppThemes.primaryCyan,
                    textGrey: AppThemes.textGrey,
                    textWhite: AppThemes.textWhite,
                    cardBg: AppThemes.cardBg,
                    onToggleButtonTimbang: _onToggleButtonTimbang,
                    onToggleButtonConection: _onToggleButtonConnection,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _isWeightIn && _isConnected
                    ? Expanded(
                      child: TransactionFormCard(
                        platnomorController: _platNomorController,
                        poController: _noDoController,
                        namasupirController: _namaSupirController,
                        potonganController: _potonganController,
                        kubikasiController: _kubikasiController,
                        nocontainerController: _noContainerController,
                        suhuController: _suhuController,
                        hargaController: _hargaController,
                        keteranganController: _keteranganController,
                        focusPlatnomor: _focusPlatNomor,
                        focusPO: _focusNoDo,
                        focusSupir: _focusSupir,
                        focusPotongan: _focusPotongan,
                        focusKubikasi: _focusKubikasi,
                        focusNoContainer: _focusNoContainer,
                        focusSuhu: _focusSuhu,
                        focusHarga: _focusHarga,
                        focusKeterangan: _focusKeterangan,
                        suppliers: _suppliers,
                        customers: _customers,
                        products: _products,
                        selectedSupplier: _selectedSupplierId,
                        selectedCustomer: _selectedCustomerId,
                        selectedProduct: _selectedProductId,
                        cardBg: AppThemes.cardBg,
                        primaryCyan: AppThemes.primaryCyan,
                        textGrey: AppThemes.textGrey,
                        inputBg: AppThemes.inputBg,
                        onSelectSupplier:
                            (value) => setState(() {
                              _selectedSupplierId = value;
                            }),
                        onSelectCustomer:
                            (value) => setState(() {
                              _selectedCustomerId = value;
                            }),
                        onSelectProduct:
                            (value) => setState(() {
                              _selectedProductId = value;
                            }),
                        onSavePressed: _handleSavePressed,
                        isFormValid: isFormValid,
                        bruto: _capturedWeight,
                        isBruto: _isBruto,
                      ),
                    )
                    : _isWeightIn && !_isConnected
                    ? Expanded(
                      child: Stack(
                        children: [
                          TransactionFormCard(
                            platnomorController: _platNomorController,
                            poController: _noDoController,
                            namasupirController: _namaSupirController,
                            potonganController: _potonganController,
                            kubikasiController: _kubikasiController,
                            nocontainerController: _noContainerController,
                            suhuController: _suhuController,
                            hargaController: _hargaController,
                            keteranganController: _keteranganController,
                            focusPlatnomor: _focusPlatNomor,
                            focusPO: _focusNoDo,
                            focusSupir: _focusSupir,
                            focusPotongan: _focusPotongan,
                            focusKubikasi: _focusKubikasi,
                            focusNoContainer: _focusNoContainer,
                            focusSuhu: _focusSuhu,
                            focusHarga: _focusHarga,
                            focusKeterangan: _focusKeterangan,
                            suppliers: _suppliers,
                            customers: _customers,
                            products: _products,
                            selectedSupplier: _selectedSupplierId,
                            selectedCustomer: _selectedCustomerId,
                            selectedProduct: _selectedProductId,
                            cardBg: AppThemes.cardBg,
                            primaryCyan: AppThemes.primaryCyan,
                            textGrey: AppThemes.textGrey,
                            inputBg: AppThemes.inputBg,
                            onSelectSupplier:
                                (value) => setState(() {
                                  _selectedSupplierId = value;
                                }),
                            onSelectCustomer:
                                (value) => setState(() {
                                  _selectedCustomerId = value;
                                }),
                            onSelectProduct:
                                (value) => setState(() {
                                  _selectedProductId = value;
                                }),
                            onSavePressed: _handleSavePressed,
                            isFormValid: isFormValid,
                            bruto: _capturedWeight,
                            isBruto: _isBruto,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadiusGeometry.all(
                                  Radius.circular(4),
                                ),
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: Text(
                                  'Menunggu koneksi timbangan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : !_isWeightIn && _isConnected
                    ? Expanded(
                      child: AddNettoTransactionFormCard(
                        platnomorController: _platNomorController,
                        poController: _noDoController,
                        namasupirController: _namaSupirController,
                        potonganController: _potonganController,
                        kubikasiController: _kubikasiController,
                        nocontainerController: _noContainerController,
                        suhuController: _suhuController,
                        hargaController: _hargaController,
                        keteranganController: _keteranganController,
                        supplierController: _supplierController,
                        customerController: _customerController,
                        productController: _productController,
                        transactionIdController: _transactionIdController,
                        focusPO: _focusNoDo,
                        focusPotongan: _focusPotongan,
                        focusKubikasi: _focusKubikasi,
                        focusNoContainer: _focusNoContainer,
                        focusSuhu: _focusSuhu,
                        focusHarga: _focusHarga,
                        focusKeterangan: _focusKeterangan,
                        cardBg: AppThemes.cardBg,
                        primaryCyan: AppThemes.primaryCyan,
                        textGrey: AppThemes.textGrey,
                        inputBg: AppThemes.inputBg,
                        onSavePressed: _handleSavePressed,
                        isFormValid: isFormValid,
                        brutoController: _brutoController,
                        tareController: _tareController,
                        nettoController: _nettoController,
                        tare: _capturedWeight,
                      ),
                    )
                    : Expanded(
                      child: Stack(
                        children: [
                          AddNettoTransactionFormCard(
                            platnomorController: _platNomorController,
                            poController: _noDoController,
                            namasupirController: _namaSupirController,
                            potonganController: _potonganController,
                            kubikasiController: _kubikasiController,
                            nocontainerController: _noContainerController,
                            suhuController: _suhuController,
                            hargaController: _hargaController,
                            keteranganController: _keteranganController,
                            supplierController: _supplierController,
                            customerController: _customerController,
                            productController: _productController,
                            transactionIdController: _transactionIdController,
                            focusPO: _focusNoDo,
                            focusPotongan: _focusPotongan,
                            focusKubikasi: _focusKubikasi,
                            focusNoContainer: _focusNoContainer,
                            focusSuhu: _focusSuhu,
                            focusHarga: _focusHarga,
                            focusKeterangan: _focusKeterangan,
                            cardBg: AppThemes.cardBg,
                            primaryCyan: AppThemes.primaryCyan,
                            textGrey: AppThemes.textGrey,
                            inputBg: AppThemes.inputBg,
                            onSavePressed: _handleSavePressed,
                            isFormValid: isFormValid,
                            brutoController: _brutoController,
                            tareController: _tareController,
                            nettoController: _nettoController,
                            tare: _capturedWeight,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadiusGeometry.all(
                                  Radius.circular(4),
                                ),
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: Text(
                                  'Menunggu koneksi timbangan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(width: 20),
              ],
            ),
            // Recent Transactions
            const SizedBox(height: 20),
            RecentTransactionTable(
              searchController: _recentSearchController,
              sortDesc: _recentSortDesc,
              draftTickets: _draftTickets,
              transactions: _recentTransactions,
              suppliers: _suppliers,
              customers: _customers,
              products: _products,
              cardBg: AppThemes.cardBg,
              textGrey: AppThemes.textGrey,
              primaryCyan: AppThemes.primaryCyan,
              inputBg: AppThemes.inputBg,
              onShowDetailMap: _handleShowDetailMap,
              onPrintMap: _handlePrintMap,
              onExportPdfMap: _handleExportPdfMap,
              onContinueAuto: _handleContinueAuto,
              onLoadDraft: _handleLoadDraft,
              onCopyToClipboard: _handleCopy,
            ),
          ],
        ),
      ),
    );
  }
}
