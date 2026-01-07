import 'package:flutter/material.dart';

class WeightMonitorCard extends StatelessWidget {
  final String displayWeight;
  final bool isWeighing;
  final bool isWeighIn;
  final bool isConnected;
  final Color cardBg;
  final Color primaryCyan;
  final Color textGrey;
  final Color textWhite;
  final Color indicatorGreen;
  final VoidCallback onToggleMode;
  final Future<void> Function() onCapture;
  final Future<void> Function() onRetry;

  const WeightMonitorCard({
    super.key,
    required this.displayWeight,
    required this.isWeighing,
    required this.isWeighIn,
    required this.isConnected,
    required this.cardBg,
    required this.primaryCyan,
    required this.textGrey,
    required this.textWhite,
    required this.indicatorGreen,
    required this.onToggleMode,
    required this.onCapture,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggleMode,
                child: Tooltip(
                  message: isWeighIn ? 'Mode: Timbang Masuk (tap to switch)' : 'Mode: Timbang Keluar (tap to switch)',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isConnected ? indicatorGreen : Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: (isConnected ? indicatorGreen.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6)), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Weighing Indicator",
                style: TextStyle(
                  color: textGrey.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "$displayWeight kg",
            style: TextStyle(
              fontSize: 90,
              color: textWhite,
              fontWeight: FontWeight.bold,
              height: 1.0,
              shadows: const [
                Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 6),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isWeighing ? null : () => onCapture(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(isWeighing ? 'Weighing...' : 'Capture Weight', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: () => onRetry(),
                    icon: Icon(Icons.refresh, color: textGrey),
                    tooltip: 'Retry connection',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
