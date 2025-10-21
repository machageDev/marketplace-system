// lib/clients/provider/employer_rating_provider.dart
import 'package:flutter/foundation.dart';
import 'package:helawork/services/api_sercice.dart';

class EmployerRatingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _ratings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get ratings => _ratings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch employer ratings - no parameters needed
  Future<void> fetchRatings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print(' Fetching employer ratings...');
      _ratings = await _apiService.fetchEmployerRatings();
      print(' Successfully fetched ${_ratings.length} ratings');
    } catch (e) {
      _errorMessage = "Failed to load employer ratings. Please try again.";
      print(' Error fetching ratings: $e');
      _ratings = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}