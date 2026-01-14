import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget displaying weighing mode buttons, clock, and indicator info.
class MainActionsCard extends StatefulWidget {
  // final bool isWeighIn;
  final ValueNotifier<String> timeNotifier;
  final Color primaryCyan;
  final Color textGrey;
  final Color textWhite;
  final Color cardBg;
  final Function(bool mode) onToggleButtonTimbang;

  const MainActionsCard({
    super.key,
    // required this.isWeighIn,
    required this.timeNotifier,
    required this.primaryCyan,
    required this.textGrey,
    required this.textWhite,
    required this.cardBg,
    required this.onToggleButtonTimbang,
  });

  @override
  State<MainActionsCard> createState() => _MainActionsCardState();
}

class _MainActionsCardState extends State<MainActionsCard> {
  bool isWeighIn = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.textGrey.withAlpha((0.12 * 255).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isWeighIn = true;
                  });
                  widget.onToggleButtonTimbang(isWeighIn);
                },
                icon:
                    isWeighIn
                        ? const Icon(Icons.check, size: 20)
                        : const SizedBox.shrink(),
                label: const Text("Timbang Masuk"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isWeighIn ? widget.primaryCyan : Colors.transparent,
                  foregroundColor: isWeighIn ? Colors.black : Colors.white,
                  elevation: 0,
                  side:
                      isWeighIn
                          ? BorderSide.none
                          : BorderSide(
                            color: widget.textGrey.withAlpha(
                              (0.6 * 255).round(),
                            ),
                          ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isWeighIn = false;
                  });
                  widget.onToggleButtonTimbang(isWeighIn);
                },
                icon:
                    !isWeighIn
                        ? const Icon(Icons.check, size: 20)
                        : const SizedBox.shrink(),
                label: const Text("Timbang Keluar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !isWeighIn ? Colors.white : Colors.transparent,
                  foregroundColor: !isWeighIn ? Colors.black : Colors.white,
                  elevation: 0,
                  side:
                      !isWeighIn
                          ? BorderSide.none
                          : BorderSide(
                            color: widget.textGrey.withAlpha(
                              (0.6 * 255).round(),
                            ),
                          ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: widget.timeNotifier,
                builder:
                    (ctx, val, _) => Text(
                      val,
                      style: TextStyle(
                        color: widget.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now()),
                style: TextStyle(color: widget.textGrey),
              ),
              const SizedBox(height: 8),
              Divider(color: widget.textGrey.withAlpha((0.12 * 255).round())),
              const SizedBox(height: 8),
              Text(
                'Indicator : GST-9000',
                style: TextStyle(color: widget.textGrey),
              ),
              Text(
                'Connected to PORT1',
                style: TextStyle(color: widget.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
