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
      
      // Filter contracts for the current user
      _rateableContracts = _filterContractsForUser(response, userId);
      
      debugPrint("✅ Found ${_rateableContracts.length} rateable contracts");
      
      if (_rateableContracts.isEmpty) {
        _error = "No contracts available for rating.\n\n"
                 "To rate someone:\n"
                 "1. Complete a contract together\n"
                 "2. Ensure payment is received\n"
                 "3. Rate within 30 days of completion\n\n"
                 "If you've completed work, check that:\n"
                 "- Contract is marked as completed\n"
                 "- Payment has been processed\n"
                 "- You haven't already rated them";
      }
      
    } catch (e) {
      _error = "Failed to load rateable contracts: ${e.toString()}";
      _rateableContracts = [];
      debugPrint("❌ Error fetching rateable contracts: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // ============ PROCESS RATEABLE CONTRACTS ============

  List<dynamic> _filterContractsForUser(List<dynamic> contracts, int userId) {
    debugPrint("📋 Filtering ${contracts.length} contracts for user $userId");
    
    final filteredContracts = <dynamic>[];
    final processedTasks = <int>{};
    
    for (final contract in contracts) {
      try {
        // Extract contract data
        final contractId = _parseToInt(contract['contract_id']) ?? 0;
        final task = contract['task'] ?? {};
        final userToRate = contract['user_to_rate'] ?? {};
        final currentUserRole = contract['current_user_role'] ?? '';
        
        if (contractId == 0) {
          debugPrint("⚠️ Invalid contract ID");
          continue;
        }
        
        final taskId = _parseToInt(task['id']) ?? 0;
        final taskTitle = task['title'] ?? 'Unknown Task';
        
        // Check if we've already processed a contract for this task
        if (processedTasks.contains(taskId)) {
          debugPrint("⏭️ Already have contract for task $taskId, skipping");
          continue;
        }
        
        // Check if user has already rated this person for this task
        final ratedUserId = _parseToInt(userToRate['id']) ?? 0;
        if (ratedUserId == 0) {
          debugPrint("⚠️ Invalid user to rate ID");
          continue;
        }
        
        if (_hasRatedUser(taskId, ratedUserId, userId)) {
          debugPrint("⏭️ Already rated user $ratedUserId for task $taskId");
          continue;
        }
        
        // Calculate days remaining for rating
        final completedDateStr = contract['completed_date'];
        final daysRemaining = _calculateDaysRemaining(completedDateStr);
        
        if (daysRemaining <= 0) {
          debugPrint("⏭️ Rating period expired for contract $contractId");
          continue;
        }
        
        // Build contract info for rating
        final contractInfo = {
          'contract_id': contractId,
          'task_id': taskId,
          'task_title': taskTitle,
          'budget': task['budget'] ?? 0,
          'user_to_rate': {
            'id': ratedUserId,
            'username': userToRate['username'] ?? 'User $ratedUserId',
            'email': userToRate['email'] ?? '',
            'profile_picture': userToRate['profile_picture'],
          },
          'current_user_role': currentUserRole,
          'completed_date': completedDateStr,
          'payment_date': contract['payment_date'],
          'days_remaining': daysRemaining,
          'can_rate_until': contract['can_rate_until'],
          'is_freelancer': currentUserRole == 'freelancer',
          'is_employer': currentUserRole == 'employer',
        };
        
        filteredContracts.add(contractInfo);
        processedTasks.add(taskId);
        
        debugPrint("✅ Added contract $contractId for rating");
        
      } catch (e) {
        debugPrint("❌ Error processing contract: $e");
        debugPrint("Contract data: $contract");
        continue;
      }
    }
    
    return filteredContracts;
  }

  int _calculateDaysRemaining(String? completedDateStr) {
    if (completedDateStr == null) return 30; // Default 30 days if no date
    
    try {
      final completedDate = DateTime.parse(completedDateStr);
      final now = DateTime.now();
      final difference = now.difference(completedDate).inDays;
      final daysRemaining = 30 - difference;
      
      return daysRemaining > 0 ? daysRemaining : 0;
    } catch (e) {
      debugPrint("Error parsing date $completedDateStr: $e");
      return 30; // Default if parsing fails
    }
  }

  bool _hasRatedUser(int taskId, int ratedUserId, int raterId) {
    return _myRatings.any((rating) {
      try {
        final ratingTaskId = _parseToInt(rating['task']) ?? 0;
        final ratingRatedUserId = _parseToInt(rating['rated_user']) ?? 0;
        final ratingRaterId = _parseToInt(rating['rater']) ?? 0;
        
        return ratingTaskId == taskId && 
               ratingRatedUserId == ratedUserId && 
               ratingRaterId == raterId;
      } catch (e) {
        return false;
      }
    });
  }

  // ============ GET CLIENTS FOR RATING (For backward compatibility) ============

  List<dynamic> get clients {
    // Convert rateable contracts to client format for existing UI
    return _rateableContracts.map((contract) {
      final userToRate = contract['user_to_rate'];
      return {
        'id': userToRate['id'],
        'username': userToRate['username'],
        'email': userToRate['email'],
        'profile_picture': userToRate['profile_picture'],
        'task_id': contract['task_id'],
        'task_title': contract['task_title'],
        'contract_id': contract['contract_id'],
        'budget': contract['budget'],
        'completed_date': contract['completed_date'],
        'payment_date': contract['payment_date'],
        'days_remaining': contract['days_remaining'],
        'is_employer': contract['is_employer'],
        'is_freelancer': contract['is_freelancer'],
      };
    }).toList();
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
      
      // Check if already rated
      if (_hasRatedUser(taskId, ratedUserId, userId)) {
        throw Exception("You have already rated this user for this task");
      }
      
      debugPrint("📤 Submitting rating: Contract $contractId, Task $taskId, User $ratedUserId, Score $score");
      
      // Submit rating with contract ID
      await ApiService.createRating(
        taskId: taskId,
        ratedUserId: ratedUserId,
        contractId: contractId,
        score: score,
        review: review,
      );
      
      // Refresh data
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

  // ============ SUBMIT CLIENT RATING (For backward compatibility) ============

  Future<void> submitClientRating({
    required int userId,
    required dynamic taskId,
    required dynamic clientId,
    required dynamic score,
    String review = '',
  }) async {
    try {
      final parsedTaskId = _parseToInt(taskId) ?? 0;
      final parsedClientId = _parseToInt(clientId) ?? 0;
      final parsedScore = _parseToInt(score) ?? 0;
      
      if (parsedTaskId == 0) throw Exception("Invalid task ID");
      if (parsedClientId == 0) throw Exception("Invalid client ID");
      if (parsedScore == 0) throw Exception("Invalid score");
      
      // Find the contract for this task and client
      final contract = _rateableContracts.firstWhere(
        (c) => c['task_id'] == parsedTaskId && c['user_to_rate']['id'] == parsedClientId,
        orElse: () => null,
      );
      
      if (contract == null) {
        throw Exception("No eligible contract found for rating. Make sure the contract is completed and paid.");
      }
      
      final contractId = _parseToInt(contract['contract_id']) ?? 0;
      
      if (contractId == 0) {
        throw Exception("Invalid contract ID");
      }
      
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
        return ratedUserId != raterUserId; // Received from others
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
        
        // You gave rating to someone else AND it's to employer/client
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
        
        // You gave rating to someone else AND it's to freelancer
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

  // Get rating summary for display
  Map<String, dynamic> getRatingSummary() {
    final received = getRatingsReceived();
    final given = getClientRatingsGiven();
    final employerGiven = getEmployerRatingsGiven();
    
    return {
      'total_received': received.length,
      'total_given': given.length + employerGiven.length,
      'average_received': getAverageRating(received),
      'average_given': getAverageRating([...given, ...employerGiven]),
      'stats_received': getRatingStats(received),
      'stats_given': getRatingStats([...given, ...employerGiven]),
    };
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