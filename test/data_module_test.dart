/// ============================================================================
/// Unit Tests untuk Data Module
/// ============================================================================
/// File: data_module_test.dart
/// Deskripsi: Unit tests untuk Repository dan Controller di Data Management module.
/// 
/// Tests mencakup:
/// 1. DataRepository: Mock DbHelper, verifikasi fetch dan insert
/// 2. DataController: Verifikasi search/filter dan state management
/// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:dakara_weighbridge/Json/listcustomer_json.dart';
import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/Json/listsupplier_json.dart';
import 'package:dakara_weighbridge/Pages/data/data_controller.dart';
import 'package:dakara_weighbridge/Pages/data/data_repository.dart';

// ============================================================================
// MOCK CLASSES
// ============================================================================

/// Mock Repository untuk testing Controller
/// Karena DbHelper menggunakan singleton pattern, mock repository langsung
class MockDataRepository extends DataRepository {
  final List<ListSupplierJson> mockSuppliers;
  final List<ListCustomerJson> mockCustomers;
  final List<ListProductJson> mockProducts;
  bool shouldThrowError = false;
  
  bool addSupplierCalled = false;
  bool addCustomerCalled = false;
  ListSupplierJson? lastAddedSupplier;
  ListCustomerJson? lastAddedCustomer;

  MockDataRepository({
    this.mockSuppliers = const [],
    this.mockCustomers = const [],
    this.mockProducts = const [],
  }) : super();

  @override
  Future<List<ListSupplierJson>> getSuppliers() async {
    if (shouldThrowError) {
      throw DataRepositoryException('Mock error');
    }
    return mockSuppliers;
  }

  @override
  Future<List<ListCustomerJson>> getCustomers() async {
    if (shouldThrowError) {
      throw DataRepositoryException('Mock error');
    }
    return mockCustomers;
  }

  @override
  Future<List<ListProductJson>> getProducts() async {
    if (shouldThrowError) {
      throw DataRepositoryException('Mock error');
    }
    return mockProducts;
  }

  @override
  Future<int> addSupplier(ListSupplierJson supplier) async {
    if (shouldThrowError) {
      throw DataRepositoryException('Mock error');
    }
    addSupplierCalled = true;
    lastAddedSupplier = supplier;
    return 1;
  }

  @override
  Future<int> addCustomer(ListCustomerJson customer) async {
    if (shouldThrowError) {
      throw DataRepositoryException('Mock error');
    }
    addCustomerCalled = true;
    lastAddedCustomer = customer;
    return 1;
  }
}

// ============================================================================
// SAMPLE DATA
// ============================================================================

final sampleSuppliers = [
  ListSupplierJson(
    supplierId: 1,
    supplierName: 'PT Konstruksi Indo',
    supplierAddress: 'Jl. Sudirman No. 100',
    supplierCity: 'Jakarta',
    supplierSubdistrict: 'Menteng',
    supplierPostCode: '10310',
  ),
  ListSupplierJson(
    supplierId: 2,
    supplierName: 'CV Mega Karya',
    supplierAddress: 'Jl. Gatot Subroto No. 55',
    supplierCity: 'Jakarta',
    supplierSubdistrict: 'Setiabudi',
    supplierPostCode: '12930',
  ),
];

final sampleCustomers = [
  ListCustomerJson(
    customerId: 1,
    customerName: 'PT ABC Indonesia',
    customerAddress: 'Jl. Ahmad Yani No. 23, Bekasi',
    customerPhone: '021-8888-9012',
  ),
  ListCustomerJson(
    customerId: 2,
    customerName: 'CV XYZ Jaya',
    customerAddress: 'Jl. Thamrin No. 88, Jakarta',
    customerPhone: '021-3333-4567',
  ),
];

final sampleProducts = [
  ListProductJson(
    productId: 1,
    productName: 'Besi Beton',
    productCode: 'BB-001',
  ),
  ListProductJson(
    productId: 2,
    productName: 'Semen Portland',
    productCode: 'SP-002',
  ),
];

// ============================================================================
// REPOSITORY TESTS
// ============================================================================

