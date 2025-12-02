import 'dart:convert';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl;

  PaymentService({
    String? baseUrl, required String authToken,
  }) : baseUrl = baseUrl ?? AppConfig.getBaseUrl();

  

 Future<Map<String, dynamic>> initializePayment({
  required String orderId,
  required String email,
}) async {
  try {
    // VALIDATE INPUTS BEFORE SENDING
    if (orderId.isEmpty) {
      return {'status': false, 'message': 'Order ID cannot be empty'};
    }
    
    if (email.isEmpty) {
      return {'status': false, 'message': 'Email cannot be empty'};
    }
    
    // Validate email format
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return {'status': false, 'message': 'Invalid email format'};
    }

    final String? authToken = await _getUserToken();
    
    if (authToken == null || authToken.isEmpty) {
      return {'status': false, 'message': 'Authentication token not found'};
    }

    // DEBUG PRINT
    final requestBody = {
      'order_id': orderId,
      'email': email,
    };
    print('PAYMENT REQUEST BODY: $requestBody');

    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.paystackInitializeEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(requestBody),
    );

    // RESPONSE DEBUG
    print('PAYMENT RESPONSE: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      return {
        'status': false,
        'message': 'Invalid request data: ${errorData['message'] ?? errorData.toString()}',
        'errors': errorData,
      };
    } else {
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode} - ${response.body}',
      };
    }
  } catch (e) {
    return {
      'status': false,
      'message': 'Network error: $e',
    };
  }
}
  // ADD THIS METHOD TO GET TOKEN FROM SHAREDPREFERENCES
  static Future<String?> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');
      
      // Debug: Print token status
      if (token == null) {
        print('NO TOKEN FOUND in SharedPreferences');
      } else {
        print('TOKEN FOUND: ${token.substring(0, 10)}...');
      }
      
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}