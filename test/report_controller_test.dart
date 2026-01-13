/// Unit test untuk ReportController
/// Verifikasi: filter, search, sort, pagination, aggregate

import 'package:flutter_test/flutter_test.dart';
import 'package:dakara_weighbridge/Pages/report/report_controller.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

void main() {
  group('ReportController', () {
    late List<ListTransactionJson> sampleData;

    setUp(() {
      sampleData = [
        ListTransactionJson(
          transactionId: 1,
          noTicket: 'T-001',
          vehiclePlate: 'B 123 ABC',
          driverName: 'Driver A',
          supplierId: 10,
          customerId: 1,
          productId: 100,
          cut: 0,
          bruto: 5000,
          tare: 1000,
          netto: 4000,
          nettoAfterCut: 4000,
          totalPrice: 400000,
          inTime: DateTime(2026, 1, 5, 10, 0),
          outTime: DateTime(2026, 1, 5, 11, 0),
          driverLabel: 1,
          operatorLabel: 1,
          managerLabel: 1,
          headWarehouseLabel: 1,
        ),
        ListTransactionJson(
          transactionId: 2,
          noTicket: 'T-002',
          vehiclePlate: 'B 456 DEF',
          driverName: 'Driver B',
          supplierId: 20,
          customerId: 1,
          productId: 100,
          cut: 0,
          bruto: 6000,
          tare: 1000,
          netto: 5000,
          nettoAfterCut: 5000,
          totalPrice: 500000,
          inTime: DateTime(2026, 1, 6, 10, 0),
          outTime: DateTime(2026, 1, 6, 11, 0),
          driverLabel: 1,
          operatorLabel: 1,
          managerLabel: 1,
          headWarehouseLabel: 1,
        ),
        ListTransactionJson(
          transactionId: 3,
          noTicket: 'T-003',
          vehiclePlate: 'B 789 GHI',
          driverName: 'Driver C',
          supplierId: 10,
          customerId: 2,
          productId: 200,
          cut: 100,
          bruto: 7000,
          tare: 1500,
          netto: 5500,
          nettoAfterCut: 5400,
          totalPrice: 540000,
          inTime: DateTime(2026, 1, 7, 14, 0),
          outTime: DateTime(2026, 1, 7, 15, 0),
          driverLabel: 1,
          operatorLabel: 1,
          managerLabel: 1,
          headWarehouseLabel: 1,
        ),
      ];
    });

    test('initializes with all data and computes aggregate', () {
      final controller = ReportController(initialData: sampleData);

      expect(controller.shown.value.length, 3);

      final agg = controller.aggregate.value;
      expect(agg['count'], 3);
      expect(agg['totalNetto'], 14500); // 4000 + 5000 + 5500
      expect(agg['revenue'], 1440000); // 400000 + 500000 + 540000
    });

    test('filters by supplier', () {
      final controller = ReportController(initialData: sampleData);

      controller.setSupplier(10);
      expect(controller.shown.value.length, 2);

      final agg = controller.aggregate.value;
      expect(agg['count'], 2);
      expect(agg['totalNetto'], 9500); // 4000 + 5500
      expect(agg['revenue'], 940000); // 400000 + 540000
    });

    test('filters by product', () {
      final controller = ReportController(initialData: sampleData);

      controller.setProduct(200);
      expect(controller.shown.value.length, 1);

      final agg = controller.aggregate.value;
      expect(agg['count'], 1);
      expect(agg['totalNetto'], 5500);
      expect(agg['revenue'], 540000);
    });

    test('filters by search query', () {
      final controller = ReportController(initialData: sampleData);

      controller.setSearch('T-002');
      expect(controller.shown.value.length, 1);
      expect(controller.shown.value.first.noTicket, 'T-002');

      controller.setSearch('B 789');
      expect(controller.shown.value.length, 1);
      expect(controller.shown.value.first.vehiclePlate, 'B 789 GHI');

      controller.setSearch('Driver A');
      expect(controller.shown.value.length, 1);
      expect(controller.shown.value.first.driverName, 'Driver A');
    });

    test('filters by date range', () {
      final controller = ReportController(initialData: sampleData);

      controller.setStartDate(DateTime(2026, 1, 6));
      expect(controller.shown.value.length, 2); // T-002 and T-003

      controller.setEndDate(DateTime(2026, 1, 6));
      expect(controller.shown.value.length, 1); // only T-002
      expect(controller.shown.value.first.noTicket, 'T-002');
    });

    test('sorts by inTime descending by default', () {
      final controller = ReportController(initialData: sampleData);

      expect(controller.sortDesc, true);
      expect(controller.shown.value.first.noTicket, 'T-003'); // newest first
      expect(controller.shown.value.last.noTicket, 'T-001'); // oldest last
    });

    test('toggleSort changes order', () {
      final controller = ReportController(initialData: sampleData);

      controller.toggleSort();
      expect(controller.sortDesc, false);
      expect(controller.shown.value.first.noTicket, 'T-001'); // oldest first
      expect(controller.shown.value.last.noTicket, 'T-003'); // newest last
    });

    test('clearFilters resets all filters', () {
      final controller = ReportController(initialData: sampleData);

      controller.setSupplier(10);
      controller.setProduct(100);
      controller.setSearch('test');
      controller.setStartDate(DateTime(2026, 1, 1));
      controller.toggleSort();

      controller.clearFilters();

      expect(controller.supplierId, null);
      expect(controller.productId, null);
      expect(controller.search, '');
      expect(controller.startDate, null);
      expect(controller.sortDesc, true);
      expect(controller.shown.value.length, 3);
    });

    test('combined filters work together', () {
      final controller = ReportController(initialData: sampleData);

      controller.setSupplier(10);
      controller.setSearch('Driver C');

      expect(controller.shown.value.length, 1);
      expect(controller.shown.value.first.noTicket, 'T-003');
    });
  });
}
