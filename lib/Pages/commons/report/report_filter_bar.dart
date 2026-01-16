/// Report Controls Widgets
/// Komponen kontrol untuk halaman Report (search, filter, date picker, export)

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_controller.dart';
import 'package:dakara_weighbridge/Pages/commons/report/report_widgets.dart';

/// Controls row used in `ReportPage`.
class ReportControls extends StatelessWidget {
  final ReportController controller;
  final TextEditingController searchController;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onShowFilter;
  final VoidCallback onExport;
  final VoidCallback onPrint;
  final VoidCallback onToggleSort;

  const ReportControls({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onShowFilter,
    required this.onExport,
    required this.onPrint,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kInputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: kTextGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: kTextWhite),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari...',
                        ),
                        onChanged: (v) => controller.setSearch(v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconBtn(
              icon: Icons.filter_list,
              tooltip: 'Filter',
              onTap: onShowFilter,
            ),
            const SizedBox(width: 8),
            IconBtn(icon: Icons.download, tooltip: 'Export', onTap: onExport),
            const SizedBox(width: 8),
            IconBtn(icon: Icons.print, tooltip: 'Print', onTap: onPrint),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            DateButton(
              date: controller.startDate,
              hint: 'Start',
              onTap: onPickStartDate,
            ),
            const SizedBox(width: 8),
            DateButton(
              date: controller.endDate,
              hint: 'End',
              onTap: onPickEndDate,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ActionButton(
                    icon:
                        controller.sortDesc
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                    label: controller.sortDesc ? 'Desc' : 'Asc',
                    color: kInputBg,
                    onTap: onToggleSort,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
  final String Function(int) getCustomerName;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const FilterSheet({
    super.key,
    required this.controller,
    required this.getSupplierName,
    required this.getProductName,
    required this.getCustomerName,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SizedBox(
      height: maxHeight,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
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
                items: [
                  null,
                  ...controller.products.value.map((p) => p.productId),
                ],
                labelFn:
                    (id) => id == null ? 'Semua Produk' : getProductName(id!),
                onChanged: (v) {
                  controller.setProduct(v);
                  onClose();
                },
              ),
              const SizedBox(height: 12),
              FilterDropdown<int?>(
                label: 'Customer',
                value: controller.customerId,
                items: [
                  null,
                  ...controller.customers.value.map((c) => c.customerId),
                ],
                labelFn:
                    (id) =>
                        id == null ? 'Semua Customer' : getCustomerName(id!),
                onChanged: (v) {
                  controller.setCustomer(v);
                  onClose();
                },
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plat Kendaraan',
                    style: TextStyle(color: kTextGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kInputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: TextEditingController(
                        text: controller.plate ?? '',
                      ),
                      style: const TextStyle(color: kTextWhite),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan plat (mis. B1234CD)',
                      ),
                      onChanged: (v) => controller.setPlate(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
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
        ),
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
