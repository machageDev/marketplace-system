import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  final String baseUrl = "http://172.16.124.1:8000/api/wallet"; 

   //static const String baseUrl = 'https://marketplace-system-1.onrender.com';
 
  Future<Map<String, dynamic>?> getWalletData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(' Fetching wallet data: Status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' Wallet data received: $data');
        
        if (data['status'] == true) {
          return data['data'];
        } else if (data.containsKey('balance')) {
          // For backward compatibility if API returns direct balance
          return {
            'balance': data['balance'],
            'bank_verified': data['bank_verified'] ?? false,
          };
        }
      } else if (response.statusCode == 404) {
        
        return await _getLegacyWalletData(token);
      }
      
      return null;
    } catch (e) {
      print('❌ Error in getWalletData: $e');
      return null;
    }
  }

  // Fallback method if main endpoint doesn't exist
  Future<Map<String, dynamic>?> _getLegacyWalletData(String token) async {
    try {
      // Try to get balance first
      final balance = await getBalance(token);
      
      if (balance != null) {
        return {
          'balance': balance,
          'bank_verified': false, // Default to false if not available
        };
      }
      
      return null;
    } catch (e) {
      print(' Legacy wallet data fallback failed: $e');
      return null;
    }
  }

  // Keep existing getBalance method
  Future<double?> getBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/balance/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is Map) {
          if (data.containsKey('balance')) {
            return double.parse(data['balance'].toString());
          } else if (data.containsKey('data') && data['data'] is Map) {
            return double.parse(data['data']['balance'].toString());
          }
        } else if (data is num) {
          return data.toDouble();
        }
      }
      
      return null;
    } catch (e) {
      print(' Error in getBalance: $e');
      return null;
    }
  }

  Future<bool> withdraw(String token, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/withdraw/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true || data['success'] == true;
      }
      
      return false;
    } catch (e) {
      print(' Error in withdraw: $e');
      return false;
    }
  }

  Future<String?> topUp(String token, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topup/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is Map) {
          return data['payment_link'] ?? 
                 data['authorization_url'] ?? 
                 data['data']?['payment_link'] ??
                 data['data']?['authorization_url'];
        }
      }
      
      return null;
    } catch (e) {
      print(' Error in topUp: $e');
      return null;
    }
  }

  
  Future<Map<String, dynamic>?> registerBankAccount(
    String token, 
    String accountNumber,
    String bankCode,
    String accountName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-bank/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'account_number': accountNumber,
          'bank_code': bankCode,
          'account_name': accountName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['status'] == true) {
          return {
            'success': true,
            'recipient_code': data['recipient_code'],
            'bank_name': data['bank_name'],
            'account_last_4': accountNumber.substring(accountNumber.length - 4),
            'message': data['message'] ?? 'Bank account registered successfully',
          };
        }
      }
      
      // Handle error response
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to register bank account',
        'errors': errorData['errors'],
      };
    } catch (e) {
      print(' Error in registerBankAccount: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  
  Future<bool> checkBankRegistration(String token) async {
    try {
      final walletData = await getWalletData(token);
      return walletData?['bank_verified'] == true || 
             walletData?['paystack_recipient_code'] != null;
    } catch (e) {
      print(' Error checking bank registration: $e');
      return false;
    }
  }
}