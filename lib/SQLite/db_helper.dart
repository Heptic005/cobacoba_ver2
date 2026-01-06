import 'package:dakara_weighbridge/Json/listproduct_json.dart';
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
	      PRIMARY KEY("accountId")
        );
      ''';

      const createCustomerTable = '''
      CREATE TABLE IF NOT EXISTS "customer" (
	    "customerId"	INTEGER NOT NULL UNIQUE,
	    "customerName"	TEXT NOT NULL,
	    "customerAddress"	TEXT NOT NULL,
	    "customerPhone"	TEXT NOT NULL,
	    PRIMARY KEY("customerId")
      );
      ''';

      const createProductTable = '''
      CREATE TABLE IF NOT EXISTS "product" (
	    "productId"	INTEGER NOT NULL UNIQUE,
	    "productName"	TEXT NOT NULL,
	    "productCode"	TEXT NOT NULL,
	    PRIMARY KEY("productId")
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
	    PRIMARY KEY("supplierId")
      );
      ''';

      const createTransactionTable = '''
      CREATE TABLE "transaction" (
	    "transactionId"	INTEGER NOT NULL UNIQUE,
	    "vehiclePlate"	TEXT NOT NULL,
	    "driverName"	TEXT NOT NULL,
	    "supplierName"	TEXT NOT NULL,
	    "customerName"	TEXT NOT NULL,
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
	    PRIMARY KEY("transactionId"),
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

  /* product */
  /// Get Products
  Future<List<ListProductJson>> getListProducts() async {
    final Database db = await database;
    List<Map<String, Object?>> result = await db.query('product');
    return result.map((e) => ListProductJson.fromJson(e)).toList();
  }

  /// Add Product
  Future<int> addProduct(ListProductJson product) async {
    final Database db = await database;
    return db.insert('product', product.toJson());
  }
}

class UnableToGetDocumentsDirectory {}
