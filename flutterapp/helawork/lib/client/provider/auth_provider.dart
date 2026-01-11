import 'package:flutter/foundation.dart';
import 'package:helawork/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;

  AuthProvider({required this.apiService});

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = false;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  // Setters
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Login method - UPDATED TO SAVE EMAIL
  Future<bool> apilogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await apiService.apilogin(username, password);

      if (response['success'] == true) {
        // ✅ Get the token and user data
        final token = response['token'] ?? '';
        final userData = response['user'] ?? {};
        
        // Store user data, tokens, etc.
        if (_rememberMe) {
          // Store credentials securely
          // await _storeCredentials(username, password);
        }
        
        // ✅ CRITICAL: Save data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        // Save token
        if (token.isNotEmpty) {
          await prefs.setString('user_token', token);
          print('✅ Token saved to SharedPreferences: ${token.substring(0, 20)}...');
        }
        
        // ✅ Save email (THIS WAS MISSING!)
        final email = userData['email'] ?? response['email'] ?? '';
        if (email.isNotEmpty) {
          await prefs.setString('user_email', email);
          print('✅ Email saved to SharedPreferences: $email');
        } else {
          // If email not in response, use username if it looks like an email
          if (username.contains('@')) {
            await prefs.setString('user_email', username);
            print('✅ Email (from username) saved: $username');
          }
        }
        
        // Save other user info
        final userId = userData['id']?.toString() ?? response['id']?.toString() ?? '';
        if (userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
          print('✅ User ID saved: $userId');
        }
        
        final userName = userData['name'] ?? response['name'] ?? username;
        if (userName.isNotEmpty) {
          await prefs.setString('user_name', userName);
          print('✅ User name saved: $userName');
        }
        
        // Print debug info
        print('🔍 All SharedPreferences after login:');
        prefs.getKeys().forEach((key) {
          if (key != 'user_token') { // Don't print full token
            print('   $key: ${prefs.get(key)}');
          } else {
            print('   $key: ${prefs.get(key)?.toString().substring(0, 20)}...');
          }
        });
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    return token != null && token.isNotEmpty;
  }

  // Method to get saved email
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Method to logout and clear all data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ Logged out - All SharedPreferences cleared');
    notifyListeners();
  }

  // Forgot password method
  Future<Map<String, dynamic>> apiforgotpassword({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    

    try {
      final response = await apiService.apiforgotpassword(
        email: email,
      );

      _isLoading = false;
      
      if (response['success'] == true) {
        notifyListeners();
        return {
          'success': true,
          'message': response['message'] ?? 'Password reset instructions sent to your email.',
        };
      } else {
        _errorMessage = response['error'] ?? 'Failed to process request.';
        notifyListeners();
        return {
          'success': false,
          'error': _errorMessage,
        };
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': _errorMessage,
      };
    }
  }

  // Register method - UPDATED TO SAVE EMAIL
  Future<Map<String, dynamic>> apiregister({
    required String username,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await apiService.apiregister(
        username: username,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      
      if (response['success'] == true) {
        // ✅ Also save email when registering
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        print('✅ Email saved during registration: $email');
        
        // Save token if provided
        final token = response['token'] ?? '';
        if (token.isNotEmpty) {
          await prefs.setString('user_token', token);
          print('✅ Token saved during registration');
        }
        
        notifyListeners();
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful!',
        };
      } else {
        _errorMessage = response['error'] ?? 'Registration failed.';
        notifyListeners();
        return {
          'success': false,
          'error': _errorMessage,
        };
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': _errorMessage,
      };
    }
  }

  // Debug method to print all stored data
  Future<void> printStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    print(' DEBUG: All stored authentication data:');
    prefs.getKeys().forEach((key) {
      final value = prefs.get(key);
      print('   $key: $value');
    });
  }

  // Method to manually set email (if needed)
  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    print('✅ Email manually set: $email');
    notifyListeners();
  }
}