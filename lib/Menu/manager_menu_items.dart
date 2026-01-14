import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Menu/menu_details.dart';

// Kita akan buat halaman-halaman ini sebentar lagi
import 'package:dakara_weighbridge/Pages/mgr_pages/user_management_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/token_generator_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/audit_transaction_page.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report.dart'; // Manager juga bisa lihat report yg sama

class ManagerMenuItems {
  List<MenuDetails> items = [
    MenuDetails(
      title: "User Mgmt",
      icon: Icons.manage_accounts_rounded,
      page: UserManagementPage(), // CRUD Supervisor & Operator
    ),
    MenuDetails(
      title: "Security Token",
      icon: Icons.vpn_key_rounded,
      page: TokenGeneratorPage(), // createTokenManualWeight
    ),
    MenuDetails(
      title: "Audit Data",
      icon: Icons.delete_sweep_rounded,
      page: AuditTransactionPage(), // hapusDataTransaksi
    ),
    MenuDetails(
      title: "Report",
      icon: Icons.analytics_rounded,
      page: Report(), // exportReport (Reuse fitur report yg sudah ada)
    ),
  ];
}