import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Use backend values directly without overriding
  List<dynamic> get tasks => _tasks;

  /// Raw list for debugging
  List<dynamic> get rawTasks => _tasks;

  // --------------------------------------------------------------------
  // 1. CREATE TASK
  // --------------------------------------------------------------------
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

      if (result['success'] == true && result['data'] != null) {
        _tasks.insert(0, result['data']);
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('createTask error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------
  // 2. DELETE TASK
  // --------------------------------------------------------------------
  Future<Map<String, dynamic>> deleteTask(BuildContext context, int taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService().deleteTask(taskId);

      if (result['success'] == true) {
        _tasks.removeWhere((task) {
          final id = task is Map ? (task['task_id'] ?? task['id'] ?? 0) : 0;
          return id == taskId;
        });

        _showSnackBar(context, result['message'] ?? 'Deleted', Colors.green);
      } else {
        _showSnackBar(context, result['message'] ?? 'Error', Colors.red);
      }

      notifyListeners();
      return result;
    } catch (e) {
      _showSnackBar(context, 'Error: $e', Colors.red);
      debugPrint('deleteTask error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------
  // 3. FETCH EMPLOYER TASKS
  // --------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchEmployerTasks(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService().fetchEmployerTasks();

      if (result['success'] == true) {
        _tasks = List<dynamic>.from(result['tasks'] ?? []);
        _errorMessage = '';
      } else {
        _errorMessage = result['error']?.toString() ?? 'Failed to fetch tasks';
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('fetchEmployerTasks error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------
  // 4. FETCH ALL TASKS
  // --------------------------------------------------------------------
  Future<void> fetchTasks(BuildContext context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      final response = await http.get(
        Uri.parse(ApiService.taskUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          _tasks = decoded;
        } else if (decoded is Map && decoded['tasks'] is List) {
          _tasks = List<dynamic>.from(decoded['tasks']);
        } else {
          _tasks = [];
        }
      } else {
        _errorMessage = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------
  // 5. SNACKBAR HELPER
  // --------------------------------------------------------------------
  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // --------------------------------------------------------------------
  // 6. FILTERS — THESE NOW USE BACKEND VALUES
  // --------------------------------------------------------------------
  List<dynamic> get onSiteTasks =>
      _tasks.where((t) => t is Map && t['service_type'] == 'on_site').toList();

  List<dynamic> get remoteTasks =>
      _tasks.where((t) => t is Map && t['service_type'] == 'remote').toList();
}
