import 'package:flutter/services.dart';

/// Clipboard service interface — abstracts clipboard operations for testability
abstract class ClipboardService {
  Future<void> copy(String text);
  Future<String?> paste();
}

/// Default implementation using Flutter's Clipboard API
class ClipboardServiceImpl implements ClipboardService {
  @override
  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
