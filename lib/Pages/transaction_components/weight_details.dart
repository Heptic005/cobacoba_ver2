import 'package:flutter/material.dart';

class WeightDetails extends StatelessWidget {
  final String bruto;
  final String tare;
  final String netto;
  final String afterCut;
  final String totalPrice;
  final Color textGrey;
  final Color cardBg;

  const WeightDetails({
    super.key,
    required this.bruto,
    required this.tare,
    required this.netto,
    required this.afterCut,
    required this.totalPrice,
    required this.textGrey,
    required this.cardBg,
  });

  Widget _detailCard(String label, String value) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textGrey.withAlpha((0.12 * 255).round())),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textGrey, fontSize: 13)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _detailCard("Bruto", bruto),
        const SizedBox(height: 16),
        _detailCard("Tara", tare),
        const SizedBox(height: 16),
        _detailCard("Netto", netto),
        const SizedBox(height: 12),
        _detailCard("After cut", afterCut),
        const SizedBox(height: 12),
        _detailCard("Total Price", totalPrice),
      ],
    );
  }
}
