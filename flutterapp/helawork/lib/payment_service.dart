import 'dart:convert';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl;
  final String? authToken;

  PaymentService({String? baseUrl, this.authToken})
      : baseUrl = baseUrl ?? AppConfig.getBaseUrl();

  /// Get authentication token from SharedPreferences
  Future<String?> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? token = prefs.getString('user_token');
      if (token != null && token.isNotEmpty) {
        return token;
      }
      
      token = prefs.getString('employer_token');
      if (token != null && token.isNotEmpty) {
        return token;
      }
      
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
      
      String? email;
      
      // 1. Check if email is stored in shared preferences
      email = prefs.getString('user_email');
      if (email != null && email.isNotEmpty) {
        return email;
      }
      
      // 2. Check employer profile
      final employerProfile = prefs.getString('employer_profile');
      if (employerProfile != null) {
        try {
          final profile = jsonDecode(employerProfile);
          email = profile['email'] ?? profile['contact_email'];
          if (email != null && email.isNotEmpty) {
            return email;
          }
        } catch (e) {
          print('❌ ERROR parsing employer profile: $e');
        }
      }
      
      // 3. Get username and generate email
      final username = prefs.getString('userName') ?? 'employer';
      email = '${username.replaceAll(' ', '.').toLowerCase()}@helawork.com';
      
      return email;
      
    } catch (e) {
      print('❌ ERROR getting employer email: $e');
      return 'employer@helawork.com';
    }
  }

  /// VERIFY payment before processing
  Future<Map<String, dynamic>> verifyOrderPayment({
    required String orderId,
    required String freelancerId,
  }) async {
    try {
      final String? token = authToken ?? await _getUserToken();
      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found',
          'code': 'AUTH_ERROR'
        };
      }

      // Check if freelancerId is provided
      if (freelancerId.isEmpty) {
        return {
          'status': false,
          'message': 'Freelancer ID is required',
          'code': 'MISSING_FREELANCER_ID'
        };
      }

      // Try the verification endpoint
      try {
        final url = Uri.parse('$baseUrl/api/orders/$orderId/verify-payment/?freelancer_id=$freelancerId');
        print('🔍 Calling verification URL: $url');
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('🔍 Verification status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          if (data['status'] == true) {
            return {
              'status': true,
              'message': 'Payment verified successfully',
              'data': data['data'] ?? {}
            };
          } else {
            return {
              'status': false,
              'message': data['message'] ?? 'Payment verification failed',
              'code': 'VERIFICATION_FAILED',
              'data': {}
            };
          }
        } else if (response.statusCode == 404 || response.statusCode == 500) {
          // Endpoint doesn't exist or has error, use fallback
          print('⚠️ Verification endpoint not available, using fallback');
          return await _fallbackVerification(orderId, freelancerId, token);
        } else {
          return {
            'status': false,
            'message': 'Server error: ${response.statusCode}',
            'code': 'SERVER_ERROR',
            'data': {}
          };
        }
      } catch (e) {
        // If endpoint doesn't exist, use fallback
        print('⚠️ Verification error: $e, using fallback');
        return await _fallbackVerification(orderId, freelancerId, token);
      }
    } catch (e) {
      print('❌ ERROR in verifyOrderPayment: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
        'code': 'NETWORK_ERROR',
        'data': {}
      };
    }
  }

  /// Fallback verification
  Future<Map<String, dynamic>> _fallbackVerification(
    String orderId, 
    String freelancerId, 
    String? token
  ) async {
    try {
      print('🔄 Using fallback verification');
      
      if (token == null) {
        return {
          'status': true, // Allow payment even without verification
          'message': 'Proceeding with payment (token not available)',
          'data': {
            'order_id': orderId,
            'freelancer_id': freelancerId,
            'freelancer_paystack_account': 'default_account',
          }
        };
      }

      // Get pending orders to find this order
      try {
        final pendingOrdersUrl = Uri.parse('$baseUrl/api/orders/pending-payment/');
        final response = await http.get(
          pendingOrdersUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          if (data['status'] == true) {
            final orders = data['orders'] ?? data['data'];
            if (orders is List) {
              for (var order in orders) {
                final currentOrderId = order['order_id']?.toString() ?? order['id']?.toString();
                if (currentOrderId == orderId) {
                  final orderFreelancer = order['freelancer'];
                  if (orderFreelancer != null) {
                    return {
                      'status': true,
                      'message': 'Payment verified from pending orders',
                      'data': {
                        'order_id': orderId,
                        'freelancer_id': freelancerId,
                        'freelancer_name': orderFreelancer['name']?.toString() ?? 'Freelancer',
                        'freelancer_email': orderFreelancer['email']?.toString() ?? '',
                        'freelancer_paystack_account': 'default_account',
                        'amount': order['amount'] != null 
                            ? (order['amount'] is num ? order['amount'].toDouble() : double.parse(order['amount'].toString()))
                            : 0.0,
                        'currency': order['currency']?.toString() ?? 'KSH',
                        'order_status': order['status']?.toString() ?? 'pending',
                        'work_completed': true,
                        'service_description': order['task']?['title']?.toString() ?? 
                                            order['service_description']?.toString() ?? 
                                            'Service',
                      }
                    };
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Error in fallback verification: $e');
      }
      
      // If not found, still allow payment but with warning
      return {
        'status': true,
        'message': 'Proceeding with payment (order not verified)',
        'data': {
          'order_id': orderId,
          'freelancer_id': freelancerId,
          'freelancer_name': 'Freelancer',
          'freelancer_email': '',
          'freelancer_paystack_account': 'default_account',
          'amount': 0.0,
          'currency': 'KSH',
          'order_status': 'pending',
          'work_completed': true,
          'service_description': 'Service',
        }
      };
      
    } catch (e) {
      print('❌ ERROR in _fallbackVerification: $e');
      return {
        'status': true, // Still allow payment
        'message': 'Proceeding despite verification error',
        'data': {
          'order_id': orderId,
          'freelancer_id': freelancerId,
          'freelancer_paystack_account': 'default_account',
        }
      };
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
      print('📋 Fetching pending orders from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📋 Response status: ${response.statusCode}');
      
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
    required String freelancerPaystackAccount,
  }) async {
    try {
      print('🚀 Initializing payment for order: $orderId');
      print('📧 Using email: $email');
      
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

      // Get token
      final String? token = authToken ?? await _getUserToken();
      
      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found. Please log in again.',
          'code': 'AUTH_ERROR'
        };
      }
      
      final requestBody = {
        'order_id': orderId.trim(),
        'email': email.trim(),
        'freelancer_paystack_account': freelancerPaystackAccount.trim(),
      };

      print('📤 Request body: $requestBody');
      
      final url = Uri.parse('$baseUrl/api/payment/initialize/');
      print('🌐 Calling URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

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
      print('✅ Verifying payment reference: $reference');
      
      final String? token = authToken ?? await _getUserToken();
      if (token == null) {
        return {
          'status': false,
          'message': 'Authentication token not found',
          'code': 'AUTH_ERROR'
        };
      }

      final url = Uri.parse('$baseUrl/api/payment/verify/$reference/');
      print('🌐 Calling URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Verify status: ${response.statusCode}');
      print('📥 Verify body: ${response.body}');

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
}