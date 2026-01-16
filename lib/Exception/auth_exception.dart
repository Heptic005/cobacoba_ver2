/// All Exception About Authenticaton and Authorization
class InvalidCredentialException implements Exception {
  String message;
  InvalidCredentialException(this.message);
}

class UserNotLoggedInException implements Exception {
  String message;
  UserNotLoggedInException(this.message);
}

class AuthorizationException implements Exception {
  String message;
  AuthorizationException(this.message);
}
