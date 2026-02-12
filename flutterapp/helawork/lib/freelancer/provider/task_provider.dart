import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Store raw data here
  List<Map<String, dynamic>> _tasks = [];
  
  // Expose processed data via this getter
  List<Map<String, dynamic>> get tasks => availableTasks;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Helper to set loading state
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// 1. MAIN FETCH METHOD
  Future<void> fetchTasks(BuildContext context) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');
      
      if (token == null) throw Exception('Please log in first');
      
      print('Fetching tasks from: ${ApiService.taskUrl}');
      final response = await http.get(
        Uri.parse(ApiService.taskUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      // Use ApiService to decode and map the hybrid fields
      final data = await ApiService.fetchTasks(response, context: context); 
      _tasks = List<Map<String, dynamic>>.from(data);
      
      print('Successfully loaded ${_tasks.length} tasks');
      
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      print('Error loading tasks: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 2. FETCH FOR PROPOSALS
  Future<void> fetchTasksForProposals(BuildContext context) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');
      if (token == null) throw Exception('Please log in first');
      
      final response = await http.get(
        Uri.parse(ApiService.taskUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final data = await ApiService.fetchTasks(response, context: context); 
      _tasks = List<Map<String, dynamic>>.from(data);
      
      print('Successfully loaded ${_tasks.length} tasks for proposals');
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 3. THE LOGIC BRAIN (Formatted Getter)
  /// FIXED: Now correctly reads 'service_type_display' from Django serializer
  List<Map<String, dynamic>> get availableTasks {
    return _tasks
        .map((task) {
          // CRITICAL FIX: Check service_type_display first (Django's human-readable field)
          String rawDisplayType = (task['service_type_display'] ?? '').toString().toLowerCase().trim();
          
          // Fallback to other fields if display field is empty
          String rawType = rawDisplayType.isNotEmpty 
              ? rawDisplayType 
              : (task['service_type'] ?? task['type'] ?? task['task_type'] ?? '').toString().toLowerCase().trim();
          
          String location = (task['location_address'] ?? task['location'] ?? task['address'] ?? '').toString().trim();
          String taskTitle = (task['title'] ?? 'Unknown Task').toString();

          // DEBUG: Print exactly what Django is sending
          print("🔍 TASK DEBUG:");
          print("   Title: $taskTitle");
          print("   service_type_display: ${task['service_type_display']}");
          print("   service_type: ${task['service_type']}");
          print("   location_address: ${task['location_address']}");
          print("   Raw Display Type: $rawDisplayType");

          // Check for On-site using Django's human-readable display value
          bool isOnSite = rawDisplayType.contains('site') || 
                         rawDisplayType.contains('physical') ||
                         rawDisplayType.contains('on') ||
                         rawDisplayType == 'on-site' ||
                         rawDisplayType == 'onsite' ||
                         // Fallback checks
                         rawType.contains('site') || 
                         rawType.contains('physical') ||
                         (location.isNotEmpty && 
                          !location.toLowerCase().contains('remote') &&
                          location.toLowerCase() != 'none' && 
                          location.toLowerCase() != 'null' && 
                          location != 'No location provided');

          String cleanDisplayType = isOnSite ? 'On-Site' : 'Remote';
          String cleanLocation = isOnSite ? location : 'Remote / Online';
          
          print("   ✅ Determined Type: $cleanDisplayType");
          print("---");

          return {
            ...task, // Keep original data
            'id': task['task_id'] ?? task['id'],
            'service_type': isOnSite ? 'onsite' : 'remote',
            'service_type_display': task['service_type_display'] ?? cleanDisplayType, // Preserve Django's value
            'display_type': cleanDisplayType,
            'location_address': cleanLocation,
          };
        })
        // Return ALL tasks, both remote and onsite
        .toList();
  }

  /// 4. HELPER METHODS
  String getTaskTitleById(int taskId) {
    try {
      final task = _tasks.firstWhere(
        (t) => (t['task_id'] ?? t['id']) == taskId,
        orElse: () => {'title': 'Selected Task'}
      );
      return task['title'] ?? 'Selected Task';
    } catch (e) {
      return 'Selected Task';
    }
  }

  /// 5. canSubmitTask method for submission logic
  /// FIXED: Now checks both service_type and service_type_display
  bool canSubmitTask(Map<String, dynamic> task) {
    // Check both the raw service_type and the display field
    String serviceType = (task['service_type'] ?? '').toString().toLowerCase();
    String serviceTypeDisplay = (task['service_type_display'] ?? '').toString().toLowerCase();
    String status = (task['status'] ?? '').toString().toLowerCase();
    
    // Check if it's remote (from either field)
    bool isRemote = serviceType.contains('remote') || 
                   serviceTypeDisplay.contains('remote');
    
    // Check if it's onsite (from either field)
    bool isOnsite = serviceType.contains('onsite') || 
                   serviceType.contains('on_site') || 
                   serviceType.contains('physical') ||
                   serviceTypeDisplay.contains('site') ||
                   serviceTypeDisplay.contains('physical') ||
                   serviceTypeDisplay.contains('on');
    
    bool isWorkable = status != 'completed' && 
                     status != 'cancelled' && 
                     status != 'closed';
    
    bool isFinished = status == 'completed' || 
                     status == 'cancelled' || 
                     status == 'closed';
    
    // Allow BOTH remote AND onsite tasks
    return (isRemote || isOnsite) && isWorkable && !isFinished;
  }

  /// 6. Dashboard stats calculator with proper status detection
  Map<String, int> calculateDashboardStats(List<Map<String, dynamic>> activeTasks) {
    int ongoingTasks = 0;
    int pendingTasks = 0;
    int completedTasks = 0;
    
    for (var task in activeTasks) {
      String status = (task['status'] ?? '').toString().toLowerCase();
      
      // Check for ongoing/in-progress tasks
      if (status.contains('progress') || 
          status == 'active' || 
          status == 'assigned' || 
          status == 'accepted' ||
          status == 'started') {
        ongoingTasks++;
      }
      // Check for pending tasks
      else if (status == 'pending' || 
               status == 'open' || 
               status == 'waiting' ||
               status == 'new') {
        pendingTasks++;
      }
      // Check for completed tasks
      else if (status == 'completed' || 
               status == 'done' || 
               status == 'finished') {
        completedTasks++;
      }
    }
    
    return {
      'ongoing': ongoingTasks,
      'pending': pendingTasks,
      'completed': completedTasks,
    };
  }

  /// 7. Filter tasks by type
  List<Map<String, dynamic>> getRemoteTasks() {
    return availableTasks.where((task) {
      String serviceType = (task['service_type'] ?? '').toString().toLowerCase();
      String displayType = (task['service_type_display'] ?? '').toString().toLowerCase();
      return serviceType.contains('remote') || displayType.contains('remote');
    }).toList();
  }

  List<Map<String, dynamic>> getOnsiteTasks() {
    return availableTasks.where((task) {
      String serviceType = (task['service_type'] ?? '').toString().toLowerCase();
      String displayType = (task['service_type_display'] ?? '').toString().toLowerCase();
      return serviceType.contains('site') || 
             serviceType.contains('physical') ||
             displayType.contains('site') || 
             displayType.contains('physical');
    }).toList();
  }

  /// 8. Get service type display name (for UI badges)
  String getServiceTypeDisplay(Map<String, dynamic> task) {
    // First check if Django already sent us the display value
    if (task['service_type_display'] != null && 
        task['service_type_display'].toString().isNotEmpty) {
      return task['service_type_display'].toString();
    }
    
    // Otherwise use our calculated display_type
    return task['display_type'] ?? 
           (task['service_type'] == 'onsite' ? 'On-Site' : 'Remote');
  }

  /// 9. Get color for service type badge
  Color getServiceTypeColor(Map<String, dynamic> task) {
    String displayType = getServiceTypeDisplay(task).toLowerCase();
    if (displayType.contains('site') || displayType.contains('physical')) {
      return Colors.orange; // On-site tasks
    }
    return Colors.blue; // Remote tasks
  }

  /// 10. Get icon for service type badge
  IconData getServiceTypeIcon(Map<String, dynamic> task) {
    String displayType = getServiceTypeDisplay(task).toLowerCase();
    if (displayType.contains('site') || displayType.contains('physical')) {
      return Icons.location_on; // On-site icon
    }
    return Icons.laptop; // Remote icon
  }
}