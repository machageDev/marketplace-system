import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class TaskProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> get tasks => _tasks;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> fetchTasks(BuildContext context) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      // CORRECTED: Use positional argument, not named argument
      final data = await ApiService.fetchTasks(context, context: null); 
      _tasks = List<Map<String, dynamic>>.from(data);
      
      print('Successfully loaded ${_tasks.length} tasks');
      
      // Debug: Print all tasks with their taken status
      for (var task in _tasks) {
        print('Task: ${task['title']} - is_taken: ${task['is_taken']}');
      }
      
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      print('Error loading tasks: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage))
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksForProposals(BuildContext context) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      // Also corrected here
      final data = await ApiService.fetchTasks(context, context: null); 
      _tasks = List<Map<String, dynamic>>.from(data);
      
      print('Successfully loaded ${_tasks.length} tasks for proposals');
      
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      print('Error loading tasks for proposals: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  List<Map<String, dynamic>> get availableTasks {
    print('Available tasks called - total tasks: ${_tasks.length}');
    
    // Debug all tasks
    for (var task in _tasks) {
      print('Task: ${task['title']}');
      print('   assigned_freelancer: ${task['assigned_freelancer'] != null ? "Exists" : "None"}');
      print('   is_taken: ${task['is_taken']}');
      print('   has_contract: ${task['has_contract']}');
    }
    
    return _tasks.map((task) {
      return {
        'id': task['task_id'] ?? task['id'],
        'title': task['title'] ?? 'Untitled Task',
        'description': task['description'] ?? '',
        'employer': task['employer'] ?? {},
        'is_taken': task['is_taken'] ?? false,
        'has_contract': task['has_contract'] ?? false,
        'assigned_freelancer': task['assigned_freelancer'],
      };
    }).toList();
  }

  String getTaskTitleById(int taskId) {
    try {
      final task = _tasks.firstWhere(
        (task) => (task['task_id'] ?? task['id']) == taskId,
        orElse: () => {'title': 'Selected Task'}
      );
      return task['title'] ?? 'Selected Task';
    } catch (e) {
      print('Error finding task title for ID $taskId: $e');
      return 'Selected Task';
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}