import 'package:dakara_weighbridge/Entities/Operator/abstract_operator.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Need to add export to pdf, excel and print feature
class Operator implements AbstractOperator {
  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final user = await DbHelper.instance.getUserByUsername(username: username);

    if (user.isEmpty || user[0].accountPassword != password) {
      throw InvalidCredentialException();
    }

    // Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('operatorId', user[0].accountID);
    await prefs.setString('operatorName', user[0].accountUsername);
    await prefs.setString('role', user[0].accountPosition);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('operatorId');
    await prefs.remove('operatorName');
    await prefs.remove('role');
  }

  @override
  Future<void> addBrutoTransaction({
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double bruto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedInStatus = prefs.getBool('isLoggedIn');
    final String? roleStatus = prefs.getString('role');

    if (isLoggedInStatus != null && isLoggedInStatus) {
      if (roleStatus != null && roleStatus == 'operator') {
        DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            noTicket: 'WB-${DateTime.now()}',
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
          ),
        );
      }
    }
  }

  @override
  Future<void> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double tare,
    required double nettoAfterCut,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedInStatus = prefs.getBool('isLoggedIn');
    final String? roleStatus = prefs.getString('role');

    if (isLoggedInStatus != null && isLoggedInStatus) {
      if (roleStatus != null && roleStatus == 'operator') {
        final transaction = await DbHelper.instance.getTransactionById(
          id: transactionId,
        );
        await DbHelper.instance.updateTransaction(
          ListTransactionJson(
            vehiclePlate: transaction[0].vehiclePlate,
            driverName: transaction[0].driverName,
            supplierId: transaction[0].supplierId,
            customerId: transaction[0].customerId,
            productId: transaction[0].productId,
            cut: transaction[0].cut,
            noTicket: transaction[0].noTicket,
            inTime: transaction[0].inTime,
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: transaction[0].bruto,
            tare: tare,
            netto: transaction[0].bruto - tare,
            nettoAfterCut: nettoAfterCut / 100 * transaction[0].bruto,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
          ),
        );
      }
    }
  }
}
