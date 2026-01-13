// filepath: test/report_perf_logger_test.dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';
import 'package:dakara_weighbridge/Pages/report/report_perf.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

List<ListTransactionJson> _generateMock(int n) {
  final now = DateTime.now();
  return List.generate(n, (i) {
    return ListTransactionJson(
      vehiclePlate: 'B-1234-XY',
      driverName: 'Driver $i',
      supplierId: i % 10,
      customerId: i % 5,
      productId: i % 3,
      cut: 0,
      noTicket: 'TKT-${i.toString().padLeft(6, '0')}',
      inTime: now.subtract(Duration(minutes: i)),
      outTime: null,
      totalPrice: (100000 + i).toDouble(),
      bruto: 1000 + i.toDouble(),
      tare: 200 + i.toDouble(),
      netto: 800 + i.toDouble(),
      nettoAfterCut: 800 + i.toDouble(),
      driverLabel: 0,
      operatorLabel: 0,
      managerLabel: 0,
      headWarehouseLabel: 0,
    );
  });
}

void main() {
  test('Report perf simulation', () async {
    PerfLogger.instance.clear();
    final mockCount = 800; // realistic but not huge
    developer.log('Generating $mockCount mock transactions...', name: 'report.test');
    final mocks = _generateMock(mockCount);

    // Measure construction / initial processing
    final swInit = Stopwatch()..start();
    final controller = ReportController(initialData: mocks);
    swInit.stop();
    developer.log('Constructor/init took ${swInit.elapsedMilliseconds}ms', name: 'report.test');

    // Measure applyFilters via search
    final swSearch = Stopwatch()..start();
    controller.setSearch('Driver 1');
    // allow debounce to fire
    await Future.delayed(const Duration(milliseconds: 450));
    swSearch.stop();
    developer.log('Search (with debounce) elapsed ${swSearch.elapsedMilliseconds}ms', name: 'report.test');

    // Simulate scrolling: repeatedly call loadMore until exhausted and record times
    final loadTimes = <int>[];
    while (controller.hasMore) {
      final sw = Stopwatch()..start();
      await controller.loadMore();
      sw.stop();
      loadTimes.add(sw.elapsedMilliseconds);
      // small wait to emulate user pacing
      await Future.delayed(const Duration(milliseconds: 20));
    }
    final avgLoad = loadTimes.isEmpty ? 0 : loadTimes.reduce((a, b) => a + b) / loadTimes.length;
    developer.log('loadMore calls: ${loadTimes.length}, avg=${avgLoad}ms', name: 'report.test');

    // Dump PerfLogger internal metrics
    PerfLogger.instance.dumpAll();

    // Simple assertion - not strict, just ensure controller has visible rows
    expect(controller.visible.value.isNotEmpty, true);
  }, timeout: Timeout(Duration(minutes: 2)));
}
