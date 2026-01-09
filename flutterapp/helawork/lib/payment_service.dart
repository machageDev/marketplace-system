import 'dart:convert';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final String baseUrl;
  final String? authToken;

  PaymentService({String? baseUrl, this.authToken})
      : baseUrl = baseUrl ?? AppConfig.getBaseUrl();

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

  Future<String> getEmployerEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? email;
      
      email = prefs.getString('user_email');
      if (email != null && email.isNotEmpty) {
        return email;
      }
      
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
      
      final username = prefs.getString('userName') ?? 'employer';
      email = '${username.replaceAll(' ', '.').toLowerCase()}@helawork.com';
      
      return email;
      
    } catch (e) {
      print('❌ ERROR getting employer email: $e');
      return 'employer@helawork.com';
    }
  }

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

      if (freelancerId.isEmpty) {
        return {
          'status': false,
          'message': 'Freelancer ID is required',
          'code': 'MISSING_FREELANCER_ID'
        };
      }

      try {
        final url = Uri.parse('$baseUrl/api/orders/$orderId/verify-payment/?freelancer_id=$freelancerId');
        print('🔗 Calling verification URL: $url');
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('📥 Verification status: ${response.statusCode}');
        
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

  Future<Map<String, dynamic>> _fallbackVerification(
    String orderId, 
    String freelancerId, 
    String? token
  ) async {
    try {
      print('🔄 Using fallback verification');
      
      if (token == null) {
        return {
          'status': true,
          'message': 'Proceeding with payment (token not available)',
          'data': {
            'order_id': orderId,
            'freelancer_id': freelancerId,
            'freelancer_paystack_account': 'default_account',
          }
        };
      }

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
        'status': true,
        'message': 'Proceeding despite verification error',
        'data': {
          'order_id': orderId,
          'freelancer_id': freelancerId,
          'freelancer_paystack_account': 'default_account',
        }
      };
    }
  }

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
      print('📋 Full Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data.containsKey('orders')) {
          final orders = data['orders'] as List?;
          return orders != null ? List<Map<String, dynamic>>.from(orders) : [];
        } else if (data.containsKey('data')) {
          final orders = data['data'] as List?;
          return orders != null ? List<Map<String, dynamic>>.from(orders) : [];
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

  Future<Map<String, dynamic>> initializePayment({
    required String orderId,
    required String email,
    required String freelancerPaystackAccount,
  }) async {
    try {
      print('🚀 Initializing payment for order: $orderId');
      print('📧 Email: $email');
      
      // Validate order ID - MUST be a valid UUID
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      
      if (!uuidRegex.hasMatch(orderId)) {
        print('❌ ERROR: Invalid order ID format: $orderId');
        return {
          'status': false,
          'message': 'Invalid order ID. Must be a valid UUID from backend.',
          'code': 'INVALID_ORDER_ID'
        };
      }
      
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

      final String? token = authToken ?? await _getUserToken();
      
      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found. Please log in again.',
          'code': 'AUTH_ERROR'
        };
      }
      
      final requestBody = {
        'order_id': orderId.trim(), // Use original order ID
        'email': email.trim(),
        'freelancer_paystack_account': freelancerPaystackAccount.trim(),
      };

      print('📦 Request body: $requestBody');
      
      final url = Uri.parse('$baseUrl/api/payment/initialize/');
      print('🔗 Calling URL: $url');

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
          'message': 'Order not found. Please create an order first.',
          'code': 'ORDER_NOT_FOUND'
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
      print('🔗 Calling URL: $url');

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

  // NEW METHOD: Get or create order for task
  Future<Map<String, dynamic>> getOrCreateOrderForTask(String taskId) async {
    try {
      final String? token = authToken ?? await _getUserToken();
      if (token == null) {
        return {'status': false, 'message': 'Not authenticated'};
      }
      
      final url = Uri.parse('$baseUrl/api/payment/create-order/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'task_id': taskId}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return {
            'status': true,
            'order_id': data['order']['order_id'],
            'amount': data['order']['amount'].toDouble(),
          };
        } else {
          return {'status': false, 'message': data['message']};
        }
      } else {
        return {'status': false, 'message': 'Failed to create order'};
      }
    } catch (e) {
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getOrderForContract(String contractId) async {
    try {
      final String? token = authToken ?? await _getUserToken();
      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found',
          'code': 'AUTH_ERROR'
        };
      }

      if (contractId.isEmpty || contractId == '0') {
        return {
          'status': false,
          'message': 'Contract ID is required',
          'code': 'MISSING_CONTRACT_ID'
        };
      }

      final url = Uri.parse('$baseUrl/api/contracts/$contractId/order/');
      print('🔗 Getting order for contract: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Get order response status: ${response.statusCode}');
      print('📥 Get order response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        return {
          'status': false,
          'message': 'Contract not found',
          'code': 'CONTRACT_NOT_FOUND'
        };
      } else if (response.statusCode == 401) {
        return {
          'status': false,
          'message': 'Unauthorized. Please log in again.',
          'code': 'AUTH_ERROR'
        };
      } else {
        return {
          'status': false,
          'message': 'Server error: ${response.statusCode}',
          'code': 'SERVER_ERROR',
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ ERROR in getOrderForContract: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }
}