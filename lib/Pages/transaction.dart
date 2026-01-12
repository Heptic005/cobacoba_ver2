import 'dart:async';
import 'package:dakara_weighbridge/Entities/Operator/operator.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/add_netto_transaction_form.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Pages/transaction_controller.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_monitor.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/add_bruto_transaction_form_card.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/recent_transactions.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/header.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_details.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/main_actions.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/transaction_detail_dialog.dart';

/// Transaction page — thin UI wrapper around TransactionController.
/// All business logic lives in the controller; this widget only renders layout and wires events.
/// TODO : Make Weight Detail and Recent Transaction
class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  // Styling constants
  static const Color _bgDark = Color(0xFF17181A);
  static const Color _cardBg = Color(0xFF23262B);
  static const Color _inputBg = Color(0xFF191A1C);
  static const Color _primaryCyan = Color(0xFF00E5C3);
  static const Color _textGrey = Colors.grey;
  static const Color _textWhite = Colors.white;
  static const Color _limeGreen = Color(0xFF97FF21);

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

  /// Data
  List<ListSupplierJson> _suppliers = [];
  List<ListProductJson> _products = [];
  List<ListCustomerJson> _customers = [];

  /// Weight From Serial
  double? _capturedWeight;

  void _onToggleButtonTimbang(bool mode) {
    setState(() {
      _isWeightIn = mode;
      _resetForm();
    });
  }

  /// Captured Weight If Any Data Come From Connected Serial
  void _onWeightCaptured(double weight) {
    setState(() {
      _capturedWeight = weight;
    });
  }

  /// Load Needed Data For Transaction Form
  Future<void> _loadSupplierProductCustomerData() async {
    _suppliers = await DbHelper.instance.getListSupplier();
    _products = await DbHelper.instance.getListProducts();
    _customers = await DbHelper.instance.getListCustomers();
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
      final bruto = double.tryParse(_capturedWeight!.toStringAsFixed(2));

      if (_isWeightIn) {
        operator.addBrutoTransaction(
          vehiclePlate: _platNomorController.text,
          driverName: _namaSupirController.text,
          supplierId: _selectedSupplierId!,
          customerId: _selectedCustomerId!,
          productId: _selectedProductId!,
          cut: cut!,
          bruto: bruto!,
          kubikasi: kubikasi,
          noDo: _noDoController.text,
          noContainer: noContainer,
          temperature: suhu,
          price: price,
          additionalInformation: _keteranganController.text,
        );
      } else {
        operator.addNettoTransaction(
          transactionId: int.tryParse(_transactionIdController.text)!,
          tare: _capturedWeight!,
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

      // Reset selections
      _selectedSupplierId = null;
      _selectedCustomerId = null;
      _selectedProductId = null;
    });
  }

  @override
  void initState() {
    super.initState();

    /// Get Current Time
    _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());
    });

    /// Load Data before Widget Building
    _loadSupplierProductCustomerData().then((_) {
      setState(() => _isLoaded = true);
    });
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
    _transactionIdController.dispose();

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
      backgroundColor: _bgDark,
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
                    isWeighIn: false,
                    cardBg: _cardBg,
                    primaryCyan: _primaryCyan,
                    textGrey: _textGrey,
                    textWhite: _textWhite,
                    onCaptured: _onWeightCaptured,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: MainActionsCard(
                    timeNotifier: _timeNotifier,
                    primaryCyan: _primaryCyan,
                    textGrey: _textGrey,
                    textWhite: _textWhite,
                    cardBg: _cardBg,
                    onToggleButtonTimbang: _onToggleButtonTimbang,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _isWeightIn
                    ? Expanded(
                      flex: 3,
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
                        cardBg: _cardBg,
                        primaryCyan: _primaryCyan,
                        textGrey: _textGrey,
                        inputBg: _inputBg,
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
                      ),
                    )
                    : Expanded(
                      flex: 3,
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
                        cardBg: _cardBg,
                        primaryCyan: _primaryCyan,
                        textGrey: _textGrey,
                        inputBg: _inputBg,
                        onSavePressed: _handleSavePressed,
                        isFormValid: isFormValid,
                      ),
                    ),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: SizedBox()),
              ],
            ),
            // Recent Transactions
          ],
        ),
      ),
    );
  }
}
