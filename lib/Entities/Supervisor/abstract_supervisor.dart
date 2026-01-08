abstract class AbstractSupervisor {
  Future<void> createOperator({
    required String username,
    required String password,
  });
  // Future<void> addEmergencyTransaction();
  // Future<void> exportReport();
}
