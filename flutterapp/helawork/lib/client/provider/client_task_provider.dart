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

  // Use this getter in your UI to see cleaned Remote/On-Site data
  List<dynamic> get tasks => formattedTasks;

  // Raw tasks for debugging if needed
  List<dynamic> get rawTasks => _tasks;

  /// 1. CREATE TASK
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
        // Insert the new task at the top of the list
        _tasks.insert(0, result['data']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. DELETE TASK
  Future<Map<String, dynamic>> deleteTask(BuildContext context, int taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService().deleteTask(taskId);

      if (result['success'] == true) {
        // Remove locally for instant UI update
        _tasks.removeWhere((task) {
          final id = task['task_id'] ?? task['id'] ?? 0;
          return id == taskId;
        });

        _showSnackBar(context, result['message'] ?? 'Deleted', Colors.green);
      } else {
        _showSnackBar(context, result['message'] ?? 'Error', Colors.red);
      }
      return result;
    } catch (e) {
      _showSnackBar(context, 'Error: $e', Colors.red);
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. FORMATTED TASKS GETTER (The "Logic" Brain)
  /// This fixes the Remote vs On-Site display issue.
  List<dynamic> get formattedTasks {
    return _tasks.map((task) {
      final taskMap = Map<String, dynamic>.from(task);

      // 1. Get raw values and clean them
      String rawType = (taskMap['service_type'] ?? '').toString().toLowerCase().trim();
      String location = (taskMap['location_address'] ?? '').toString().trim();
      String serverDisplay = (taskMap['service_type_display'] ?? '').toString();

      // 2. Strong Logic Check
      // A task is On-Site if:
      // - The server explicitly says 'on_site'
      // - OR there is a real address that isn't 'None', 'null', etc.
      bool isOnSite = rawType == 'on_site' ||
          (location.isNotEmpty &&
              location.toLowerCase() != 'none' && // Fixes the "None" string issue
              location.toLowerCase() != 'null' &&
              location != 'No location provided' &&
              location != 'Remote' &&
              location != 'Remote Task');

      // 3. Determine the clean Display Label
      String cleanDisplayType;
      if (isOnSite) {
        cleanDisplayType = 'On-Site';
      } else {
        cleanDisplayType = 'Remote';
      }

      // 4. Determine clean Location Text
      String cleanLocation;
      if (isOnSite) {
        cleanLocation = location;
      } else {
        cleanLocation = 'Remote / Online';
      }

      return {
        ...taskMap,
        // Override with our corrected logic
        'service_type': isOnSite ? 'on_site' : 'remote',
        'display_type': cleanDisplayType,
        'location_address': cleanLocation,
        // Keep original just in case
        'original_display': serverDisplay, 
      };
    }).toList();
  }

  /// 4. FETCH EMPLOYER TASKS
  Future<Map<String, dynamic>> fetchEmployerTasks(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService().fetchEmployerTasks(context);
      if (result['success'] == true) {
        _tasks = List<dynamic>.from(result['tasks'] ?? []);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 5. FETCH ALL TASKS
  Future<void> fetchTasks(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    await _performFetch(() => http.get(
          Uri.parse(ApiService.taskUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ), context);
  }

  // --- Helpers ---
  Future<void> _performFetch(Future<http.Response> Function() call, BuildContext context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final response = await call();
      _tasks = await ApiService.fetchTasks(response, context: context);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // Filter Getters using our clean logic
  List<dynamic> get onSiteTasks => tasks.where((t) => t['service_type'] == 'on_site').toList();
  List<dynamic> get remoteTasks => tasks.where((t) => t['service_type'] == 'remote').toList();
}