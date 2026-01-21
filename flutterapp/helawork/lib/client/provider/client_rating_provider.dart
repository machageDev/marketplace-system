import 'dart:convert';

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
      
      // Debug: Print work types
      for (final task in _tasksForRating) {
        final workType = task['work_type']?.toString().toLowerCase() ?? 'unknown';
        print("📋 Task '${task['title']}': work_type = '$workType'");
      }
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
      final task = tasksForRating[i];
      final workType = task['work_type']?.toString().toLowerCase() ?? 'unknown';
      print("Task $i: ${task['title']} | work_type: '$workType'");
    }
    print("=====================================");
  }

  // ✅ CORRECT: Employer rates Freelancer WITH EXTENDED DATA
  Future<bool> submitEmployerRating({
    required int taskId,
    required int freelancerId,
    required int score,
    String review = '',
    Map<String, dynamic>? extendedData,
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
        extendedData: extendedData,
      );
      
      if (result['success'] == true) {
        print("✅ Employer rating submitted successfully");
        if (extendedData != null) {
          print("📊 Extended data included: $extendedData");
        }
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

  // ✅ NEW: Handle Onsite Task Completion with specific metadata
  Future<bool> handleOnsiteCompletion({
    required Map<String, dynamic> task,
    required int freelancerId,
    required int score,
    int? punctuality,
    int? behavior,
    String review = "",
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final taskId = task['id'] ?? task['task_id'];
      
      if (taskId == null) {
        throw Exception("Task ID is null for onsite task");
      }
      
      // We package Onsite-specific metadata
      Map<String, dynamic> onsiteMetadata = {
        'work_type': 'onsite',
        'punctuality': punctuality ?? score,
        'professional_conduct': behavior ?? score,
        'completed_at_location': true,
        'rating_type': 'onsite_assessment',
        'metadata_version': '1.0',
      };
      
      // Add timestamp for verification
      onsiteMetadata['rated_at'] = DateTime.now().toIso8601String();
      
      print("🏢 Submitting onsite rating for task $taskId");
      print("📊 Onsite metadata: $onsiteMetadata");
      
      final result = await ApiService().submitEmployerRating(
        taskId: taskId,
        freelancerId: freelancerId,
        score: score,
        review: review,
        extendedData: onsiteMetadata,
      );
      
      if (result['success'] == true) {
        print("✅ Onsite rating submitted successfully! Payment released.");
        print("💰 Task marked as completed: ${task['title']}");
        
        // Remove the rated task from the list
        _tasksForRating.removeWhere((t) => t['id'] == taskId || t['task_id'] == taskId);
        
        // Show success message with payment info
        _error = null;
        notifyListeners();
        
        // Trigger a refresh of tasks
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fetchEmployerRateableTasks();
        });
        
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Failed to submit onsite rating';
        _error = errorMsg;
        print("❌ Onsite rating submission failed: $errorMsg");
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _error = "Failed to submit onsite rating: $e";
      print("❌ Error in handleOnsiteCompletion: $e");
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NEW: Check if task is onsite
  bool isOnsiteTask(dynamic task) {
    if (task == null) return false;
    
    // Check work_type field
    final workType = task['work_type']?.toString().toLowerCase() ?? '';
    final isOnsite = workType == 'onsite' || 
                    workType == 'on-site' || 
                    workType == 'physical' ||
                    workType == 'in_person' ||
                    workType == 'in-person';
    
    // Also check category/tags if work_type is not clear
    if (!isOnsite) {
      final category = task['category']?.toString().toLowerCase() ?? '';
      final tags = task['tags']?.toString().toLowerCase() ?? '';
      
      // Common onsite task categories
      final onsiteCategories = [
        'cleaning', 'repair', 'maintenance', 'construction',
        'delivery', 'installation', 'assembly', 'event',
        'catering', 'photography', 'videography', 'consultation',
        'training', 'workshop', 'tutoring'
      ];
      
      for (final cat in onsiteCategories) {
        if (category.contains(cat) || tags.contains(cat)) {
          return true;
        }
      }
    }
    
    return isOnsite;
  }

  // ✅ NEW: Get onsite-specific rating criteria
  List<Map<String, dynamic>> getOnsiteRatingCriteria() {
    return [
      {
        'title': 'Punctuality & Arrival Time',
        'description': 'Did the freelancer arrive on time as scheduled?',
        'key': 'punctuality',
        'hints': [
          '1 - Arrived significantly late or not at all',
          '2 - Arrived somewhat late',
          '3 - Arrived on time',
          '4 - Arrived slightly early or exactly on time',
          '5 - Arrived early and well-prepared'
        ]
      },
      {
        'title': 'Onsite Professionalism & Conduct',
        'description': 'Professional behavior, appearance, and interaction at your location',
        'key': 'professionalism',
        'hints': [
          '1 - Unprofessional conduct',
          '2 - Some professionalism issues',
          '3 - Acceptable professional conduct',
          '4 - Professional and courteous',
          '5 - Exceptionally professional in all aspects'
        ]
      },
      {
        'title': 'Quality of Service',
        'description': 'How well was the actual work performed?',
        'key': 'quality',
        'hints': [
          '1 - Poor quality, needs rework',
          '2 - Below average quality',
          '3 - Acceptable quality',
          '4 - Good quality work',
          '5 - Excellent quality, exceeded expectations'
        ]
      },
      {
        'title': 'Communication During Service',
        'description': 'Clear communication about progress and any issues',
        'key': 'communication',
        'hints': [
          '1 - Poor communication',
          '2 - Minimal communication',
          '3 - Adequate communication',
          '4 - Good communication',
          '5 - Excellent, proactive communication'
        ]
      }
    ];
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
  
  // Helper method to parse extended data from rating response
  Map<String, dynamic> parseExtendedData(dynamic ratingData) {
    try {
      if (ratingData is Map && ratingData.containsKey('extended_data')) {
        final extendedData = ratingData['extended_data'];
        if (extendedData is String && extendedData.isNotEmpty) {
          return jsonDecode(extendedData);
        } else if (extendedData is Map) {
          return Map<String, dynamic>.from(extendedData);
        }
      }
      
      // Fallback: Try to parse from review text (legacy format)
      if (ratingData['review'] is String) {
        final review = ratingData['review'] as String;
        final markerIndex = review.indexOf('__EXTENDED_DATA__:');
        if (markerIndex != -1) {
          final jsonString = review.substring(markerIndex + '__EXTENDED_DATA__:'.length);
          return jsonDecode(jsonString);
        }
      }
      
      return {};
    } catch (e) {
      print("❌ Error parsing extended data: $e");
      return {};
    }
  }
  
  // ✅ NEW: Analyze extended data to determine rating type
  String getRatingType(dynamic ratingData) {
    final extendedData = parseExtendedData(ratingData);
    
    if (extendedData.containsKey('work_type') && extendedData['work_type'] == 'onsite') {
      return 'onsite';
    } else if (extendedData.containsKey('category_scores')) {
      return 'detailed_remote';
    } else if (extendedData.containsKey('performance_tags')) {
      return 'tagged_remote';
    } else {
      return 'simple_remote';
    }
  }
  
  // ✅ NEW: Get formatted rating description based on type
  String getRatingDescription(dynamic ratingData) {
    final type = getRatingType(ratingData);
    
    switch (type) {
      case 'onsite':
        final extendedData = parseExtendedData(ratingData);
        final punctuality = extendedData['punctuality'] ?? 'N/A';
        final conduct = extendedData['professional_conduct'] ?? 'N/A';
        return 'Onsite Rating - Punctuality: $punctuality/5, Conduct: $conduct/5';
        
      case 'detailed_remote':
        final extendedData = parseExtendedData(ratingData);
        final categories = extendedData['category_scores'] ?? {};
        return 'Detailed Remote Rating - ${categories.length} categories rated';
        
      case 'tagged_remote':
        final extendedData = parseExtendedData(ratingData);
        final tags = extendedData['performance_tags'] ?? [];
        return 'Remote Rating with ${tags.length} performance tags';
        
      default:
        return 'Standard Remote Rating';
    }
  }
}