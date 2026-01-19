import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dakara_weighbridge/Menu/menu_items.dart';
import 'package:dakara_weighbridge/Pages/tec_pages/techician_page.dart';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final menu = MenuItems();
  final PageController pageController = PageController();
  List<String> menuItems = ["Token", "CreateOPT", "Report"];
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  Color bgGrey = const Color.fromARGB(255, 228, 230, 232);
  Color royalGrey = const Color.fromARGB(255, 86, 105, 113);
  Color limeGreen = const Color.fromARGB(255, 151, 255, 33);

  String? _username = '';

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('name');
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: menu.items.length,
          itemBuilder: (context, index) => PageStorage(
            bucket: PageStorageBucket(),
            child: KeyedSubtree(
              key: PageStorageKey('page_$index'),
              child: menu.supervisorItems[index].page,
            ),
          ),
        ),

        // Top Bar
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
                          values: const [0, 1, 2],
                          iconOpacity: 0.7,
                          height: 45,
                          indicatorSize: const Size.fromWidth(90),
                          animatedIconBuilder: (context, local, global) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  menuItems[local.value],
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
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
                          children: [
                            const Icon(Icons.wordpress_outlined,
                                color: Colors.white),
                            const SizedBox(width: 5),
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

                      // Account & Others
                      Row(
                        children: [
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
                          const SizedBox(width: 6),
                          // Setting button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: const Color.fromARGB(18, 255, 255, 255),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings),
                              color: Colors.white,
                              iconSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Account button (Popup Menu)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'logout') {
                                  AuthService().logout();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Dashboard()),
                                  );
                                }
                              },
                              color: Colors.black87, // ✅ background gelap
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                    color: Colors.grey.withAlpha(40)),
                              ),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Row(
                                    children: [
                                      Icon(Icons.person,
                                          color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hello ${_username ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.logout,
                                          color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.person,
                                  color: Colors.blueAccent),
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
