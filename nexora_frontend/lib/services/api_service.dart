import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/purchase_order.dart';
import '../models/shop.dart';

class ApiService {
  // Base URL resolution order:
  //   1. Compile-time:  flutter run --dart-define=API_BASE_URL=https://x/api
  //   2. Runtime:       the ⚙ server button on the login page (saved to
  //                     SharedPreferences) -- so the GitHub Pages web build
  //                     can be pointed at any running backend without a
  //                     rebuild.
  //   3. Fallback:      the local Django dev server.
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static String? _overrideBaseUrl;

  static String get baseUrl => _overrideBaseUrl ?? _defaultBaseUrl;

  /// Point the app at a different backend at runtime. Pass null to reset to
  /// the compile-time default.
  static Future<void> setServerUrl(String? url) async {
    _overrideBaseUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_overrideBaseUrl == null) {
      await prefs.remove('server_base_url');
    } else {
      await prefs.setString('server_base_url', _overrideBaseUrl!);
    }
  }

  /// The URL chosen at runtime, or null when the compile-time default is in
  /// use (used by the login page's server picker to pre-fill its field).
  static Future<String?> getServerUrl() async {
    if (_overrideBaseUrl != null) return _overrideBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_base_url');
  }

  /// Load any saved runtime override -- call once at app startup.
  static Future<void> loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_base_url');
    _overrideBaseUrl = (saved == null || saved.isEmpty) ? null : saved;
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final data = jsonData['data'] ?? jsonData;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access'] ?? '');
      await prefs.setString('refresh_token', data['refresh'] ?? '');
      await prefs.setString('user', jsonEncode(data['user'] ?? {}));
      return data;
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final msg = errorData['detail'] ?? errorData['message'] ?? 'Login failed';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Login failed: ${response.statusCode}');
      }
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );
      } catch (_) {}
    }
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
  }

  /// Returns the logged-in user's email from the stored session profile.
  /// Used to link purchases to the customer account (RFM + My Orders).
  static Future<String> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return '';
    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      return (user['email'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  /// Clears locally stored session data without any network calls.
  /// Used at app startup so a stale session can never auto-log anyone in.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
  }

  /// Checks whether the stored access token is still valid by calling
  /// /auth/me/. Tries one silent refresh when the access token has expired.
  /// Returns true only when the backend confirms the session, so a stale
  /// token can never land the user inside a dashboard.
  static Future<bool> validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) return false;

    Future<bool> check() async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/auth/me/'),
          headers: {
            'Authorization': 'Bearer ${prefs.getString('access_token') ?? token}',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          // Keep the cached profile fresh so role changes propagate.
          try {
            final decoded = jsonDecode(response.body);
            final user = decoded is Map<String, dynamic> && decoded.containsKey('data')
                ? decoded['data']
                : decoded;
            if (user is Map<String, dynamic>) {
              await prefs.setString('user', jsonEncode(user));
            }
          } catch (_) {}
          return true;
        }
        return false;
      } catch (_) {
        return false; // unreachable server -> treat as unvalidated
      }
    }

    if (await check()) return true;

    // Access token may have just expired: one silent refresh, then re-check.
    if (await _refreshToken()) {
      return await check();
    }
    return false;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('Not logged in');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'] ?? jsonData;
        await prefs.setString('access_token', data['access'] ?? '');
        return true;
      }
    } catch (e) {}
    return false;
  }

  static Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _authHeaders();

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else if (method == 'PATCH') {
        response = await http.patch(url, headers: headers, body: jsonEncode(body));
      } else {
        throw Exception('Unsupported method');
      }

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _authHeaders();
          if (method == 'GET') {
            response = await http.get(url, headers: newHeaders);
          } else if (method == 'POST') {
            response = await http.post(url, headers: newHeaders, body: jsonEncode(body));
          } else if (method == 'PUT') {
            response = await http.put(url, headers: newHeaders, body: jsonEncode(body));
          } else if (method == 'DELETE') {
            response = await http.delete(url, headers: newHeaders);
          } else if (method == 'PATCH') {
            response = await http.patch(url, headers: newHeaders, body: jsonEncode(body));
          }
          // If the refresh failed too, rethrow the original 401 below.
          if (response.statusCode == 401) {
            throw Exception('Session expired. Please log in again.');
          }
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
            return decoded['data'];
          }
          return decoded;
        }
        return {};
      } else {
        String errorMsg = 'Request failed: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            final errors = <String>[];
            errorData.forEach((key, value) {
              if (value is List) {
                errors.add('$key: ${value.join(', ')}');
              } else if (value is String) {
                errors.add('$key: $value');
              } else if (value is Map) {
                value.forEach((subKey, subValue) {
                  errors.add('$key.$subKey: ${subValue is List ? subValue.join(', ') : subValue}');
                });
              }
            });
            if (errors.isNotEmpty) {
              errorMsg = errors.join('; ');
            }
          } else if (errorData is String) {
            errorMsg = errorData;
          }
        } catch (_) {
          // Body is not JSON -- likely an HTML server error page (Django 500
          // page). Never dump raw HTML into a snackbar; show a short message.
          final body = response.body;
          if (body.contains('<!DOCTYPE') || body.contains('<title>')) {
            final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(body);
            final title = titleMatch?.group(1)?.trim().split('\n').first ?? 'Server error';
            errorMsg = 'Server error ($title). Check the Django console for details.';
          } else if (body.isNotEmpty) {
            errorMsg = body.length > 200 ? '${body.substring(0, 200)}…' : body;
          }
        }
        // RETHROW the real HTTP error instead of swallowing it into a
        // generic 'Network error' that hid the actual problem from the user.
        throw Exception(errorMsg);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      // Only genuine connectivity failures (SocketException, etc.) land here.
      throw Exception('Network error: $e');
    }
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  static Future<List<Product>> getProducts() async {
    final response = await _request('GET', '/products/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await _request('POST', '/products/', body: data);
    if (response is Map<String, dynamic>) {
      return Product.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _request('PUT', '/products/$id/', body: data);
    if (response is Map<String, dynamic>) {
      return Product.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<void> deleteProduct(String id) async {
    await _request('DELETE', '/products/$id/');
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  static Future<List<Category>> getCategoriesTree() async {
    final response = await _request('GET', '/categories/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Category> createCategory(Map<String, dynamic> data) async {
    final response = await _request('POST', '/categories/', body: data);
    if (response is Map<String, dynamic>) {
      return Category.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<Category> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _request('PUT', '/categories/$id/', body: data);
    if (response is Map<String, dynamic>) {
      return Category.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<void> deleteCategory(String id) async {
    await _request('DELETE', '/categories/$id/');
  }

  // ============================================================
  // SHOPS – FULL CRUD
  // ============================================================

  static Future<List<Shop>> getShops() async {
    final response = await _request('GET', '/shops/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => Shop.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Shop> createShop(Map<String, dynamic> data) async {
    final response = await _request('POST', '/shops/', body: data);
    if (response is Map<String, dynamic>) {
      return Shop.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<Shop> updateShop(String id, Map<String, dynamic> data) async {
    final response = await _request('PUT', '/shops/$id/', body: data);
    if (response is Map<String, dynamic>) {
      return Shop.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<void> deleteShop(String id) async {
    await _request('DELETE', '/shops/$id/');
  }

  // ============================================================
  // SALES
  // ============================================================

  static Future<List<Sale>> getSales({String? customerId, bool mine = false}) async {
    String url = '/sales/';
    if (mine) {
      url = '/sales/mine/';
    } else if (customerId != null) {
      url += '?customer=$customerId';
    }
    final response = await _request('GET', url);
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => Sale.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Sale> createSale(Map<String, dynamic> data) async {
    final response = await _request('POST', '/sales/', body: data);
    if (response is Map<String, dynamic>) {
      return Sale.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  /// RFM segment distribution for the current shop.
  static Future<List<Map<String, dynamic>>> getRfmSegments() async {
    final response = await _request('GET', '/customers/rfm_segments/');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  // ============================================================
  // CUSTOMERS
  // ============================================================

  static Future<List<Customer>> getCustomers() async {
    final response = await _request('GET', '/customers/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => Customer.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await _request('POST', '/customers/', body: data);
    if (response is Map<String, dynamic>) {
      return Customer.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<Customer> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await _request('PUT', '/customers/$id/', body: data);
    if (response is Map<String, dynamic>) {
      return Customer.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  static Future<void> deleteCustomer(String id) async {
    await _request('DELETE', '/customers/$id/');
  }

  // ============================================================
  // SUPPLIERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getSuppliers() async {
    final response = await _request('GET', '/suppliers/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    final response = await _request('POST', '/suppliers/', body: data);
    if (response is Map<String, dynamic>) return response;
    throw Exception('Invalid response format');
  }

  // ============================================================
  // PURCHASE ORDERS
  // ============================================================

  static Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await _request('GET', '/purchase-orders/');
    List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic>) {
      list = response['results'] ?? [];
    } else {
      list = [];
    }
    return list.map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<PurchaseOrder> createPurchaseOrder(Map<String, dynamic> data) async {
    final response = await _request('POST', '/purchase-orders/', body: data);
    if (response is Map<String, dynamic>) {
      return PurchaseOrder.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  // ============================================================
  // GOODS INFO (placeholder)
  // ============================================================

  static Future<List<dynamic>> getGoodsInfo() async {
    return [];
  }

  static Future<Map<String, dynamic>> createGoodsInfo(Map<String, dynamic> data) async {
    throw Exception('Goods info feature not implemented');
  }

  static Future<void> deleteGoodsInfo(String id) async {
    throw Exception('Goods info feature not implemented');
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _request('GET', '/auth/me/');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final updated = await _request('PATCH', '/auth/me/', body: data);
    // Keep the cached session user (name/phone/avatar) in sync for next launch.
    if (updated is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updated));
    }
  }

  /// Uploads a new profile picture: multipart PATCH of the raw image bytes.
  /// Returns the updated user map, including the absolute avatar_url.
  static Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes, String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) throw Exception('Not logged in');

    final request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/auth/me/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: filename));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      // Access token expired mid-upload: refresh once and retry.
      if (await _refreshToken()) {
        return uploadAvatar(bytes, filename);
      }
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Upload failed (${response.statusCode})';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          if (err['detail'] is String) {
            msg = err['detail'];
          } else if (err['errors'] is Map) {
            (err['errors'] as Map).forEach((k, v) {
              msg += ' ${k}: ${v is List ? v.join(", ") : v}';
            });
          }
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
    if (data is Map<String, dynamic>) {
      await prefs.setString('user', jsonEncode(data));
      return data;
    }
    return {};
  }

  // ============================================================
  // REGISTRATION (real account + shop creation)
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String shopName,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'shop_name': shopName,
        'phone': phone ?? '',
      }),
    );
    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      final data = jsonData['data'] ?? jsonData;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access'] ?? '');
      await prefs.setString('refresh_token', data['refresh'] ?? '');
      await prefs.setString('user', jsonEncode(data['user'] ?? {}));
      return data;
    }
    String msg = 'Registration failed';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData['errors'] is Map) {
        final errors = errorData['errors'] as Map;
        msg = errors.entries
            .map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}')
            .join('; ');
      }
    } catch (_) {}
    throw Exception(msg);
  }

  // ============================================================
  // UTILITY
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }
}