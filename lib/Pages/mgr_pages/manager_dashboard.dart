// manager_dashboard.dart
import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:flutter/material.dart';

// Import Halaman Fitur Manager
import 'package:dakara_weighbridge/Pages/mgr_pages/user_management_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/token_generator_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/audit_transaction_page.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report.dart'; 
import 'package:dakara_weighbridge/Pages/opt_pages/techician_page.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final PageController pageController = PageController();

  // Menu Manager
  final List<String> _menuLabels = ["Users", "Token", "Audit", "Report"];

  final List<Widget> _pages = [
    const UserManagementPage(),
    const TokenGeneratorPage(),
    const AuditTransactionPage(),
    const Report(),
  ];

  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  void _handleLogout() {
    AuthService().logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: _pages.length,
          itemBuilder: (context, index) => PageStorage(
            bucket: PageStorageBucket(),
            child: KeyedSubtree(
              key: PageStorageKey('page_$index'),
              child: _pages[index],
            ),
          ),
        ),

        // Top Bar sama persis dengan dashboard.dart
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
              decoration: const BoxDecoration(
                color: Color.fromARGB(0, 238, 238, 238),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Toggle Menu
                  RepaintBoundary(
                    child: ValueListenableBuilder<int>(
                      valueListenable: selectedIndex,
                      builder: (_, current, __) {
                        return AnimatedToggleSwitch<int>.custom(
                          textDirection: TextDirection.ltr,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          current: current,
                          values: const [0, 1, 2, 3],
                          iconOpacity: 0.7,
                          height: 45,
                          indicatorSize: const Size.fromWidth(90),
                          animatedIconBuilder: (context, local, global) {
                            return Row(
                              spacing: 7,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _menuLabels[local.value],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                          style: const ToggleStyle(
                            borderColor: Colors.transparent,
                          ),
                          styleBuilder: (i) => const ToggleStyle(
                            indicatorGradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF0080FF),
                                Color(0xFF00E5FF),
                              ],
                            ),
                          ),
                          onChanged: (i) {
                            selectedIndex.value = i;
                            pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Logo + Buttons kanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo sama dengan dashboard.dart
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          spacing: 5,
                          children: [
                            const Icon(Icons.wordpress_outlined, color: Colors.white),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "Dakara WeightBridge",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  "The New Generation of Weight Bridge",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tombol kanan sama persis
                      Row(
                        spacing: 6,
                        children: [
                          // Serial button
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: Container(
                                  height: 40,
                                  width: 125,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: Colors.white12,
                                      width: 0.6,
                                      strokeAlign: BorderSide.strokeAlignOutside,
                                    ),
                                    color: const Color.fromARGB(69, 84, 88, 96),
                                  ),
                                  child: InkWell(
                                    onTap: () {},
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 15),
                                      child: const Text(
                                        "Connected",
                                        style: TextStyle(
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: const Color.fromARGB(247, 74, 86, 102),
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.settings_input_component_rounded),
                                  color: Colors.white,
                                  iconSize: 18,
                                ),
                              ),
                            ],
                          ),
                          // Notif button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: const Color.fromARGB(18, 255, 255, 255),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications_none_rounded),
                              color: Colors.white,
                              iconSize: 18,
                            ),
                          ),
                          // Setting button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: const Color.fromARGB(18, 255, 255, 255),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const TechnicianPage();
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings),
                              color: Colors.white,
                              iconSize: 18,
                            ),
                          ),
                          // Account button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.person),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
