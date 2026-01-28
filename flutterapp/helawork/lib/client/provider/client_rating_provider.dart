import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class ClientRatingProvider with ChangeNotifier {
  List<dynamic> _ratings = [];
  List<dynamic> _tasksForRating = [];
  Map<String, dynamic> _submissionStats = {};
  bool _isLoading = false;
  String? _error;
  
  // Add this instance variable
  final ApiService _apiService = ApiService();

  List<dynamic> get ratings => _ratings;
  List<dynamic> get tasksForRating => _tasksForRating;
  Map<String, dynamic> get submissionStats => _submissionStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch rateable tasks
  Future<void> fetchEmployerRateableTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use the instance variable
      final response = await _apiService.getEmployerRateableTasks();
      
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          _tasksForRating = List<dynamic>.from(response['tasks'] ?? []);
          print("✅ Loaded ${_tasksForRating.length} tasks for employer rating");
        } else {
          _error = response['error'] ?? 'Failed to load tasks';
        }
      } else if (response is List) {
        _tasksForRating = response;
        print("✅ Loaded ${_tasksForRating.length} tasks (legacy format)");
      } else {
        _error = 'Invalid response format from server';
      }
      
    } catch (e) {
      _error = "Failed to load completed tasks: $e";
      print("❌ Error fetching employer tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FIXED: Corrected method signature and logic
  Future<bool> submitEmployerRating({
    required Map<String, dynamic> task,
    required dynamic freelancerId,
    required dynamic score,
    String review = '',
    int? punctuality,
    int? quality,
    Map<String, dynamic>? extendedData,
    // Removed duplicate taskId parameter
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 1. Parse IDs safely
      final int taskId = _parseToInt(task['id'] ?? task['task_id']);
      final int parsedFreelancerId = _parseToInt(freelancerId);
      final int parsedScore = _parseToInt(score);
      
      if (taskId == 0 || parsedFreelancerId == 0) {
        _error = "Invalid Task or Freelancer ID";
        return false;
      }
      
      // 2. Check if it's onsite
      final bool isOnsite = isOnsiteTask(task);
      
      // 3. Prepare extended data
      final Map<String, dynamic> finalExtendedData = extendedData ?? {};
      
      // Force the type based on our helper check
      finalExtendedData['work_type'] = isOnsite ? 'onsite' : 'remote';
      
      // If Onsite, ensure punctuality is included
      if (isOnsite) {
        finalExtendedData['punctuality'] = punctuality ?? parsedScore;
      } else {
        finalExtendedData['technical_quality'] = quality ?? parsedScore;
      }
      
      print("📤 Submitting rating for Task $taskId | Type: ${finalExtendedData['work_type']}");
      print("📤 Score: $parsedScore | Review: ${review.isNotEmpty ? 'Yes' : 'No'}");
      
      // 4. Call API service
      final result = await _apiService.submitEmployerRating(
        taskId: taskId,
        freelancerId: parsedFreelancerId,
        score: parsedScore,
        review: review,
        extendedData: finalExtendedData,
      );
      
      if (result['success'] == true) {
        // Remove the task from rateable tasks list
        _tasksForRating.removeWhere((t) => _parseToInt(t['id'] ?? t['task_id']) == taskId);
        print("✅ Rating submitted successfully");
        return true;
      } else {
        _error = result['error'] ?? 'Failed to submit rating';
        print("❌ API returned error: $_error");
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print("❌ Exception in submitEmployerRating: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Your helper is great, keep it exactly like this:
  bool isOnsiteTask(dynamic task) {
    if (task == null) return false;
    final serviceType = task['service_type']?.toString().toLowerCase() ?? '';
    // This matches your Django 'on_site' log perfectly
    return serviceType == 'on_site' || serviceType == 'onsite' || serviceType == 'on-site';
  }
  
  // Get employer ratings from freelancers
  Future<List<dynamic>> getEmployerRatings(int employerId) async {
    try {
      return await _apiService.getEmployerRatings(employerId);
    } catch (e) {
      print("❌ Error fetching employer ratings: $e");
      return [];
    }
  }

  // Helper methods
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAll() {
    _ratings = [];
    _tasksForRating = [];
    _submissionStats = {};
    _error = null;
    notifyListeners();
  }
  
  // FIXED: Now saves to state so the UI can display the list
  Future<void> fetchEmployerRatings(int employerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final List<dynamic> data = await _apiService.getEmployerRatings(employerId);
      
      print("📊 Raw ratings data received: ${data.length} items");
      
      // Process and store ratings
      _ratings = data.map((item) {
        // Ensure item is a Map
        Map<String, dynamic> mapItem;
        if (item is Map) {
          mapItem = Map<String, dynamic>.from(item);
        } else {
          mapItem = {'error': 'Invalid data format'};
        }
        
        return {
          ...mapItem,
          'display_name': mapItem['rater_name'] ?? mapItem['freelancer']?['name'] ?? 'Freelancer',
          'display_score': (mapItem['score'] ?? 0).toDouble(),
          'display_review': mapItem['review'] ?? 'No comment provided',
          'display_date': mapItem['created_at'],
        };
      }).toList();
      
      print("✅ Loaded ${_ratings.length} ratings received from freelancers");
    } catch (e) {
      _error = "Failed to load ratings: $e";
      print("❌ Error fetching employer ratings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}