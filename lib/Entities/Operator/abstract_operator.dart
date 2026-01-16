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
}
