import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Product {
  String id;
  String cid;
  String cName;
  String volumeFrom;
  String volumeTo;
  String dateFrom;
  String dateTo;
  double price;
  double? offPrice;
  String? imagePath;

  Product({
    required this.id,
    required this.cid,
    required this.cName,
    required this.volumeFrom,
    required this.volumeTo,
    required this.dateFrom,
    required this.dateTo,
    required this.price,
    this.offPrice,
    this.imagePath,
  });

  double get effectivePrice => offPrice != null && offPrice! < price ? offPrice! : price;

  Map<String, dynamic> toJson() => {
    'id': id,
    'cid': cid,
    'cName': cName,
    'volumeFrom': volumeFrom,
    'volumeTo': volumeTo,
    'dateFrom': dateFrom,
    'dateTo': dateTo,
    'price': price,
    'offPrice': offPrice,
    'imagePath': imagePath,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    cid: json['cid'],
    cName: json['cName'],
    volumeFrom: json['volumeFrom'],
    volumeTo: json['volumeTo'],
    dateFrom: json['dateFrom'],
    dateTo: json['dateTo'],
    price: json['price'],
    offPrice: json['offPrice'],
    imagePath: json['imagePath'],
  );
}

class GoodsInfoRecord {
  String id;
  String forField;
  String fromField;
  DateTime startDate;
  DateTime endDate;
  double volumeBuying;
  double volumeSelling;
  double price;

  GoodsInfoRecord({
    required this.id,
    required this.forField,
    required this.fromField,
    required this.startDate,
    required this.endDate,
    required this.volumeBuying,
    required this.volumeSelling,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'forField': forField,
    'fromField': fromField,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'volumeBuying': volumeBuying,
    'volumeSelling': volumeSelling,
    'price': price,
  };

  factory GoodsInfoRecord.fromJson(Map<String, dynamic> json) => GoodsInfoRecord(
    id: json['id'],
    forField: json['forField'],
    fromField: json['fromField'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    volumeBuying: json['volumeBuying'],
    volumeSelling: json['volumeSelling'],
    price: json['price'],
  );
}

class Customer {
  String username;
  double totalSpent;
  String email;
  String? profileImagePath;

  Customer({required this.username, required this.email, this.profileImagePath, this.totalSpent = 0});

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'profileImagePath': profileImagePath,
    'totalSpent': totalSpent,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    username: json['username'],
    email: json['email'],
    profileImagePath: json['profileImagePath'],
    totalSpent: json['totalSpent'],
  );
}

class Sale {
  String id;
  String productId;
  String productName;
  int quantity;
  double totalPrice;
  DateTime date;
  String customerUsername;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.date,
    required this.customerUsername,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'date': date.toIso8601String(),
    'customerUsername': customerUsername,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    totalPrice: json['totalPrice'],
    date: DateTime.parse(json['date']),
    customerUsername: json['customerUsername'],
  );
}

class PurchaseOrder {
  String id;
  String productId;
  String productName;
  int quantity;
  double totalCost;
  DateTime date;

  PurchaseOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalCost,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalCost': totalCost,
    'date': date.toIso8601String(),
  };

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
    id: json['id'],
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    totalCost: json['totalCost'],
    date: DateTime.parse(json['date']),
  );
}

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  List<Product> _products = [];
  List<GoodsInfoRecord> _goodsInfoRecords = [];
  List<Customer> _customers = [];
  List<Sale> _sales = [];
  List<PurchaseOrder> _purchaseOrders = [];

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Products
    String? productsJson = prefs.getString('products');
    if (productsJson != null) {
      List<dynamic> decoded = jsonDecode(productsJson);
      _products = decoded.map((p) => Product.fromJson(p)).toList();
    } else {
      _products = _defaultProducts();
      await saveProducts();
    }

    // Goods Info Records
    String? goodsInfoJson = prefs.getString('goods_info_records');
    if (goodsInfoJson != null) {
      List<dynamic> decoded = jsonDecode(goodsInfoJson);
      _goodsInfoRecords = decoded.map((r) => GoodsInfoRecord.fromJson(r)).toList();
    } else {
      _goodsInfoRecords = [];
    }

    // Customers
    String? customersJson = prefs.getString('customers');
    if (customersJson != null) {
      List<dynamic> decoded = jsonDecode(customersJson);
      _customers = decoded.map((c) => Customer.fromJson(c)).toList();
    } else {
      _customers = [];
    }

    // Sales
    String? salesJson = prefs.getString('sales');
    if (salesJson != null) {
      List<dynamic> decoded = jsonDecode(salesJson);
      _sales = decoded.map((s) => Sale.fromJson(s)).toList();
    } else {
      _sales = [];
    }

    // Purchase Orders
    String? purchasesJson = prefs.getString('purchase_orders');
    if (purchasesJson != null) {
      List<dynamic> decoded = jsonDecode(purchasesJson);
      _purchaseOrders = decoded.map((po) => PurchaseOrder.fromJson(po)).toList();
    } else {
      _purchaseOrders = [];
    }
  }

  List<Product> _defaultProducts() {
    return [
      Product(
        id: '1', cid: '12345', cName: 'Laptop',
        volumeFrom: '2kg', volumeTo: '3kg',
        dateFrom: '2025-01-01', dateTo: '2025-12-31',
        price: 899.99, offPrice: 799.99,
      ),
      Product(
        id: '2', cid: '67890', cName: 'T-Shirt',
        volumeFrom: '150g', volumeTo: '250g',
        dateFrom: '2025-03-01', dateTo: '2025-09-30',
        price: 19.99, offPrice: 14.99,
      ),
      Product(
        id: '3', cid: '11111', cName: 'Phone',
        volumeFrom: '200g', volumeTo: '300g',
        dateFrom: '2025-05-01', dateTo: '2025-08-15',
        price: 499.99, offPrice: null,
      ),
    ];
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(_products.map((p) => p.toJson()).toList());
    await prefs.setString('products', jsonStr);
  }

  Future<void> saveGoodsInfoRecords() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(_goodsInfoRecords.map((r) => r.toJson()).toList());
    await prefs.setString('goods_info_records', jsonStr);
  }

  Future<void> saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(_customers.map((c) => c.toJson()).toList());
    await prefs.setString('customers', jsonStr);
  }

  Future<void> saveSales() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(_sales.map((s) => s.toJson()).toList());
    await prefs.setString('sales', jsonStr);
  }

  Future<void> savePurchaseOrders() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(_purchaseOrders.map((po) => po.toJson()).toList());
    await prefs.setString('purchase_orders', jsonStr);
  }

  // Products
  List<Product> get products => List.unmodifiable(_products);
  void addProduct(Product p) { _products.add(p); saveProducts(); }
  void updateProduct(Product p) { int i = _products.indexWhere((prod) => prod.id == p.id); if (i != -1) _products[i] = p; saveProducts(); }
  void deleteProduct(String id) { _products.removeWhere((p) => p.id == id); saveProducts(); }

  // Goods Info Records
  List<GoodsInfoRecord> get goodsInfoRecords => List.unmodifiable(_goodsInfoRecords);
  void addGoodsInfoRecord(GoodsInfoRecord r) { _goodsInfoRecords.add(r); saveGoodsInfoRecords(); }
  void deleteGoodsInfoRecord(String id) { _goodsInfoRecords.removeWhere((r) => r.id == id); saveGoodsInfoRecords(); }

  // Customers
  List<Customer> get customers => List.unmodifiable(_customers);
  void addOrUpdateCustomer(Customer customer) {
    int index = _customers.indexWhere((c) => c.username == customer.username);
    if (index != -1) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    saveCustomers();
  }
  Customer? getCustomer(String username) {
    try {
      return _customers.firstWhere((c) => c.username == username);
    } catch (e) {
      return null;
    }
  }

  // Sales
  List<Sale> get sales => List.unmodifiable(_sales);
  void addSale(Sale sale) { _sales.add(sale); saveSales(); }

  // Purchase Orders
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  void addPurchaseOrder(PurchaseOrder po) { _purchaseOrders.add(po); savePurchaseOrders(); }
}