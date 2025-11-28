import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class RatingProvider with ChangeNotifier {
  List<dynamic> _ratings = [];
  List<dynamic> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get ratings => _ratings;
  List<dynamic> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ADD THIS MISSING METHOD
  Future<void> fetchMyRatings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final currentUserId = await _getCurrentUserId();
      final data = await ApiService.getData('/users/$currentUserId/ratings/');
      _ratings = data;
      print("✅ Loaded ${_ratings.length} ratings for user $currentUserId");
    } catch (e) {
      _error = "Failed to load ratings: $e";
      print("❌ Error fetching ratings: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fetch clients from completed tasks
  Future<void> fetchClientsFromCompletedTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final currentUserId = await _getCurrentUserId();
      // Fetch tasks where freelancer was assigned and task is completed
      final tasks = await ApiService.getData('/freelancers/$currentUserId/completed-tasks/');
      
      // Extract unique clients from completed tasks
      final clients = <dynamic>[];
      final clientIds = <int>{};
      
      for (final task in tasks) {
        final client = task['employer'];
        if (client != null && client['id'] != null) {
          final clientId = client['id'] as int;
          if (!clientIds.contains(clientId)) {
            clientIds.add(clientId);
            clients.add(client);
          }
        }
      }
      
      _clients = clients;
      print("✅ Loaded ${_clients.length} clients from completed tasks");
    } catch (e) {
      _error = "Failed to load clients from tasks: $e";
      print("❌ Error fetching clients from tasks: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Fetch ratings for a specific client (for profile pages)
  Future<void> fetchClientRatings(int clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.getData('/users/$clientId/ratings/');
      _ratings = data;
      print("✅ Loaded ${_ratings.length} ratings for client $clientId");
    } catch (e) {
      _error = "Failed to load client ratings: $e";
      print("❌ Error fetching client ratings: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Submit a rating for a client (freelancer rates client)
  Future<void> rateClient({
    required int taskId,
    required int clientId,
    required int freelancerId,
    required int score,
    String review = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await ApiService.postData('/ratings/create/', {
        'task': taskId,
        'rated_user': clientId,
        'rater_user': freelancerId,
        'score': score,
        'review': review,
        'rating_type': 'client_rating',
      });
      
      print("✅ Client rating submitted successfully for client $clientId");
      
      // Refresh client ratings after submission
      await fetchClientRatings(clientId);
      
    } catch (e) {
      _error = "Failed to submit client rating: $e";
      print("❌ Error submitting client rating: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get client's average rating
  double getClientAverageRating() {
    if (_ratings.isEmpty) return 0.0;
    
    final clientRatings = _ratings.where((rating) => 
        rating['rating_type'] == 'client_rating' || 
        rating['rated_user_type'] == 'client').toList();
    
    if (clientRatings.isEmpty) return 0.0;
    
    final total = clientRatings.fold(0, (sum, rating) => sum + (rating['score'] as int));
    return total / clientRatings.length;
  }

  // Get client rating statistics
  Map<int, int> getClientRatingStats() {
    final stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    final clientRatings = _ratings.where((rating) => 
        rating['rating_type'] == 'client_rating' || 
        rating['rated_user_type'] == 'client').toList();
    
    for (final rating in clientRatings) {
      final score = rating['score'] as int;
      if (stats.containsKey(score)) {
        stats[score] = stats[score]! + 1;
      }
    }
    
    return stats;
  }

  // Get all client reviews with details
  List<Map<String, dynamic>> getClientReviews() {
    final clientRatings = _ratings.where((rating) => 
        rating['rating_type'] == 'client_rating' || 
        rating['rated_user_type'] == 'client').toList();
    
    return clientRatings.map((rating) {
      return {
        'id': rating['id'],
        'score': rating['score'],
        'review': rating['review'] ?? '',
        'created_at': rating['created_at'],
        'rater_name': rating['rater_user']?['username'] ?? 'Anonymous',
        'rater_avatar': rating['rater_user']?['profile_picture'],
        'task_title': rating['task']?['title'] ?? 'Completed Task',
      };
    }).toList();
  }

  // Get total number of client ratings
  int getClientRatingCount() {
    return _ratings.where((rating) => 
        rating['rating_type'] == 'client_rating' || 
        rating['rated_user_type'] == 'client').length;
  }

  // Check if current freelancer has already rated this client for a specific task
  bool hasRatedClient(int clientId, int freelancerId, int taskId) {
    return _ratings.any((rating) =>
        rating['rated_user'] == clientId &&
        rating['rater_user'] == freelancerId &&
        rating['task'] == taskId &&
        (rating['rating_type'] == 'client_rating' || rating['rated_user_type'] == 'client'));
  }

  // Get average rating for any user
  double getAverageRating(List<dynamic> userRatings) {
    if (userRatings.isEmpty) return 0.0;
    
    final total = userRatings.fold(0, (sum, rating) => sum + (rating['score'] as int));
    return total / userRatings.length;
  }

  // Get general rating statistics
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