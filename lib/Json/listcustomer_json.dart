// get from https://app.quicktype.io/
import 'dart:convert';

/// 6 January 2026
/// This is Customer Data Model

ListCustomerJson ListCustomerJsonFromJson(String str) =>
    ListCustomerJson.fromJson(json.decode(str));

String ListCustomerJsonToJson(ListCustomerJson data) =>
    json.encode(data.toJson());

class ListCustomerJson {
  final int customerId;
  final String customerName;
  final String customerAddress;
  final String customerPhone;

  ListCustomerJson({
    this.customerId = 0,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
  });

  factory ListCustomerJson.fromJson(Map<String, dynamic> json) =>
      ListCustomerJson(
        customerId: json["customerId"],
        customerName: json["customerName"],
        customerAddress: json["customerAddress"],
        customerPhone: json["customerPhone"],
      );

  Map<String, dynamic> toJson() => {
    // "customerId": customerId,
    "customerName": customerName,
    "customerAddress": customerAddress,
    "customerPhone": customerPhone,
  };
}
