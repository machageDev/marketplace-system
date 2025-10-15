
import 'package:flutter/foundation.dart';
import 'package:helawork/services/api_sercice.dart';


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

  // Login method
  Future<bool> apilogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await apiService.login(username, password);

      if (response['success'] == true) {
        // Store user data, tokens, etc.
        if (_rememberMe) {
          // Store credentials securely
          // await _storeCredentials(username, password);
        }
        
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

  // Forgot password method
 // Add this method to your existing AuthProvider class
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
  // Add this method to your existing AuthProvider class
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
}