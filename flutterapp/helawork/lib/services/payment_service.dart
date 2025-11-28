import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'http://192.168.100.188:8000/api';

  // Initialize payment with Django backend
  static Future<Map<String, dynamic>> initializePayment({
    required String orderId,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/initialize/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Verify payment status
  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/verify/$reference/'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Verification failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get order details
  static Future<Map<String, dynamic>> getOrderDetails({
    required String orderId,
    required String email,
    required double amount,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/order/$orderId/?email=$email&amount=$amount'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Failed to fetch order details',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get transaction history
  static Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/history/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Failed to fetch transactions',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }
}