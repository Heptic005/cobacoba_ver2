import 'package:dakara_weighbridge/Entities/Operator/abstract_operator.dart';
import 'package:dakara_weighbridge/Exception/transaction_exception.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';

class Operator implements AbstractOperator {
  /// Operator Creating Bruto Transaction
  /// TODO : First Transaction Maybe Tare First, So Make the Conditional Statement
  /// TODO : Change Function Name and Implementation in UI Because The Weight is Between Bruto and Tare
  @override
  Future<void> addBrutoTransaction({
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    required double bruto,
    bool isBruto = false,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
  }) async {
    try {
      if (isBruto) {
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'WB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: bruto,
            tare: 0,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
          ),
        );
      } else {
        final tare = bruto;
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'WB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: 0,
            tare: tare,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
          ),
        );
      }
    } catch (_) {
      throw TransactionCreationException('Failed to Create Transaction');
    }
  }

  /*
   TODO : MAKE SURE THE CALCULATION IS CORRECT,
    Initial Weight Value Maybe Bruto or Tare,
    So Make The Conditional Statement
   */

  /// Operator Creating Netto Transaction
  @override
  Future<void> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double weight,
  }) async {
    final transaction = await DbHelper.instance.getTransactionById(
      id: transactionId,
    );

    /// TODO : Make Custom Exception
    if (transaction.isEmpty)
      throw TransactionGetFailedException('Not Found Any Transactions');
    final t = transaction[0];
    if (t.bruto != 0) {
      final updated = ListTransactionJson(
        vehiclePlate: t.vehiclePlate,
        driverName: t.driverName,
        supplierId: t.supplierId,
        customerId: t.customerId,
        productId: t.productId,
        cut: t.cut,
        kubikasi: kubikasi ?? t.kubikasi,
        noDO: noDo ?? t.noDO,
        noContainer: noContainer ?? t.noContainer,
        temperature: temperature ?? t.temperature,
        price: t.price,
        additionalInformation: additionalInformation ?? t.additionalInformation,
        noTicket: t.noTicket,
        inTime: t.inTime,
        outTime: DateTime.now(),
        totalPrice:
            t.price == 0
                ? price ??
                    0 *
                        (t.bruto -
                            weight -
                            ((t.bruto - weight) * (t.cut / 100)))
                : t.price! *
                    (t.bruto - weight - ((t.bruto - weight) * (t.cut / 100))),
        bruto: t.bruto,
        tare: weight,
        netto: t.bruto - weight,
        nettoAfterCut: t.bruto - weight - ((t.bruto - weight) * (t.cut / 100)),
        driverLabel: t.driverLabel,
        operatorLabel: t.operatorLabel,
        managerLabel: t.managerLabel,
        headWarehouseLabel: t.headWarehouseLabel,
        isDrafted: 0,
        transactionId: t.transactionId,
        isManual: t.isManual,
      );

      await DbHelper.instance.updateTransaction(updated);
    } else {
      final updated = ListTransactionJson(
        vehiclePlate: t.vehiclePlate,
        driverName: t.driverName,
        supplierId: t.supplierId,
        customerId: t.customerId,
        productId: t.productId,
        cut: t.cut,
        kubikasi: kubikasi ?? t.kubikasi,
        noDO: noDo ?? t.noDO,
        noContainer: noContainer ?? t.noContainer,
        temperature: temperature ?? t.temperature,
        price: t.price,
        additionalInformation: additionalInformation ?? t.additionalInformation,
        noTicket: t.noTicket,
        inTime: t.inTime,
        outTime: DateTime.now(),
        totalPrice:
            t.price == 0
                ? price ??
                    0 * (weight - t.tare - ((weight - t.tare) * (t.cut / 100)))
                : t.price! *
                    (weight - t.tare - ((weight - t.tare) * (t.cut / 100))),
        bruto: weight,
        tare: t.tare,
        netto: weight - t.tare,
        nettoAfterCut: weight - t.tare - ((weight - t.tare) * (t.cut / 100)),
        driverLabel: t.driverLabel,
        operatorLabel: t.operatorLabel,
        managerLabel: t.managerLabel,
        headWarehouseLabel: t.headWarehouseLabel,
        isDrafted: 0,
        transactionId: t.transactionId,
        isManual: t.isManual,
      );
      await DbHelper.instance.updateTransaction(updated);
    }
  }
}
