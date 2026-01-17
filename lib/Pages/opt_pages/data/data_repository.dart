/// Deskripsi: Repository layer untuk mengakses data Supplier, Customer, dan Product

import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';

/// Repository class untuk mengelola akses data Supplier, Customer, dan Product
class DataRepository {
  final DbHelper _dbHelper;

  /// Constructor dengan dependency injection untuk DbHelper
  DataRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;


  // SUPPLIER METHODS

  /// Mengambil semua data supplier dari database
  /// Returns: List<ListSupplierJson> - daftar supplier tanpa filter
  Future<List<ListSupplierJson>> getSuppliers() async {
    try {
      return await _dbHelper.getListSupplier();
    } catch (e) {
      throw DataRepositoryException('Gagal mengambil data supplier: $e');
    }
  }

  /// Menambahkan supplier baru ke database
  /// [supplier] - Data supplier yang akan ditambahkan
  /// Returns: int - ID dari supplier yang baru ditambahkan
  Future<int> addSupplier(ListSupplierJson supplier) async {
    try {
      return await _dbHelper.addSupplier(supplier);
    } catch (e) {
      throw DataRepositoryException('Gagal menambahkan supplier: $e');
    }
  }

  // CUSTOMER METHODS
  /// Mengambil semua data customer dari database
  /// Returns: List<ListCustomerJson> - daftar customer tanpa filter
  Future<List<ListCustomerJson>> getCustomers() async {
    try {
      return await _dbHelper.getListCustomers();
    } catch (e) {
      throw DataRepositoryException('Gagal mengambil data customer: $e');
    }
  }

  /// Menambahkan customer baru ke database
  /// Returns: int - ID dari customer yang baru ditambahkan
  Future<int> addCustomer(ListCustomerJson customer) async {
    try {
      return await _dbHelper.addCustomer(customer);
    } catch (e) {
      throw DataRepositoryException('Gagal menambahkan customer: $e');
    }
  }

  // PRODUCT METHODS

  /// Mengambil semua data product dari database
  Future<List<ListProductJson>> getProducts() async {
    try {
      return await _dbHelper.getListProducts();
    } catch (e) {
      throw DataRepositoryException('Gagal mengambil data product: $e');
    }
  }

  /// Menambahkan product baru ke database
  Future<int> addProduct(ListProductJson product) async {
    try {
      final db = await _dbHelper.database;
      final map = <String, dynamic>{
        'productName': product.productName,
        'productCode': product.productCode,
      };
      return await db.insert('product', map);
    } catch (e) {
      throw DataRepositoryException('Gagal menambahkan product: $e');
    }
  }

}

/// Custom exception untuk error di repository layer
class DataRepositoryException implements Exception {
  final String message;
  DataRepositoryException(this.message);

  @override
  String toString() => message;
}
