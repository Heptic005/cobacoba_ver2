import 'package:dakara_weighbridge/Entities/Manager/abstract_manager.dart';
import 'package:dakara_weighbridge/Exception/token_exception.dart';
import 'package:dakara_weighbridge/Exception/transaction_exception.dart';
import 'package:dakara_weighbridge/Exception/user_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';

class Manager implements AbstractManager {
  /// Manager Creating Account For Supervisor And Operator
  @override
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final newAccount = ListAccountJson(
        accountUsername: username,
        accountPassword: password,
        accountPosition: role,
      );
      await DbHelper.instance.addUser(newAccount);
    } catch (_) {
      throw UserCreationFailedException(
        'Failed To Create New Supervisor or Operator',
      );
    }
  }

  /// Manager Creating Token For Supervisor To Be Able To Special Transaction
  @override
  Future<String> createTokenForManualWeight() async {
    try {
      final token = await TokenService.createToken();
      return token.tokenCode;
    } catch (_) {
      throw TokenCreationException(
        'Failed to Create Token for Special Transaction',
      );
    }
  }

  /// Manager Deleting Specific Supervisor or Operator by Id
  @override
  Future<void> deleteSupervisorAndOperator({required int id}) async {
    try {
      await DbHelper.instance.deleteUser(id: id);
    } catch (_) {
      throw UserDeleteFailedException(
        'Failed to Delete Supervisor or Operator',
      );
    }
  }

  /// Manager Deleting Specific Transaction by Id
  @override
  Future<void> deleteTransaction({required int transactionId}) async {
    try {
      await DbHelper.instance.deleteTransaction(id: transactionId);
    } catch (_) {
      throw TransactionDeleteFailedException('Failed to Delete Transaction');
    }
  }

  /// get List Supervisor and Operator
  @override
  Future<List<ListAccountJson>> getSupervisorAndOperator() async {
    try {
      final account = await DbHelper.instance.getSupervisorAndOperatorAccount();
      return account;
    } catch (_) {
      throw UserGetFailedException('Failed to Get User Data');
    }
  }

  /// Update Specific Supervisor and Operator
  @override
  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final updatedAccount = ListAccountJson(
        accountID: id,
        accountUsername: username,
        accountPassword: password,
        accountPosition: role,
      );
      await DbHelper.instance.updateUser(updatedAccount);
    } catch (_) {
      throw UserUpdateFailedException('Failed to Update User Data');
    }
  }

  /// Get List Transaction
  @override
  Future<List<ListTransactionJson>> getAllTransactions() async {
    try {
      final listTransaction = await DbHelper.instance.getListTransaction();
      return listTransaction;
    } catch (_) {
      throw TransactionGetFailedException('Failed to Get Transaction Data');
    }
  }
}
