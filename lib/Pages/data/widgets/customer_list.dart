/// ============================================================================
/// Customer List Widget
/// ============================================================================
/// File: customer_list.dart
/// Deskripsi: Widget untuk menampilkan daftar customer dalam format tabel.
///            Menampilkan kolom: Nama Customer, Alamat, No. Telp
///            ID customer tidak ditampilkan sesuai requirement keamanan.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Pages/data/widgets/data_table_widget.dart';

/// Widget list untuk menampilkan data customer
class CustomerList extends StatelessWidget {
  /// Daftar customer yang akan ditampilkan
  final List<ListCustomerJson> customers;
  
  /// Callback ketika loading
  final bool isLoading;

  const CustomerList({
    super.key,
    required this.customers,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00BCD4),
        ),
      );
    }

    // Konfigurasi kolom untuk customer table (sesuai Figma)
    final columns = [
      const TableColumnConfig(
        headerText: 'Nama Customer',
        flex: 2,
      ),
      const TableColumnConfig(
        headerText: 'Alamat',
        flex: 3,
      ),
      const TableColumnConfig(
        headerText: 'No. Telp',
        flex: 2,
      ),
    ];

    // Konversi data customer ke format TableRowData
    // NOTE: customerId tidak dimasukkan ke dalam tampilan
    final rows = customers.map((customer) {
      return TableRowData(
        cells: [
          TableCellData(
            text: customer.customerName,
            icon: Icons.people,
            iconColor: const Color(0xFF00BCD4),
          ),
          TableCellData(
            text: customer.customerAddress,
          ),
          TableCellData(
            text: customer.customerPhone,
            icon: Icons.phone,
            iconColor: Colors.grey[400],
          ),
        ],
      );
    }).toList();

    return DataTableWidget(
      columns: columns,
      rows: rows,
      emptyMessage: 'Tidak ada data customer',
    );
  }
}
