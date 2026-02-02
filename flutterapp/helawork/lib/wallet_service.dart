import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WalletService {
 //final String baseUrl = "http://192.168.100.188:8000/api/wallet";
  final String baseUrl = "https://marketplace-system-1.onrender.com/api/wallet";

  /// Helper to generate standard headers
  Map<String, String> _getHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// 1. Fetch Full Wallet Data
  Future<Map<String, dynamic>?> getWalletData(String token) async {
    try {
      debugPrint('--- 🛰️ API CALL: Fetching Wallet ---');
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: _getHeaders(token),
      );

      debugPrint('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle nested 'data' key if present, otherwise return raw map
        if (data is Map<String, dynamic>) {
          if (data['status'] == true && data.containsKey('data')) {
            return data['data'];
          }
          return data;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Auth Error: Unauthorized access. Check token.');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Network Error in getWalletData: $e');
      return null;
    }
  }

  /// 2. Withdraw Funds
  Future<bool> withdraw(String token, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/withdraw/'),
        headers: _getHeaders(token),
        body: json.encode({'amount': amount}),
      );
      
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['status'] == true;
    } catch (e) {
      debugPrint('❌ Error in withdraw: $e');
      return false;
    }
  }

  /// 3. Get Current Balance Only
  Future<double?> getBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/balance/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for common balance nesting patterns
        if (data is Map) {
          var val = data['balance'] ?? data['data']?['balance'];
          if (val != null) return double.parse(val.toString());
        } else if (data is num) {
          return data.toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in getBalance: $e');
      return null;
    }
  }

  /// 4. Initiate Top Up (Paystack/Flutterwave Link)
  Future<String?> topUp(String token, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topup/'),
        headers: _getHeaders(token),
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract payment URL from various possible keys
        if (data is Map) {
          return data['payment_link'] ?? 
                 data['authorization_url'] ?? 
                 data['data']?['payment_link'] ??
                 data['data']?['authorization_url'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in topUp: $e');
      return null;
    }
  }

  /// 5. Register Bank Account for Withdrawals
  Future<Map<String, dynamic>?> registerBankAccount(
    String token,
    String accountNumber,
    String bankCode,
    String accountName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-bank/'),
        headers: _getHeaders(token),
        body: json.encode({
          'account_number': accountNumber,
          'bank_code': bankCode,
          'account_name': accountName,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return {
            'success': true,
            'recipient_code': data['recipient_code'] ?? data['data']?['recipient_code'],
            'bank_name': data['bank_name'] ?? data['data']?['bank_name'],
            'account_last_4': accountNumber.length >= 4 
                ? accountNumber.substring(accountNumber.length - 4) 
                : accountNumber,
            'message': data['message'] ?? 'Bank account registered successfully',
          };
        }
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to register bank account',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint('❌ Error in registerBankAccount: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 6. Check if user has a bank account linked
  Future<bool> checkBankRegistration(String token) async {
    try {
      final walletData = await getWalletData(token);
      if (walletData == null) return false;
      
      return walletData['bank_verified'] == true || 
             walletData['paystack_recipient_code'] != null ||
             walletData['bank_name'] != null;
    } catch (e) {
      debugPrint('❌ Error checking bank registration: $e');
      return false;
    }
  }
}