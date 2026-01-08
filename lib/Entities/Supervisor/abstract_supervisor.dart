abstract class AbstractSupervisor {
  Future<void> login({required String username, required String password});
  Future<void> logout();
  Future<void> createOperator({
    required String username,
    required String password,
  });
  // Future<void> addEmergencyTransaction();
  // Future<void> exportReport();
}
