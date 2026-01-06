import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class ClientRatingProvider with ChangeNotifier {
  List<dynamic> _ratings = [];
  List<dynamic> _tasksForRating = [];
  Map<String, dynamic> _submissionStats = {};
  bool _isLoading = false;
  String? _error;

  List<dynamic> get ratings => _ratings;
  List<dynamic> get tasksForRating => _tasksForRating;
  Map<String, dynamic> get submissionStats => _submissionStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch tasks for employer to rate freelancers
  Future<void> fetchEmployerRateableTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _tasksForRating = await ApiService().getEmployerRateableTasks();
      print("✅ Loaded ${_tasksForRating.length} tasks for employer rating");
    } catch (e) {
      _error = "Failed to load completed tasks: $e";
      print("❌ Error fetching employer tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get employer ratings from freelancers
  Future<List<dynamic>> getEmployerRatings(int employerId) async {
    try {
      return await ApiService().getEmployerRatings(employerId);
    } catch (e) {
      print("❌ Error fetching employer ratings: $e");
      return [];
    }
  }

  void debugTasks() {
    print("=== CLIENT RATING PROVIDER DEBUG ===");
    print("tasksForRating: $tasksForRating");
    print("tasksForRating length: ${tasksForRating.length}");
    for (int i = 0; i < tasksForRating.length; i++) {
      print("Task $i: ${tasksForRating[i]}");
    }
    print("=====================================");
  }

  // ✅ CORRECT: Employer rates Freelancer
  Future<bool> submitEmployerRating({
    required int taskId,
    required int freelancerId,
    required int score,
    String review = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await ApiService().submitEmployerRating(
        taskId: taskId,
        freelancerId: freelancerId,
        score: score,
        review: review,
      );
      
      if (result['success'] == true) {
        print("✅ Employer rating submitted successfully");
        // Remove the rated task from the list
        _tasksForRating.removeWhere((task) => task['id'] == taskId || task['task_id'] == taskId);
        return true;
      } else {
        _error = result['message'] ?? 'Failed to submit rating';
        return false;
      }
      
    } catch (e) {
      _error = "Failed to submit rating: $e";
      print("❌ Error submitting rating: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch ratings for a specific user
  Future<void> fetchUserRatings(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _ratings = await ApiService.getUserRatings(userId);
      print("✅ Loaded ${_ratings.length} ratings for user $userId");
    } catch (e) {
      _error = "Failed to load user ratings: $e";
      print("❌ Error fetching user ratings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch ratings for a specific task
  Future<void> fetchTaskRatings(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _ratings = await ApiService().getTaskRatings(taskId);
      print("✅ Loaded ${_ratings.length} ratings for task $taskId");
    } catch (e) {
      _error = "Failed to load task ratings: $e";
      print("❌ Error fetching task ratings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get average rating for current user
  double get myAverageRating {
    if (_ratings.isEmpty) return 0.0;
    
    final receivedRatings = _ratings.where((r) => r['rated_user'] == _getCurrentUserId()).toList();
    if (receivedRatings.isEmpty) return 0.0;
    
    final total = receivedRatings.fold(0, (sum, rating) => sum + (rating['score'] as int));
    return total / receivedRatings.length;
  }

  // Get rating statistics
  Map<String, int> getRatingStats() {
    final stats = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    
    final receivedRatings = _ratings.where((r) => r['rated_user'] == _getCurrentUserId()).toList();
    
    for (final rating in receivedRatings) {
      final score = rating['score'].toString();
      if (stats.containsKey(score)) {
        stats[score] = stats[score]! + 1;
      }
    }
    
    return stats;
  }

  // Check if user has already rated a task
  bool hasRatedTask(int taskId) {
    return _ratings.any((rating) => rating['task'] == taskId && rating['rater'] == _getCurrentUserId());
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _ratings = [];
    _tasksForRating = [];
    _submissionStats = {};
    _error = null;
    notifyListeners();
  }

  // Helper method to get current user ID
  int _getCurrentUserId() {
    return 1; // Replace with actual user ID logic
  }
}