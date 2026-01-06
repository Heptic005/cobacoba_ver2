// get from https://app.quicktype.io/
import 'dart:convert';

/// 6 January 2026
/// This is Transaction Data Model

ListTransactionJson ListTransactionJsonFromJson(String str) =>
    ListTransactionJson.fromJson(json.decode(str));

String ListTransactionJsonToJson(ListTransactionJson data) =>
    json.encode(data.toJson());

class ListTransactionJson {
  final int transactionId;
  final String vehiclePlate;
  final String driverName;
  final String supplierName;
  final String customerName;
  final String ProductName;
  final int cut;
  final int? kubikasi;
  final String? noDO;
  final int? noContainer;
  final double? temperature;
  final double? price;
  final String? additionalInformation;
  final String noTicket;
  final DateTime inTime;
  final DateTime outTime;
  final double totalPrice;
  final double bruto;
  final double tare;
  final double netto;
  final double nettoAfterCut;
  final bool driverLabel;
  final bool operatorLabel;
  final bool managerLabel;
  final bool headWarehouseLabel;

  ListTransactionJson({
    required this.vehiclePlate,
    required this.driverName,
    required this.supplierName,
    required this.customerName,
    required this.ProductName,
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
  });

  factory ListTransactionJson.fromJson(Map<String, dynamic> json) =>
      ListTransactionJson(
        vehiclePlate: json['vehiclePlate'],
        driverName: json['driverName'],
        supplierName: json['supplierName'],
        customerName: json['customerName'],
        ProductName: json['ProductName'],
        cut: json['cut'],
        noTicket: json['noTicket'],
        inTime: json['inTime'],
        outTime: json['outTime'],
        totalPrice: json['totalPrice'],
        bruto: json['bruto'],
        tare: json['tare'],
        netto: json['netto'],
        nettoAfterCut: json['nettoAfterCut'],
        driverLabel: json['driverLabel'],
        transactionId: json['transactionId'],
        operatorLabel: json['operatorLabel'],
        managerLabel: json['managerLabel'],
        headWarehouseLabel: json['headWearhouseLabel'],
      );

  Map<String, dynamic> toJson() => {
    "vehiclePlate": vehiclePlate,
    "driverName": driverName,
    "supplierName": supplierName,
    "customerName": customerName,
    "ProductName": ProductName,
    "cut": cut,
    "noTicket": noTicket,
    "inTime": inTime,
    "outTime": outTime,
    "totalPrice": totalPrice,
    "bruto": bruto,
    "tare": tare,
    "netto": netto,
    "nettoAfterCut": nettoAfterCut,
    "driverLabel": driverLabel,
    "operatorLabel": operatorLabel,
    "managerLabel": managerLabel,
    "headWarehouseLabel": headWarehouseLabel,
    // "transactionId": transactionId,
  };
}
