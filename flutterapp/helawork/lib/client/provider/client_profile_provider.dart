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
      
      print('DEBUG: checkProfileExists raw response: $result');
      
      // Handle Django response
      if (result.containsKey('exists')) {
        _profileExists = result['exists'] ?? false;
        print('DEBUG: Profile exists? $_profileExists');
        
        if (_profileExists && result.containsKey('profile')) {
          _profile = result['profile'];
          print('DEBUG: Profile data loaded from check');
        } else if (_profileExists && result.containsKey('id')) {
          // If result is the profile itself
          _profile = result;
        } else {
          _profile = null;
        }
      } else if (result.containsKey('id')) {
        // Direct profile object
        _profileExists = true;
        _profile = result;
        print('DEBUG: Direct profile object received');
      } else if (result.containsKey('error')) {
        print('DEBUG: Error in check: ${result['error']}');
        _profileExists = false;
        _profile = null;
      } else {
        // Unknown response format
        print('DEBUG: Unknown response format in checkProfileExists: $result');
        _profileExists = false;
        _profile = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return _profileExists;
    } catch (e) {
      print('Error checking profile existence: $e');
      _profileExists = false;
      _profile = null;
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
      } else {
        _profile = null;
      }
    } catch (e) {
      print('Silent check failed: $e');
      _profileExists = false;
      _profile = null;
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      print('DEBUG: Fetching employer profile...');
      final result = await _apiService.getEmployerProfile();
      
      print('DEBUG: Fetch profile raw response: $result');
      
      // Handle different Django response formats
      if (result.containsKey('id')) {
        // Direct profile object from Django (most common)
        _profile = result;
        _hasError = false;
        _profileExists = true;
        print('DEBUG: Profile loaded successfully (direct object)');
      } else if (result.containsKey('data') && result['data'] != null) {
        // Response with 'data' field
        _profile = result['data'];
        _hasError = false;
        _profileExists = true;
        print('DEBUG: Profile loaded successfully (data field)');
      } else if (result.containsKey('success') && result['success'] == true) {
        // Success response
        if (result.containsKey('data')) {
          _profile = result['data'];
        } else {
          _profile = result;
        }
        _hasError = false;
        _profileExists = true;
        print('DEBUG: Profile loaded successfully (success: true)');
      } else if (result.containsKey('exists') && result['exists'] == false) {
        // Profile doesn't exist
        _profile = null;
        _profileExists = false;
        _hasError = false;
        _errorMessage = null;
        print('DEBUG: No profile found (exists: false)');
      } else if (result.containsKey('error')) {
        // Error response
        final errorMsg = result['error'];
        print('DEBUG: Server returned error: $errorMsg');
        
        if (errorMsg.toString().contains('Profile not found') || 
            errorMsg.toString().contains('Create one first') ||
            errorMsg.toString().contains('404')) {
          _profile = null;
          _profileExists = false;
          _hasError = false;
          _errorMessage = null;
          print('DEBUG: Profile not found (normal case)');
        } else {
          _errorMessage = errorMsg.toString();
          _profile = null;
          _hasError = true;
          _profileExists = false;
          print('DEBUG: Server error: $errorMsg');
        }
      } else {
        // Unexpected response format
        print('DEBUG: Unexpected response format, trying to use as profile: $result');
        _profile = result; // Try to use whatever we got
        _hasError = false;
        _profileExists = true;
        print('DEBUG: Using raw response as profile');
      }
    } catch (e) {
      print('DEBUG: fetchProfile error: $e');
      
      final errorStr = e.toString();
      
      // Check specific error types
      if (errorStr.contains("Profile not found") || 
          errorStr.contains("Create one first") ||
          errorStr.contains("404")) {
        _profile = null;
        _profileExists = false;
        _hasError = false;
        _errorMessage = null;
        print('DEBUG: Profile not found (404)');
      } else if (errorStr.contains("Unauthorized") ||
                 errorStr.contains("401")) {
        _errorMessage = "Session expired. Please login again.";
        _profile = null;
        _hasError = true;
        _profileExists = false;
        print('DEBUG: Unauthorized (401)');
      } else if (errorStr.contains("500") || 
                 errorStr.contains("Server error")) {
        // 500 error - server issue
        print('DEBUG: Server error 500, trying fallback check...');
        try {
          final existsResult = await _apiService.checkProfileExists();
          print('DEBUG: Fallback check result: $existsResult');
          
          if (existsResult.containsKey('exists') && existsResult['exists'] == true) {
            if (existsResult.containsKey('profile')) {
              _profile = existsResult['profile'];
              _profileExists = true;
              _hasError = false;
              print('DEBUG: Fallback check found profile');
            } else {
              _profile = null;
              _profileExists = false;
              _hasError = true;
              _errorMessage = "Profile exists but data incomplete.";
              print('DEBUG: Fallback found exists but no profile data');
            }
          } else {
            _profile = null;
            _profileExists = false;
            _hasError = false;
            print('DEBUG: Fallback check says no profile');
          }
        } catch (fallbackError) {
          print('DEBUG: Fallback check also failed: $fallbackError');
          _errorMessage = "Server error. Please try again.";
          _profile = null;
          _hasError = true;
          _profileExists = false;
        }
      } else {
        _errorMessage = "Failed to load profile: ${e.toString()}";
        _profile = null;
        _hasError = true;
        _profileExists = false;
        print('DEBUG: Unknown error: $e');
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
      print('DEBUG: Updating profile with data: $data');
      final result = await _apiService.updateEmployerProfile(data);
      
      print('DEBUG: Update response: $result');
      
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
      print('DEBUG: Creating profile with data: $data');
      final result = await _apiService.createEmployerProfile(data);
      
      print('DEBUG: Create response: $result');
      
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
    print('DEBUG: saveProfile called with data: $data');
    
    try {
      print('DEBUG: Checking if profile exists on server...');
      final existsResult = await _apiService.checkProfileExists();
      final serverSaysExists = existsResult['exists'] ?? false;
      
      print('DEBUG: Server response: $existsResult');
      print('DEBUG: Server says profile exists? $serverSaysExists');
      
      // Update our local state to match server
      _profileExists = serverSaysExists;
      
      if (serverSaysExists && existsResult.containsKey('profile')) {
        _profile = existsResult['profile'];
        print('DEBUG: Updated _profile from server: $_profile');
      } else {
        _profile = null;
        print('DEBUG: Cleared _profile - server says no profile');
      }
      
      notifyListeners();
      
      // Now decide based on SERVER response
      if (!serverSaysExists) {
        print('DEBUG: Server confirms no profile - creating new');
        return await createProfile(data);
      } else {
        print('DEBUG: Server confirms profile exists - updating');
        return await updateProfile(data);
      }
    } catch (e) {
      print('DEBUG: Error checking profile existence: $e');
      
      // If server check fails, try to fetch profile directly
      try {
        await fetchProfile();
        if (_profileExists) {
          print('DEBUG: Profile exists according to fetchProfile - updating');
          return await updateProfile(data);
        } else {
          print('DEBUG: Profile doesn\'t exist according to fetchProfile - creating');
          return await createProfile(data);
        }
      } catch (fetchError) {
        print('DEBUG: fetchProfile also failed: $fetchError');
        
        // Last resort: try create, if fails with "already exists", try update
        try {
          return await createProfile(data);
        } catch (createError) {
          if (createError.toString().contains('already exists')) {
            print('DEBUG: Create says already exists - trying update');
            return await updateProfile(data);
          }
          rethrow;
        }
      }
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