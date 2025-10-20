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

  /// Fetch employer ratings from the API
  Future<void> fetchRatings(int employerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ratings = (await _apiService.fetchEmployerRatings(employerId));
    } catch (e) {
      _errorMessage = "Failed to load employer ratings. Please try again.";
      if (kDebugMode) {
        print("Error fetching ratings: $e");
      }
      _ratings = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
