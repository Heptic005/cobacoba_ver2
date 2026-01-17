/// Deskripsi: Dialog form untuk menambahkan data Supplier atau Customer baru.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/data_controller.dart';

/// Enum untuk tipe entity yang akan ditambahkan
enum EntityType { supplier, customer, product }

/// Dialog untuk menambahkan Supplier atau Customer baru
class AddEntityDialog extends StatefulWidget {
  /// Tipe entity (supplier/customer)
  final EntityType entityType;

  /// Controller untuk handle insert data
  final DataController controller;

  const AddEntityDialog({
    super.key,
    required this.entityType,
    required this.controller,
  });

  /// Helper method untuk menampilkan dialog
  static Future<bool?> show({
    required BuildContext context,
    required EntityType entityType,
    required DataController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              AddEntityDialog(entityType: entityType, controller: controller),
    );
  }

  @override
  State<AddEntityDialog> createState() => _AddEntityDialogState();
}

class _AddEntityDialogState extends State<AddEntityDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _subdistrictController = TextEditingController();
  final _postCodeController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _subdistrictController.dispose();
    _postCodeController.dispose();
    super.dispose();
  }

  /// Cek apakah form ini untuk Supplier
  bool get isSupplier => widget.entityType == EntityType.supplier;
  bool get isProduct => widget.entityType == EntityType.product;

  /// Judul dialog berdasarkan tipe entity
  String get dialogTitle =>
      isProduct
        ? 'Tambah Barang Baru'
        : isSupplier
          ? 'Tambah Supplier Baru'
          : 'Tambah Customer Baru';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // Form fields
              _buildFormFields(),
              const SizedBox(height: 24),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          isProduct
              ? Icons.inventory_2_outlined
              : isSupplier
                  ? Icons.business
                  : Icons.people,
          color: const Color(0xFF00BCD4),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          dialogTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    if (isProduct) {
      return Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nama Barang',
            hint: 'Masukkan nama barang',
            validator: widget.controller.validateProductName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _codeController,
            label: 'Kode Barang',
            hint: 'Contoh: PRD-001',
            validator: widget.controller.validateProductCode,
          ),
        ],
      );
    }
    if (isSupplier) {
      return Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nama Supplier',
            hint: 'Masukkan nama supplier',
            validator: widget.controller.validateSupplierName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap',
            validator: widget.controller.validateSupplierAddress,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Kota',
                  hint: 'Nama kota',
                  validator: widget.controller.validateSupplierCity,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _subdistrictController,
                  label: 'Kecamatan',
                  hint: 'Nama kecamatan',
                  validator: widget.controller.validateSupplierSubdistrict,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _postCodeController,
            label: 'Kode Pos',
            hint: '12345',
            validator: widget.controller.validatePostCode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
          ),
        ],
      );
    } else {
      // Customer form
      return Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nama Customer',
            hint: 'Masukkan nama customer',
            validator: widget.controller.validateCustomerName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap',
            validator: widget.controller.validateCustomerAddress,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'No. Telepon',
            hint: '021-xxxx-xxxx atau 08xxxxxxxxxx',
            validator: widget.controller.validatePhone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\+\(\)\s]')),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        errorStyle: const TextStyle(
          color: Color(0xFFFF6B6B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      enabled: !_isSubmitting,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text('Batal', style: TextStyle(color: Colors.grey[400])),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Simpan'),
        ),
      ],
    );
  }

  // SUBMIT HANDLER

  Future<void> _handleSubmit() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

   if (isProduct) {
      final validation = widget.controller.validateProductName(
        _nameController.text,
      ) ??
          widget.controller.validateProductCode(
            _codeController.text,
      );
      if (validation != null) {
       setState(() {
         _errorMessage = validation;
       });
        return;
     }
  }

    setState(() {
      _isSubmitting = true;
    });

    try {
      bool success;

      if (isSupplier) {
        success = await widget.controller.addSupplier(
          name: _nameController.text,
          address: _addressController.text,
          city: _cityController.text,
          subdistrict: _subdistrictController.text,
          postCode: _postCodeController.text,
        );
      } else if (isProduct) {
        success = await widget.controller.addProduct(
          name: _nameController.text,
          code: _codeController.text,
        );
      } else {
        success = await widget.controller.addCustomer(
          name: _nameController.text,
          address: _addressController.text,
          phone: _phoneController.text,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProduct
                  ? 'Barang berhasil ditambahkan'
                  : isSupplier
                      ? 'Supplier berhasil ditambahkan'
                      : 'Customer berhasil ditambahkan',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
