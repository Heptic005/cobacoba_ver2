/// TODO : Create Another Form for add Netto Transaction

import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/bruto_transaction_search_bar.dart';
import 'package:dakara_weighbridge/Pages/transaction_components/weight_details.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';

class AddNettoTransactionFormCard extends StatefulWidget {
  final TextEditingController platnomorController;
  final TextEditingController poController;
  final TextEditingController namasupirController;
  final TextEditingController potonganController;
  final TextEditingController kubikasiController;
  final TextEditingController nocontainerController;
  final TextEditingController suhuController;
  final TextEditingController hargaController;
  final TextEditingController keteranganController;
  final TextEditingController supplierController;
  final TextEditingController customerController;
  final TextEditingController productController;
  final TextEditingController transactionIdController;
  final TextEditingController brutoController;
  final TextEditingController tareController;
  final TextEditingController nettoController;

  final FocusNode focusPO;
  final FocusNode focusPotongan;
  final FocusNode focusKubikasi;
  final FocusNode focusNoContainer;
  final FocusNode focusSuhu;
  final FocusNode focusHarga;
  final FocusNode focusKeterangan;

  final Color cardBg;
  final Color primaryCyan;
  final Color textGrey;
  final Color inputBg;

  final Future<void> Function() onSavePressed;
  final bool isFormValid;
  double? tare;

  AddNettoTransactionFormCard({
    super.key,
    required this.platnomorController,
    required this.poController,
    required this.namasupirController,
    required this.potonganController,
    required this.kubikasiController,
    required this.nocontainerController,
    required this.suhuController,
    required this.hargaController,
    required this.keteranganController,
    required this.focusPO,
    required this.focusPotongan,
    required this.focusKubikasi,
    required this.focusNoContainer,
    required this.focusSuhu,
    required this.focusHarga,
    required this.focusKeterangan,
    required this.cardBg,
    required this.primaryCyan,
    required this.textGrey,
    required this.inputBg,
    required this.onSavePressed,
    required this.isFormValid,
    required this.supplierController,
    required this.customerController,
    required this.productController,
    required this.transactionIdController,
    required this.brutoController,
    required this.tareController,
    required this.nettoController,
    this.tare,
  });

  @override
  State<AddNettoTransactionFormCard> createState() =>
      _TransactionFormCardState();
}

class _TransactionFormCardState extends State<AddNettoTransactionFormCard> {
  /// Make initialization for placeholder so the value doesn't null
  ListTransactionJson _transaction = ListTransactionJson(
    vehiclePlate: '',
    driverName: '',
    supplierId: 0,
    customerId: 0,
    productId: 0,
    cut: 0,
    noTicket: '',
    inTime: DateTime.now(),
    outTime: DateTime.now(),
    totalPrice: 0,
    bruto: 0,
    tare: 0,
    netto: 0,
    nettoAfterCut: 0,
    driverLabel: 0,
    operatorLabel: 0,
    managerLabel: 0,
    headWarehouseLabel: 0,
  );

  /// Make Existing Data to Be Placeholder
  void _onSelected(ListTransactionJson transaction) async {
    print(transaction.productName);
    print(transaction.noDO);
    print(transaction.additionalInformation);
    setState(() {
      _transaction = transaction;
      widget.brutoController.text = _transaction.bruto.toString();
      widget.transactionIdController.text =
          _transaction.transactionId.toString();
      widget.supplierController.text = _transaction.supplierName!;
      widget.customerController.text = _transaction.customerName!;
      widget.productController.text = _transaction.productName!;
      widget.platnomorController.text = _transaction.vehiclePlate;
      widget.namasupirController.text = _transaction.driverName;
      widget.poController.text = _transaction.noDO ?? '';
      widget.potonganController.text = _transaction.cut.toString();
      widget.kubikasiController.text =
          _transaction.kubikasi == null ? '' : _transaction.kubikasi.toString();
      widget.nocontainerController.text =
          _transaction.noContainer == null
              ? ''
              : _transaction.noContainer.toString();
      widget.suhuController.text =
          _transaction.temperature == null
              ? ''
              : _transaction.temperature.toString();
      widget.hargaController.text =
          _transaction.price == null ? '' : _transaction.price.toString();
      widget.keteranganController.text =
          _transaction.additionalInformation ?? '';
    });
  }

