import 'package:dakara_weighbridge/Entities/Manager/abstract_manager.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listtoken_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Manager implements AbstractManager {
  /// Manager Creating Account For Supervisor And Operator
  @override
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  }) async {
    final newAccount = ListAccountJson(
      accountUsername: username,
      accountPassword: password,
      accountPosition: role,
    );
    await DbHelper.instance.addUser(newAccount);
  }

  /// Manager Creating Token For Supervisor To Be Able To Special Transaction
  @override
  Future<void> createTokenForManualWeight() async {
    /// TODO : Finishing create Token for Manual Weight
    await TokenService.createToken();
  }

  /// Manager Deleting Specific Supervisor or Operator by Id
  @override
  Future<void> deleteSupervisorAndOperator({required int id}) async {
    await DbHelper.instance.deleteUser(id: id);
  }

  /// Manager Deleting Specific Transaction by Id
  @override
  Future<void> deleteTransaction({required int transactionId}) async {
    await DbHelper.instance.deleteTransaction(id: transactionId);
  }

  /// get List Supervisor and Operator
  @override
  Future<void> getSupervisorAndOperator() {
    // TODO: implement getSupervisorAndOperator
    throw UnimplementedError();
  }

  /// Update Specific Supervisor and Operator
  @override
  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  }) async {
    final updatedAccount = ListAccountJson(
      accountID: id,
      accountUsername: username,
      accountPassword: password,
      accountPosition: role,
    );
    await DbHelper.instance.updateUser(updatedAccount);
  }
}
