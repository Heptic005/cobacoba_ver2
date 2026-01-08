// get from https://app.quicktype.io/
import 'dart:convert';

/// Modified to match DB Schema and include Foreign Keys

ListTransactionJson listTransactionJsonFromJson(String str) =>
    ListTransactionJson.fromJson(json.decode(str));

String listTransactionJsonToJson(ListTransactionJson data) =>
    json.encode(data.toJson());

class ListTransactionJson {
  final int transactionId;
  final String vehiclePlate;
  final String driverName;
  final int supplierId;
  final int customerId;
  final int productId;
  final int cut;
  final int? kubikasi;
  final String? noDO;
  final int? noContainer;
  final double? temperature;
  final double? price;
  final String? additionalInformation;
  final String noTicket;
  final DateTime inTime;
  final DateTime? outTime;
  final double totalPrice;
  final double bruto;
  final double tare;
  final double netto;
  final double nettoAfterCut;
  final int driverLabel;
  final int operatorLabel;
  final int managerLabel;
  final int headWarehouseLabel;
  // final int isDraft;

  ListTransactionJson({
    required this.vehiclePlate,
    required this.driverName,
    required this.supplierId,
    required this.customerId,
    required this.productId,
    required this.cut,
    this.kubikasi,
    this.noDO,
    this.noContainer,
    this.temperature,
    this.price,
    this.additionalInformation,
    required this.noTicket,
    required this.inTime,
    required this.outTime,
    required this.totalPrice,
    required this.bruto,
    required this.tare,
    required this.netto,
    required this.nettoAfterCut,
    required this.driverLabel,
    this.transactionId = 0,
    required this.operatorLabel,
    required this.managerLabel,
    required this.headWarehouseLabel,
    // required this.isDraft,
  });

  factory ListTransactionJson.fromJson(
    Map<String, dynamic> json,
  ) => ListTransactionJson(
    vehiclePlate: json['vehiclePlate'],
    driverName: json['driverName'],
    supplierId: json['supplierId'], // Mapping from DB column which will be IDs
    customerId: json['customerId'], // Mapping from DB column which will be IDs
    productId: json['productId'], // Mapping from DB column which will be IDs
    cut: json['cut'],
    noTicket: json['noTicket'],
    inTime: DateTime.parse(json['inTime']),
    outTime: json['outTime'] == null ? null : DateTime.parse(json['outTime']),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    bruto: (json['bruto'] as num).toDouble(),
    tare: (json['tare'] as num).toDouble(),
    netto: (json['netto'] as num).toDouble(),
    nettoAfterCut: (json['nettoAfterCut'] as num).toDouble(),
    driverLabel: json['driverLabel'],
    transactionId: json['transactionId'],
    operatorLabel: json['operatorLabel'],
    managerLabel: json['managerLabel'],
    headWarehouseLabel: json['headWarehouseLabel'],
    // isDraft: json['isDraft'],
  );

  Map<String, dynamic> toJson() => {
    "vehiclePlate": vehiclePlate,
    "driverName": driverName,
    "supplierId": supplierId,
    "customerId": customerId,
    "productId": productId,
    "cut": cut,
    "kubikasi": kubikasi,
    "noDO": noDO,
    "noContainer": noContainer,
    "temperature": temperature,
    "price": price,
    "additionalInformation": additionalInformation,
    "noTicket": noTicket,
    "inTime": inTime.toIso8601String(),
    "outTime": outTime == null ? null : outTime!.toIso8601String(),
    "totalPrice": totalPrice,
    "bruto": bruto,
    "tare": tare,
    "netto": netto,
    "nettoAfterCut": nettoAfterCut,
    "driverLabel": driverLabel,
    "operatorLabel": operatorLabel,
    "managerLabel": managerLabel,
    "headWarehouseLabel": headWarehouseLabel,
  };
}
