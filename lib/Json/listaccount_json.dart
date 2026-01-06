// get from https://app.quicktype.io/
import 'dart:convert';

/// 6 January 2026
/// This is Account Data Model

ListAccountJson ListAccountJsonFromJson(String str) =>
    ListAccountJson.fromJson(json.decode(str));

String ListAccountJsonToJson(ListAccountJson data) =>
    json.encode(data.toJson());

class ListAccountJson {
  final int accountID;
  final String accountUsername;
  final String accountPassword;
  final String accountPosition;

  ListAccountJson({
    this.accountID = 0,
    required this.accountUsername,
    required this.accountPassword,
    required this.accountPosition,
  });

  factory ListAccountJson.fromJson(Map<String, dynamic> json) =>
      ListAccountJson(
        accountID: json["accountID"],
        accountUsername: json["accountUsername"],
        accountPassword: json["accountPassword"],
        accountPosition: json["accountPosition"],
      );

  Map<String, dynamic> toJson() => {
    // "accountID": accountID,
    "accountUsername": accountUsername,
    "accountPassword": accountPassword,
    "accountPosition": accountPosition,
  };
}
