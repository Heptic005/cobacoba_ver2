import 'dart:async';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:dakara_weighbridge/Services/config_service.dart';
import 'package:dakara_weighbridge/Services/serial_service.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  /// Test
  final _configService = ConfigService();
  String _port = 'COM1';
  int _baudRate = 9600;

  ///
  final SerialService _serialService = SerialService();
  final ScrollController _scrollController = ScrollController();

  List<String> _ports = [];
  String? _selectedPort;
  bool _isConnected = false;

  final List<String> _logs = [];
  StreamSubscription<String>? _subscription;
  final TextEditingController _cmdController = TextEditingController();

  /// User Name
  String? _username = '';

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('name');
  }

  @override
  void initState() {
    super.initState();

    /// Load Username
    _loadUsername();

    /// Latest Config File
    _loadConfig();

    /// Look For Available Ports
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

  Future<void> _loadConfig() async {
    final config = await _configService.load();
    setState(() {
      _port = config['serial']['port'];
      _baudRate = config['serial']['baudRate'];
    });
  }

  Future<void> _save() async {
    final config = await _configService.load();

    config['serial']['port'] = _port;
    config['serial']['baudRate'] = _baudRate;

    await _configService.save(config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Config disimpan. Reconnect diperlukan')),
    );
  }

  void _refreshPorts() {
    setState(() {
      _ports = _serialService.availablePorts;
      if (_ports.isNotEmpty && _selectedPort == null) {
        _selectedPort = _ports.first;
      }
    });
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
          PopupMenuButton(
            onSelected: (v) {
              if (v == 'refresh') {
                _refreshPorts;
              }
              if (v == 'logout') {
                AuthService().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Dashboard();
                    },
                  ),
                );
              }
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text('Hello Teknisi $_username'),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: const Text('Refresh Port'),
                  ),
                  PopupMenuItem(value: 'logout', child: const Text('Logout')),
                ],
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Row(
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
                  value: _port,
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
                  onChanged: (v) => setState(() => _port = v!),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: _baudRate,
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
                  onChanged: (v) => setState(() => _baudRate = v!),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.black,
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
