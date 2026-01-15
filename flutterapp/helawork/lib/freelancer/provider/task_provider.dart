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
  /// This fixes the Remote vs On-Site display issue for Freelancers.
  List<Map<String, dynamic>> get availableTasks {
    return _tasks.map((task) {
      
      // 1. Get raw values and clean them
      String rawType = (task['service_type'] ?? '').toString().toLowerCase().trim();
      String location = (task['location_address'] ?? '').toString().trim();
      (task['service_type_display'] ?? '').toString();

      // 2. Strong Logic Check
      // A task is On-Site if: 
      // - The server explicitly says 'on_site' 
      // - OR there is a real address that isn't 'None', 'null', etc.
      bool isOnSite = rawType == 'on_site' || 
                     (location.isNotEmpty && 
                      location.toLowerCase() != 'none' && 
                      location.toLowerCase() != 'null' && 
                      location != 'No location provided' &&
                      location != 'Remote' &&
                      location != 'Remote Task');

      // 3. Determine Clean Strings
      String cleanDisplayType = isOnSite ? 'On-Site' : 'Remote';
      String cleanLocation = isOnSite ? location : 'Remote / Online';

      // 4. Return the cleaned object
      return {
        'id': task['task_id'] ?? task['id'],
        'title': task['title'] ?? 'Untitled Task',
        'description': task['description'] ?? '',
        'employer': task['employer'] ?? {},
        'is_taken': task['is_taken'] ?? false,
        'has_contract': task['has_contract'] ?? false,
        'assigned_freelancer': task['assigned_freelancer'],
        
        // HYBRID FIELDS (Fixed)
        'service_type': isOnSite ? 'on_site' : 'remote',
        'display_type': cleanDisplayType,        // USE THIS IN UI FOR LABEL
        'location_address': cleanLocation,       // USE THIS IN UI FOR LOCATION TEXT
        
        'budget': task['budget'] ?? '0.00',
        'payment_type': task['payment_type'] ?? 'fixed',
        'is_urgent': task['is_urgent'] ?? false,
        'skills': task['required_skills'] ?? task['skills'] ?? '',
        'deadline': task['deadline'],
      };
    }).toList();
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
}