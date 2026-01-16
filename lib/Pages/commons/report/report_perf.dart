// filepath: lib/Pages/report/report_perf.dart
import 'dart:collection';
import 'dart:developer' as developer;

/// Simple perf logger to record milliseconds for named operations.
class PerfLogger {
  PerfLogger._internal();
  static final PerfLogger instance = PerfLogger._internal();

  final Map<String, List<int>> _records = HashMap();

  void record(String name, int ms) {
    _records.putIfAbsent(name, () => <int>[]).add(ms);
    developer.log('Perf [$name]: ${ms}ms', name: 'report.perf');
  }

  double average(String name) {
    final r = _records[name];
    if (r == null || r.isEmpty) return 0.0;
    final total = r.fold<int>(0, (p, e) => p + e);
    return total / r.length;
  }

  void dumpAll() {
    _records.forEach((k, v) {
      final avg = v.isEmpty ? 0 : v.fold<int>(0, (p, e) => p + e) ~/ v.length;
      developer.log('PerfSummary [$k]: avg=${avg}ms count=${v.length}', name: 'report.perf');
    });
  }

  void clear() => _records.clear();
}
