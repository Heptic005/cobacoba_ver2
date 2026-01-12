/// Data Controller (ViewModel)
/// Deskripsi: Controller/ViewModel untuk halaman Data Management.
///            Bertanggung jawab untuk:
///            - Mengambil data dari Repository
///            - Mengelola state loading, error, dan data
///            - Implementasi fitur search/filter lokal
///            - Validasi dan sanitasi input sebelum dikirim ke repository
///            - Expose data ke UI melalui Future/Stream
/// 

import 'package:flutter/foundation.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Pages/data/data_repository.dart';

/// Enum untuk merepresentasikan tab yang aktif
enum DataTab { supplier, customer, product }

/// Controller class menggunakan ChangeNotifier untuk reactive state management
class DataController extends ChangeNotifier {
  final DataRepository _repository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  
  /// Tab yang sedang aktif
  DataTab _activeTab = DataTab.supplier;
  DataTab get activeTab => _activeTab;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Search query untuk filtering
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Data lists (raw dari database)
  List<ListSupplierJson> _suppliers = [];
  List<ListCustomerJson> _customers = [];
  List<ListProductJson> _products = [];

  /// Getter untuk data yang sudah difilter berdasarkan search query
  List<ListSupplierJson> get suppliers => _filterSuppliers();
  List<ListCustomerJson> get customers => _filterCustomers();
  List<ListProductJson> get products => _filterProducts();

  /// Count untuk badge di tab
  int get supplierCount => _suppliers.length;
  int get customerCount => _customers.length;
  int get productCount => _products.length;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  DataController({DataRepository? repository})
      : _repository = repository ?? DataRepository();

  // ============================================================================
  // TAB MANAGEMENT
  // ============================================================================

  /// Mengubah tab yang aktif dan me-reset search query
  void setActiveTab(DataTab tab) {
    _activeTab = tab;
    _searchQuery = ''; // Reset search saat pindah tab
    notifyListeners();
  }

  // ============================================================================
  // SEARCH / FILTER
  // ============================================================================

  /// Update search query dan trigger filter
  void updateSearchQuery(String query) {
    // Sanitasi query untuk mencegah input berbahaya
    final sanitized = _sanitizeSearchQuery(query);
    _searchQuery = sanitized.toLowerCase();
    notifyListeners();
  }

  /// Sanitasi input search: hilangkan karakter kontrol, tag/script, dan angle brackets
  String _sanitizeSearchQuery(String raw) {
    var q = raw.trim();

    // Hilangkan karakter kontrol non-printable
    q = q.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

    // Hilangkan angle brackets untuk cegah HTML/script
    q = q.replaceAll(RegExp(r'[<>]'), '');

    // Hilangkan pola script sederhana
    q = q.replaceAll(RegExp(r'</?script>', caseSensitive: false), '');

    return q;
  }

