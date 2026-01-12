/// ============================================================================
/// Supplier List Widget
/// ============================================================================
/// File: supplier_list.dart
/// Deskripsi: Widget untuk menampilkan daftar supplier dalam format tabel.
///            Menampilkan kolom: Nama Supplier, Alamat, Kota
///            ID supplier tidak ditampilkan sesuai requirement keamanan.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Pages/data/widgets/data_table_widget.dart';

/// Widget list untuk menampilkan data supplier
class SupplierList extends StatelessWidget {
  /// Daftar supplier yang akan ditampilkan
  final List<ListSupplierJson> suppliers;
  
  /// Callback ketika loading
  final bool isLoading;

  const SupplierList({
    super.key,
    required this.suppliers,
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

    // Konfigurasi kolom untuk supplier table (tampilkan semua field kecuali ID)
    final columns = [
      const TableColumnConfig(
        headerText: 'Nama Supplier',
        flex: 2,
      ),
      const TableColumnConfig(
        headerText: 'Alamat',
        flex: 3,
      ),
      const TableColumnConfig(
        headerText: 'Kecamatan',
        flex: 2,
      ),
      const TableColumnConfig(
        headerText: 'Kota',
        flex: 2,
      ),
      const TableColumnConfig(
        headerText: 'Kode Pos',
        flex: 1,
      ),
    ];

    // Konversi data supplier ke format TableRowData
    // NOTE: supplierId tidak dimasukkan ke dalam tampilan
    final rows = suppliers.map((supplier) {
      return TableRowData(
        cells: [
          TableCellData(
            text: supplier.supplierName,
            icon: Icons.business,
            iconColor: const Color(0xFF00BCD4),
          ),
          TableCellData(
            text: supplier.supplierAddress,
          ),
          TableCellData(
            text: supplier.supplierSubdistrict,
          ),
          TableCellData(
            text: supplier.supplierCity,
          ),
          TableCellData(
            text: supplier.supplierPostCode,
          ),
        ],
      );
    }).toList();

    return DataTableWidget(
      columns: columns,
      rows: rows,
      emptyMessage: 'Tidak ada data supplier',
    );
  }
}
