/// ============================================================================
/// Menu Items Configuration
/// ============================================================================
/// File: menu_items.dart
/// Deskripsi: Konfigurasi menu items untuk navigasi halaman di dashboard.
///            
/// UPDATED: Menggunakan DataPage dari modul data yang termodularisasi
/// ============================================================================

import 'package:dakara_weighbridge/Menu/menu_details.dart';
import 'package:dakara_weighbridge/Pages/data/data_page.dart'; // Updated import
import 'package:dakara_weighbridge/Pages/report.dart';
import 'package:dakara_weighbridge/Pages/transaction.dart';
import 'package:flutter/material.dart';

class MenuItems {
  List<MenuDetails> items = [
    MenuDetails(
      title: "Transaction",
      icon: Icons.attach_money_rounded,
      page: Transaction(),
    ),
    MenuDetails(
      title: "Report",
      icon: Icons.laptop_chromebook_rounded,
      page: Report(),
    ),
    MenuDetails(
      title: "Data",
      icon: Icons.view_in_ar_rounded,
      page: DataPage(), // Updated: menggunakan DataPage yang termodularisasi
    ),
  ];
}
