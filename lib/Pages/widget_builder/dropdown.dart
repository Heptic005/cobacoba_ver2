import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:flutter/material.dart';

Widget buildDropdownSupplier({
  required String label,
  required List<ListSupplierJson> items,
  required Function(int?) onChanged,
  required List<Color> colors,
  int? value,
  String? hint,
  IconData? prefixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<int>(
        initialValue: value,
        items:
            items.map((ListSupplierJson item) {
              return DropdownMenuItem<int>(
                value: item.supplierId,
                child: Text(
                  item.supplierName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        dropdownColor: colors[0], // Ensure dropdown popup matches input bg
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ), // Selected text color
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors[1]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: colors[0],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: colors[1]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[1].withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[2], width: 1.5),
          ),
        ),
        icon: Icon(Icons.arrow_drop_down, color: colors[1]),
      ),
    ],
  );
}

Widget buildDropdownCustomer({
  required String label,
  required List<ListCustomerJson> items,
  required Function(int?) onChanged,
  required List<Color> colors,
  int? value,
  String? hint,
  IconData? prefixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<int>(
        initialValue: value,
        items:
            items.map((ListCustomerJson item) {
              return DropdownMenuItem<int>(
                value: item.customerId,
                child: Text(
                  item.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        dropdownColor: colors[0], // Ensure dropdown popup matches input bg
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ), // Selected text color
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors[1]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: colors[0],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: colors[1]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[1].withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[2], width: 1.5),
          ),
        ),
        icon: Icon(Icons.arrow_drop_down, color: colors[1]),
      ),
    ],
  );
}

Widget buildDropdownProduct({
  required String label,
  required List<ListProductJson> items,
  required Function(int?) onChanged,
  required List<Color> colors,
  int? value,
  String? hint,
  IconData? prefixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<int>(
        initialValue: value,
        items:
            items.map((ListProductJson item) {
              return DropdownMenuItem<int>(
                value: item.productId,
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        dropdownColor: colors[0], // Ensure dropdown popup matches input bg
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ), // Selected text color
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors[1]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: colors[0],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: colors[1]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[1].withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors[2], width: 1.5),
          ),
        ),
        icon: Icon(Icons.arrow_drop_down, color: colors[1]),
      ),
    ],
  );
}
