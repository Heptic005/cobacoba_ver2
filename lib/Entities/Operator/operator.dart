import 'package:dakara_weighbridge/Entities/Operator/abstract_operator.dart';
import 'package:dakara_weighbridge/Exception/token_exception.dart';
import 'package:dakara_weighbridge/Exception/transaction_exception.dart';
import 'package:dakara_weighbridge/Json/listrequesttoken_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Operator implements AbstractOperator {
  /// Operator Creating Bruto Transaction
  /// TODO : First Transaction Maybe Tare First, So Make the Conditional Statement
  /// TODO : Change Function Name and Implementation in UI Because The Weight is Between Bruto and Tare
  @override
  Future<void> addBrutoTransaction({
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    required double bruto,
    bool isBruto = false,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
  }) async {
    try {
      if (isBruto) {
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'WB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: bruto,
            tare: 0,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
          ),
        );
      } else {
        final tare = bruto;
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'WB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: 0,
            tare: tare,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
          ),
        );
      }
    } catch (e) {
      print(e);
      throw TransactionCreationException('Failed to Create Transaction');
    }
  }

  /*
   TODO : MAKE SURE THE CALCULATION IS CORRECT,
    Initial Weight Value Maybe Bruto or Tare,
    So Make The Conditional Statement
    17 - 18 January 2026
   */

  /// Operator Creating Netto Transaction
  @override
  Future<void> addNettoTransaction({
    required int transactionId,
    int? kubikasi,
    String? noDo,
    int? cut,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
    required double weight,
  }) async {
    final transaction = await DbHelper.instance.getTransactionById(
      id: transactionId,
    );

    /// TODO : Make Custom Exception
    if (transaction.isEmpty)
      throw TransactionGetFailedException('Not Found Any Transactions');
    final t = transaction[0];
    if (t.bruto != 0) {
      final netto = t.bruto - weight;
      final usedCut = cut ?? t.cut;
      final nettoAfterCut = netto - (netto * (usedCut / 100));
      final usedPrice =
          (t.price != null && t.price! > 0) ? t.price! : (price ?? 0);

      final updated = ListTransactionJson(
        vehiclePlate: t.vehiclePlate,
        driverName: t.driverName,
        supplierId: t.supplierId,
        customerId: t.customerId,
        productId: t.productId,
        cut: usedCut,
        kubikasi: kubikasi ?? t.kubikasi,
        noDO: noDo ?? t.noDO,
        noContainer: noContainer ?? t.noContainer,
        temperature: temperature ?? t.temperature,
        price: usedPrice,
        additionalInformation: additionalInformation ?? t.additionalInformation,
        noTicket: t.noTicket,
        inTime: t.inTime,
        outTime: DateTime.now(),
        totalPrice: nettoAfterCut * usedPrice,
        bruto: t.bruto,
        tare: weight,
        netto: netto,
        nettoAfterCut: nettoAfterCut,
        driverLabel: t.driverLabel,
        operatorLabel: t.operatorLabel,
        managerLabel: t.managerLabel,
        headWarehouseLabel: t.headWarehouseLabel,
        isDrafted: 0,
        transactionId: t.transactionId,
        isManual: t.isManual,
      );

      await DbHelper.instance.updateTransaction(updated);
    } else {
      final netto = weight - t.tare;
      final nettoAfterCut = netto - (netto * (cut ?? t.cut / 100));
      final usedPrice =
          (t.price != null && t.price! > 0) ? t.price! : (price ?? 0);
      final updated = ListTransactionJson(
        vehiclePlate: t.vehiclePlate,
        driverName: t.driverName,
        supplierId: t.supplierId,
        customerId: t.customerId,
        productId: t.productId,
        cut: t.cut,
        kubikasi: kubikasi ?? t.kubikasi,
        noDO: noDo ?? t.noDO,
        noContainer: noContainer ?? t.noContainer,
        temperature: temperature ?? t.temperature,
        price: usedPrice,
        additionalInformation: additionalInformation ?? t.additionalInformation,
        noTicket: t.noTicket,
        inTime: t.inTime,
        outTime: DateTime.now(),
        totalPrice: nettoAfterCut * usedPrice,
        bruto: weight,
        tare: t.tare,
        netto: netto,
        nettoAfterCut: nettoAfterCut,
        driverLabel: t.driverLabel,
        operatorLabel: t.operatorLabel,
        managerLabel: t.managerLabel,
        headWarehouseLabel: t.headWarehouseLabel,
        isDrafted: 0,
        transactionId: t.transactionId,
        isManual: t.isManual,
      );
      await DbHelper.instance.updateTransaction(updated);
    }
  }

  /// Validate Special Transaction Token
  @override
  Future<bool> validateToken(String inputToken) async {
    final token = await DbHelper.instance.getToken(inputToken);
    // print(token!.isExpired);

    if (token == null)
      throw TokenInvalidException('Invalid Manual Weighing Token');
    if (token.isUsed == 1) throw TokenAlreadyUseException('Token Already Used');
    if (token.isExpired) throw TokenExpiredException('Expired Token');

    // tandai sudah dipakai
    /// Uncomment if already done
    // await DbHelper.instance.markTokenUsed(inputToken);
    return true;
  }

  /// Creating Request Token
  @override
  Future<void> createRequestToken({required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final supervisorId = prefs.getInt('id');

      await DbHelper.instance.createRequestForManualToken(
        ListRequestTokenJson(
          requestedBy: supervisorId!,
          reason: reason,
          status: 'requesting',
          requestedAt: DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
        ),
      );
    } catch (_) {
      throw TokenRequestCreationException(
        'Failed to Create Request for Special Transaction',
      );
    }
  }

  /// Add Special Transaction by Operator
  @override
  Future<void> addSpecialTransaction({
    String? token,
    required String vehiclePlate,
    required String driverName,
    required int supplierId,
    required int customerId,
    required int productId,
    required int cut,
    required double weight,
    bool isBruto = false,
    int? kubikasi,
    String? noDo,
    int? noContainer,
    double? temperature,
    double? price,
    String? additionalInformation,
  }) async {
    try {
      if (isBruto) {
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'MWB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: weight,
            tare: 0,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
            isManual: 1,
          ),
        );
      } else {
        final tare = weight;
        await DbHelper.instance.addTransaction(
          ListTransactionJson(
            vehiclePlate: vehiclePlate,
            driverName: driverName,
            supplierId: supplierId,
            customerId: customerId,
            productId: productId,
            cut: cut,
            kubikasi: kubikasi,
            noDO: noDo,
            noContainer: noContainer,
            temperature: temperature,
            price: price,
            additionalInformation: additionalInformation,
            noTicket: 'MWB-${DateTime.now().millisecondsSinceEpoch}',
            inTime: DateTime.now(),
            outTime: DateTime.now(),
            totalPrice: 0,
            bruto: 0,
            tare: tare,
            netto: 0,
            nettoAfterCut: 0,
            driverLabel: 0,
            operatorLabel: 0,
            managerLabel: 0,
            headWarehouseLabel: 0,
            isDrafted: 1,
            isManual: 1,
          ),
        );
      }
    } catch (_) {
      throw TransactionCreationException(
        'Failed to Create Special Transaction',
      );
    }
  }
}
