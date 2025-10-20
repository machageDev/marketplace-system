// employer_rating_provider.dart
import 'package:flutter/foundation.dart';
import 'package:helawork/services/api_sercice.dart';


class EmployerRatingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _ratings = [];

  List<dynamic> get ratings => _ratings;

  Future<void> loadRatings(String token) async {
    _ratings = (await _apiService.fetchEmployerRatings(token as int)) as List;
    notifyListeners();
  }
}
