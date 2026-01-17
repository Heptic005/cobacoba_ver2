/// Deskripsi: Widget untuk menampilkan daftar product/barang dalam format tabel.

import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Themes/app_themes.dart';

/// Widget list untuk menampilkan data product
class ProductList extends StatelessWidget {
  /// Daftar product yang akan ditampilkan
  final List<ListProductJson> products;

  /// Callback ketika loading
  final bool isLoading;

  const ProductList({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppThemes.primaryCyan),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.inbox_outlined, size: 64, color: AppThemes.blueGrey),
              SizedBox(height: 12),
              Text(
                'Tidak ada data barang',
                style: TextStyle(color: AppThemes.textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 120,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final rowIndex = index ~/ 4;
        final gradientPair = AppThemes.productGradients[
          (index + rowIndex) % AppThemes.productGradients.length];

        return _ProductCard(
          product: product,
          gradientColors: gradientPair,
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ListProductJson product;
  final List<Color> gradientColors;

  const _ProductCard({required this.product, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                product.productCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
