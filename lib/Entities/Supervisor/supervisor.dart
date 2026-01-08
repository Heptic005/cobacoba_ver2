import 'package:dakara_weighbridge/Entities/Supervisor/abstract_supervisor.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO : Need to add export report, emergency transaction
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
}
