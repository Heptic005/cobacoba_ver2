abstract class AbstractManager {
  Future<void> login({required String username, required String password});
  Future<void> logout();
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  });
  Future<void> getSupervisorAndOperator();
  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  });
  Future<void> deleteSupervisorAndOperator({required int id});
  Future<void> deleteTransaction({required int transactionId});
  Future<void> createTokenForManualWeight();
  // Future<void> exportReport();
}
