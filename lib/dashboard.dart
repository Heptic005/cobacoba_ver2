import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dakara_weighbridge/Menu/menu_items.dart';
import 'package:dakara_weighbridge/Pages/techician_page.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
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
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: menu.items.length,
                  itemBuilder: (context, index) => PageStorage( // keep page state alive per tab
                    bucket: PageStorageBucket(),
                    child: KeyedSubtree(
                      key: PageStorageKey('page_$index'),
                      child: menu.items[index].page,
                    ),
                  ),
                ),

                // Top Bar
                ClipRect(
                  child: BackdropFilter(
                    // Lower blur sigma to reduce GPU cost on low-end devices
                    filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(0, 238, 238, 238),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Menu Bar
                          // RepaintBoundary isolates top bar from page repaint
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
                                      spacing: 7,
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
                                      // shorten duration to reduce jank
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
                              // Logo Aplikasi
                              Container(
                                padding: EdgeInsets.symmetric(
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
                                    Icon(
                                      Icons.wordpress_outlined,
                                      color: Colors.white,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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

                              // Account & Others Button
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
                                          // padding: EdgeInsets.only(right: 50),
                                          // padding: EdgeInsets.all(.3),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            border: Border.all(
                                              color: Colors.white12,
                                              width: 0.6,
                                              strokeAlign:
                                                  BorderSide.strokeAlignOutside,
                                            ),
                                            color: const Color.fromARGB(
                                              69,
                                              84,
                                              88,
                                              96,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () {},
                                            hoverColor: const Color.fromARGB(
                                              247,
                                              74,
                                              86,
                                              102,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            hoverDuration: Duration(
                                              milliseconds: 100,
                                            ),
                                            child: Container(
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(
                                                left: 15,
                                              ),
                                              child: Text(
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
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          color: const Color.fromARGB(
                                            247,
                                            74,
                                            86,
                                            102,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons
                                                .settings_input_component_rounded,
                                          ),
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
                                      color: const Color.fromARGB(
                                        18,
                                        255,
                                        255,
                                        255,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.notifications_none_rounded,
                                      ),
                                      color: Colors.white,
                                      iconSize: 18,
                                    ),
                                  ),
                                  // Setting button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: const Color.fromARGB(
                                        18,
                                        255,
                                        255,
                                        255,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return TechnicianPage();
                                            },
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.settings),
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
                                      onPressed: () {},
                                      icon: Icon(Icons.person),
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
            ),
          ),
        ),
      ),
    );
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
