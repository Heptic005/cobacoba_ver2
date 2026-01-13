abstract class AbstractSupervisor {
  Future<void> createOperator({
    required String username,
    required String password,
  });
  Future<bool> validateToken(String inputToken);
  // Future<void> addEmergencyTransaction();
  // Future<void> exportReport();
}
