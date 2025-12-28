import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientProfileProvider with ChangeNotifier {
  late final ApiService _apiService;
  
  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _hasError = false;
  int? _employerId;
  bool _profileExists = false;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  int? get employerId => _employerId;
  bool get profileExists => _profileExists;

  ClientProfileProvider() {
    _apiService = ApiService();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadEmployerId();
    await _checkProfileExistsSilent();
  }

  Future<void> _loadEmployerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _employerId = prefs.getInt('employer_id');
      print('=== ClientProfileProvider: Loaded employerId from storage: $_employerId');
    } catch (e) {
      print('=== ClientProfileProvider: Error loading employerId: $e');
    }
  }

  Future<void> setEmployerId(int id) async {
    try {
      _employerId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('employer_id', id);
      print('=== ClientProfileProvider: Saved employerId to storage: $id');
      notifyListeners();
      
      await _checkProfileExistsSilent();
    } catch (e) {
      print('=== ClientProfileProvider: Error setting employerId: $e');
    }
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkProfileExists() async {
    try {
      final result = await _apiService.checkProfileExists();
      _profileExists = result['exists'] ?? false;
      
      if (_profileExists && result['employer_id'] != null) {
        await setEmployerId(result['employer_id']);
      }
      
      notifyListeners();
      return _profileExists;
    } catch (e) {
      print('=== ClientProfileProvider: Error checking profile existence: $e');
      _profileExists = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkProfileExistsSilent() async {
    if (_employerId == null) return;
    
    try {
      final result = await _apiService.checkProfileExists();
      _profileExists = result['exists'] ?? false;
    } catch (e) {
      print('=== ClientProfileProvider: Silent check failed: $e');
      _profileExists = false;
    }
  }

  Future<void> fetchProfile() async {
    print('=== ClientProfileProvider: fetchProfile called ===');
    print('Current employerId: $_employerId');
    
    if (_employerId == null) {
      _errorMessage = "No employer ID found. Please login again.";
      _hasError = true;
      print('=== ClientProfileProvider: ERROR - No employerId found');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      print('=== ClientProfileProvider: Calling API with employerId: $_employerId');
      _profile = await _apiService.getEmployerProfile(_employerId!);
      _hasError = false;
      _profileExists = true;
      print('=== ClientProfileProvider: Profile fetched successfully');
      print('Profile data keys: ${_profile?.keys.toList()}');
    } catch (e) {
      if (e.toString().contains("Profile not found") || 
          e.toString().contains("404")) {
        _profile = null;
        _errorMessage = null;
        _hasError = false;
        _profileExists = false;
        print('=== ClientProfileProvider: Profile not found, showing create profile UI');
      } else {
        _errorMessage = "Failed to load profile: $e";
        _profile = null;
        _hasError = true;
        _profileExists = false;
        print('=== ClientProfileProvider: Error fetching profile: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_employerId == null) {
      _errorMessage = "No employer ID found";
      _hasError = true;
      notifyListeners();
      return false;
    }

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
      final updatedProfile = await _apiService.updateEmployerProfile(_employerId!, data);
      _profile = updatedProfile;
      _hasError = false;
      _profileExists = true;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update profile: ${e.toString()}";
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
      final newProfile = await _apiService.createEmployerProfile(data);
      _profile = newProfile;
      _hasError = false;
      _profileExists = true;
      
      if (_profile != null) {
        if (_profile!['employer'] != null) {
          await setEmployerId(_profile!['employer']);
        } else if (_profile!['employer_id'] != null) {
          await setEmployerId(_profile!['employer_id']);
        } else if (_profile!['id'] != null) {
          print('=== Profile created with ID: ${_profile!['id']}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to create profile: ${e.toString()}";
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
    } else if (_employerId != null) {
      return await updateProfile(data);
    } else {
      _errorMessage = "Employer ID is required to update profile";
      _hasError = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIdNumber(String idNumber) async {
  if (_employerId == null) {
    _errorMessage = "No employer ID found";
    _hasError = true;
    notifyListeners();
    return false;
  }

  // Validate ID number
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
    // Call ApiService to update ID number
    await _apiService.updateIdNumber(idNumber);
    
    _hasError = false;
    
    // Refresh profile to get updated verification status
    await fetchProfile();
    
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = "Failed to update ID number: ${e.toString()}";
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
      await _apiService.verifyEmail(token);
      _hasError = false;
      
      await fetchProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to verify email: ${e.toString()}";
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
      await _apiService.verifyPhone(code);
      _hasError = false;
      
      await fetchProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to verify phone: ${e.toString()}";
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
      await prefs.remove('employer_id');
    } catch (e) {
      print('Error clearing employerId: $e');
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
    
    final emailVerified = _profile!['email_verified'] ?? false;
    final phoneVerified = _profile!['phone_verified'] ?? false;
    final idVerified = _profile!['id_verified'] ?? false;
    final verificationStatus = _profile!['verification_status'] ?? 'unverified';
    
    return emailVerified && phoneVerified && idVerified && 
           verificationStatus == 'verified';
  }

  String get displayName {
    if (_profile == null) return 'Unknown';
    
    final accountType = _profile!['account_type'] ?? 'individual';
    
    if (accountType == 'individual') {
      return _profile!['full_name'] ?? 'Individual User';
    } else {
      return _profile!['company_name'] ?? 'Business User';
    }
  }
}