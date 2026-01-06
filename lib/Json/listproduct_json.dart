// get from https://app.quicktype.io/
import 'dart:convert';

/// 6 January 2026
/// This is Product Data Model

ListProductJson ListProductJsonFromJson(String str) =>
    ListProductJson.fromJson(json.decode(str));

String ListProductJsonToJson(ListProductJson data) =>
    json.encode(data.toJson());

class ListProductJson {
  final int productId;
  final String productName;
  final String productCode;

  ListProductJson({
    this.productId = 0,
    required this.productName,
    required this.productCode,
  });

  factory ListProductJson.fromJson(Map<String, dynamic> json) =>
      ListProductJson(
        productId: json['productId'],
        productName: json['productName'],
        productCode: json['productCode'],
      );

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "productName": productName,
    "productCode": productCode,
  };
}
