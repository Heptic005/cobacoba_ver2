import 'package:dakara_weighbridge/Entities/Supervisor/abstract_supervisor.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Supervisor implements AbstractSupervisor {
  @override
  Future<void> createOperator({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInStatus = prefs.getBool('isLoggedIn');
    final roleStatus = prefs.getString('role');

    if (isLoggedInStatus ?? false) {
      if (roleStatus == 'supervisor') {
        await DbHelper.instance.addUser(
          ListAccountJson(
            accountUsername: username,
            accountPassword: password,
            accountPosition: 'operator',
          ),
        );
      }
      throw AuthorizationException();
    }
  }

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final user = await DbHelper.instance.getUserByUsername(username: username);

    if (user.isEmpty || user[0].accountPassword != password) {
      throw InvalidCredentialException();
    }

    // Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('supervisorId', user[0].accountID);
    await prefs.setString('supervisorName', user[0].accountUsername);
    await prefs.setString('role', user[0].accountPosition);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('supervisorId');
    await prefs.remove('supervisorName');
    await prefs.remove('role');
  }
}
