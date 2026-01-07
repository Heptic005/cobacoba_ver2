/// Print service interface — abstracts printing for testability and platform-specific implementations
abstract class PrintService {
  Future<void> print(String content);
  bool isAvailable();
}

/// Stub implementation for testing and development
class PrintServiceStub implements PrintService {
  @override
  Future<void> print(String content) async {
    // TODO: Integrate real printing (e.g., flutter_pos_printer, pdf package)
    // For now, this is a no-op stub
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  bool isAvailable() {
    return false; // stub not connected to real printer
  }
}
