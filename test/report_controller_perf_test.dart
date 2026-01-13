import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

List<ListTransactionJson> generateTransactions(int n) {
  final rand = Random(42);
  final now = DateTime.now();
  return List.generate(n, (i) {
    final bruto = 1000 + rand.nextDouble() * 2000;
    final tare = rand.nextDouble() * 200;
    final netto = bruto - tare;
    final afterCut = netto * 0.98;
    return ListTransactionJson(
      vehiclePlate: 'B ${1000 + i}',
      driverName: 'Driver $i',
      supplierId: rand.nextInt(10) + 1,
      customerId: rand.nextInt(10) + 1,
      productId: rand.nextInt(10) + 1,
      cut: 2,
      kubikasi: 0,
      noDO: '',
      noContainer: 0,
      temperature: 25.0 + rand.nextDouble() * 5,
      price: 100.0 + rand.nextDouble() * 50,
      additionalInformation: '',
      noTicket: 'TICKET-${i.toString().padLeft(6, '0')}',
      inTime: now.subtract(Duration(minutes: i)),
      outTime: now.add(Duration(minutes: 5)),
      totalPrice: (afterCut * (100 + rand.nextDouble() * 50)),
      bruto: bruto,
      tare: tare,
      netto: netto,
      nettoAfterCut: afterCut,
      driverLabel: 0,
      operatorLabel: 0,
      managerLabel: 0,
      headWarehouseLabel: 0,
    );
  });
}

void main() {
  test('ReportController perf smoke test', () async {
    final dataCount = 2000; // adjust to simulate load
    developer.log('Generating $dataCount transactions...', name: 'perf_test');
    final data = generateTransactions(dataCount);

    // measure construction + initial filter
    final swInit = Stopwatch()..start();
    final controller = ReportController(initialData: data);
    swInit.stop();
    developer.log('init+applyFilters: ${swInit.elapsedMilliseconds} ms', name: 'perf_test');

    // measure search filtering
    final swSearch = Stopwatch()..start();
    controller.setSearch('TICKET-000100');
    swSearch.stop();
    developer.log('setSearch (applyFilters): ${swSearch.elapsedMilliseconds} ms', name: 'perf_test');

    // measure page navigation (using controller.pageItems/nextPage)
    final swPage = Stopwatch()..start();
    var items = controller.pageItems();
    swPage.stop();
    developer.log('pageItems (initial): ${swPage.elapsedMilliseconds} ms, count=${items.length}', name: 'perf_test');

    final swMulti = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      controller.nextPage();
      items = controller.pageItems();
    }
    swMulti.stop();
    developer.log('5x nextPage+pageItems: ${swMulti.elapsedMilliseconds} ms, lastPageCount=${items.length}', name: 'perf_test');

    // simple aggregate check
    developer.log('current visible page size: ${controller.pageItems().length}', name: 'perf_test');
    developer.log('total filtered: ${controller.shown.value.length}', name: 'perf_test');

    controller.dispose();
  }, timeout: Timeout.none);
}
