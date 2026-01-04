import 'dart:convert';
import 'dart:math';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl;
  final String? authToken;

  PaymentService({String? baseUrl, this.authToken})
      : baseUrl = baseUrl ?? AppConfig.getBaseUrl();

  /// Get authentication token from SharedPreferences
  static Future<String?> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try user_token first
      String? token = prefs.getString('user_token');
      if (token != null && token.isNotEmpty) {
        print('✅ DEBUG: Found user_token: ${token.substring(0, min(10, token.length))}...');
        return token;
      }
      
      // Try employer_token
      token = prefs.getString('employer_token');
      if (token != null && token.isNotEmpty) {
        print('✅ DEBUG: Found employer_token: ${token.substring(0, min(10, token.length))}...');
        return token;
      }
      
      // Try any other token keys
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.contains('token') || key.contains('Token')) {
          token = prefs.getString(key);
          if (token != null && token.isNotEmpty) {
            print('✅ DEBUG: Found token in key "$key": ${token.substring(0, min(10, token.length))}...');
            return token;
          }
        }
      }
      
      print('❌ DEBUG: No token found in SharedPreferences');
      return null;
      
    } catch (e) {
      print('❌ ERROR getting token: $e');
      return null;
    }
  }

  /// Get employer email for payment
  Future<String> getEmployerEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check multiple possible sources
      String? email;
      
      // 1. Check if email is stored in shared preferences
      email = prefs.getString('user_email');
      if (email != null && email.isNotEmpty) {
        print('✅ DEBUG: Found email in SharedPreferences: $email');
        return email;
      }
      
      // 2. Check employer profile
      final employerProfile = prefs.getString('employer_profile');
      if (employerProfile != null) {
        try {
          final profile = jsonDecode(employerProfile);
          email = profile['email'] ?? profile['contact_email'];
          if (email != null && email.isNotEmpty) {
            print('✅ DEBUG: Found email in employer profile: $email');
            return email;
          }
        } catch (e) {
          print('❌ ERROR parsing employer profile: $e');
        }
      }
      
      // 3. Get username and generate email
      final username = prefs.getString('userName') ?? 'employer';
      email = '${username.replaceAll(' ', '.').toLowerCase()}@helawork.com';
      print('✅ DEBUG: Generated email: $email');
      
      return email;
      
    } catch (e) {
      print('❌ ERROR getting employer email: $e');
      return 'employer@helawork.com';
    }
  }

  /// Fetch pending orders for payment
  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      final String? token = authToken ?? await _getUserToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('$baseUrl/api/orders/pending-payment/');
      print('✅ DEBUG: Fetching pending orders from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          if (data.containsKey('orders')) {
            final orders = data['orders'] as List?;
            return orders != null ? List<Map<String, dynamic>>.from(orders) : [];
          } else if (data.containsKey('data')) {
            final orders = data['data'] as List?;
            return orders != null ? List<Map<String, dynamic>>.from(orders) : [];
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERROR in getPendingOrders: $e');
      rethrow;
    }
  }

  /// Initialize payment for a specific order
  Future<Map<String, dynamic>> initializePayment({
    required String orderId,
    required String email,
  }) async {
    try {
      print('🚀 DEBUG: Initializing payment...');
      print('   Order ID: $orderId');
      print('   Email: $email');
      
      // Input validation
      if (orderId.isEmpty) {
        return {
          'status': false,
          'message': 'Order ID cannot be empty',
          'code': 'VALIDATION_ERROR'
        };
      }
      
      if (email.isEmpty) {
        return {
          'status': false, 
          'message': 'Email cannot be empty',
          'code': 'VALIDATION_ERROR'
        };
      }
      
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'status': false,
          'message': 'Invalid email format',
          'code': 'VALIDATION_ERROR'
        };
      }

      // Get token - prioritize authToken from constructor
      final String? token;
      if (authToken != null && authToken!.isNotEmpty) {
        token = authToken;
        print('✅ DEBUG: Using token from constructor');
      } else {
        print('⚠️ DEBUG: No constructor token, getting from SharedPreferences');
        token = await _getUserToken();
      }
      
      if (token == null || token.isEmpty) {
        print('❌ DEBUG: Token is null or empty!');
        print('❌ DEBUG: authToken was: ${authToken ?? "NULL"}');
        return {
          'status': false,
          'message': 'Authentication token not found. Please log in again.',
          'code': 'AUTH_ERROR'
        };
      }
      
      print('✅ DEBUG: Token found: ${token.substring(0, min(10, token.length))}...');
      
      final requestBody = {
        'order_id': orderId.trim(),
        'email': email.trim(),
      };
      
      print('✅ DEBUG: Request body: $requestBody');

      final url = Uri.parse('$baseUrl/api/payment/initialize/');
      print('✅ DEBUG: Payment URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('✅ DEBUG: Response status: ${response.statusCode}');
      print('✅ DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          return {
            'status': true,
            'message': responseData['message'] ?? 'Payment initialized',
            'data': responseData['data'] ?? responseData,
          };
        } else {
          return {
            'status': false,
            'message': responseData['message'] ?? 'Payment initialization failed',
            'data': responseData,
          };
        }
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'status': false,
          'message': errorData['message'] ?? 'Invalid request',
          'errors': errorData['errors'] ?? errorData,
          'code': 'VALIDATION_ERROR'
        };
      } else if (response.statusCode == 401) {
        return {
          'status': false,
          'message': 'Unauthorized. Please log in again.',
          'code': 'AUTH_ERROR'
        };
      } else if (response.statusCode == 404) {
        return {
          'status': false,
          'message': 'Payment endpoint not found',
          'code': 'ENDPOINT_NOT_FOUND'
        };
      } else {
        return {
          'status': false,
          'message': 'Server error: ${response.statusCode}',
          'body': response.body,
          'code': 'SERVER_ERROR'
        };
      }
    } catch (e) {
      print('❌ ERROR in initializePayment: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  /// Verify payment using reference
  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      print('✅ DEBUG: Verifying payment reference: $reference');
      
      final String? token = authToken ?? await _getUserToken();
      if (token == null) {
        return {
          'status': false,
          'message': 'Authentication token not found',
          'code': 'AUTH_ERROR'
        };
      }

      final url = Uri.parse('$baseUrl/api/payment/verify/$reference/');
      print('✅ DEBUG: Verify URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ DEBUG: Verify status: ${response.statusCode}');
      print('✅ DEBUG: Verify body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        return {
          'status': false,
          'message': 'Payment verification failed or transaction not found',
          'code': 'NOT_FOUND'
        };
      } else {
        return {
          'status': false,
          'message': 'Verification error: ${response.statusCode}',
          'body': response.body,
          'code': 'SERVER_ERROR'
        };
      }
    } catch (e) {
      print('❌ ERROR in verifyPayment: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  /// Debug method to test token
  static Future<void> debugTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('🔍 DEBUG TOKENS:');
      print('All keys: ${prefs.getKeys()}');
      
      final userToken = prefs.getString('user_token');
      print('user_token: ${userToken ?? "NULL"}');
      if (userToken != null) {
        print('  Length: ${userToken.length}');
        print('  First 10: ${userToken.substring(0, min(10, userToken.length))}...');
      }
      
      final employerToken = prefs.getString('employer_token');
      print('employer_token: ${employerToken ?? "NULL"}');
    } catch (e) {
      print('❌ Error debugging tokens: $e');
    }
  }
}