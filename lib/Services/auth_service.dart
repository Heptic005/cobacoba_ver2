import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO : Implements Hashing Password Etc.

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  ListAccountJson? _currentUser;

  ListAccountJson? get currentUser => _currentUser;

  /// Hashing a password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<ListAccountJson?> login({
    required String username,
    required String password,
  }) async {
    final hashedPassword = hashPassword(password);
    final user = await DbHelper.instance.authenticateUser(
      username: username,

      /// TODO : Delete if register feature already fix
      // password: hashedPassword,
      password: password,
    );
    if (user == null) return null;

    // --- PERBAIKAN: Update Last Login Time ---
    await DbHelper.instance.updateLastLogin(user.accountID);
    // -----------------------------------------

    final prefs = await SharedPreferences.getInstance();
    _currentUser = user;
    if (user.accountPosition == 'manager') {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('id', user.accountID);
      await prefs.setString('name', user.accountUsername);
      await prefs.setString('role', user.accountPosition);
    } else if (user.accountPosition == 'supervisor') {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('id', user.accountID);
      await prefs.setString('name', user.accountUsername);
      await prefs.setString('role', user.accountPosition);
    } else if (user.accountPosition == 'operator') {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('id', user.accountID);
      await prefs.setString('name', user.accountUsername);
      await prefs.setString('role', user.accountPosition);
    } else if (user.accountPosition == 'technician') {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('id', user.accountID);
      await prefs.setString('name', user.accountUsername);
      await prefs.setString('role', user.accountPosition);
    }

    return user;
  }

  void logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('id');
    await prefs.remove('name');
    await prefs.remove('role');
  }
}