
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> get tasks => _tasks;

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
      
      print('Tasks API response status: ${response.statusCode}');

      // Use ApiService to decode and map the hybrid fields
      final data = await ApiService.fetchTasks(response, context: context); 
      _tasks = List<Map<String, dynamic>>.from(data);
      
      print('Successfully loaded ${_tasks.length} tasks');
      
      // CRITICAL DEBUG: Check if hybrid fields exist in the raw data
      if (_tasks.isNotEmpty) {
        print('--- DATA SYNC CHECK ---');
        print('Title: ${_tasks[0]['title']}');
        print('Service Type: ${_tasks[0]['service_type']}');
        print('Location: ${_tasks[0]['location_address']}');
        print('-----------------------');
      }
      
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

  /// 3. THE GETTER (This sends data to your UI)
  List<Map<String, dynamic>> get availableTasks {
    return _tasks.map((task) {
      return {
        'id': task['task_id'] ?? task['id'],
        'title': task['title'] ?? 'Untitled Task',
        'description': task['description'] ?? '',
        'employer': task['employer'] ?? {},
        'is_taken': task['is_taken'] ?? false,
        'has_contract': task['has_contract'] ?? false,
        'assigned_freelancer': task['assigned_freelancer'],
        
        // HYBRID FIELDS: This ensures your UI always sees these keys
        'service_type': task['service_type'] ?? 'remote', 
        'location_address': task['location_address'] ?? 'Remote Task',
        'budget': task['budget'] ?? '0.00',
        'payment_type': task['payment_type'] ?? 'fixed',
        'is_urgent': task['is_urgent'] ?? false,
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