import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class ClientRatingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<dynamic> _tasks = [];
  String? _errorMessage; 

  
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  List<dynamic> get tasks => _tasks;

  Future<void> fetchTasks(int employerId) async {
    _isLoading = true;
    _errorMessage = null; 
    notifyListeners();

    try {
      _tasks = await _apiService.getTasksForRating();
      _errorMessage = null; 
    } catch (e) {
      _errorMessage = "Failed to load tasks: $e";
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRating({
    required int taskId,
    required int freelancerId,
    required int employerId,
    required int score,
    String? review,
  }) async {
    _isLoading = true;
    _errorMessage = null; 
    notifyListeners();

    try {
      final data = {
        "task": taskId,
        "freelancer": freelancerId,
        "employer": employerId,
        "score": score,
        "review": review ?? "",
      };

      final success = await _apiService.apisubmitRating(data);
      
      if (!success) {
        _errorMessage = "Failed to submit rating";
      }
      
      return success;
    } catch (e) {
      _errorMessage = "Failed to submit rating: $e"; 
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}