import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class RatingProvider with ChangeNotifier {
  List<dynamic> _ratings = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get ratings => _ratings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch ratings for current user (both given and received)
  Future<void> fetchMyRatings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get current user ID from your auth system
      final currentUserId = await _getCurrentUserId();
      final data = await ApiService.getData('/users/$currentUserId/ratings/');
      _ratings = data;
      print(" Loaded ${_ratings.length} ratings for user $currentUserId");
    } catch (e) {
      _error = "Failed to load ratings: $e";
      print(" Error fetching ratings: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fetch ratings for a specific user (for profile pages)
  Future<void> fetchUserRatings(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.getData('/users/$userId/ratings/');
      _ratings = data;
      print("✅ Loaded ${_ratings.length} ratings for user $userId");
    } catch (e) {
      _error = "Failed to load user ratings: $e";
      print("❌ Error fetching user ratings: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fetch ratings for a specific task
  Future<void> fetchTaskRatings(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.getData('/tasks/$taskId/ratings/');
      _ratings = data;
      print("✅ Loaded ${_ratings.length} ratings for task $taskId");
    } catch (e) {
      _error = "Failed to load task ratings: $e";
      print("❌ Error fetching task ratings: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Submit a new rating (unified for both employer→freelancer and freelancer→employer)
  Future<void> submitRating({
    required int taskId,
    required int ratedUserId, // The user being rated
    required int score,
    String review = '', required int freelancerId, required int employerId,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await ApiService.postData('/ratings/create/', {
        'task': taskId,
        'rated_user': ratedUserId,
        'score': score,
        'review': review,
      });
      
      print("✅ Rating submitted successfully for user $ratedUserId");
      
      // Refresh ratings after submission
      await fetchMyRatings();
      
    } catch (e) {
      _error = "Failed to submit rating: $e";
      print("❌ Error submitting rating: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get average rating for a user
  double getAverageRating(List<dynamic> userRatings) {
    if (userRatings.isEmpty) return 0.0;
    
    final total = userRatings.fold(0, (sum, rating) => sum + (rating['score'] as int));
    return total / userRatings.length;
  }

  // Get rating statistics
  Map<int, int> getRatingStats(List<dynamic> userRatings) {
    final stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final rating in userRatings) {
      final score = rating['score'] as int;
      if (stats.containsKey(score)) {
        stats[score] = stats[score]! + 1;
      }
    }
    
    return stats;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear ratings
  void clearRatings() {
    _ratings = [];
    notifyListeners();
  }

  // Helper method to get current user ID
  Future<int> _getCurrentUserId() async {
    // Replace with your actual user ID retrieval logic
    // Example: 
    // final user = await AuthService.getCurrentUser();
    // return user.id;
    return 1; // Temporary - implement based on your auth system
  }
}