import 'dart:async';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:flutter/material.dart';

class WeightCountFromSerial extends StatefulWidget {
  const WeightCountFromSerial({super.key});

  @override
  State<WeightCountFromSerial> createState() => _WeightCountFromSerialState();
}

class _WeightCountFromSerialState extends State<WeightCountFromSerial> {
  final SerialService _serialService = SerialService();
  final ScrollController _scrollController = ScrollController();

  List<String> _ports = [];
  String? _selectedPort;
  int _selectedBaudRate = 9600;
  bool _isConnected = false;

  final List<String> _logs = [];
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _refreshPorts();
    _isConnected = _serialService.isConnected;
    _selectedPort = _serialService.connectedPortName;

    if (_isConnected) {
      _startListening(); // ✅ ini benar
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

      setState(() => _isConnected = false);
    } else {
      if (_selectedPort == null) return;

      bool success = _serialService.connect(_selectedPort!, _selectedBaudRate);
      if (success) {
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
    return Row(
      children: [
        Container(
          width: 300,
          color: const Color(0xFF262F36),
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
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
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
      ],
    );
  }
}