  /// Filter supplier berdasarkan nama atau alamat
  List<ListSupplierJson> _filterSuppliers() {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      return s.supplierName.toLowerCase().contains(_searchQuery) ||
          s.supplierAddress.toLowerCase().contains(_searchQuery) ||
          s.supplierCity.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// Filter customer berdasarkan nama, alamat, atau nomor telepon
  List<ListCustomerJson> _filterCustomers() {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      return c.customerName.toLowerCase().contains(_searchQuery) ||
          c.customerAddress.toLowerCase().contains(_searchQuery) ||
          c.customerPhone.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// Filter product berdasarkan nama atau kode
  List<ListProductJson> _filterProducts() {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      return p.productName.toLowerCase().contains(_searchQuery) ||
          p.productCode.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // ============================================================================
  // DATA FETCHING
  // ============================================================================

  /// Load semua data (supplier, customer, product) dari repository
  Future<void> loadAllData() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Fetch semua data secara paralel untuk efisiensi
      final results = await Future.wait([
        _repository.getSuppliers(),
        _repository.getCustomers(),
        _repository.getProducts(),
      ]);

      _suppliers = results[0] as List<ListSupplierJson>;
      _customers = results[1] as List<ListCustomerJson>;
      _products = results[2] as List<ListProductJson>;
    } on DataRepositoryException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh data untuk tab yang aktif
  Future<void> refreshCurrentTab() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      switch (_activeTab) {
        case DataTab.supplier:
          _suppliers = await _repository.getSuppliers();
          break;
        case DataTab.customer:
          _customers = await _repository.getCustomers();
          break;
        case DataTab.product:
          _products = await _repository.getProducts();
          break;
      }
    } on DataRepositoryException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // DATA INSERTION (hanya Supplier & Customer)
  // ============================================================================

  /// Menambahkan supplier baru
  /// Returns: bool - true jika berhasil, false jika gagal
  /// Throws: Exception dengan pesan error untuk ditampilkan di UI
  Future<bool> addSupplier({
    required String name,
    required String address,
    required String city,
    required String subdistrict,
    required String postCode,
  }) async {
    // Validasi input
    final validationError = _validateSupplierInput(
      name: name,
      address: address,
      city: city,
      subdistrict: subdistrict,
      postCode: postCode,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Sanitasi input
    final supplier = ListSupplierJson(
      supplierName: _sanitizeInput(name),
      supplierAddress: _sanitizeInput(address),
      supplierCity: _sanitizeInput(city),
      supplierSubdistrict: _sanitizeInput(subdistrict),
      supplierPostCode: _sanitizeInput(postCode),
    );

    try {
      await _repository.addSupplier(supplier);
      // Refresh data supplier setelah insert berhasil
      _suppliers = await _repository.getSuppliers();
      notifyListeners();
      return true;
    } on DataRepositoryException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Menambahkan customer baru
  /// Returns: bool - true jika berhasil, false jika gagal
  /// Throws: Exception dengan pesan error untuk ditampilkan di UI
  Future<bool> addCustomer({
    required String name,
    required String address,
    required String phone,
  }) async {
    // Validasi input
    final validationError = _validateCustomerInput(
      name: name,
      address: address,
      phone: phone,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Sanitasi input
    final customer = ListCustomerJson(
      customerName: _sanitizeInput(name),
      customerAddress: _sanitizeInput(address),
      customerPhone: _sanitizePhoneNumber(phone),
    );

    try {
      await _repository.addCustomer(customer);
      // Refresh data customer setelah insert berhasil
      _customers = await _repository.getCustomers();
      notifyListeners();
      return true;
    } on DataRepositoryException catch (e) {
      throw Exception(e.message);
    }
  }

  // ============================================================================
  // INPUT VALIDATION
  // ============================================================================

  /// Validasi input supplier
  /// Returns: String error message jika invalid, null jika valid
  String? _validateSupplierInput({
    required String name,
    required String address,
    required String city,
    required String subdistrict,
    required String postCode,
  }) {
    if (name.trim().isEmpty) return 'Nama supplier harus diisi';
    if (name.trim().length < 3) return 'Nama supplier minimal 3 karakter';
    if (name.trim().length > 100) return 'Nama supplier maksimal 100 karakter';
    final addressError = _validateAddress(address);
    if (addressError != null) return addressError;
    
    if (city.trim().isEmpty) return 'Kota harus diisi';
    if (city.trim().length > 50) return 'Kota maksimal 50 karakter';
    
    if (subdistrict.trim().isEmpty) return 'Kecamatan harus diisi';
    if (subdistrict.trim().length > 50) return 'Kecamatan maksimal 50 karakter';
    
    if (postCode.trim().isEmpty) return 'Kode pos harus diisi';
    if (!_isValidPostCode(postCode)) return 'Format kode pos tidak valid (5 digit angka)';
    
    return null;
  }

  /// Validasi input customer
  /// Returns: String error message jika invalid, null jika valid
  String? _validateCustomerInput({
    required String name,
    required String address,
    required String phone,
  }) {
    if (name.trim().isEmpty) return 'Nama customer harus diisi';
    if (name.trim().length < 3) return 'Nama customer minimal 3 karakter';
    if (name.trim().length > 100) return 'Nama customer maksimal 100 karakter';
    final addressError = _validateAddress(address);
    if (addressError != null) return addressError;
    
    if (phone.trim().isEmpty) return 'Nomor telepon harus diisi';
    final phoneError = _validatePhoneNumber(phone);
    if (phoneError != null) return phoneError;
    
    return null;
  }

  /// Validator publik untuk dipakai langsung di TextFormField
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon harus diisi';
    }
    return _validatePhoneNumber(value);
  }

  /// Validasi format nomor telepon Indonesia dengan pesan error spesifik
  /// Mendukung: 08xx, +628xx, 628xx, 021-xxxx, (021) xxxx
  String? _validatePhoneNumber(String phone) {
    final raw = phone.trim();

    // Tolak karakter selain angka, spasi, tanda +, -, atau tanda kurung
    if (RegExp(r'[^\d\s\-\+\(\)]').hasMatch(raw)) {
      return 'Nomor telepon hanya boleh berisi angka, spasi, +, -, atau tanda kurung';
    }

    // Pastikan tanda + hanya di posisi awal (jika ada)
    if (raw.indexOf('+') > 0 || raw.substring(1).contains('+')) {
      return 'Tanda + hanya boleh di awal nomor';
    }

    // Normalisasi: hapus spasi, tanda kurung, dan strip untuk pengecekan
    final normalized = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Cek prefix yang valid
    if (!(normalized.startsWith('+62') ||
        normalized.startsWith('62') ||
        normalized.startsWith('0'))) {
      return 'Nomor telepon harus diawali +62, 62, atau 0';
    }

    // Ambil bagian setelah prefix untuk pengecekan panjang digit
    final subscriber = normalized.startsWith('+62')
        ? normalized.substring(3)
        : normalized.startsWith('62')
            ? normalized.substring(2)
            : normalized.substring(1);

    if (subscriber.length < 8 || subscriber.length > 13) {
      return 'Panjang nomor setelah prefix harus 8-13 digit';
    }

    // Pastikan hanya angka (selain tanda + yang sudah di awal)
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(normalized)) {
      return 'Nomor telepon hanya boleh mengandung angka';
    }

    return null;
  }

  /// Validasi format kode pos (5 digit angka)
  bool _isValidPostCode(String postCode) {
    final pattern = RegExp(r'^[0-9]{5}$');
    return pattern.hasMatch(postCode.trim());
  }

  /// Validasi alamat untuk mencegah input berbahaya (script/HTML/tag)
  String? _validateAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return 'Alamat harus diisi';
    if (trimmed.length > 200) return 'Alamat maksimal 200 karakter';

    // Tolak karakter kontrol dan angle brackets untuk menghindari injection/HTML/script
    if (RegExp(r'[<>]').hasMatch(trimmed)) {
      return 'Alamat tidak boleh mengandung karakter < atau >';
    }

    // Tolak pola script sederhana (case-insensitive) tanpa inline flag yang tidak didukung
    if (RegExp(r'</?script>', caseSensitive: false).hasMatch(trimmed)) {
      return 'Alamat tidak valid';
    }

    // Tolak karakter kontrol non-printable
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(trimmed)) {
      return 'Alamat mengandung karakter tidak valid';
    }

    return null;
  }

  // ============================================================================
  // INPUT SANITIZATION
  // ============================================================================

  /// Sanitasi input umum: trim whitespace, hapus karakter berbahaya
  String _sanitizeInput(String input) {
    // Hilangkan whitespace berlebih & karakter kontrol, cegah script tag sederhana
    final trimmed = input.trim();
    final noCtrl = trimmed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return noCtrl;
  }

  /// Sanitasi nomor telepon: hapus karakter non-angka kecuali + di depan
  String _sanitizePhoneNumber(String phone) {
    // Simpan tanda + jika ada di depan
    final hasPlus = phone.trim().startsWith('+');
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return hasPlus ? '+$cleaned' : cleaned;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cleanup jika diperlukan
    super.dispose();
  }
}
