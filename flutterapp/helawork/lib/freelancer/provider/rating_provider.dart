import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class RatingProvider with ChangeNotifier {
  // State
  List<dynamic> _myRatings = [];
  List<dynamic> _rateableContracts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<dynamic> get ratings => _myRatings;
  List<dynamic> get rateableContracts => _rateableContracts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============ FETCH METHODS ============

  Future<void> fetchMyRatings(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (userId == 0) throw Exception("User not logged in");
      
      // Get your ratings
      _myRatings = await ApiService.getUserRatings(userId);
      debugPrint("✅ Loaded ${_myRatings.length} ratings");
      
    } catch (e) {
      _error = "Failed to load ratings: ${e.toString()}";
      _myRatings = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }
  Future<void> fetchRateableContracts(int userId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    if (userId == 0) throw Exception("User not logged in");
    
    debugPrint("🔍 Fetching rateable contracts for user $userId");
    
    // Get rateable contracts (completed + paid) from new endpoint
    final response = await ApiService.getRateableContracts();
    
    // DEBUG: Log the full response
    debugPrint("📦 Full backend response: $response");
    
    // FIX: Extract the 'tasks' array from the response
    List<dynamic> tasks = [];
    if (response is Map && response.containsKey('tasks')) {
      // Response is a Map with 'tasks' key
      tasks = List<dynamic>.from(response['tasks'] ?? []);
      debugPrint("📊 Extracted ${tasks.length} tasks from response");
    } else    // Response is already a List (old format)
    tasks = response;
  
    
    _rateableContracts = tasks;
    
    debugPrint("✅ Found ${_rateableContracts.length} rateable contracts");
    
    if (_rateableContracts.isNotEmpty) {
      for (var i = 0; i < _rateableContracts.length; i++) {
        final contract = _rateableContracts[i];
        debugPrint("📝 Contract $i: ${contract['contract_id']} - Task: ${contract['task']?['title']}");
      }
    }
    
    if (_rateableContracts.isEmpty) {
      _error = "No contracts available for rating.\n\n"
               "To rate someone:\n"
               "1. Complete a contract together\n"
               "2. Ensure payment is received\n"
               "3. Rate within 30 days of completion";
    }
    
  } catch (e) {
    _error = "Failed to load rateable contracts: ${e.toString()}";
    _rateableContracts = [];
    debugPrint("❌ Error fetching rateable contracts: $e");
  }
  
  _isLoading = false;
  notifyListeners();
}

  // ============ SUBMIT RATING ============

  Future<void> submitRating({
    required int userId,
    required int contractId,
    required int taskId,
    required int ratedUserId,
    required int score,
    String review = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (userId == 0) throw Exception("User not logged in");
      if (contractId == 0) throw Exception("Invalid contract ID");
      if (taskId == 0) throw Exception("Invalid task ID");
      if (ratedUserId == 0) throw Exception("Invalid user to rate");
      if (score < 1 || score > 5) throw Exception("Score must be between 1 and 5");
      
      debugPrint("📤 Submitting rating: Contract $contractId, Task $taskId, User $ratedUserId, Score $score");
      
      final result = await ApiService.createRating(
        taskId: taskId,
        ratedUserId: ratedUserId,
        contractId: contractId,
        score: score,
        review: review,
      );
      
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to submit rating');
      }
      
      await Future.wait([
        fetchMyRatings(userId),
        fetchRateableContracts(userId),
      ]);
      
      debugPrint("✅ Rating submitted successfully");
      
    } catch (e) {
      _error = "Failed to submit rating: ${e.toString()}";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ SUBMIT CLIENT RATING (KEEP THIS METHOD!) ============

  Future<void> submitClientRating({
    required int userId,
    required dynamic taskId,
    required dynamic clientId,
    required dynamic score,
    String review = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final parsedTaskId = _parseToInt(taskId) ?? 0;
      final parsedClientId = _parseToInt(clientId) ?? 0;
      final parsedScore = _parseToInt(score) ?? 0;
      
      if (parsedTaskId == 0) throw Exception("Invalid task ID");
      if (parsedClientId == 0) throw Exception("Invalid client ID");
      if (parsedScore == 0) throw Exception("Invalid score");
      
      debugPrint("🔍 Looking for contract with task: $parsedTaskId, client: $parsedClientId");
      
      // Find the contract for this task and client
      Map<String, dynamic>? matchingContract;
      for (final contract in _rateableContracts) {
        final contractTask = contract['task'] is Map
            ? Map<String, dynamic>.from(contract['task'])
            : <String, dynamic>{};
        
        final userToRate = contract['user_to_rate'] is Map
            ? Map<String, dynamic>.from(contract['user_to_rate'])
            : <String, dynamic>{};
        
        final contractTaskId = _parseToInt(contractTask['id'] ?? contract['task_id']) ?? 0;
        final contractClientId = _parseToInt(userToRate['id']) ?? 0;
        
        if (contractTaskId == parsedTaskId && contractClientId == parsedClientId) {
          matchingContract = contract;
          break;
        }
      }
      
      if (matchingContract == null) {
        debugPrint("❌ No matching contract found. Available contracts:");
        for (final contract in _rateableContracts) {
          final task = contract['task'] is Map
              ? Map<String, dynamic>.from(contract['task'])
              : <String, dynamic>{};
          final user = contract['user_to_rate'] is Map
              ? Map<String, dynamic>.from(contract['user_to_rate'])
              : <String, dynamic>{};
          
          debugPrint("   Contract ${contract['contract_id']}: Task ${task['id']} - User ${user['id']}");
        }
        
        throw Exception("No eligible contract found for rating. Make sure the contract is completed and paid.");
      }
      
      final contractId = _parseToInt(matchingContract['contract_id']) ?? 0;
      
      if (contractId == 0) {
        throw Exception("Invalid contract ID");
      }
      
      debugPrint("✅ Found matching contract $contractId");
      
      // Use new submitRating method
      await submitRating(
        userId: userId,
        contractId: contractId,
        taskId: parsedTaskId,
        ratedUserId: parsedClientId,
        score: parsedScore,
        review: review,
      );
      
    } catch (e) {
      _error = "Failed to submit rating: ${e.toString()}";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ UTILITY METHODS ============

  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  // ============ PUBLIC METHODS ============

  List<dynamic> getRatingsReceived() {
    return _myRatings.where((rating) {
      try {
        final ratedUserId = _parseToInt(rating['rated_user']);
        final raterUserId = _parseToInt(rating['rater']);
        return ratedUserId != raterUserId;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<dynamic> getClientRatingsGiven() {
    return _myRatings.where((rating) {
      try {
        final ratedUserId = _parseToInt(rating['rated_user']);
        final raterUserId = _parseToInt(rating['rater']);
        final ratingType = rating['rating_type']?.toString() ?? '';
        
        return ratedUserId != raterUserId && 
               (ratingType.contains('freelancer_to_employer') || 
                ratingType.contains('freelancer_to_client'));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<dynamic> getEmployerRatingsGiven() {
    return _myRatings.where((rating) {
      try {
        final ratedUserId = _parseToInt(rating['rated_user']);
        final raterUserId = _parseToInt(rating['rater']);
        final ratingType = rating['rating_type']?.toString() ?? '';
        
        return ratedUserId != raterUserId && 
               (ratingType.contains('employer_to_freelancer'));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  double getAverageRating(List<dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;
    
    int totalScore = 0;
    int validRatings = 0;
    
    for (final rating in ratings) {
      final scoreInt = _parseToInt(rating['score']);
      
      if (scoreInt != null && scoreInt >= 1 && scoreInt <= 5) {
        totalScore += scoreInt;
        validRatings++;
      }
    }
    
    return validRatings > 0 ? totalScore / validRatings : 0.0;
  }

  Map<int, int> getRatingStats(List<dynamic> ratings) {
    final stats = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final rating in ratings) {
      final scoreInt = _parseToInt(rating['score']);

      if (scoreInt != null && scoreInt >= 1 && scoreInt <= 5) {
        stats[scoreInt] = stats[scoreInt]! + 1;
      }
    }

    return stats;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _myRatings = [];
    _rateableContracts = [];
    _error = null;
    notifyListeners();
  }
}