import 'package:flutter/material.dart';

class WeightMonitorManualCard extends StatefulWidget {
  final bool isWeighIn;
  final Color cardBg;
  final Color primaryCyan;
  final Color textGrey;
  final Color textWhite;
  final void Function(double weight) onCaptured;

  const WeightMonitorManualCard({
    super.key,
    required this.isWeighIn,
    required this.cardBg,
    required this.primaryCyan,
    required this.textGrey,
    required this.textWhite,
    required this.onCaptured,
  });

  @override
  State<WeightMonitorManualCard> createState() =>
      _WeightMonitorManualCardState();
}

class _WeightMonitorManualCardState extends State<WeightMonitorManualCard> {
  final TextEditingController _manualController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isRequireToken = true;

  double? _displayWeight;
  bool _isCaptured = false;

  @override
  void dispose() {
    _manualController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _captureWeight() {
    final value = double.tryParse(_manualController.text);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berat manual tidak valid')));
      return;
    }

    // if (_isRequireToken && _tokenController.text.isEmpty) {
    //   _showError('Token Supervisor Wajib Di Isi');
    //   return;
    // }

    setState(() {
      _displayWeight = value;
      _isCaptured = true;
    });

    widget.onCaptured(value);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() {
    setState(() {
      _displayWeight = null;
      _isCaptured = false;
      _manualController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
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
          /// TITLE
          Row(
            children: [
              const SizedBox(width: 10),
              Text(
                widget.isWeighIn
                    ? "Timbang Masuk (Manual)"
                    : "Timbang Keluar (Manual)",
                style: TextStyle(
                  color: widget.textGrey.withAlpha((0.85 * 255).round()),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// DISPLAY
          Text(
            _displayWeight == null
                ? '-- KG'
                : "${_displayWeight!.toStringAsFixed(2)} KG",
            style: TextStyle(
              fontSize: 72,
              color: widget.textWhite,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 20),

          /// INPUT
          TextField(
            controller: _manualController,
            enabled: !_isCaptured,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Masukkan berat manual',
              filled: true,
              fillColor: Colors.white.withAlpha((0.08 * 255).round()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: widget.textWhite, fontSize: 18),
          ),

          const Spacer(),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCaptured ? null : _captureWeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isCaptured ? 'Captured' : 'Capture Manual',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _reset,
                icon: Icon(Icons.refresh, color: widget.textGrey),
                tooltip: 'Reset',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
