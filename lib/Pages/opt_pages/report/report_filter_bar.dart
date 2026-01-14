/// Report Controls Widgets
/// Komponen kontrol untuk halaman Report (search, filter, date picker, export)

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report/report_widgets.dart';

/// Widget utama untuk Controls bar (search, date, filter, export)
class ReportControls extends StatelessWidget {
  final ReportController controller;
  final TextEditingController searchController;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onShowFilter;
  final VoidCallback onExport;
  final VoidCallback onPrint;

  const ReportControls({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onShowFilter,
    required this.onExport,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: kTextWhite),
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan tiket, plat, atau produk...',
                hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: kTextGrey),
                filled: true,
                fillColor: kInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (v) => controller.setSearch(v),
            ),
          ),
          const SizedBox(width: 16),
          // Date pickers
          DateButton(
            date: controller.startDate,
            hint: 'Dari',
            onTap: onPickStartDate,
          ),
          const SizedBox(width: 8),
          DateButton(
            date: controller.endDate,
            hint: 'Sampai',
            onTap: onPickEndDate,
          ),
          const SizedBox(width: 8),
          // Filter icon
          IconBtn(
            icon: Icons.filter_list,
            tooltip: 'Filter',
            onTap: onShowFilter,
          ),
          const Spacer(),
          // Ekspor button
          ActionButton(
            icon: Icons.file_download,
            label: 'Ekspor',
            color: kPrimaryCyan,
            onTap: onExport,
          ),
          const SizedBox(width: 8),
          // Cetak button
          ActionButton(
            icon: Icons.print,
            label: 'Cetak',
            color: kTextGrey,
            onTap: onPrint,
          ),
        ],
      ),
    );
  }
}

/// Date picker button widget
class DateButton extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const DateButton({
    super.key,
    required this.date,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kInputBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: kTextGrey),
            const SizedBox(width: 8),
            Text(
              date != null ? dateShortFormat.format(date!) : hint,
              style: TextStyle(
                color: date != null ? kTextWhite : kTextGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon button widget
class IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kInputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kTextGrey, size: 20),
        ),
      ),
    );
  }
}

/// Action button widget (Ekspor, Cetak)
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color == kPrimaryCyan ? kPrimaryCyan : kInputBg,
        foregroundColor: color == kPrimaryCyan ? Colors.black : kTextWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Filter bottom sheet content
class FilterSheet extends StatelessWidget {
  final ReportController controller;
  final String Function(int) getSupplierName;
  final String Function(int) getProductName;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const FilterSheet({
    super.key,
    required this.controller,
    required this.getSupplierName,
    required this.getProductName,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextWhite,
            ),
          ),
          const SizedBox(height: 16),
          FilterDropdown<int?>(
            label: 'Supplier',
            value: controller.supplierId,
            items: [
              null,
              ...controller.suppliers.value.map((s) => s.supplierId),
            ],
            labelFn:
                (id) => id == null ? 'Semua Supplier' : getSupplierName(id),
            onChanged: (v) {
              controller.setSupplier(v);
              onClose();
            },
          ),
          const SizedBox(height: 12),
          FilterDropdown<int?>(
            label: 'Produk',
            value: controller.productId,
            items: [null, ...controller.products.value.map((p) => p.productId)],
            labelFn: (id) => id == null ? 'Semua Produk' : getProductName(id),
            onChanged: (v) {
              controller.setProduct(v);
              onClose();
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Only call onClear here. onClear (from caller) is responsible
                // for closing the sheet using the correct sheetContext to avoid
                // deactivated-context errors or double pop.
                onClear();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kTextGrey),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Reset Semua Filter',
                style: TextStyle(color: kTextGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic dropdown untuk filter
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelFn;
  final void Function(T?) onChanged;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelFn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kInputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              dropdownColor: kCardBg,
              style: const TextStyle(color: kTextWhite),
              items:
                  items
                      .map(
                        (v) => DropdownMenuItem<T>(
                          value: v,
                          child: Text(labelFn(v)),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
