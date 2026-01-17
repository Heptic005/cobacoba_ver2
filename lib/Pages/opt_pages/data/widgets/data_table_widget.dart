/// Deskripsi: Generic table widget untuk menampilkan data dalam format tabel.

import 'package:flutter/material.dart';

/// Konfigurasi untuk satu kolom tabel
class TableColumnConfig {
  final String headerText;
  final double flex;
  final IconData? headerIcon;
  
  const TableColumnConfig({
    required this.headerText,
    this.flex = 1.0,
    this.headerIcon,
  });
}

/// Row data yang akan ditampilkan di tabel
class TableRowData {
  final List<TableCellData> cells;
  
  const TableRowData({required this.cells});
}

/// Data untuk satu cell dalam tabel
class TableCellData {
  final String text;
  final IconData? icon;
  final Color? iconColor;
  
  const TableCellData({
    required this.text,
    this.icon,
    this.iconColor,
  });
}

/// Widget table generik yang dapat dikonfigurasi
class DataTableWidget extends StatelessWidget {
  /// Daftar konfigurasi kolom
  final List<TableColumnConfig> columns;
  
  /// Daftar data row yang akan ditampilkan
  final List<TableRowData> rows;
  
  /// Pesan yang ditampilkan jika tidak ada data
  final String emptyMessage;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'Tidak ada data',
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header row
        _buildHeaderRow(),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) => _buildDataRow(rows[index], index),
          ),
        ),
      ],
    );
  }

  /// Build header row dengan styling
  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            flex: column.flex.toInt(),
            child: Row(
              children: [
                if (column.headerIcon != null) ...[
                  Icon(
                    column.headerIcon,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  column.headerText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build single data row
  Widget _buildDataRow(TableRowData row, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: index.isEven 
            ? Colors.transparent 
            : Colors.grey.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          row.cells.length,
          (cellIndex) {
            final cell = row.cells[cellIndex];
            final column = columns[cellIndex];
            
            return Expanded(
              flex: column.flex.toInt(),
              child: Row(
                children: [
                  if (cell.icon != null) ...[
                    Icon(
                      cell.icon,
                      size: 18,
                      color: cell.iconColor ?? const Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      cell.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
