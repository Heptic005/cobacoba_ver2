import 'dart:math';

import 'package:dakara_weighbridge/Json/listtoken_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static String _generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static Future<ListTokenJson> createToken({
    Duration validFor = const Duration(days: 1),
  }) async {
    final token = _generateToken();
    final expiresAt = DateTime.now().add(validFor);
    final prefs = await SharedPreferences.getInstance();
    final tokenCreatorId = prefs.getInt('id');

    final weighingToken = ListTokenJson(
      tokenCode: token,
      expiresAt: expiresAt,
      createdBy: tokenCreatorId!,
      createdAt: DateTime.now(),
    );

    await DbHelper.instance.createTokenForManualWeight(weighingToken);
    return weighingToken;
  }
}
