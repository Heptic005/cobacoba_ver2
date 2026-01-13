import 'package:dakara_weighbridge/Pages/transaction_components/weight_details.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';

class TransactionFormCard extends StatelessWidget {
  final TextEditingController platnomorController;
  final TextEditingController poController;
  final TextEditingController namasupirController;
  final TextEditingController potonganController;
  final TextEditingController kubikasiController;
  final TextEditingController nocontainerController;
  final TextEditingController suhuController;
  final TextEditingController hargaController;
  final TextEditingController keteranganController;

  final FocusNode focusPlatnomor;
  final FocusNode focusPO;
  final FocusNode focusSupir;
  final FocusNode focusPotongan;
  final FocusNode focusKubikasi;
  final FocusNode focusNoContainer;
  final FocusNode focusSuhu;
  final FocusNode focusHarga;
  final FocusNode focusKeterangan;

  final List<ListSupplierJson> suppliers;
  final List<ListCustomerJson> customers;
  final List<ListProductJson> products;
  final int? selectedSupplier;
  final int? selectedCustomer;
  final int? selectedProduct;
  final double? bruto;

  final Color cardBg;
  final Color primaryCyan;
  final Color textGrey;
  final Color inputBg;

  final void Function(int?) onSelectSupplier;
  final void Function(int?) onSelectCustomer;
  final void Function(int?) onSelectProduct;
  final Future<void> Function() onSavePressed;
  final bool isFormValid;

  const TransactionFormCard({
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
    required this.focusPlatnomor,
    required this.focusPO,
    required this.focusSupir,
    required this.focusPotongan,
    required this.focusKubikasi,
    required this.focusNoContainer,
    required this.focusSuhu,
    required this.focusHarga,
    required this.focusKeterangan,
    required this.suppliers,
    required this.customers,
    required this.products,
    required this.selectedSupplier,
    required this.selectedCustomer,
    required this.selectedProduct,
    required this.cardBg,
    required this.primaryCyan,
    required this.textGrey,
    required this.inputBg,
    required this.onSelectSupplier,
    required this.onSelectCustomer,
    required this.onSelectProduct,
    required this.onSavePressed,
    required this.isFormValid,
    this.bruto = 0,
  });

  Widget _buildTextInput({
    required TextEditingController controller,
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
        labelStyle: TextStyle(color: textGrey),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withAlpha((0.5 * 255).round()),
        ),
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: textGrey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: textGrey.withAlpha((0.12 * 255).round()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryCyan, width: 1.5),
        ),
      ),
      onFieldSubmitted: (v) {
        if (nextFocus != null)
          FocusScope.of(focus!.context!).requestFocus(nextFocus);
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required void Function(int?) onChanged,
    int? initialValue,
    IconData? prefixIcon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: initialValue,
      items:
          items.map((item) {
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
      dropdownColor: inputBg,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textGrey),
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: textGrey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: textGrey.withAlpha((0.12 * 255).round()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryCyan, width: 1.5),
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: textGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(children: [const SizedBox(width: 12)]),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        controller: platnomorController,
                        label: 'Plat Nomor',
                        hint: 'B 1234 ABC',
                        focus: focusPlatnomor,
                        nextFocus: focusSupir,
                        textCapital: TextCapitalization.characters,
                        prefixIcon: Icons.local_shipping_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: namasupirController,
                        label: 'Nama Supir',
                        focus: focusSupir,
                        nextFocus: focusPotongan,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<ListSupplierJson>(
                        label: 'Supplier',
                        items: suppliers,
                        onChanged: onSelectSupplier,
                        initialValue: selectedSupplier,
                        prefixIcon: Icons.store_mall_directory_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown<ListCustomerJson>(
                        label: 'Customer',
                        items: customers,
                        onChanged: onSelectCustomer,
                        initialValue: selectedCustomer,
                        prefixIcon: Icons.business_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<ListProductJson>(
                        label: 'Barang',
                        items: products,
                        onChanged: onSelectProduct,
                        initialValue: selectedProduct,
                        prefixIcon: Icons.category_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: poController,
                        label: 'Nomor DO / PO',
                        focus: focusPO,
                        nextFocus: focusNoContainer,
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
                        controller: potonganController,
                        label: 'Potongan (%)',
                        hint: '0',
                        focus: focusPotongan,
                        nextFocus: focusKubikasi,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.percent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: kubikasiController,
                        label: 'Kubikasi (opt)',
                        hint: '0',
                        focus: focusKubikasi,
                        nextFocus: focusPO,
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
                        controller: nocontainerController,
                        label: 'No Container (opt)',
                        hint: 'max 20 chars',
                        focus: focusNoContainer,
                        nextFocus: focusSuhu,
                        maxLength: 20,
                        prefixIcon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextInput(
                        controller: suhuController,
                        label: 'Suhu (opt)',
                        hint: '°C',
                        focus: focusSuhu,
                        nextFocus: focusHarga,
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
                        controller: hargaController,
                        label: 'Harga / kg (opt)',
                        hint: '0',
                        focus: focusHarga,
                        nextFocus: focusKeterangan,
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
                  controller: keteranganController,
                  label: 'Keterangan (Manual) (opt)',
                  hint: 'Catatan...',
                  focus: focusKeterangan,
                  maxLength: 500,
                  prefixIcon: Icons.note_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isFormValid ? () => onSavePressed() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryCyan,
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
                if (!isFormValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Lengkapi: Supplier, Customer, Barang, Plat Nomor, Nama Supir, dan Simpan Berat',
                      style: TextStyle(color: textGrey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: WeightDetails(
            bruto: bruto?.toStringAsFixed(2) ?? '0',
            tare: '0',
            netto: '0',
            afterCut: '0',
            totalPrice: '0',
            textGrey: textGrey,
            cardBg: cardBg,
          ),
        ),
      ],
    );
  }
}
