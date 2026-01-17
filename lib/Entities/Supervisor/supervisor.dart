import 'package:dakara_weighbridge/Entities/Supervisor/abstract_supervisor.dart';
import 'package:dakara_weighbridge/Exception/token_exception.dart';
import 'package:dakara_weighbridge/Exception/user_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';

class Supervisor implements AbstractSupervisor {
  /// Creating Account For Operator
  @override
  Future<void> createOperator({
    required String username,
    required String password,
  }) async {
    try {
      await DbHelper.instance.addUser(
        ListAccountJson(
          accountUsername: username,
          accountPassword: password,
          accountPosition: 'operator',
        ),
      );
    } catch (_) {
      throw UserCreationFailedException('Failed to Create Operator');
    }
  }

  /// Supervisor Creating Token For Operator To Be Able To Special Transaction
  @override
  Future<String> createTokenForManualWeight() async {
    try {
      final token = await TokenService.createToken();
      return token.tokenCode;
    } catch (_) {
      throw TokenCreationException(
        'Failed to Create Token for Special Transaction',
      );
    }
  }
}
