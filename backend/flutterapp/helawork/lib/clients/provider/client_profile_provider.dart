// lib/clients/provider/client_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class ClientProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(int employerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.getEmployerProfile(employerId);
    } catch (e) {
      _errorMessage = "Failed to load profile: $e";
      _profile = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(int employerId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateEmployerProfile(employerId, data);
      await fetchProfile(employerId);
    } catch (e) {
      _errorMessage = "Failed to update profile: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
