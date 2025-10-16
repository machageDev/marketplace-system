import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';

class TaskProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<dynamic> get tasks => _tasks;

  // Create Task
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required String category,
    double? budget,
    DateTime? deadline,
    String? skills,
    bool isUrgent = false,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await ApiService().createTask(
        title: title,
        description: description,
        category: category,
        budget: budget,
        deadline: deadline,
        skills: skills,
        isUrgent: isUrgent,
      );

      _isLoading = false;
      
      if (result['success'] == true) {
        // Add the new task to the local list
        if (result['data'] != null) {
          _tasks.insert(0, result['data']);
        }
        notifyListeners();
        return {
          'success': true,
          'message': result['message'] ?? 'Task created successfully!',
          'data': result['data'],
        };
      } else {
        _errorMessage = result['error'] ?? 'Failed to create task';
        notifyListeners();
        return {
          'success': false,
          'message': result['error'] ?? 'Failed to create task',
        };
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Fetch all tasks
  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final tasks = await ApiService.fetchTasks();
      _tasks = tasks;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Fetch employer's tasks
  Future<Map<String, dynamic>> fetchEmployerTasks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await ApiService().fetchEmployerTasks();
      _isLoading = false;
      
      if (result['success'] == true) {
        _tasks = result['tasks'] ?? [];
        notifyListeners();
        return {
          'success': true,
          'tasks': _tasks,
          'stats': result['stats'] ?? {},
        };
      } else {
        _errorMessage = result['error'] ?? 'Failed to load tasks';
        notifyListeners();
        return {
          'success': false,
          'message': result['error'] ?? 'Failed to load tasks',
        };
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Get task by ID
  dynamic getTaskById(int taskId) {
    try {
      return _tasks.firstWhere((task) => task['task_id'] == taskId);
    } catch (e) {
      return null;
    }
  }

  // Update task status
  Future<Map<String, dynamic>> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find the task in local list
      final taskIndex = _tasks.indexWhere((task) => task['task_id'] == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex]['status'] = status;
      }

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Task status updated successfully',
      };
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}