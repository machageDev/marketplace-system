import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/freelancer/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  String? _token;
  String? _userId; // Add this private variable

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;
  String? get userId => _userId; // ADD THIS GETTER - you were missing this!

  Future<Map<String, dynamic>> login(
    BuildContext context,
    String username,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);

      if (response["success"] == true) {
        _isLoggedIn = true;
        _userData = response["data"];
        _token = response["data"]["token"];
        
        // Set the userId from response
        _userId = _userData?['id']?.toString() ?? _userData?['user_id']?.toString();
        
        // Debug print to verify
        debugPrint('Saved token: $_token');
        debugPrint('Saved user ID: $_userId');

        // Store in secure storage
        await _secureStorage.write(key: "auth_token", value: _token);
        if (_userId != null) {
          await _secureStorage.write(key: "user_id", value: _userId!);
        }

        // Update dashboard if needed
        if (context.mounted) {
          final dashboardProvider =
              Provider.of<DashboardProvider>(context, listen: false);

          dashboardProvider.updateUserProfile(
            _userData?['name'] ?? "User",
            _userData?['profile_picture'] ?? "",
          );
        }
      } else {
        _isLoggedIn = false;
        _userData = null;
        _token = null;
        _userId = null;
        await _secureStorage.delete(key: "auth_token");
        await _secureStorage.delete(key: "user_id");
      }

      return response;
    } catch (e) {
      debugPrint("Login error: $e");
      _isLoggedIn = false;
      _userData = null;
      _token = null;
      _userId = null;
      await _secureStorage.delete(key: "auth_token");
      await _secureStorage.delete(key: "user_id");
      return {"success": false, "message": "Something went wrong"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name,
        email,
        phone,
        password,
        confirmPassword,
      );
      return response;
    } catch (e) {
      debugPrint("Register error: $e");
      return {"success": false, "message": "Something went wrong"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _isLoggedIn = false;
    _userData = null;
    _token = null;
    _userId = null;
    
    await _secureStorage.delete(key: "auth_token");
    await _secureStorage.delete(key: "user_id");
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final token = await _secureStorage.read(key: "auth_token");
    final userId = await _secureStorage.read(key: "user_id");
    
    if (token != null && userId != null) {
      _isLoggedIn = true;
      _token = token;
      _userId = userId; // Set the userId when checking login status
    } else {
      _isLoggedIn = false;
      _token = null;
      _userData = null;
      _userId = null;
    }
    notifyListeners();
  }

  // Helper method to get userId as integer
  int? get userIdAsInt {
    if (_userId == null) return null;
    return int.tryParse(_userId!);
  }

  // Helper method with fallback
  int getUserIdOrZero() {
    return userIdAsInt ?? 0;
  }
}