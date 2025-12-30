import 'dart:convert';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl;

  PaymentService({String? baseUrl, required String authToken})
      : baseUrl = baseUrl ?? AppConfig.getBaseUrl();

  /// Fetch pending orders for payment
  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      final String? authToken = await _getUserToken();
      if (authToken == null) throw Exception('Authentication token not found');

      final url = Uri.parse('$baseUrl/api/orders/pending-payment/');
      print('DEBUG: Fetching pending orders from $url');
      print('DEBUG: Auth token: ${authToken.substring(0, 10)}...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      } else if (response.statusCode == 400) {
        print('DEBUG: No orders found for payment');
        return [];
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPendingOrders: $e');
      return [];
    }
  }

  /// Initialize payment for a specific order
  Future<Map<String, dynamic>> initializePayment({
    required String orderId,
    required String email,
  }) async {
    try {
      // Input validation
      if (orderId.isEmpty) {
        return {'status': false, 'message': 'Order ID cannot be empty'};
      }
      if (email.isEmpty) {
        return {'status': false, 'message': 'Email cannot be empty'};
      }
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return {'status': false, 'message': 'Invalid email format'};
      }

      final String? authToken = await _getUserToken();
      if (authToken == null || authToken.isEmpty) {
        return {'status': false, 'message': 'Authentication token not found'};
      }

      final requestBody = {'order_id': orderId, 'email': email};
      print('DEBUG: Payment request body: $requestBody');

      final url = Uri.parse('$baseUrl${AppConfig.paystackInitializeEndpoint}');
      print('DEBUG: Payment init URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Payment init status code: ${response.statusCode}');
      print('DEBUG: Payment init body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'status': false,
          'message':
              'Invalid request data: ${errorData['message'] ?? errorData.toString()}',
          'errors': errorData,
        };
      } else {
        return {
          'status': false,
          'message': 'Server error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  /// Get user auth token from SharedPreferences
  static Future<String?> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');
      print('DEBUG: Token found: ${token?.substring(0, 10)}...');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}
