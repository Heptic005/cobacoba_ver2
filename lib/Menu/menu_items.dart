import 'package:dakara_weighbridge/Menu/manager_menu_items.dart';
import 'package:dakara_weighbridge/Menu/menu_details.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/token_generator_page.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/data_page.dart'; 
import 'package:dakara_weighbridge/Pages/opt_pages/report.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Entities/Supervisor/supervisor.dart';
import 'package:dakara_weighbridge/Pages/spv_pages/create_operator_spv.dart';

class MenuItems {
  // Menu untuk Operator
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
      page: DataPage(),
    ),
  ];
  List<MenuDetails> supervisorItems = [
        MenuDetails(
          title: "Buat Operator Baru",
          icon: Icons.person_add,
          page: CreateOperatorPage(),
        ),
        MenuDetails(
          title: "Report",
          icon: Icons.warning_amber,
          page: ReportPage(),
        ),
      ];
      
      
}
