import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String baseUrl = 'http://your-django-server.com/api';
  
  static Future<Map<String, dynamic>> initializePayment({
    required double amount,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/initialize-payment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to initialize payment');
      }
    } catch (e) {
      throw Exception('Payment initialization error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/verify-payment/$reference/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify payment');
      }
    } catch (e) {
      throw Exception('Payment verification error: $e');
    }
  }
}