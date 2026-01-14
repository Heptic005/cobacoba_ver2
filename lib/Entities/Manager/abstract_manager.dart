import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

abstract class AbstractManager {
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  });

  Future<List<ListAccountJson>> getSupervisorAndOperator();

  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  });

  Future<void> deleteSupervisorAndOperator({required int id});

  Future<List<ListTransactionJson>> getAllTransactions();

  Future<void> deleteTransaction({required int transactionId});

  Future<String> createTokenForManualWeight();
}
