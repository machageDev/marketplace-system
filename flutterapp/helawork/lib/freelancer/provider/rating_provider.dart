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
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getUserRatings(userId);
      
      _myRatings = data.map((item) {
        final Map<String, dynamic> mapItem = Map<String, dynamic>.from(item as Map);
        return {
          ...mapItem,
          'display_name': mapItem['rater_name'] ?? 'Client',
          'display_title': mapItem['task_title'] ?? 'Task',
          'display_score': (mapItem['score'] ?? 0).toDouble(),
        };
      }).toList();

      _error = null;
    } catch (e) {
      debugPrint("❌ Error in fetchMyRatings: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRateableContracts(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (userId == 0) throw Exception("User not logged in");
      
      final response = await ApiService.getRateableContracts();
      
      List<dynamic> tasks = [];
      if (response is Map && response.containsKey('tasks')) {
        tasks = List<dynamic>.from(response['tasks'] ?? []);
      } else {
        tasks = response as List<dynamic>;
      }
      
      _rateableContracts = tasks;
      _error = _rateableContracts.isEmpty ? "No contracts available for rating." : null;
      
    } catch (e) {
      _error = "Failed to load rateable contracts: ${e.toString()}";
      _rateableContracts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ RATING FILTERING METHODS ============

  // Get ratings WHERE USER IS RATED (received from others)
  List<Map<String, dynamic>> getRatingsReceived() {
    try {
      return _myRatings.where((rating) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rating as Map);
        final ratingType = (map['rating_type']?.toString() ?? '').toLowerCase();
        
        // Ratings received are when employer rates freelancer
        return ratingType.contains('employer_to_freelancer');
      }).map((rating) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rating as Map);
        
        return {
          'display_name': map['rater_name'] ?? 'Client',
          'display_score': (map['score'] ?? 0).toDouble(),
          'display_title': map['task_title'] ?? 'No Title',
          'display_review': map['review'] ?? '',
          'date': map['created_at'],
          'rating_type': map['rating_type'],
          'is_received': true,
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error in getRatingsReceived: $e");
      return [];
    }
  }

  // Get ratings WHERE USER IS RATER (given to others)
  List<Map<String, dynamic>> getRatingsGiven() {
    try {
      final List<Map<String, dynamic>> givenRatings = _myRatings.where((rating) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rating as Map);
        final ratingType = (map['rating_type']?.toString() ?? '').toLowerCase();
        
        // DEBUG: Print each rating to see what's in them
        debugPrint("🔍 Checking rating - type: $ratingType, rater: ${map['rater']}, rated_user: ${map['rated_user']}");
        
        // Ratings given are when freelancer rates employer
        return ratingType.contains('freelancer_to_employer');
      }).map((rating) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rating as Map);
        
        return {
          'display_name': map['rated_user_name'] ?? 'Client',
          'display_score': (map['score'] ?? 0).toDouble(),
          'display_title': map['task_title'] ?? 'No Title',
          'display_review': map['review'] ?? '',
          'date': map['created_at'],
          'rating_type': map['rating_type'],
          'is_given': true,
          'rater': map['rater'],
          'rated_user': map['rated_user'],
        };
      }).toList();
      
      debugPrint("✅ Found ${givenRatings.length} ratings given");
      return givenRatings;
    } catch (e) {
      debugPrint("❌ Error in getRatingsGiven: $e");
      return [];
    }
  }

  // ============ ADDED BACK: getClientRatingsGiven ============
  
  List<dynamic> getClientRatingsGiven() {
    try {
      return _myRatings.where((rating) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rating as Map);
        final ratingType = (map['rating_type']?.toString() ?? '').toLowerCase();
        
        // Client ratings given are when freelancer rates employer
        return ratingType.contains('freelancer_to_employer');
      }).toList();
    } catch (e) {
      debugPrint("❌ Error in getClientRatingsGiven: $e");
      return [];
    }
  }

  // ============ COMBINED METHOD FOR UI ============

  List<Map<String, dynamic>> getFilteredRatings(int tabIndex) {
    debugPrint("🎯 ====== GET FILTERED RATINGS CALLED ======");
    debugPrint("🎯 Tab index: $tabIndex (${tabIndex == 0 ? 'Received' : 'Given'})");
    debugPrint("📦 _myRatings count: ${_myRatings.length}");
    debugPrint("📊 Received ratings count: ${getRatingsReceived().length}");
    debugPrint("📊 Given ratings count: ${getRatingsGiven().length}");
    debugPrint("📊 Rateable contracts: ${_rateableContracts.length}");
    
    List<Map<String, dynamic>> result;
    
    if (tabIndex == 0) {
      // Received tab - ratings from clients to freelancer
      result = getRatingsReceived();
      debugPrint("🎯 Returning ${result.length} received ratings");
    } else {
      // Given tab - ratings from freelancer to clients
      result = getRatingsGiven();
      debugPrint("🎯 Found ${result.length} given ratings");
      
      // If no ratings given, show rateable contracts
      if (result.isEmpty && _rateableContracts.isNotEmpty) {
        debugPrint("🎯 No ratings given yet, converting ${_rateableContracts.length} rateable contracts...");
        result = _rateableContracts.map<Map<String, dynamic>>((contract) {
          final Map<String, dynamic> cMap = Map<String, dynamic>.from(contract as Map);
          final Map<String, dynamic> taskData = cMap['task'] is Map 
              ? Map<String, dynamic>.from(cMap['task']) 
              : {};
          final Map<String, dynamic> clientData = cMap['client'] is Map 
              ? Map<String, dynamic>.from(cMap['client']) 
              : {};
          
          final formattedContract = {
            'id': cMap['contract_id'],
            'is_rateable_contract': true,
            'contract_id': cMap['contract_id'],
            'task_id': taskData['id'],
            'task_title': taskData['title'] ?? 'Untitled Task',
            'client_name': clientData['name'] ?? 'Client',
            'client_id': clientData['user_id'] ?? clientData['user'] ?? clientData['id'],
            'budget': taskData['budget'] ?? '0.00',
            'status': cMap['status'] ?? 'completed',
            'display_name': clientData['name'] ?? 'Client',
            'display_title': taskData['title'] ?? 'Untitled Task',
            'display_score': 0.0,
            'display_review': 'Rate this client',
            'date': '',
            'rating_type': 'rateable_contract',
          };
          
          debugPrint("📋 Created rateable contract item: $formattedContract");
          return formattedContract;
        }).toList();
      }
    }
    
    debugPrint("🎯 Final filtered result: ${result.length} items");
    if (result.isEmpty) {
      debugPrint("🎯 Result is empty!");
    } else {
      debugPrint("🎯 First item keys: ${result.first.keys.toList()}");
      debugPrint("🎯 First item is_rateable_contract: ${result.first['is_rateable_contract']}");
    }
    debugPrint("🎯 ====== END GET FILTERED RATINGS ======");
    
    return result;
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
      
    } catch (e) {
      _error = "Failed to submit rating: ${e.toString()}";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
Future<void> submitClientRating({
  required int userId,
  required dynamic taskId,
  required dynamic clientId,
  required dynamic score,
  String review = '', 
  required int freelancerId, 
  required Map<String, Object> task, 
  required Map<String, dynamic> extendedData,
}) async {
  _isLoading = true;
  notifyListeners();
  
  try {
    final int pTaskId = _parseToInt(taskId) ?? 0;
    final int pScore = _parseToInt(score) ?? 0;
    
    // 1. DATA MINING: Find the real Target ID
    int contractId = 0;
    int targetUserId = 0;

    for (var contract in _rateableContracts) {
      final cMap = Map<String, dynamic>.from(contract as Map);
      final taskData = cMap['task'] is Map ? Map<String, dynamic>.from(cMap['task']) : {};
      final int foundTaskId = _parseToInt(taskData['id'] ?? cMap['task_id']) ?? 0;

      if (foundTaskId == pTaskId) {
        contractId = _parseToInt(cMap['contract_id']) ?? 0;
        final clientData = cMap['client'] ?? {};
        
        // Try every possible ID key in your JSON structure
        targetUserId = _parseToInt(clientData['user_id'] ?? 
                                  clientData['user_account_id'] ?? 
                                  clientData['id']) ?? 0;
        break;
      }
    }

    // 2. FALLBACK: Use the clientId passed from the screen if loop fails
    if (targetUserId == 0) {
      targetUserId = _parseToInt(clientId) ?? 0;
    }

    // 3. THE "STOP" LOGIC: Never send 0, never send 'Me'
    if (targetUserId == 0) throw Exception("Error: Target ID is 0. Data source is missing the Client ID.");
    if (targetUserId == userId) throw Exception("Error: Target ID matches your ID ($userId). Cannot rate yourself.");

    debugPrint("🚀 SUBMITTING TO DJANGO: Rater: $userId -> Target: $targetUserId");

    // 4. API CALL
    final result = await ApiService.createRating(
      taskId: pTaskId,
      ratedUserId: targetUserId, // This MUST be the Employer ID
      contractId: contractId,
      score: pScore,
      review: review,
    );

    if (result['success'] == true) {
      await Future.wait([fetchMyRatings(userId), fetchRateableContracts(userId)]);
    } else {
      throw Exception(result['message'] ?? 'Server error');
    }
  } catch (e) {
    _error = e.toString();
    debugPrint("❌ Rating Failure: $e");
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
// Get combined list of ratings given AND rateable contracts
List<Map<String, dynamic>> getCombinedGivenRatings() {
  try {
    // Get actual ratings given
    final List<Map<String, dynamic>> givenRatings = getRatingsGiven();
    
    // If there are actual ratings, return them
    if (givenRatings.isNotEmpty) {
      debugPrint("✅ Found ${givenRatings.length} actual ratings given");
      return givenRatings;
    }
    
    // If no ratings given, return rateable contracts as "to-rate" items
    debugPrint("📊 No ratings given yet, showing ${_rateableContracts.length} rateable contracts");
    
    return _rateableContracts.map<Map<String, dynamic>>((contract) {
      final Map<String, dynamic> cMap = Map<String, dynamic>.from(contract as Map);
      final Map<String, dynamic> taskData = cMap['task'] is Map 
          ? Map<String, dynamic>.from(cMap['task']) 
          : {};
      final Map<String, dynamic> clientData = cMap['client'] is Map 
          ? Map<String, dynamic>.from(cMap['client']) 
          : {};
      
      // Inside getCombinedGivenRatings, update the return map:
// Inside getCombinedGivenRatings return map:
return {
  'is_rateable_contract': true,
  'contract_id': cMap['contract_id'],
  'task_id': taskData['id'],
  'task_title': taskData['title'] ?? 'Untitled Task',
  'client_name': clientData['name'] ?? 'Client',
  
  // 🔥 THE FIX: Prioritize the account ID that Django expects
  'client_id': clientData['user_id'] ?? clientData['user'] ?? clientData['id'],
  
  'display_name': clientData['name'] ?? 'Client',
  'display_title': taskData['title'] ?? 'Untitled Task',
  'display_score': 0.0,
  'display_review': 'Tap to rate this client',
  'is_not_rated_yet': true,
};
    }).toList();
  } catch (e) {
    debugPrint(" Error in getCombinedGivenRatings: $e");
    return [];
  }
}

  // ============ UTILITIES ============

  int? _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }


  void clear() {
    _myRatings = [];
    _rateableContracts = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}