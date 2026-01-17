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
  final String? lastLogin; // <--- TAMBAHAN BARU

  ListAccountJson({
    this.accountID = 0,
    required this.accountUsername,
    required this.accountPassword,
    required this.accountPosition,
    this.lastLogin, // <--- TAMBAHAN BARU
  });

  factory ListAccountJson.fromJson(Map<String, dynamic> json) =>
      ListAccountJson(
        accountID: json["accountId"] ?? json["accountID"] ?? 0,
        accountUsername:
            json["accountUsername"] ??
            json["accountusername"] ??
            json["username"] ??
            '',
        accountPassword:
            json["accountPassword"] ??
            json["accountpassword"] ??
            json["password"] ??
            '',
        accountPosition:
            json["accountPosition"] ??
            json["accountposition"] ??
            json["position"] ??
            '',
        lastLogin: json["lastLogin"], // <--- AMBIL DARI DB
      );

  Map<String, dynamic> toJson() => {
    // "accountID": accountID,
    "accountUsername": accountUsername,
    "accountPassword": accountPassword,
    "accountPosition": accountPosition,
    "lastLogin": lastLogin, // <--- KIRIM KE DB
  };
}