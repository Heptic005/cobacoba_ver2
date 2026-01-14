import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dakara_weighbridge/Menu/menu_items.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/placeholder.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/dashboard.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/techician_page.dart';
import 'package:dakara_weighbridge/Pages/spv_pages/placeholder.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pages/login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final menu = MenuItems();
  final PageController pageController = PageController();
  List<String> menuItems = ["Transaction", "Report", "Data"];
  // Use ValueNotifier to avoid rebuilding the whole scaffold when toggling
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
  Color bgGrey = const Color.fromARGB(255, 228, 230, 232);
  Color royalGrey = const Color.fromARGB(255, 86, 105, 113);
  // Color limeGreen = const Color.fromARGB(255, 124, 233, 0);
  Color limeGreen = const Color.fromARGB(255, 151, 255, 33);

  /// Role
  String _role = '';

  void _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
    // xAlign = transactionAlign;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dakara WeightBridge',
      theme: AppThemes.lightTheme,
      home: Scaffold(
        body: WindowBorder(
          color: bgGrey,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 54, 68, 77),
                  Color.fromARGB(255, 22, 25, 33),
                  Color.fromARGB(255, 22, 25, 33),
                  Color.fromARGB(255, 38, 47, 54),
                ],
                stops: [0, 0.7, 0.9, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // begin: Alignment(-0.0, -1.3),
                // end: Alignment(-0.0, 1),
              ),
            ),
            child: _buildHome(),
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    switch (_role) {
      case 'supervisor':
        return const SupervisorTemporaryDashboard();
      case 'operator':
        return const OperatorDashboard();
      case 'manager':
        return const ManagerTemporaryDashboard();
      default:
        return const LoginPage();
    }
  }

  Widget alternativeIconBuilder(
    BuildContext context,
    AnimatedToggleProperties<int> local,
    GlobalToggleProperties<int> global,
    int select,
  ) {
    IconData data = Icons.desktop_mac_outlined;
    switch (local.value) {
      case 0:
        data = Icons.desktop_mac_outlined;
        break;
      case 1:
        data = Icons.description_rounded;
        break;
      case 2:
        data = Icons.bubble_chart;
        break;
      case 3:
        data = Icons.people;
        break;
    }
    return Icon(
      data,
      size: 20,
      // color: select == local.value ? Colors.black : Colors.transparent,
    );
  }
}
