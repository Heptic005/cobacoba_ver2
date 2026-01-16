import 'dart:convert';

ListTokenJson listTokenJsonFromJson(String str) =>
    ListTokenJson.fromJson(json.decode(str));

String listTokenJsonToJson(ListTokenJson data) => json.encode(data.toJson());

class ListTokenJson {
  final int tokenId;
  final String tokenCode;
  final DateTime expiresAt;
  final int isUsed;
  final int createdBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  ListTokenJson({
    this.tokenId = 0,
    required this.tokenCode,
    required this.expiresAt,
    this.isUsed = 0,
    required this.createdBy,
    this.usedAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory ListTokenJson.fromJson(Map<String, dynamic> json) => ListTokenJson(
    tokenId: json['tokenId'],
    tokenCode: json['tokenCode'],
    expiresAt: DateTime.parse(json['expiresAt']),
    isUsed: json['isUsed'],
    createdBy: json['createdBy'],
    usedAt: json['usedAt'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    "tokenCode": tokenCode,
    "expiresAt": expiresAt.toIso8601String(),
    "isUsed": isUsed,
    "createdBy": createdBy,
    "usedAt": usedAt,
    "createdAt": createdAt.toIso8601String(),
  };
}
