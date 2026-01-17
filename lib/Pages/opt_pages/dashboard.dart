import 'dart:async';
import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dakara_weighbridge/Entities/Operator/operator.dart';
import 'package:dakara_weighbridge/Menu/menu_items.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/special_transaction.dart';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:dakara_weighbridge/Services/config_service.dart';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  /// Listening To Transaction Connect Button To Serial
  static ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  final menu = MenuItems();
  final PageController pageController = PageController();
  List<String> menuItems = ["Transaction", "Report", "Data"];
  // Use ValueNotifier to avoid rebuilding the whole scaffold when toggling
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
  Color bgGrey = const Color.fromARGB(255, 228, 230, 232);
  Color royalGrey = const Color.fromARGB(255, 86, 105, 113);
  // Color limeGreen = const Color.fromARGB(255, 124, 233, 0);
  Color limeGreen = const Color.fromARGB(255, 151, 255, 33);

  /// Serial
  StreamSubscription<String>? _subscription;

  /// Token for Special Transaction Controller
  final TextEditingController tokenController = TextEditingController();
  final FocusNode tokenFocus = FocusNode();

  /// User Name
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
  void dispose() {
    tokenController.dispose();
    tokenFocus.dispose();
    super.dispose();
  }

  void _showInputTokenDialog(BuildContext context) {
    showDialog(
      context: (context),
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Input Token for Special Transaction',
            style: TextStyle(color: AppThemes.textWhite),
          ),
          backgroundColor: AppThemes.cardBg,
          content: TextFormField(
            controller: tokenController,
            focusNode: tokenFocus,
            maxLength: 6,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Token',
              labelStyle: TextStyle(color: AppThemes.textGrey),
              hintText: 'ABCDEF',
              hintStyle: TextStyle(
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
              filled: true,
              fillColor: AppThemes.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: const Icon(Icons.generating_tokens),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppThemes.textGrey.withAlpha((0.12 * 255).round()),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppThemes.primaryCyan,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                tokenController.clear();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppThemes.textRed),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final _isTokenValid = await Operator().validateToken(
                    tokenController.text,
                  );
                  if (_isTokenValid) tokenController.clear();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SpecialTransaction();
                      },
                    ),
                  );
                } catch (e) {
                  print('token not valid');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.inputBg,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: AppThemes.textWhite),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: menu.items.length,
          itemBuilder:
              (context, index) => PageStorage(
                // keep page state alive per tab
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
                          styleBuilder:
                              (i) => const ToggleStyle(
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
                            Icon(Icons.wordpress_outlined, color: Colors.white),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  width: 130,
                                  // padding: EdgeInsets.only(right: 50),
                                  // padding: EdgeInsets.all(.3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: Colors.white12,
                                      width: 0.6,
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                    ),
                                    color: const Color.fromARGB(69, 84, 88, 96),
                                  ),
                                  child: ValueListenableBuilder(
                                    valueListenable:
                                        OperatorDashboard.isConnected,
                                    builder: (context, isConnected, _) {
                                      return InkWell(
                                        onTap:
                                            OperatorDashboard
                                                        .isConnected
                                                        .value ==
                                                    true
                                                ? () async {
                                                  _subscription?.cancel();
                                                  _subscription = null;
                                                  SerialService().disconnect();
                                                  print('Disconnected');
                                                  OperatorDashboard
                                                      .isConnected
                                                      .value = false;
                                                }
                                                : () async {
                                                  SerialService().connect(
                                                    await ConfigService()
                                                        .load(),
                                                  );
                                                  print('Connected');
                                                  OperatorDashboard
                                                      .isConnected
                                                      .value = true;
                                                },
                                        hoverColor: const Color.fromARGB(
                                          247,
                                          74,
                                          86,
                                          102,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                        hoverDuration: Duration(
                                          milliseconds: 100,
                                        ),
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(
                                            left: 15,
                                          ),
                                          child: ValueListenableBuilder(
                                            valueListenable:
                                                OperatorDashboard.isConnected,
                                            builder: (context, isConnected, _) {
                                              if (isConnected) {
                                                return Text(
                                                  "Connected",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    height: 1,
                                                  ),
                                                );
                                              } else {
                                                return Text(
                                                  "Disconnected",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    height: 1,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    // child:
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
                                  icon: Icon(
                                    Icons.settings_input_component_rounded,
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
                              color: const Color.fromARGB(18, 255, 255, 255),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.notifications_none_rounded),
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
                              onPressed: () {},
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
                            child: PopupMenuButton(
                              onSelected: (v) {
                                if (v == 'special_transaction') {
                                  _showInputTokenDialog(context);
                                }
                                if (v == 'logout') {
                                  AuthService().logout();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return Dashboard();
                                      },
                                    ),
                                  );
                                }
                              },
                              itemBuilder:
                                  (_) => [
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text('Hello Operator $_username'),
                                    ),
                                    PopupMenuItem(
                                      value: 'special_transaction',
                                      child: const Text(
                                        'Create Special Transaction',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'logout',
                                      child: const Text('Logout'),
                                    ),
                                  ],
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
