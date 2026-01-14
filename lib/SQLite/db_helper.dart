import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listrequesttoken_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Json/listtoken_json.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 6 January 2026
/// Still Needed to Add CRUD for All Entities
class DbHelper {
  static final DbHelper instance = DbHelper._internal();
  DbHelper._internal();
  factory DbHelper() => instance;
  static Database? _database;
  final String databaseName = 'daprin.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _database ??= await init();
  }

  Future<Database> init() async {
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, databaseName);
      // print(dbPath);

      const createAccountTable = '''
      CREATE TABLE IF NOT EXISTS "account" (
	     "accountId"	INTEGER NOT NULL UNIQUE,
	     "accountUsername"	TEXT NOT NULL UNIQUE,
	     "accountPassword"	TEXT NOT NULL,
	     "accountPosition"	TEXT NOT NULL,
	      PRIMARY KEY("accountId" AUTOINCREMENT)
        );
      ''';

      const createCustomerTable = '''
      CREATE TABLE IF NOT EXISTS "customer" (
	    "customerId"	INTEGER NOT NULL UNIQUE,
	    "customerName"	TEXT NOT NULL,
	    "customerAddress"	TEXT NOT NULL,
	    "customerPhone"	TEXT NOT NULL,
	    PRIMARY KEY("customerId" AUTOINCREMENT)
      );
      ''';

      const createProductTable = '''
      CREATE TABLE IF NOT EXISTS "product" (
	    "productId"	INTEGER NOT NULL UNIQUE,
	    "productName"	TEXT NOT NULL,
	    "productCode"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("productId" AUTOINCREMENT)
      );
      ''';

      const createSupplierTable = '''
      CREATE TABLE IF NOT EXISTS "supplier" (
	    "supplierId"	INTEGER NOT NULL UNIQUE,
	    "supplierName"	TEXT NOT NULL,
	    "supplierAddress"	TEXT NOT NULL,
	    "supplierCity"	TEXT NOT NULL,
	    "supplierSubdistrict"	TEXT NOT NULL,
	    "supplierPostCode"	TEXT NOT NULL,
	    PRIMARY KEY("supplierId" AUTOINCREMENT)
      );
      ''';

      const createManualTokensTable = '''
      CREATE TABLE IF NOT EXISTS "manual_tokens" (
	    "tokenId"	INTEGER NOT NULL UNIQUE,
	    "tokenCode"	TEXT NOT NULL,
	    "expiresAt"	TEXT NOT NULL,
	    "isUsed"	INTEGER NOT NULL,
	    "createdBy"	INTEGER NOT NULL,
	    "usedAt"	TEXT,
	    "createdAt"	TEXT,
	    PRIMARY KEY("tokenId" AUTOINCREMENT)
      );
      ''';

      const createTokenRequestTable = '''
      CREATE TABLE IF NOT EXISTS "token_requests" (
	    "tokenRequestId"	INTEGER NOT NULL UNIQUE,
	    "requestedBy"	INTEGER NOT NULL,
	    "reason"	TEXT NOT NULL,
	    "status"	TEXT NOT NULL,
	    "approvedBy"	INTEGER,
	    "tokenId"	INTEGER,
	    "requestedAt"	TEXT NOT NULL,
	    "approvedAt"	INTEGER,
	    PRIMARY KEY("tokenRequestId" AUTOINCREMENT),
	    FOREIGN KEY("tokenId") REFERENCES "manual_tokens"("tokenId")
      );
      ''';

      const createTransactionTable = '''
      CREATE TABLE "transaction" (
	    "transactionId"	INTEGER NOT NULL UNIQUE,
	    "vehiclePlate"	TEXT NOT NULL,
	    "driverName"	TEXT NOT NULL,
	    "supplierId"	INTEGER NOT NULL,
	    "customerId"	INTEGER NOT NULL,
	    "productId"	INTEGER NOT NULL,
	    "cut"	INTEGER NOT NULL,
	    "kubikasi"	INTEGER,
	    "noDO"	TEXT,
	    "noContainer"	INTEGER,
	    "temperature"	NUMERIC,
	    "price"	NUMERIC,
	    "additionalInformation"	TEXT,
	    "noTicket"	TEXT NOT NULL,
	    "inTime"	TEXT NOT NULL,
	    "outTime"	TEXT NOT NULL,
	    "totalPrice"	NUMERIC NOT NULL,
	    "bruto"	NUMERIC NOT NULL,
	    "tare"	NUMERIC NOT NULL,
	    "netto"	NUMERIC NOT NULL,
	    "nettoAfterCut"	NUMERIC NOT NULL,
	    "driverLabel"	INTEGER NOT NULL,
	    "operatorLabel"	INTEGER NOT NULL,
	    "managerLabel"	INTEGER NOT NULL,
	    "headWarehouseLabel"	INTEGER NOT NULL,
	    "isDrafted"	INTEGER NOT NULL DEFAULT 1,
	    "isManual"	INTEGER NOT NULL DEFAULT 0,
	    PRIMARY KEY("transactionId" AUTOINCREMENT),
	    FOREIGN KEY("customerId") REFERENCES "customer"("customerId"),
	    FOREIGN KEY("productId") REFERENCES "product"("productId"),
	    FOREIGN KEY("supplierId") REFERENCES "supplier"("supplierId")
      );
      ''';

      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          //Tables
          await db.execute(createAccountTable);
          await db.execute(createCustomerTable);
          await db.execute(createProductTable);
          await db.execute(createSupplierTable);
          await db.execute(createManualTokensTable);
          await db.execute(createTokenRequestTable);
          await db.execute(createTransactionTable);
        },
      );
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  /* customer */
  /// Add Customer
  Future<int> addCustomer(ListCustomerJson customer) async {
    final Database db = await database;
    return db.insert('customer', customer.toJson());
  }

  /// Get Customers
  Future<List<ListCustomerJson>> getListCustomers() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('customer', limit: 20);
    return result.map((e) => ListCustomerJson.fromJson(e)).toList();
  }

  /// Update Customer
  Future<int> updateCustomer(ListCustomerJson customer) async {
    final Database db = await database;
    return db.update(
      'customer',
      customer.toJson(),
      where: 'customerId = ?',
      whereArgs: [customer.customerId],
    );
  }

  /// Delete Customer
  Future<int> deleteCustomer(ListCustomerJson customer) async {
    final Database db = await database;
    return db.delete(
      'customer',
      where: 'customerId = ?',
      whereArgs: [customer.customerId],
    );
  }

  /* product */
  /// Get Products
  Future<List<ListProductJson>> getListProducts() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('product', limit: 10);
    return result.map((e) => ListProductJson.fromJson(e)).toList();
  }

  /// Add Product
  Future<int> addProduct(ListProductJson product) async {
    final Database db = await database;
    return db.insert('product', product.toJson());
  }

  /// Update Product
  Future<int> updateProduct(ListProductJson product) async {
    final Database db = await database;
    return db.update(
      'product',
      product.toJson(),
      where: 'productId = ?',
      whereArgs: [product.productId],
    );
  }

  /// Delete Product
  Future<int> deleteProduct(ListProductJson product) async {
    final Database db = await database;
    return db.delete(
      'product',
      where: 'productId = ?',
      whereArgs: [product.productId],
    );
  }

  /// Get Product Name By ID
  Future<String> getProductNameById(int id) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.map((e) => e['productName']).toString();
  }

  /* Supplier */
  /// Get Supplier
  Future<List<ListSupplierJson>> getListSupplier() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('supplier', limit: 30);
    return result.map((e) => ListSupplierJson.fromJson(e)).toList();
  }

  /// Add Supplier
  Future<int> addSupplier(ListSupplierJson supplier) async {
    final Database db = await database;
    return db.insert('supplier', supplier.toJson());
  }

  /// Update Supplier
  Future<int> updateSupplier(ListSupplierJson supplier) async {
    final Database db = await database;
    return db.update(
      'supplier',
      supplier.toJson(),
      where: 'supplierId = ?',
      whereArgs: [supplier.supplierId],
    );
  }

  /// Delete Supplier
  Future<int> deleteSupplier(ListSupplierJson supplier) async {
    final Database db = await database;
    return db.delete(
      'product',
      where: 'supplierId = ?',
      whereArgs: [supplier.supplierId],
    );
  }

  /* Transaction */
  /// Add Transaction
  Future<int> addTransaction(ListTransactionJson transaction) async {
    final Database db = await database;
    return db.insert('transaction', transaction.toJson());
  }

  /// Delete Transaction
  Future<int> deleteTransaction({required int id}) async {
    final Database db = await database;
    return db.delete(
      'transaction',
      where: 'transactionId = ?',
      whereArgs: [id],
    );
  }

  /// Update Transaction
  Future<int> updateTransaction(ListTransactionJson transaction) async {
    final Database db = await database;
    return db.update(
      'transaction',
      transaction.toJson(),
      where: 'transactionId = ?',
      whereArgs: [transaction.transactionId],
    );
  }

  /// Get Transactions
  Future<List<ListTransactionJson>> getListTransaction() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.rawQuery('''
        SELECT 
      t.transactionId,
      t.vehiclePlate,
      t.driverName,
      t.noTicket,
      t.inTime,
      t.outTime,
      t.kubikasi,
      t.noDO,
      t.noContainer,
      t.temperature,
      t.additionalInformation,
      t.price,
      t.bruto,
      t.tare,
      t.netto,
      t.nettoAfterCut,
      t.totalPrice,
      t.cut,
      t.driverLabel,
      t.operatorLabel,
      t.managerLabel,
      t.headWarehouseLabel,
      t.isDrafted,
      t.isManual,
      s.supplierId,
      s.supplierName,
      c.customerId,
      c.customerName,
      p.productId,
      p.productName
      FROM "transaction" t
      LEFT JOIN supplier s ON t.supplierId = s.supplierId
      LEFT JOIN customer c ON t.customerId = c.customerId
      LEFT JOIN product p ON t.productId = p.productId
      ORDER BY t.inTime DESC;
      ''');
    return result.map((e) => ListTransactionJson.fromJson(e)).toList();
  }

  /// Get Transaction By Id
  Future<List<ListTransactionJson>> getTransactionById({
    required int id,
  }) async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query(
      'transaction',
      where: 'transactionId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.map((e) => ListTransactionJson.fromJson(e)).toList();
  }

  /// Get Transactions By No Ticket
  Future<List<ListTransactionJson>> getTransactionByNoTicket({
    required String noTicket,
  }) async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.rawQuery('''
    SELECT 
      t.transactionId,
      t.vehiclePlate,
      t.driverName,
      t.noTicket,
      t.inTime,
      t.outTime,
      t.kubikasi,
      t.noDO,
      t.noContainer,
      t.temperature,
      t.additionalInformation,
      t.price,
      t.bruto,
      t.tare,
      t.netto,
      t.nettoAfterCut,
      t.totalPrice,
      t.cut,
      t.driverLabel,
      t.operatorLabel,
      t.managerLabel,
      t.headWarehouseLabel,
      t.isDrafted,
      t.isManual,
      s.supplierId,
      s.supplierName,
      c.customerId,
      c.customerName,
      p.productId,
      p.productName
      FROM "transaction" t
      LEFT JOIN supplier s ON t.supplierId = s.supplierId
      LEFT JOIN customer c ON t.customerId = c.customerId
      LEFT JOIN product p ON t.productId = p.productId
    WHERE noTicket LIKE "%$noTicket%" AND isDrafted = '1'
    LIMIT 3
    ''');
    return result.map((e) => ListTransactionJson.fromJson(e)).toList();
  }

  /* User */
  /// Get Users
  Future<List<ListAccountJson>> getAllUser() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('account');
    return result.map((e) => ListAccountJson.fromJson(e)).toList();
  }

  /// Add User
  Future<int> addUser(ListAccountJson user) async {
    final Database db = await database;
    return db.insert('account', user.toJson());
  }

  /// Delete User
  Future<int> deleteUser({required int id}) async {
    final Database db = await database;
    return db.delete('account', where: 'accountId = ?', whereArgs: [id]);
  }

  /// Update User
  Future<int> updateUser(ListAccountJson user) async {
    final Database db = await database;
    return db.update(
      'account',
      user.toJson(),
      where: 'accountId = ?',
      whereArgs: [user.accountID],
    );
  }

  /// Get User By Username
  Future<List<ListAccountJson>> getUserByUsername({
    required String username,
  }) async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query(
      'account',
      where: 'accountUsername = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.map((e) => ListAccountJson.fromJson(e)).toList();
  }

  Future<List<ListAccountJson>> getSupervisorAndOperatorAccount() async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'account',
      where: 'accountPosition = ? OR accountPosition = ?',
      whereArgs: ['supervisor', 'operator'],
    );
    return result.map((e) => ListAccountJson.fromJson(e)).toList();
  }

  /// Authenticate User
  Future<ListAccountJson?> authenticateUser({
    required String username,
    required String password,
  }) async {
    final user = await getUserByUsername(username: username);
    if (user.isEmpty) throw InvalidCredentialException("Invalid Credential");
    final storedPassword = user[0].accountPassword;
    if (storedPassword == password) {
      return user[0];
    } else {
      throw InvalidCredentialException("Invalid Credential");
    }
  }

  /// TODO : Implementing Create and Update Manual Transaction Token
  /// Create Manual Transaction Token
  Future<int> createTokenForManualWeight(ListTokenJson token) async {
    final Database db = await database;
    return db.insert('manual_tokens', token.toJson());
  }

  /// get Token
  Future<ListTokenJson?> getToken(String token) async {
    final Database db = await database;
    final result = await db.query(
      'manual_tokens',
      where: 'tokenCode = ? AND isUsed = ?',
      whereArgs: [token, 0],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.map((e) => ListTokenJson.fromJson(e)).first;
  }

  /// mark token as used
  Future<void> markTokenUsed(String token) async {
    final Database db = await database;
    await db.update(
      'manual_tokens',
      {'isUsed': 1, 'usedAt': DateTime.now().toString()},
      where: 'tokenCode = ?',
      whereArgs: [token],
    );
  }

  /// Create Request for Manual Token
  Future<int> createRequestForManualToken(ListRequestTokenJson token) async {
    final Database db = await database;
    return db.insert('token_requests', token.toJson());
  }
}

class UnableToGetDocumentsDirectory {}