void main() {
  group('DataRepository Tests (via MockDataRepository)', () {
    test('getSuppliers should return list', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockSuppliers: sampleSuppliers);

      // Act
      final result = await mockRepo.getSuppliers();

      // Assert
      expect(result.length, 2);
      expect(result[0].supplierName, 'PT Konstruksi Indo');
      // NOTE: supplierId tetap ada di model, tapi tidak ditampilkan di UI
    });

    test('getCustomers should return list', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockCustomers: sampleCustomers);

      // Act
      final result = await mockRepo.getCustomers();

      // Assert
      expect(result.length, 2);
      expect(result[0].customerName, 'PT ABC Indonesia');
    });

    test('getProducts should return list', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockProducts: sampleProducts);

      // Act
      final result = await mockRepo.getProducts();

      // Assert
      expect(result.length, 2);
      expect(result[0].productName, 'Besi Beton');
    });

    test('addSupplier should set flag and store supplier', () async {
      // Arrange
      final mockRepo = MockDataRepository();
      final newSupplier = ListSupplierJson(
        supplierName: 'Test Supplier',
        supplierAddress: 'Test Address',
        supplierCity: 'Test City',
        supplierSubdistrict: 'Test Subdistrict',
        supplierPostCode: '12345',
      );

      // Act
      await mockRepo.addSupplier(newSupplier);

      // Assert
      expect(mockRepo.addSupplierCalled, true);
      expect(mockRepo.lastAddedSupplier?.supplierName, 'Test Supplier');
    });

    test('addCustomer should set flag and store customer', () async {
      // Arrange
      final mockRepo = MockDataRepository();
      final newCustomer = ListCustomerJson(
        customerName: 'Test Customer',
        customerAddress: 'Test Address',
        customerPhone: '08123456789',
      );

      // Act
      await mockRepo.addCustomer(newCustomer);

      // Assert
      expect(mockRepo.addCustomerCalled, true);
      expect(mockRepo.lastAddedCustomer?.customerName, 'Test Customer');
    });

    test('getSuppliers should throw error when shouldThrowError is true', () async {
      // Arrange
      final mockRepo = MockDataRepository();
      mockRepo.shouldThrowError = true;

      // Act & Assert
      expect(() => mockRepo.getSuppliers(), throwsA(isA<DataRepositoryException>()));
    });
  });

  // ============================================================================
  // CONTROLLER TESTS
  // ============================================================================

  group('DataController Tests', () {
    test('loadAllData should populate all lists', () async {
      // Arrange
      final mockRepo = MockDataRepository(
        mockSuppliers: sampleSuppliers,
        mockCustomers: sampleCustomers,
        mockProducts: sampleProducts,
      );
      final controller = DataController(repository: mockRepo);

      // Act
      await controller.loadAllData();

      // Assert
      expect(controller.supplierCount, 2);
      expect(controller.customerCount, 2);
      expect(controller.productCount, 2);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, null);
    });

    test('setActiveTab should change active tab', () {
      // Arrange
      final controller = DataController();

      // Act & Assert
      expect(controller.activeTab, DataTab.supplier); // default

      controller.setActiveTab(DataTab.customer);
      expect(controller.activeTab, DataTab.customer);

      controller.setActiveTab(DataTab.product);
      expect(controller.activeTab, DataTab.product);
    });

    test('updateSearchQuery should filter suppliers', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockSuppliers: sampleSuppliers);
      final controller = DataController(repository: mockRepo);
      await controller.loadAllData();

      // Act
      controller.updateSearchQuery('Konstruksi');

      // Assert
      expect(controller.suppliers.length, 1);
      expect(controller.suppliers[0].supplierName, 'PT Konstruksi Indo');
    });

    test('updateSearchQuery should filter customers', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockCustomers: sampleCustomers);
      final controller = DataController(repository: mockRepo);
      await controller.loadAllData();
      controller.setActiveTab(DataTab.customer);

      // Act
      controller.updateSearchQuery('ABC');

      // Assert
      expect(controller.customers.length, 1);
      expect(controller.customers[0].customerName, 'PT ABC Indonesia');
    });

    test('updateSearchQuery should filter products', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockProducts: sampleProducts);
      final controller = DataController(repository: mockRepo);
      await controller.loadAllData();
      controller.setActiveTab(DataTab.product);

      // Act
      controller.updateSearchQuery('Beton');

      // Assert
      expect(controller.products.length, 1);
      expect(controller.products[0].productName, 'Besi Beton');
    });

    test('empty search query should return all data', () async {
      // Arrange
      final mockRepo = MockDataRepository(mockSuppliers: sampleSuppliers);
      final controller = DataController(repository: mockRepo);
      await controller.loadAllData();

      // Act
      controller.updateSearchQuery('Konstruksi');
      expect(controller.suppliers.length, 1);

      controller.updateSearchQuery('');

      // Assert
      expect(controller.suppliers.length, 2);
    });

    test('loadAllData should set error message on failure', () async {
      // Arrange
      final mockRepo = MockDataRepository();
      mockRepo.shouldThrowError = true;
      final controller = DataController(repository: mockRepo);

      // Act
      await controller.loadAllData();

      // Assert
      expect(controller.errorMessage, isNotNull);
      expect(controller.isLoading, false);
    });

    test('addSupplier should validate required fields', () async {
      // Arrange
      final controller = DataController();

      // Act & Assert
      expect(
        () => controller.addSupplier(
          name: '',
          address: 'Test Address',
          city: 'Test City',
          subdistrict: 'Test Sub',
          postCode: '12345',
        ),
        throwsException,
      );
    });

    test('addSupplier should validate post code format', () async {
      // Arrange
      final controller = DataController();

      // Act & Assert
      expect(
        () => controller.addSupplier(
          name: 'Test Supplier',
          address: 'Test Address',
          city: 'Test City',
          subdistrict: 'Test Sub',
          postCode: '123', // Invalid: harus 5 digit
        ),
        throwsException,
      );
    });

    test('addCustomer should validate phone format', () async {
      // Arrange
      final controller = DataController();

      // Act & Assert
      expect(
        () => controller.addCustomer(
          name: 'Test Customer',
          address: 'Test Address',
          phone: '123', // Invalid phone format
        ),
        throwsException,
      );
    });

    test('clearError should reset error message', () async {
      // Arrange
      final mockRepo = MockDataRepository();
      mockRepo.shouldThrowError = true;
      final controller = DataController(repository: mockRepo);
      await controller.loadAllData();
      expect(controller.errorMessage, isNotNull);

      // Act
      controller.clearError();

      // Assert
      expect(controller.errorMessage, null);
    });
  });
}
