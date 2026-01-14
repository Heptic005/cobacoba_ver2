/// ============================================================================
/// Data Page (UI)
/// ============================================================================
/// File: data_page.dart
/// Deskripsi: Halaman utama untuk Manajemen Data (Supplier, Customer, Product).
///            Halaman ini menampilkan:
///            - Tabs untuk navigasi antar tipe data (Supplier/Customer/Barang)
///            - Search bar untuk filtering data
///            - Tombol "Tambah Baru" untuk Supplier dan Customer
///            - List/Table data sesuai tab yang aktif
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/data_controller.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/widgets/add_entity_dialog.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/widgets/supplier_list.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/widgets/customer_list.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/data/widgets/product_list.dart';

// Palet warna diselaraskan dengan halaman Transaction/Report
const Color _bgDark = Color(0xFF17181A);
const Color _cardBg = Color(0xFF23262B);
const Color _inputBg = Color(0xFF191A1C);
const Color _primaryCyan = Color(0xFF00E5C3);
const Color _textGrey = Color(0xFF9E9E9E);
const Color _textWhite = Colors.white;

/// Widget utama untuk halaman Data Management
/// Menggunakan ChangeNotifierProvider untuk menyediakan DataController
class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataController()..loadAllData(),
      child: const _DataPageContent(),
    );
  }
}

/// Content widget yang menggunakan DataController dari Provider
class _DataPageContent extends StatelessWidget {
  const _DataPageContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: SingleChildScrollView(
        // Tambah jarak top agar judul tidak tertimpa header global
        padding: const EdgeInsets.fromLTRB(50, 80, 50, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const _HeaderSection(),
            const SizedBox(height: 24),

            // Tab Buttons
            const _TabButtons(),
            const SizedBox(height: 24),

            // Search & Action Bar
            const _SearchActionBar(),
            const SizedBox(height: 8),

            // Data Container
            Container(
              constraints: const BoxConstraints(minHeight: 400),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const _DataContent(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header section dengan judul dan deskripsi
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manajemen Data',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kelola supplier, customer, dan barang',
          style: TextStyle(fontSize: 14, color: _textGrey),
        ),
      ],
    );
  }
}

/// Tab buttons untuk navigasi antar data type
class _TabButtons extends StatelessWidget {
  const _TabButtons();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, controller, _) {
        return Row(
          children: [
            _TabButton(
              icon: Icons.business,
              label: 'Supplier',
              count: controller.supplierCount,
              isActive: controller.activeTab == DataTab.supplier,
              onTap: () => controller.setActiveTab(DataTab.supplier),
            ),
            const SizedBox(width: 12),
            _TabButton(
              icon: Icons.people,
              label: 'Customer',
              count: controller.customerCount,
              isActive: controller.activeTab == DataTab.customer,
              onTap: () => controller.setActiveTab(DataTab.customer),
            ),
            const SizedBox(width: 12),
            _TabButton(
              icon: Icons.inventory_2_outlined,
              label: 'Barang',
              count: controller.productCount,
              isActive: controller.activeTab == DataTab.product,
              onTap: () => controller.setActiveTab(DataTab.product),
            ),
          ],
        );
      },
    );
  }
}

/// Single tab button widget
class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? _primaryCyan : _cardBg,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isActive ? _textWhite : _textGrey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _textWhite : _textGrey,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? _textWhite.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? _textWhite : _textGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search bar dan action button
class _SearchActionBar extends StatelessWidget {
  const _SearchActionBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, controller, _) {
        // Tentukan apakah tombol tambah harus ditampilkan
        // Product tidak bisa ditambah
        final showAddButton = controller.activeTab != DataTab.product;

        return Row(
          children: [
            // Search Box
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  onChanged: controller.updateSearchQuery,
                  style: const TextStyle(color: _textWhite),
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    hintStyle: TextStyle(color: _textGrey),
                    prefixIcon: const Icon(Icons.search, color: _textGrey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Add Button (hanya untuk Supplier dan Customer)
            if (showAddButton)
              ElevatedButton.icon(
                onPressed: () => _handleAddNew(context, controller),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryCyan,
                  foregroundColor: _textWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Handle tombol tambah baru
  void _handleAddNew(BuildContext context, DataController controller) {
    final entityType =
        controller.activeTab == DataTab.supplier
            ? EntityType.supplier
            : EntityType.customer;

    AddEntityDialog.show(
      context: context,
      entityType: entityType,
      controller: controller,
    );
  }
}

/// Container untuk menampilkan data list
class _DataContent extends StatelessWidget {
  const _DataContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataController>(
      builder: (context, controller, _) {
        // Handle error state
        if (controller.errorMessage != null) {
          return _ErrorWidget(
            message: controller.errorMessage!,
            onRetry: controller.loadAllData,
          );
        }

        // Count info
        final countText = _getCountText(controller);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Count info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                countText,
                style: TextStyle(fontSize: 13, color: _textGrey),
              ),
            ),

            // Data list berdasarkan tab aktif
            SizedBox(height: 400, child: _buildActiveTabContent(controller)),
          ],
        );
      },
    );
  }

  String _getCountText(DataController controller) {
    switch (controller.activeTab) {
      case DataTab.supplier:
        return 'Menampilkan ${controller.suppliers.length} entri';
      case DataTab.customer:
        return 'Menampilkan ${controller.customers.length} entri';
      case DataTab.product:
        return 'Menampilkan ${controller.products.length} entri';
    }
  }

  Widget _buildActiveTabContent(DataController controller) {
    switch (controller.activeTab) {
      case DataTab.supplier:
        return SupplierList(
          suppliers: controller.suppliers,
          isLoading: controller.isLoading,
        );
      case DataTab.customer:
        return CustomerList(
          customers: controller.customers,
          isLoading: controller.isLoading,
        );
      case DataTab.product:
        return ProductList(
          products: controller.products,
          isLoading: controller.isLoading,
        );
    }
  }
}

/// Widget untuk menampilkan error state
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryCyan,
                foregroundColor: _textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
