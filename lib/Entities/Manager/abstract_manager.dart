import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

abstract class AbstractManager {
  // Create User
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  });

  // Get All Users (Ubah dari void menjadi List)
  Future<List<ListAccountJson>> getSupervisorAndOperator();

  // Update User
  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  });

  // Delete User
  Future<void> deleteSupervisorAndOperator({required int id});

  // Get Transactions (Untuk Audit)
  Future<List<ListTransactionJson>> getAllTransactions();

  // Delete Transaction
  Future<void> deleteTransaction({required int transactionId});

  // Create Token
  Future<String> createTokenForManualWeight(int managerId);
}