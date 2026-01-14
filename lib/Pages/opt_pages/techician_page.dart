import 'dart:async';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:flutter/material.dart';

class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
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

  void _sendCmd() {
    if (_cmdController.text.isNotEmpty) {
      _serialService.write("${_cmdController.text}\r\n");
      setState(() {
        _logs.add(">> ${_cmdController.text}");
        _cmdController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2830),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262F36),
        title: const Text(
          "Technician Mode",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPorts,
          ),
        ],
      ),
      body: Row(
        children: [
          // Side Panel: Config
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
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
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

          // Main Panel: Terminal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cmdController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Enter command...",
                            hintStyle: TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Color(0xFF262F36),
                          ),
                          onSubmitted: (_) => _sendCmd(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                        onPressed: _sendCmd,
                      ),
                    ],
                  ),
                  // Quick Commands
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => setState(() => _logs.clear()),
                      child: const Text(
                        "Clear Terminal",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
