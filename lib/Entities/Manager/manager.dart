<<<<<<< HEAD
import 'dart:math';
// PERBAIKAN IMPORT: Menambahkan 'Entities' ke dalam path
import 'package:dakara_weighbridge/Entities/Manager/abstract_manager.dart'; 
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listtoken_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
=======
import 'package:dakara_weighbridge/Entities/Manager/abstract_manager.dart';
import 'package:dakara_weighbridge/Exception/token_exception.dart';
import 'package:dakara_weighbridge/Exception/transaction_exception.dart';
import 'package:dakara_weighbridge/Exception/user_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';
>>>>>>> d13ebe9be112632c95baa1247581c23105f57cbc

class Manager implements AbstractManager {
  
  // --- USER MANAGEMENT ---

  @override
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  }) async {
<<<<<<< HEAD
    final newAccount = ListAccountJson(
      accountID: 0, 
      accountUsername: username,
      accountPassword: password,
      accountPosition: role,
    );
    await DbHelper.instance.addUser(newAccount);
=======
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
>>>>>>> d13ebe9be112632c95baa1247581c23105f57cbc
  }

  @override
<<<<<<< HEAD
  Future<List<ListAccountJson>> getSupervisorAndOperator() async {
    return await DbHelper.instance.getAllUser();
  }

=======
  Future<void> createTokenForManualWeight() async {
    try {
      await TokenService.createToken();
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
>>>>>>> d13ebe9be112632c95baa1247581c23105f57cbc
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

  @override
  Future<void> deleteSupervisorAndOperator({required int id}) async {
    await DbHelper.instance.deleteUser(id: id);
  }

  // --- TRANSACTION MANAGEMENT ---

  @override
  Future<List<ListTransactionJson>> getAllTransactions() async {
    return await DbHelper.instance.getListTransaction();
  }

  @override
  Future<void> deleteTransaction({required int transactionId}) async {
    await DbHelper.instance.deleteTransaction(id: transactionId);
  }

  // --- TOKEN MANAGEMENT ---

  @override
  Future<String> createTokenForManualWeight(int managerId) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String tokenCode = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    // PERBAIKAN TIPE DATA: Menghapus .toString() karena model minta DateTime
    final newToken = ListTokenJson(
      tokenId: 0, 
      tokenCode: tokenCode,
      // Hapus .toString() di bawah ini
      expiresAt: DateTime.now().add(const Duration(hours: 24)), 
      isUsed: 0,
      createdBy: managerId,
      usedAt: null,
      // Hapus .toString() di bawah ini juga
      createdAt: DateTime.now(), 
    );

    await DbHelper.instance.createTokenForManualWeight(newToken);
    
    return tokenCode;
  }
}