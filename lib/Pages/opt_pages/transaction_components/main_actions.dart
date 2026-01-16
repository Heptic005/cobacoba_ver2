import 'dart:async';

import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget displaying weighing mode buttons, clock, and indicator info.
class MainActionsCard extends StatefulWidget {
  final ValueNotifier<String> timeNotifier;
  final Color primaryCyan;
  final Color textGrey;
  final Color textWhite;
  final Color cardBg;
  final Function(bool mode) onToggleButtonTimbang;
  final Function(bool connectionStatus) onToggleButtonConection;

  const MainActionsCard({
    super.key,
    required this.timeNotifier,
    required this.primaryCyan,
    required this.textGrey,
    required this.textWhite,
    required this.cardBg,
    required this.onToggleButtonTimbang,
    required this.onToggleButtonConection,
  });

  @override
  State<MainActionsCard> createState() => _MainActionsCardState();
}

class _MainActionsCardState extends State<MainActionsCard> {
  bool isWeighIn = true;
  final SerialService _serialService = SerialService();
  final ScrollController _scrollController = ScrollController();

  List<String> _ports = [];
  String? _selectedPort;
  int _selectedBaudRate = 9600;
  bool _isConnected = false;

  final List<String> _logs = [];
  StreamSubscription<String>? _subscription;
  final TextEditingController _cmdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshPorts();
    _isConnected = _serialService.isConnected;
    _selectedPort = _serialService.connectedPortName;
    if (_isConnected) {
      _startListening();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _refreshPorts() {
    setState(() {
      _ports = _serialService.availablePorts;
      if (_ports.isNotEmpty && _selectedPort == null) {
        _selectedPort = _ports.first;
      }
    });
  }

  void _toggleConnection() {
    if (_isConnected) {
      _subscription?.cancel();
      _subscription = null;

      _serialService.disconnect();

      widget.onToggleButtonConection(false);
      setState(() => _isConnected = false);
    } else {
      if (_selectedPort == null) return;

      bool success = _serialService.connect(_selectedPort!, _selectedBaudRate);
      if (success) {
        widget.onToggleButtonConection(true);
        setState(() => _isConnected = true);
        _startListening();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to connect")));
      }
    }
  }

  void _startListening() {
    _subscription?.cancel(); // cegah double listen

    _subscription = _serialService.stream.listen(
      (data) {
        if (!mounted) return;

        setState(() {
          _logs.add(data);

          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _logs.add("Error: $err"));
      },
    );
  }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 200,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Connection Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedPort,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF36444D),
                      decoration: const InputDecoration(
                        labelText: "Port",
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                      items:
                          _ports
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedPort = v),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _selectedBaudRate,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF36444D),
                      decoration: const InputDecoration(
                        labelText: "Baud Rate",
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                      items:
                          [9600, 19200, 38400, 57600, 115200]
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b.toString()),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedBaudRate = v!),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _toggleConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isConnected
                                  ? Colors.redAccent
                                  : const Color(0xFF00E5FF),
                        ),
                        child: Text(
                          _isConnected ? "DISCONNECT" : "CONNECT",
                          style: TextStyle(
                            color: _isConnected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
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
                    DateFormat(
                      "EEEE, d MMMM yyyy",
                      "id_ID",
                    ).format(DateTime.now()),
                    style: TextStyle(color: widget.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: widget.textGrey.withAlpha((0.12 * 255).round()),
                  ),
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
            ],
          ),
        ),
      ],
    );
  }
}
