import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';


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
      _errorMessage = "Failed to load profile: $e";
      _profile = null;
      _hasError = true;
      print('Error fetching profile: $e');
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

  // Create profile (if doesn't exist)
  Future<bool> createProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProfile = await _apiService.createEmployerProfile(data);
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
}