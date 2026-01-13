/// TODO : MAKE AN EXCEPTION FOR ANY ERROR COME FROM TOKEN

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
