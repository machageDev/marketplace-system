import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';
class ClientRatingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  List<dynamic> get tasks => _tasks;

  Future<void> fetchTasks(int employerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasksForRating(employerId);
    } catch (e) {
      _tasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitRating({
    required int taskId,
    required int freelancerId,
    required int employerId,
    required int score,
    String? review,
  }) async {
    final data = {
      "task": taskId,
      "freelancer": freelancerId,
      "employer": employerId,
      "score": score,
      "review": review ?? "",
    };

    return await _apiService.apisubmitRating(data);
  }
}
