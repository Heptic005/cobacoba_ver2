abstract class AbstractSupervisor {
  Future<void> createOperator({
    required String username,
    required String password,
  });
  Future<bool> validateToken(String inputToken);
  Future<void> createRequestToken({required String reason});
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
  });
}
