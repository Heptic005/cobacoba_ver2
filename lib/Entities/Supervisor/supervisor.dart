import 'package:dakara_weighbridge/Entities/Supervisor/abstract_supervisor.dart';
import 'package:dakara_weighbridge/Exception/token_exception.dart';
import 'package:dakara_weighbridge/Exception/transaction_exception.dart';
import 'package:dakara_weighbridge/Exception/user_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listrequesttoken_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Supervisor implements AbstractSupervisor {
  /// Creating Account For Operator
  @override
  Future<void> createOperator({
    required String username,
    required String password,
  }) async {
    try {
      await DbHelper.instance.addUser(
        ListAccountJson(
          accountUsername: username,
          accountPassword: password,
          accountPosition: 'operator',
        ),
      );
    } catch (_) {
      throw UserCreationFailedException('Failed to Create Operator');
    }
  }

  /// Validate Special Transaction Token
  @override
  Future<bool> validateToken(String inputToken) async {
    final token = await DbHelper.instance.getToken(inputToken);
    // print(token!.isExpired);

    if (token == null)
      throw TokenInvalidException('Invalid Manual Weighing Token');
    if (token.isUsed == 1) throw TokenAlreadyUseException('Token Already Used');
    if (token.isExpired) throw TokenExpiredException('Expired Token');

    // tandai sudah dipakai
    await DbHelper.instance.markTokenUsed(inputToken);
    return true;
  }

  /// Creating Request Token
  @override
  Future<void> createRequestToken({required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final supervisorId = prefs.getInt('id');

      await DbHelper.instance.createRequestForManualToken(
        ListRequestTokenJson(
          requestedBy: supervisorId!,
          reason: reason,
          status: 'requesting',
          requestedAt: DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
        ),
      );
    } catch (_) {
      throw TokenRequestCreationException(
        'Failed to Create Request for Special Transaction',
      );
    }
  }

  /// Add Special Transaction by Supervisor
  @override
  Future<void> addEmergencyTransaction({
    String? token,
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
    try {
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
          noTicket: 'MWB-${DateTime.now().millisecondsSinceEpoch}',
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
          isManual: 1,
        ),
      );
    } catch (_) {
      throw TransactionCreationException(
        'Failed to Create Special Transaction',
      );
    }
  }
}
