import 'package:dakara_weighbridge/Entities/Manager/abstract_manager.dart';

/// TODO : Need To Implements all Methods
class Manager implements AbstractManager {
  @override
  Future<void> createSupervisorAndOperator({
    required String username,
    required String password,
    required String role,
  }) {
    // TODO: implement createSupervisorAndOperator
    throw UnimplementedError();
  }

  @override
  Future<void> createTokenForManualWeight() {
    // TODO: implement createTokenForManualWeight
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSupervisorAndOperator({required int id}) {
    // TODO: implement deleteSupervisorAndOperator
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction({required int transactionId}) {
    // TODO: implement deleteTransaction
    throw UnimplementedError();
  }

  @override
  Future<void> getSupervisorAndOperator() {
    // TODO: implement getSupervisorAndOperator
    throw UnimplementedError();
  }

  @override
  Future<void> updateSupervisorAndOperator({
    required int id,
    required String username,
    required String password,
    required String role,
  }) {
    // TODO: implement updateSupervisorAndOperator
    throw UnimplementedError();
  }
}
