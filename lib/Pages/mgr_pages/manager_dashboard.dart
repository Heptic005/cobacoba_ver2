import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:flutter/material.dart';

// Import Halaman Fitur Manager
import 'package:dakara_weighbridge/Pages/mgr_pages/user_management_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/token_generator_page.dart';
import 'package:dakara_weighbridge/Pages/mgr_pages/audit_transaction_page.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/report.dart'; 

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final PageController pageController = PageController();
  
  // 1. DAFTAR MENU MANAGER (Teks untuk di Tombol Atas)
  final List<String> _menuLabels = ["Users", "Token", "Audit", "Report"];

  // 2. DAFTAR HALAMAN (Sesuai urutan menu di atas)
  final List<Widget> _pages = [
    const UserManagementPage(),   // Index 0
    const TokenGeneratorPage(),   // Index 1
    const AuditTransactionPage(), // Index 2
    const Report(),               // Index 3
  ];

  // State untuk Tab yang dipilih
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  // Fungsi Logout
  void _handleLogout() {
    AuthService().logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Color (Abu-abu muda sesuai tema)
      backgroundColor: const Color.fromARGB(255, 228, 230, 232), 
      body: Stack(
        children: [
          // LAYER 1: ISI HALAMAN (PageView)
          PageView.builder(
            controller: pageController,
            itemCount: _pages.length,
            // Disable swipe agar user harus klik tombol (opsional, biar mirip tab)
            physics: const NeverScrollableScrollPhysics(), 
            itemBuilder: (context, index) {
              return Padding(
                // Beri jarak di atas agar tidak tertutup Top Bar
                padding: const EdgeInsets.only(top: 80), 
                child: _pages[index],
              );
            },
          ),

          // LAYER 2: TOP BAR (Glassmorphism / Blur Effect)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(240, 54, 68, 77), // Warna Gelap Transparan
                  boxShadow: [
                    BoxShadow(
                      // PERBAIKAN DI SINI: Menggunakan .withValues(alpha: ...)
                      color: Colors.black.withValues(alpha: 0.2), 
                      blurRadius: 10, 
                      offset: const Offset(0, 5)
                    )
                  ]
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    
                    // A. MENU TENGAH (TOGGLE SWITCH)
                    RepaintBoundary(
                      child: ValueListenableBuilder<int>(
                        valueListenable: selectedIndex,
                        builder: (_, current, __) {
                          return AnimatedToggleSwitch<int>.custom(
                            textDirection: TextDirection.ltr,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            current: current,
                            values: const [0, 1, 2, 3], // Index untuk 4 menu
                            iconOpacity: 0.7,
                            height: 45,
                            indicatorSize: const Size.fromWidth(90),
                            
                            // Builder untuk Teks Menu
                            animatedIconBuilder: (context, local, global) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _menuLabels[local.value],
                                    style: const TextStyle(
                                      color: Colors.black, // Warna teks saat aktif (akan ditimpa styleBuilder)
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                            
                            // Style Background Toggle
                            style: const ToggleStyle(
                              borderColor: Colors.transparent,
                              backgroundColor: Colors.black26, // Warna track belakang
                            ),
                            
                            // Style Indicator (Tombol yang bergerak)
                            styleBuilder: (i) => const ToggleStyle(
                              indicatorGradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF0080FF), // Biru
                                  Color(0xFF00E5FF), // Cyan
                                ],
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            
                            // Logic saat diklik
                            onChanged: (i) {
                              selectedIndex.value = i;
                              pageController.jumpToPage(i); // Pindah halaman
                            },
                          );
                        },
                      ),
                    ),

                    // B. LOGO KIRI & TOMBOL KANAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- LOGO (KIRI) ---
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings, color: Colors.white), // Icon Manager
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "MANAGER PANEL",
                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, height: 1.2),
                                  ),
                                  Text(
                                    "Administrator Mode",
                                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w200),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // --- TOMBOL AKSI (KANAN) ---
                        Row(
                          children: [
                            // Tombol 1: Settings (Opsional, Pemanis)
                            _buildCircleButton(
                              icon: Icons.settings, 
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan Manager")));
                              }
                            ),
                            const SizedBox(width: 10),
                            
                            // Tombol 2: LOGOUT (Penting)
                            _buildCircleButton(
                              icon: Icons.logout, 
                              color: Colors.redAccent,
                              onTap: _handleLogout
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
    );
  }

  // Helper Widget untuk membuat tombol bulat kecil di kanan
  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: color, 
        iconSize: 20,
        tooltip: "Action",
      ),
    );
  }
}