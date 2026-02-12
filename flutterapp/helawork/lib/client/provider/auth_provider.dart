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

  // ✅ FULLY CORRECTED LOGIN METHOD
  Future<bool> apilogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Call the API
      final response = await apiService.apilogin(username, password);

      if (response['success'] == true) {
        // 2. Extract data safely (handles both nested and flat responses)
        final apiData = response['data'] ?? response; 
        final token = apiData['token']?.toString() ?? '';
        final userData = apiData['user'] ?? apiData;
        
        // 3. Get Preferences instance
        final prefs = await SharedPreferences.getInstance();
        
        // 4. CRITICAL: Clear old session data first
        await prefs.clear(); 
        print('✅ Auth: Storage cleared for new session');

        // 5. Save the NEW token and sync
        if (token.isNotEmpty) {
          await prefs.setString('user_token', token);
          // Force disk sync so the Dashboard sees it immediately
          await prefs.reload(); 
          print('✅ Auth: Token saved: ${token.substring(0, 10)}...');
          
          // 6. Fetch full user profile to get email and other details
          await fetchUserProfile();
        } else {
          print('⚠️ Auth: No token found in response data');
        }
        
        // 7. Save User Details from login response (fallback)
        final email = userData['email'] ?? '';
        if (email.isNotEmpty) {
          await prefs.setString('user_email', email);
          print('✅ Auth: Email saved from login: $email');
        } else if (username.contains('@')) {
          await prefs.setString('user_email', username);
          print('✅ Auth: Username used as email: $username');
        }
        
        final userId = userData['id']?.toString() ?? '';
        if (userId.isNotEmpty) await prefs.setString('user_id', userId);
        
        final userName = userData['name'] ?? userData['username'] ?? username;
        if (userName.isNotEmpty) await prefs.setString('user_name', userName);
        
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
      print('❌ Auth Error: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ FETCH USER PROFILE - FIXED VERSION
  Future<void> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        debugPrint("❌ fetchUserProfile: No token found");
        return;
      }
      
      debugPrint("🔄 fetchUserProfile: Fetching profile...");
      final response = await apiService.getUserProfile(token);
      
      if (response?["success"] == true) {
        final userData = response?["data"];
        final String? email = userData["email"];
        final String? name = userData["name"] ?? userData["username"];
        final String? userId = userData["id"]?.toString();
        
        if (email != null && email.isNotEmpty) {
          await prefs.setString('user_email', email);
          debugPrint("✅ fetchUserProfile: Saved email: $email");
        }
        
        if (name != null && name.isNotEmpty) {
          await prefs.setString('user_name', name);
          debugPrint("✅ fetchUserProfile: Saved name: $name");
        }
        
        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
          debugPrint("✅ fetchUserProfile: Saved user_id: $userId");
        }
        
        await prefs.reload();
      } else {
        debugPrint("❌ fetchUserProfile: Failed - ${response?['message']}");
      }
    } catch (e) {
      debugPrint("❌ fetchUserProfile: Error - $e");
    }
  }

  // ✅ AUTH STATUS CHECK
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Always reload before checking status
    final token = prefs.getString('user_token');
    return token != null && token.isNotEmpty;
  }

  // ✅ GET USER EMAIL - Helper method
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString('user_email');
  }

  // ✅ GET USER TOKEN - Helper method
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString('user_token');
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🚪 Auth: Logged out and storage wiped');
    notifyListeners();
  }

  // ✅ REGISTER
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        
        final token = response['token'] ?? (response['data'] != null ? response['data']['token'] : null);
        if (token != null) {
          await prefs.setString('user_token', token);
          await prefs.reload();
          
          // Fetch full profile after registration
          await fetchUserProfile();
        }
        
        notifyListeners();
        return {'success': true, 'message': response['message'] ?? 'Success'};
      } else {
        _errorMessage = response['error'] ?? 'Registration failed.';
        notifyListeners();
        return {'success': false, 'error': _errorMessage};
      }
    } catch (e) {
      _isLoading = false;
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ FORGOT PASSWORD
  Future<Map<String, dynamic>> apiforgotpassword({required String email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await apiService.apiforgotpassword(email: email);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }
}