import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientProfileProvider with ChangeNotifier {
  late final ApiService _apiService;
  
  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _hasError = false;
  int? _employerId;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  int? get employerId => _employerId;

  ClientProfileProvider() {
    _apiService = ApiService();
    _loadEmployerId();
  }

  Future<void> _loadEmployerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _employerId = prefs.getInt('employer_id');
      print('Loaded employerId from storage: $_employerId');
    } catch (e) {
      print('Error loading employerId: $e');
    }
  }

  Future<void> setEmployerId(int id) async {
    try {
      _employerId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('employer_id', id);
      print('Saved employerId to storage: $id');
      notifyListeners();
    } catch (e) {
      print('Error setting employerId: $e');
    }
  }

  // Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Check if profile exists
  Future<bool> checkProfileExists() async {
    if (_employerId == null) return false;
    
    try {
      await _apiService.getEmployerProfile(_employerId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fetch profile - REMOVED parameter since we use stored _employerId
  Future<void> fetchProfile() async {
    if (_employerId == null) {
      _errorMessage = "No employer ID found. Please login again.";
      _hasError = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.getEmployerProfile(_employerId!);
      _hasError = false;
      print('Profile fetched successfully');
    } catch (e) {
      if (e.toString().contains("Profile not found") || 
          e.toString().contains("404")) {
        _profile = null;
        _errorMessage = null;
        _hasError = false;
        print('Profile not found, showing create profile UI');
      } else {
        _errorMessage = "Failed to load profile: $e";
        _profile = null;
        _hasError = true;
        print('Error fetching profile: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_employerId == null) {
      _errorMessage = "No employer ID found";
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
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update profile: $e";
      _hasError = true;
      print('Error updating profile: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create profile
  Future<bool> createProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProfile = await _apiService.createEmployerProfile(data);
      _profile = newProfile;
      _hasError = false;
      
      // Update employerId if it's in the response
      if (_profile != null && _profile!['employer_id'] != null) {
        await setEmployerId(_profile!['employer_id']);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to create profile: $e";
      _hasError = true;
      print('Error creating profile: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save profile (handles both create and update) - Fixed parameter
  Future<bool> saveProfile(Map<String, dynamic> data) async {
    if (_profile == null) {
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

  // Upload ID document
  Future<bool> uploadIdDocument(String filePath) async {
    if (_employerId == null) {
      _errorMessage = "No employer ID found";
      _hasError = true;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await http.MultipartFile.fromPath('id_document', filePath);
      await _apiService.uploadIdDocument(_employerId!, file);
      _hasError = false;
      
      // Refresh profile to get updated verification status
      await fetchProfile(); // Fixed: No parameter needed
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to upload ID: $e";
      _hasError = true;
      print('Error uploading ID: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify email
  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.verifyEmail(token);
      _hasError = false;
      
      // Refresh profile to get updated verification status
      await fetchProfile(); // Fixed: No parameter needed
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to verify email: $e";
      _hasError = true;
      print('Error verifying email: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify phone
  Future<bool> verifyPhone(String code) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.verifyPhone(code);
      _hasError = false;
      
      // Refresh profile to get updated verification status
      await fetchProfile(); // Fixed: No parameter needed
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to verify phone: $e";
      _hasError = true;
      print('Error verifying phone: $e');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear profile (for logout)
  void clearProfile() {
    _profile = null;
    _employerId = null;
    _isLoading = false;
    _errorMessage = null;
    _hasError = false;
    notifyListeners();
  }

  // Check if profile is loaded
  bool get isProfileLoaded => _profile != null;
}