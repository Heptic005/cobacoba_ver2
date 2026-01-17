import 'package:dakara_weighbridge/Pages/opt_pages/dashboard.dart';
import 'package:dakara_weighbridge/Pages/opt_pages/transaction_components/bruto_transaction_search_bar.dart';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:flutter/material.dart';

class WeightMonitorCard extends StatefulWidget {
  final bool isWeighIn;
  final bool isBruto;
  final Color cardBg;
  final Color primaryCyan;
  final Color textGrey;
  final Color textWhite;
  final void Function(double weight, bool isBruto) onCaptured;

  const WeightMonitorCard({
    super.key,
    required this.isWeighIn,
    required this.cardBg,
    required this.primaryCyan,
    required this.textGrey,
    required this.textWhite,
    required this.onCaptured,
    required this.isBruto,
  });

  @override
  State<WeightMonitorCard> createState() => _WeightMonitorCardState();
}

class _WeightMonitorCardState extends State<WeightMonitorCard> {
  double? _displayWeight;
  bool _isCaptured = false;
  bool _isBruto = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isWeighIn ? "Timbang Masuk" : "Timbang Keluar",
                      style: TextStyle(
                        color: widget.textGrey.withAlpha((0.85 * 255).round()),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    widget.isWeighIn
                        ? ElevatedButton.icon(
                          onPressed: () {
                            _isCaptured
                                ? null
                                : setState(() {
                                  _isBruto = !_isBruto;
                                });
                          },
                          label:
                              _isBruto
                                  ? const Text("Bruto")
                                  : const Text("Tare"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryCyan,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            side: BorderSide.none,
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
                        )
                        : const SizedBox(),
                  ],
                ),
              ),
            ],
          ),
          StreamBuilder(
            stream: SerialService().stream,
            builder: (context, snapshot) {
              if (!_isCaptured && snapshot.hasData) {
                _displayWeight = double.tryParse(snapshot.data!);
              }

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _displayWeight == null
                          ? '-- KG'
                          : "${_displayWeight!.toString()} KG",
                      style: TextStyle(
                        fontSize: 80,
                        color: widget.textWhite,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        widget.isWeighIn
                            ? ValueListenableBuilder(
                              valueListenable: OperatorDashboard.isConnected,
                              builder: (context, isConnected, _) {
                                return isConnected
                                    ? Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            (_displayWeight == null ||
                                                    _isCaptured)
                                                ? null
                                                : () {
                                                  setState(() {
                                                    _isCaptured = true;
                                                  });
                                                  widget.onCaptured(
                                                    _displayWeight!,
                                                    _isBruto,
                                                  );
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: widget.primaryCyan,
                                          foregroundColor: Colors.black,
                                          elevation: 4,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                          ),
                                          child: Text(
                                            _isCaptured
                                                ? "Captured"
                                                : "Capture Weight",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    : Expanded(
                                      child: ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: widget.primaryCyan,
                                          foregroundColor: Colors.black,
                                          elevation: 4,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                          ),
                                          child: Text(
                                            _isCaptured
                                                ? "Captured"
                                                : "Capture Weight",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                              },
                            )
                            : ValueListenableBuilder(
                              valueListenable: OperatorDashboard.isConnected,
                              builder: (context, isConnected, _) {
                                return isConnected
                                    ? ValueListenableBuilder(
                                      valueListenable:
                                          SearchTicketField.isSelected,
                                      builder: (context, isSelected, _) {
                                        return isSelected
                                            ? Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                    (_displayWeight == null ||
                                                            _isCaptured)
                                                        ? null
                                                        : () {
                                                          setState(() {
                                                            _isCaptured = true;
                                                          });
                                                          widget.onCaptured(
                                                            _displayWeight!,
                                                            _isBruto,
                                                          );
                                                        },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      widget.primaryCyan,
                                                  foregroundColor: Colors.black,
                                                  elevation: 4,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 18,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6.0,
                                                      ),
                                                  child: Text(
                                                    _isCaptured
                                                        ? "Captured"
                                                        : "Capture Weight",
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            : Expanded(
                                              child: ElevatedButton(
                                                onPressed: null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      widget.primaryCyan,
                                                  foregroundColor: Colors.black,
                                                  elevation: 4,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 18,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6.0,
                                                      ),
                                                  child: Text(
                                                    _isCaptured
                                                        ? "Captured"
                                                        : "Capture Weight",
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                      },
                                    )
                                    : Expanded(
                                      child: ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: widget.primaryCyan,
                                          foregroundColor: Colors.black,
                                          elevation: 4,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                          ),
                                          child: Text(
                                            _isCaptured
                                                ? "Captured"
                                                : "Capture Weight",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                              },
                            ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isCaptured = false;
                                  _displayWeight = null;
                                  // widget.onCaptured(0);
                                });
                              },
                              icon: Icon(Icons.refresh, color: widget.textGrey),
                              tooltip: 'Retry Capture',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
