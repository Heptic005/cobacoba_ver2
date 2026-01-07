import 'package:flutter_test/flutter_test.dart';
import 'package:dakara_weighbridge/Pages/transaction_controller.dart';

void main() {
  group('TransactionController', () {
    late TransactionController controller;

    setUp(() {
      controller = TransactionController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Capture Flow', () {
      test('captureBrutoSimulated sets capturedBruto and lastCapturedWeight', () async {
        expect(controller.capturedBruto, isNull);
        
        await controller.captureBrutoSimulated();
        
        expect(controller.capturedBruto, isNotNull);
        expect(controller.capturedBruto, greaterThan(0));
        expect(controller.lastCapturedWeight, equals(controller.capturedBruto));
        expect(controller.isWeighing, isFalse);
      });

      test('captureTareSimulated sets capturedTare and lastCapturedWeight', () async {
        expect(controller.capturedTare, isNull);
        
        await controller.captureTareSimulated();
        
        expect(controller.capturedTare, isNotNull);
        expect(controller.capturedTare, greaterThan(0));
        expect(controller.lastCapturedWeight, equals(controller.capturedTare));
        expect(controller.isWeighing, isFalse);
      });

      test('capture flow: weigh-in then weigh-out produces valid netto', () async {
        // Simulate weigh-in (capture bruto)
        await controller.captureBrutoSimulated();
        final bruto = controller.capturedBruto!;
        
        // Simulate weigh-out (capture tare)
        await controller.captureTareSimulated();
        final tare = controller.capturedTare!;
        
        // Compute netto
        final netto = controller.computeNetto(bruto, tare);
        
        expect(netto, greaterThanOrEqualTo(0));
        expect(netto, equals(bruto - tare));
      });
    });

    group('Computation Methods', () {
      test('computeNetto returns correct value', () {
        expect(controller.computeNetto(5000, 3000), equals(2000));
        expect(controller.computeNetto(3000, 5000), equals(0.0)); // negative clamped to 0
        expect(controller.computeNetto(100, 100), equals(0.0));
      });

      test('computeAfterCut returns correct value', () {
        expect(controller.computeAfterCut(1000, 0), equals(1000)); // no cut
        expect(controller.computeAfterCut(1000, 10), equals(900)); // 10% cut
        expect(controller.computeAfterCut(1000, 50), equals(500)); // 50% cut
        expect(controller.computeAfterCut(1000, 100), equals(0)); // 100% cut
      });

      test('computeTotalPrice returns correct value', () {
        expect(controller.computeTotalPrice(100, 10), equals(1000));
        expect(controller.computeTotalPrice(0, 10), equals(0));
        expect(controller.computeTotalPrice(100, 0), equals(0));
      });

      test('full calculation chain: bruto -> tare -> netto -> afterCut -> totalPrice', () {
        final bruto = 5000.0;
        final tare = 3000.0;
        final cutPct = 10.0;
        final price = 5.0;
        
        final netto = controller.computeNetto(bruto, tare);
        expect(netto, equals(2000.0));
        
        final afterCut = controller.computeAfterCut(netto, cutPct);
        expect(afterCut, equals(1800.0)); // 2000 - 10%
        
        final totalPrice = controller.computeTotalPrice(afterCut, price);
        expect(totalPrice, equals(9000.0)); // 1800 * 5
      });
    });

    group('Ticket Generation', () {
      test('generateTicket creates unique tickets', () {
        final ticket1 = controller.generateTicket();
        final ticket2 = controller.generateTicket();
        
        expect(ticket1, isNotEmpty);
        expect(ticket2, isNotEmpty);
        expect(ticket1, isNot(equals(ticket2)));
        expect(ticket1, contains('T-'));
      });

      test('generateTicket increments counter', () {
        final initialCounter = controller.ticketCounter;
        controller.generateTicket();
        expect(controller.ticketCounter, equals(initialCounter + 1));
      });
    });

    group('Helper Methods', () {
      test('formatDateTime formats correctly', () {
        final dt = DateTime(2024, 12, 31, 23, 59);
        final formatted = controller.formatDateTime(dt);
        expect(formatted, contains('31 Dec 2024'));
        expect(formatted, contains('23:59'));
      });

      test('formatDate formats correctly', () {
        final dt = DateTime(2024, 12, 31);
        final formatted = controller.formatDate(dt);
        expect(formatted, contains('31 Dec 2024'));
      });

      test('formatTime formats correctly', () {
        final dt = DateTime(2024, 12, 31, 23, 59, 58);
        final formatted = controller.formatTime(dt);
        expect(formatted, equals('23:59:58'));
      });
    });

    group('Name Lookup Helpers', () {
      test('productNameFromId returns empty string for null', () {
        expect(controller.productNameFromId(null), isEmpty);
      });

      test('supplierNameFromId returns empty string for null', () {
        expect(controller.supplierNameFromId(null), isEmpty);
      });

      test('customerNameFromId returns empty string for null', () {
        expect(controller.customerNameFromId(null), isEmpty);
      });
    });

    group('Display Computation', () {
      test('computeBrutoDisplay returns capturedBruto when set', () async {
        await controller.captureBrutoSimulated();
        final bruto = controller.computeBrutoDisplay();
        expect(bruto, equals(controller.capturedBruto));
      });

      test('computeTareDisplay returns capturedTare when set', () async {
        await controller.captureTareSimulated();
        final tare = controller.computeTareDisplay();
        expect(tare, equals(controller.capturedTare));
      });
    });

    group('Reset Functionality', () {
      test('resetCapture clears all captured weights', () async {
        // Capture some weights first
        await controller.captureBrutoSimulated();
        await controller.captureTareSimulated();
        
        expect(controller.capturedBruto, isNotNull);
        expect(controller.capturedTare, isNotNull);
        expect(controller.lastCapturedWeight, greaterThan(0));
        
        // Reset
        controller.resetCapture();
        
        // Verify all reset to initial state
        expect(controller.capturedBruto, isNull);
        expect(controller.capturedTare, isNull);
        expect(controller.lastCapturedWeight, equals(0.0));
        expect(controller.currentTicketPreview, isNull);
      });

      test('computeBrutoDisplay and computeTareDisplay return 0 after reset', () async {
        // Capture and verify non-zero
        await controller.captureBrutoSimulated();
        expect(controller.computeBrutoDisplay(), greaterThan(0));
        
        // Reset
        controller.resetCapture();
        
        // Verify display shows 0
        expect(controller.computeBrutoDisplay(), equals(0.0));
        expect(controller.computeTareDisplay(), equals(0.0));
        expect(controller.isJustReset, isTrue);
      });

      test('isJustReset flag clears on new capture', () async {
        // Reset first
        controller.resetCapture();
        expect(controller.isJustReset, isTrue);
        
        // Capture new weight
        await controller.captureBrutoSimulated();
        
        // Flag should be cleared
        expect(controller.isJustReset, isFalse);
        expect(controller.computeBrutoDisplay(), greaterThan(0));
      });
    });
  });
}
