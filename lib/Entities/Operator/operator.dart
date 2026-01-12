import 'package:dakara_weighbridge/Entities/Operator/abstract_operator.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO : Need to add export to pdf, excel and print feature
class Operator implements AbstractOperator {
  @override
  Future<int> addBrutoTransaction({
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    required double bruto,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedInStatus = prefs.getBool('isLoggedIn');
    final String? roleStatus = prefs.getString('role');
    if (isLoggedInStatus == true && roleStatus == 'operator') {
      final id = await DbHelper.instance.addTransaction(
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
      return id;
    }
    return -1;
  }

  @override
  Future<int> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double tare,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedInStatus = prefs.getBool('isLoggedIn');
    final String? roleStatus = prefs.getString('role');
    if (isLoggedInStatus == true && roleStatus == 'operator') {
      final transaction = await DbHelper.instance.getTransactionById(
        id: transactionId,
      );
      if (transaction.isEmpty) return 0;
      final t = transaction[0];
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
        price: price ?? t.price,
        additionalInformation: additionalInformation ?? t.additionalInformation,
        noTicket: t.noTicket,
        inTime: t.inTime,
        outTime: DateTime.now(),
        totalPrice: 0,
        bruto: t.bruto,
        tare: tare,
        netto: t.bruto - tare,
        nettoAfterCut: 0,
        driverLabel: t.driverLabel,
        operatorLabel: t.operatorLabel,
        managerLabel: t.managerLabel,
        headWarehouseLabel: t.headWarehouseLabel,
        isDrafted: 0,
        transactionId: t.transactionId,
      );
      return await DbHelper.instance.updateTransaction(updated);
    }
    return 0;
  }
}
