import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helawork/services/api_sercice.dart';

class UserProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic> _profile = {};
  bool _isLoading = false;
  String _errorMessage = '';
  bool _profileExists = false;

  Map<String, dynamic> get profile => _profile;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get profileExists => _profileExists;

  // Clear errors
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Load profile from API
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: "auth_token");
      if (token == null) {
        _errorMessage = 'Please log in to view profile';
        _profileExists = false;
      } else {
        final response = await ApiService.getUserProfile(token);
        
        if (response?['success'] == true && response?['data'] != null) {
          _profile = response?['data']['profile'] ?? {};
          _profileExists = _profile.isNotEmpty;
        } else {
          _profile = {};
          _profileExists = false;
          if (response?['message']?.contains('not found') ?? false) {
            _errorMessage = 'Profile not found. Create one below!';
          } else {
            _errorMessage = response?['message'] ?? 'Failed to load profile';
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading profile: $e';
      _profile = {};
      _profileExists = false;
      print('Error loading profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set profile field (for editing)
  void setProfileField(String key, dynamic value) {
    _profile[key] = value;
    notifyListeners();
  }

  // Save/Update profile
  Future<bool> saveProfile(BuildContext context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: "auth_token");
      if (token == null) {
        _errorMessage = 'Please log in to save profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _apiService.updateUserProfile(_profile, token);
      
      if (response['success'] == true) {
        // Update local profile with server response
        if (response['data']?['profile'] != null) {
          _profile = response['data']['profile'];
          _profileExists = true;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to save profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save profile'),
            backgroundColor: Colors.red,
          ),
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error saving profile: $e';
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear profile data
  void clearProfile() {
    _profile = {};
    _profileExists = false;
    notifyListeners();
  }
}