  Widget _buildTextInput({
    TextEditingController? controller,
    required String label,
    String? hint,
    FocusNode? focus,
    FocusNode? nextFocus,
    TextCapitalization textCapital = TextCapitalization.none,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focus,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapital,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.textGrey),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withAlpha((0.5 * 255).round()),
        ),
        filled: true,
        fillColor: widget.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: widget.textGrey)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.textGrey.withAlpha((0.12 * 255).round()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.primaryCyan, width: 1.5),
        ),
      ),
      onFieldSubmitted: (v) {
        if (nextFocus != null)
          FocusScope.of(focus!.context!).requestFocus(nextFocus);
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                SearchTicketField(onSelected: _onSelected),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(children: [const SizedBox(width: 12)]),
                ),
                Text(
                  _transaction.noTicket,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(children: [const SizedBox(width: 12)]),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.platnomorController,
                        label: 'Plat Nomor',
                        hint: 'B 1234 ABC',
                        textCapital: TextCapitalization.characters,
                        prefixIcon: Icons.local_shipping_outlined,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.namasupirController,
                        label: 'Nama Supir',
                        enabled: false,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.supplierController,
                        label: 'Supplier',
                        enabled: false,
                        prefixIcon: Icons.store_mall_directory_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.customerController,
                        label: 'Customer',
                        enabled: false,
                        prefixIcon: Icons.business_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.productController,
                        label: 'Product',
                        enabled: false,
                        prefixIcon: Icons.category_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.poController,
                        label: 'Nomor DO / PO',
                        focus: widget.focusPO,
                        nextFocus: widget.focusNoContainer,
                        prefixIcon: Icons.description_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.potonganController,
                        label: 'Potongan (%)',
                        hint: '0',
                        focus: widget.focusPotongan,
                        nextFocus: widget.focusKubikasi,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.percent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.kubikasiController,
                        label: 'Kubikasi (opt)',
                        hint: '0',
                        focus: widget.focusKubikasi,
                        nextFocus: widget.focusPO,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.numbers,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.nocontainerController,
                        label: 'No Container (opt)',
                        hint: 'max 20 chars',
                        focus: widget.focusNoContainer,
                        nextFocus: widget.focusSuhu,
                        maxLength: 20,
                        prefixIcon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.suhuController,
                        label: 'Suhu (opt)',
                        hint: '°C',
                        focus: widget.focusSuhu,
                        nextFocus: widget.focusHarga,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.thermostat_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: widget.hargaController,
                        label: 'Harga / kg (opt)',
                        hint: '0',
                        focus: widget.focusHarga,
                        nextFocus: widget.focusKeterangan,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: widget.keteranganController,
                  label: 'Keterangan (Manual) (opt)',
                  hint: 'Catatan...',
                  focus: widget.focusKeterangan,
                  maxLength: 500,
                  prefixIcon: Icons.note_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        widget.isFormValid
                            ? () => widget.onSavePressed()
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryCyan,
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
                    child: const Text('SIMPAN'),
                  ),
                ),
                const SizedBox(height: 8),
                if (!widget.isFormValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Lengkapi: Supplier, Customer, Barang, Plat Nomor, Nama Supir, dan Simpan Berat',
                      style: TextStyle(color: widget.textGrey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,

          /// TODO : MAKE SURE THE CALCULATION IS CORRECT
          child: WeightDetails(
            bruto:
                widget.brutoController.text.isEmpty
                    ? '0.00'
                    : widget.brutoController.text,
            tare: widget.tare?.toStringAsFixed(2) ?? '0.00',
            netto: ((double.tryParse(widget.brutoController.text) ?? 0) -
                    (widget.tare?.toDouble() ?? 0))
                .toStringAsFixed(2),
            afterCut: (((double.tryParse(widget.brutoController.text) ?? 0) -
                        (widget.tare?.toDouble() ?? 0)) -
                    (((double.tryParse(widget.brutoController.text) ?? 0) -
                            (widget.tare?.toDouble() ?? 0)) *
                        (double.tryParse(widget.potonganController.text) ?? 0) /
                        100))
                .toStringAsFixed(2),
            totalPrice: ((((double.tryParse(widget.brutoController.text) ?? 0) -
                            (widget.tare?.toDouble() ?? 0)) -
                        (((double.tryParse(widget.brutoController.text) ?? 0) -
                                (widget.tare?.toDouble() ?? 0)) *
                            (double.tryParse(widget.potonganController.text) ??
                                0) /
                            100)) *
                    (double.tryParse(widget.hargaController.text) ?? 0))
                .toStringAsFixed(2),
            textGrey: widget.textGrey,
            cardBg: widget.cardBg,
          ),
        ),
      ],
    );
  }
}
