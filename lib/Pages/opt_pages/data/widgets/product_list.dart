/// ============================================================================
/// Product List Widget
/// ============================================================================
/// File: product_list.dart
/// Deskripsi: Widget untuk menampilkan daftar product/barang dalam format tabel.
///            Menampilkan kolom: Nama Barang, Kode Barang
///            ID product tidak ditampilkan sesuai requirement keamanan.
///
/// CATATAN: Product bersifat read-only, tidak ada tombol tambah.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/widgets/data_table_widget.dart';

/// Widget list untuk menampilkan data product
class ProductList extends StatelessWidget {
  /// Daftar product yang akan ditampilkan
  final List<ListProductJson> products;

  /// Callback ketika loading
  final bool isLoading;

  const ProductList({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      );
    }

    // Konfigurasi kolom untuk product table
    final columns = [
      const TableColumnConfig(headerText: 'Nama Barang', flex: 2),
      const TableColumnConfig(headerText: 'Kode Barang', flex: 2),
    ];

    // Konversi data product ke format TableRowData
    // NOTE: productId tidak dimasukkan ke dalam tampilan
    final rows =
        products.map((product) {
          return TableRowData(
            cells: [
              TableCellData(
                text: product.productName,
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF00BCD4),
              ),
              TableCellData(text: product.productCode),
            ],
          );
        }).toList();

    return DataTableWidget(
      columns: columns,
      rows: rows,
      emptyMessage: 'Tidak ada data barang',
    );
  }
}
