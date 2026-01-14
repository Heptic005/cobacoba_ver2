/// All Exception About Creating, Update, Read, Delete And Other
class TransactionCreationException implements Exception {
  String message;
  TransactionCreationException(this.message);
}

class TransactionGetFailedException implements Exception {
  String message;
  TransactionGetFailedException(this.message);
}

class TransactionUpdateFailedException implements Exception {
  String message;
  TransactionUpdateFailedException(this.message);
}

class TransactionDeleteFailedException implements Exception {
  String message;
  TransactionDeleteFailedException(this.message);
}
