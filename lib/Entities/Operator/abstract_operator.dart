abstract class AbstractOperator {
  Future<void> login({required String username, required String password});
  Future<void> logout();
  Future<void> addBrutoTransaction({
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double bruto,
  });
  Future<void> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double tare,
    required double nettoAfterCut,
  });
}
