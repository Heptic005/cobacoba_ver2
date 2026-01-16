import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class ConfigService {
  static const _dirPath = 'C:/ProgramData/Daprin';
  static const _fileName = 'config.json';

  Future<File> _getFile() async {
    final dir = Directory(_dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  Future<void> initConfig() async {
    final file = await _getFile();

    if (!await file.exists()) {
      final defaultConfig = await rootBundle.loadString(
        'assets/default_config.json',
      );
      await file.writeAsString(defaultConfig);
    }
  }

  Future<Map<String, dynamic>> load() async {
    final file = await _getFile();
    final jsonString = await file.readAsString();
    return jsonDecode(jsonString);
  }

  Future<void> save(Map<String, dynamic> newConfig) async {
    final file = await _getFile();
    final jsonString = const JsonEncoder.withIndent('  ').convert(newConfig);
    await file.writeAsString(jsonString, flush: true);
  }
}
