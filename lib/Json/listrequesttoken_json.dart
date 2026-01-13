import 'dart:convert';

ListRequestTokenJson listTokenJsonFromJson(String str) =>
    ListRequestTokenJson.fromJson(json.decode(str));

String listTokenJsonToJson(ListRequestTokenJson data) =>
    json.encode(data.toJson());

class ListRequestTokenJson {
  final int tokenRequestId;
  final int requestedBy;
  final String reason;
  final String status;
  final int? approvedBy;
  final int? tokenId;
  final String requestedAt;
  final int? approvedAt;

  ListRequestTokenJson({
    this.tokenRequestId = 0,
    required this.requestedBy,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.tokenId,
    required this.requestedAt,
    this.approvedAt,
  });

  factory ListRequestTokenJson.fromJson(Map<String, dynamic> json) =>
      ListRequestTokenJson(
        tokenRequestId: json['tokenRequestId'],
        requestedBy: json['requestedBy'],
        reason: json['reason'],
        status: json['status'],
        approvedBy: json['approvedBy'],
        tokenId: json['tokenId'],
        requestedAt: json['requestedAt'],
        approvedAt: json['approvedAt'],
      );

  Map<String, dynamic> toJson() => {
    'requestedBy': requestedBy,
    'reason': reason,
    'status': status,
    'approvedBy': approvedBy,
    'tokenId': tokenId,
    'requestedAt': requestedAt,
    'approvedAt': approvedAt,
  };
}
