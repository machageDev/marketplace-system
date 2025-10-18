import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class ClientProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _profile;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;

  Future<void> fetchProfile(int employerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _apiService.getEmployerProfile(employerId);
    } catch (e) {
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
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
