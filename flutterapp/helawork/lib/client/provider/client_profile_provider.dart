import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _hasError = false;
  bool _profileExists = false;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get profileExists => _profileExists;

  ClientProfileProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkProfileExistsSilent();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkProfileExists() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _apiService.checkProfileExists();
      
      _profileExists = result['exists'] ?? false;
      
      if (_profileExists && result.containsKey('profile')) {
        _profile = result['profile'];
      }
      
      _isLoading = false;
      notifyListeners();
      return _profileExists;
    } catch (e) {
      print('Error checking profile existence: $e');
      _profileExists = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      File imageFile = File(filePath);
      
      final result = await _apiService.uploadProfilePicture(imageFile);
      
      if (result['success'] == true) {
        _hasError = false;
        _profile = result['data'];
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['message'] ?? 'Failed to upload picture');
      }
    } catch (e) {
      _errorMessage = "Failed to upload profile picture: ${e.toString()}";
      _hasError = true;
      print('Error uploading profile picture: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkProfileExistsSilent() async {
    try {
      final result = await _apiService.checkProfileExists();
      _profileExists = result['exists'] ?? false;
      
      if (_profileExists && result.containsKey('profile')) {
        _profile = result['profile'];
      }
    } catch (e) {
      print('Silent check failed: $e');
      _profileExists = false;
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getEmployerProfile();
      
      if (result['success'] == true) {
        _profile = result['data'];
        _hasError = false;
        _profileExists = true;
      } else {
        throw Exception(result['error'] ?? 'Profile not found');
      }
    } catch (e) {
      if (e.toString().contains("Profile not found") || 
          e.toString().contains("Create one first") ||
          e.toString().contains("404")) {
        _profile = null;
        _profileExists = false;
        _hasError = false;
        _errorMessage = null;
      } else if (e.toString().contains("Unauthorized") ||
                 e.toString().contains("401")) {
        _errorMessage = "Session expired. Please login again.";
        _profile = null;
        _hasError = true;
        _profileExists = false;
      } else {
        _errorMessage = e.toString();
        _profile = null;
        _hasError = true;
        _profileExists = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      _errorMessage = "No data provided for update";
      _hasError = true;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateEmployerProfile(data);
      
      if (result['success'] == true) {
        _profile = result['data'];
        _hasError = false;
        _profileExists = true;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'Update failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
      print('Error updating profile: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.createEmployerProfile(data);
      
      if (result['success'] == true) {
        _profile = result['data'];
        _hasError = false;
        _profileExists = true;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'Create failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
      print('Error creating profile: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveProfile(Map<String, dynamic> data) async {
    if (_profile == null || !_profileExists) {
      return await createProfile(data);
    } else {
      return await updateProfile(data);
    }
  }

  Future<bool> updateIdNumber(String idNumber) async {
    if (idNumber.isEmpty) {
      _errorMessage = "ID number cannot be empty";
      _hasError = true;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateIdNumber(idNumber);
      
      if (result['success'] == true) {
        _hasError = false;
        
        if (result.containsKey('data')) {
          final data = result['data'];
          _profile?['id_number'] = data['id_number'];
          _profile?['verification_status'] = data['verification_status'];
          _profile?['id_verified'] = data['id_verified'];
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'ID update failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
      print('Error updating ID number: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.verifyEmail(token);
      
      if (result['success'] == true) {
        _hasError = false;
        
        if (result.containsKey('data')) {
          _profile = result['data'];
        } else if (result.containsKey('profile')) {
          _profile = result['profile'];
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
      print('Error verifying email: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhone(String code) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.verifyPhone(code);
      
      if (result['success'] == true) {
        _hasError = false;
        
        if (result.containsKey('data')) {
          _profile = result['data'];
        } else if (result.containsKey('profile')) {
          _profile = result['profile'];
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? result['message'] ?? 'Phone verification failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
      print('Error verifying phone: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearProfile() async {
    _profile = null;
    _profileExists = false;
    _isLoading = false;
    _errorMessage = null;
    _hasError = false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');
    } catch (e) {
      print('Error clearing storage: $e');
    }
    
    notifyListeners();
  }

  bool get isProfileLoaded => _profile != null;

  dynamic getProfileField(String key, {dynamic defaultValue}) {
    if (_profile == null) return defaultValue;
    return _profile![key] ?? defaultValue;
  }

  bool get isProfileVerified {
    if (_profile == null) return false;
    
    final emailVerified = getProfileField('email_verified', defaultValue: false);
    final phoneVerified = getProfileField('phone_verified', defaultValue: false);
    final idVerified = getProfileField('id_verified', defaultValue: false);
    final verificationStatus = getProfileField('verification_status', defaultValue: 'unverified');
    
    return emailVerified && phoneVerified && idVerified && 
           verificationStatus == 'verified';
  }

  String get displayName {
    if (_profile == null) return 'Unknown';
    
    final fullName = getProfileField('full_name');
    return fullName ?? 'User';
  }
  
  String? get profilePictureUrl {
    if (_profile == null) return null;
    
    final picture = getProfileField('profile_picture');
    
    if (picture != null && picture is String && picture.startsWith('/')) {
      return '${ApiService.baseUrl}$picture';
    }
    
    return picture;
  }
  
  // Helper getters for Django model fields
  String get fullName => getProfileField('full_name', defaultValue: '');
  String get contactEmail => getProfileField('contact_email', defaultValue: '');
  String get phoneNumber => getProfileField('phone_number', defaultValue: '');
  String get city => getProfileField('city', defaultValue: '');
  String get address => getProfileField('address', defaultValue: '');
  String get profession => getProfileField('profession', defaultValue: '');
  String get skills => getProfileField('skills', defaultValue: '');
  String get bio => getProfileField('bio', defaultValue: '');
  String? get linkedinUrl => getProfileField('linkedin_url');
  String? get twitterUrl => getProfileField('twitter_url');
  
  // Verification progress getter
  int get verificationProgress {
    if (_profile == null) return 0;
    
    int steps = 0;
    if (getProfileField('email_verified', defaultValue: false)) steps++;
    if (getProfileField('phone_verified', defaultValue: false)) steps++;
    if (getProfileField('id_number') != null) steps++;
    
    return (steps / 3 * 100).round();
  }
  
  // Numeric field getters with safe parsing
  double get totalSpent {
    final value = getProfileField('total_spent');
    if (value == null) return 0.0;
    
    try {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return 0.0;
      }
    } catch (e) {
      print('Error parsing total spent: $e');
      return 0.0;
    }
  }
  
  double get avgFreelancerRating {
    final value = getProfileField('avg_freelancer_rating');
    if (value == null) return 0.0;
    
    try {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return 0.0;
      }
    } catch (e) {
      print('Error parsing average rating: $e');
      return 0.0;
    }
  }
}