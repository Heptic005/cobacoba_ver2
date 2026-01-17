abstract class AbstractOperator {
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
    bool isBruto,
  });
  Future<void> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double weight,
  });
  Future<bool> validateToken(String inputToken);
  Future<void> createRequestToken({required String reason});
  Future<void> addSpecialTransaction({
    String? token,
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    required double weight,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    bool isBruto,
  });
}
