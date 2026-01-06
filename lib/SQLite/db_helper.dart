import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
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
	    "productCode"	TEXT NOT NULL,
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

      const createTransactionTable = '''
      CREATE TABLE IF NOT EXISTS "transaction" (
	    "transactionId"	INTEGER NOT NULL UNIQUE,
	    "vehiclePlate"	TEXT NOT NULL,
	    "driverName"	INT NOT NULL,
	    "supplierName"	INT NOT NULL,
	    "customerName"	INT NOT NULL,
	    "productName"	TEXT NOT NULL,
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
	    PRIMARY KEY("transactionId" AUTOINCREMENT),
	    FOREIGN KEY("customerName") REFERENCES "customer"("customerId"),
	    FOREIGN KEY("productName") REFERENCES "product"("productId"),
	    FOREIGN KEY("supplierName") REFERENCES "supplier"("supplierId")
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
    return db.delete('customer', where: customer.customerId.toString());
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
    return db.delete('product', where: product.productId.toString());
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
    return db.delete('product', where: supplier.supplierId.toString());
  }

  /* Transaction */
  /// Add Transaction
  Future<int> addTransaction(ListTransactionJson transaction) async {
    final Database db = await database;
    return db.insert('transaction', transaction.toJson());
  }

  /// Get Transactions
  Future<List<ListTransactionJson>> getListTransaction() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('transaction');
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
  Future<int> deleteUser(ListAccountJson user) async {
    final Database db = await database;
    return db.delete('account', where: user.accountID.toString());
  }

  /// Update User
  Future<int> updateUser(ListAccountJson user) async {
    final Database db = await database;
    return db.update(
      'account',
      user.toJson(),
      where: 'userId = ?',
      whereArgs: [user.accountID],
    );
  }
}

class UnableToGetDocumentsDirectory {}
