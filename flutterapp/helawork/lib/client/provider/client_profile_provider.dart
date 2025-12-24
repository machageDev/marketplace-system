import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';


class ClientProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _hasError = false;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  // Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Check if profile exists
  Future<bool> checkProfileExists(int employerId) async {
    try {
      _profile = await _apiService.getEmployerProfile(employerId);
      return _profile != null && _profile!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Fetch profile
  Future<void> fetchProfile(int employerId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.getEmployerProfile(employerId);
      _hasError = false;
    } catch (e) {
      if (e.toString().contains("Profile not found") || 
          e.toString().contains("404")) {
        // Profile doesn't exist yet - this is not an error
        _profile = null;
        _errorMessage = null;
        _hasError = false;
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
  Future<bool> updateProfile(int employerId, Map<String, dynamic> data) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _apiService.updateEmployerProfile(employerId, data);
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
  Future<bool> createProfile(int employerId, Map<String, dynamic> data) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProfile = await _apiService.createEmployerProfile({
        ...data,
        'employer_id': employerId,
      });
      _profile = newProfile;
      _hasError = false;
      
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

  // Save profile (handles both create and update)
  Future<bool> saveProfile(int employerId, Map<String, dynamic> data) async {
    if (_profile == null) {
      return await createProfile(employerId, data);
    } else {
      return await updateProfile(employerId, data);
    }
  }
}