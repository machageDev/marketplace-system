// lib/clients/provider/task_provider.dart
import 'package:flutter/foundation.dart';
import 'package:helawork/clients/models/task_model.dart';

import 'package:helawork/services/api_sercice.dart';


class TaskProvider with ChangeNotifier {
  final ApiService apiService;

  TaskProvider({required this.apiService});

  bool _isLoading = false;
  String _errorMessage = '';
  List<Task> _tasks = [];
  Map<String, dynamic> _stats = {};

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;
  Map<String, dynamic> get stats => _stats;

  int get totalTasks => _stats['total_tasks'] ?? 0;
  int get openTasks => _stats['open_tasks'] ?? 0;
  int get assignedTasks => _stats['assigned_tasks'] ?? 0;
  int get completedTasks => _stats['completed_tasks'] ?? 0;

  // Load employer tasks
  Future<void> loadEmployerTasks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await apiService.fetchEmployerTasks();

      if (response['success'] == true) {
        final tasksData = response['tasks'] as List<dynamic>? ?? [];
        _tasks = tasksData.map((taskJson) => Task.fromJson(taskJson)).toList();
        _stats = response['stats'] ?? {};
        _errorMessage = '';
      } else {
        _errorMessage = response['error'] ?? 'Failed to load tasks';
        _tasks = [];
        _stats = {};
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _tasks = [];
      _stats = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  // Add this method to your existing TaskProvider class
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
    final response = await apiService.createTask(
      title: title,
      description: description,
      category: category,
      budget: budget,
      deadline: deadline,
      skills: skills,
      isUrgent: isUrgent,
    );

    _isLoading = false;

    if (response['success'] == true) {
      notifyListeners();
      return {
        'success': true,
        'message': response['message'] ?? 'Task created successfully!',
      };
    } else {
      _errorMessage = response['error'] ?? 'Failed to create task';
      notifyListeners();
      return {
        'success': false,
        'error': _errorMessage,
      };
    }
  } catch (e) {
    _errorMessage = 'An unexpected error occurred. Please try again.';
    _isLoading = false;
    notifyListeners();
    return {
      'success': false,
      'error': _errorMessage,
    };
  }
}
}