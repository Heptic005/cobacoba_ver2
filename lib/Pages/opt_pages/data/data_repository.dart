/// ============================================================================
/// Data Repository
/// ============================================================================
/// File: data_repository.dart
/// Deskripsi: Repository layer untuk mengakses data Supplier, Customer, dan Product
///            dari database melalui DbHelper. Repository ini bertanggung jawab untuk:
///            - Memanggil method DbHelper untuk fetch data
///            - Melakukan insert data baru (khusus Supplier dan Customer)
///            - TIDAK memodifikasi db_helper.dart
/// 
/// Catatan Keamanan:
/// - Tidak melakukan string concatenation untuk query
/// - Menggunakan parameterized queries melalui DbHelper
/// - Sanitasi input dilakukan di Controller sebelum sampai ke repository
/// ============================================================================

import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';

/// Repository class untuk mengelola akses data Supplier, Customer, dan Product
class DataRepository {
  final DbHelper _dbHelper;

  /// Constructor dengan dependency injection untuk DbHelper
  DataRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;

  // ============================================================================
  // SUPPLIER METHODS
  // ============================================================================

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

  // ============================================================================
  // CUSTOMER METHODS
  // ============================================================================

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

  // ============================================================================
  // PRODUCT METHODS
  // ============================================================================

  /// Mengambil semua data product dari database
  /// CATATAN: Product hanya bisa dibaca, tidak ada method insert
  /// Returns: List<ListProductJson> - daftar product tanpa filter
  Future<List<ListProductJson>> getProducts() async {
    try {
      return await _dbHelper.getListProducts();
    } catch (e) {
      throw DataRepositoryException('Gagal mengambil data product: $e');
    }
  }

  // product tidak bisa ditambahkan melalui halaman Data
}

/// Custom exception untuk error di repository layer
class DataRepositoryException implements Exception {
  final String message;
  DataRepositoryException(this.message);

  @override
  String toString() => message;
}
