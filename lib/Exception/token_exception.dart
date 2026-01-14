/// All Exception About Token of Special Transaction

class TokenExpiredException implements Exception {
  String message;
  TokenExpiredException(this.message);
}

class TokenAlreadyUseException implements Exception {
  String message;
  TokenAlreadyUseException(this.message);
}

class TokenInvalidException implements Exception {
  String message;
  TokenInvalidException(this.message);
}

class TokenCreationException implements Exception {
  String message;
  TokenCreationException(this.message);
}

class TokenRequestCreationException implements Exception {
  String message;
  TokenRequestCreationException(this.message);
}
