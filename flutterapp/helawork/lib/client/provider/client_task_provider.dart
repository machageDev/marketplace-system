import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';


class TaskProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<dynamic> get tasks => _tasks;

  Future<Map<String, dynamic>> createTask({
  required String title,
  required String description,
  required String category,
  required String serviceType,
  required String paymentType,
  double? budget,
  DateTime? deadline,
  String? skills,
  bool isUrgent = false,
  String? locationAddress,
  double? latitude,
  double? longitude,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    final result = await ApiService().createTask(
      title: title,
      description: description,      
      category: category,
      serviceType: serviceType,
      paymentType: paymentType,
      budget: budget,
      deadline: deadline,
      skills: skills,
      isUrgent: isUrgent,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
    );

    _isLoading = false;
    if (result['success'] == true) {
      _tasks.insert(0, result['data']);
      notifyListeners();
    }
    return result;
  } catch (e) {
    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': e.toString()};
  }
}
  // Fetch all tasks
  Future<void> fetchTasks(dynamic context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final tasks = await ApiService.fetchTasks(context, context: context);
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
  Future<Map<String, dynamic>> fetchEmployerTasks(BuildContext context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await ApiService().fetchEmployerTasks( context);
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