/// All Exception About Creating, Update, Read, Delete User
class UserCreationFailedException implements Exception {
  String message;
  UserCreationFailedException(this.message);
}

class UserGetFailedException implements Exception {
  String message;
  UserGetFailedException(this.message);
}

class UserUpdateFailedException implements Exception {
  String message;
  UserUpdateFailedException(this.message);
}

class UserDeleteFailedException implements Exception {
  String message;
  UserDeleteFailedException(this.message);
}
