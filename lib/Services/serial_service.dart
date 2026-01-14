import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  static final SerialService _instance = SerialService._internal();
  factory SerialService() => _instance;
  SerialService._internal();

  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _readerSub;

  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  bool get isConnected => _port != null && _port!.isOpen;
  String? _connectedPortName;
  String? get connectedPortName => _connectedPortName;

  List<String> get availablePorts => SerialPort.availablePorts;

  /// Connecting to Specific Port
  bool connect(String portName, int baudRate) {
    disconnect();

    try {
      final port = SerialPort(portName);
      if (!port.openReadWrite()) {
        debugPrint("Gagal membuka port");
        return false;
      }

      final config = port.config;
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = 0;
      port.config = config;

      _port = port;
      _connectedPortName = portName;

      _startReader();

      return true;
    } catch (e) {
      debugPrint("Error connecting: $e");
      return false;
    }
  }

  void _startReader() {
    if (_port == null) return;

    _reader = SerialPortReader(_port!);
    _readerSub = _reader!.stream.listen(
      (Uint8List data) {
        if (data.isEmpty) return;
        final text = String.fromCharCodes(data);
        _controller.add(text);
      },
      onError: (e) {
        debugPrint("Serial read error: $e");
      },
      cancelOnError: true,
    );
  }

  void write(String data) {
    if (!isConnected) return;
    _port!.write(Uint8List.fromList(data.codeUnits));
  }

  void disconnect() {
    _readerSub?.cancel();
    _readerSub = null;
    _reader = null;

    if (_port != null) {
      _port!.close();
      _port!.dispose();
      _port = null;
    }

    _connectedPortName = null;
  }
}
