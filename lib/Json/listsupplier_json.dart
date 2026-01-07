import 'dart:convert';

/// 6 January 2026
/// This is Supplier Data Model

ListSupplierJson ListSupplierJsonFromJsonString(String str) =>
    ListSupplierJson.fromJson(json.decode(str));

String ListSupplierJsonToJsonString(ListSupplierJson data) =>
    json.encode(data.toJson());

class ListSupplierJson {
  final int supplierId;
  final String supplierName;
  final String supplierAddress;
  final String supplierCity;
  final String supplierSubdistrict;
  final String supplierPostCode;

  ListSupplierJson({
    this.supplierId = 0,
    required this.supplierName,
    required this.supplierAddress,
    required this.supplierCity,
    required this.supplierSubdistrict,
    required this.supplierPostCode,
  });

  factory ListSupplierJson.fromJson(Map<String, dynamic> json) =>
      ListSupplierJson(
        supplierId: json['supplierId'],
        supplierName: json['supplierName'],
        supplierAddress: json['supplierAddress'],
        supplierCity: json['supplierCity'],
        supplierSubdistrict: json['supplierSubdistrict'],
        supplierPostCode: json['supplierPostCode'],
      );

  Map<String, dynamic> toJson() => {
    "supplierName": supplierName,
    "supplierAddress": supplierAddress,
    "supplierCity": supplierCity,
    "supplierSubdistrict": supplierSubdistrict,
    "supplierPostCode": supplierPostCode,
  };
}
