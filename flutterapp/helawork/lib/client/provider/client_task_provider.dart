import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:http/http.dart' as http;

class TaskProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<dynamic> get tasks => formattedTasks;

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
        serviceType: serviceType, // MUST BE 'on_site' or 'remote'
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
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. FORMATTED TASKS GETTER
  List<dynamic> get formattedTasks {
    return _tasks.map((task) {
      final taskMap = Map<String, dynamic>.from(task);
      
      // Data Cleaning based on your logs
      String rawType = (taskMap['service_type'] ?? '').toString().toLowerCase();
      String location = (taskMap['location_address'] ?? '').toString();
      String display = (taskMap['service_type_display'] ?? '').toString();

      // STRICT ON-SITE LOGIC
      // It is On-Site only if the server says so OR if there is a real physical address
      bool isOnSite = rawType == 'on_site' || 
                     (location.isNotEmpty && 
                      location != 'No location provided' && 
                      location != 'Remote Task' && 
                      location != 'null');

      return {
        ...taskMap,
        'service_type': isOnSite ? 'on_site' : 'remote',
        'location_address': location,
        // If display is the string 'null', use our logic-based label
        'display_type': (display != 'null' && display.isNotEmpty) 
            ? display 
            : (isOnSite ? 'On-Site' : 'Remote'),
      };
    }).toList();
  }

  /// 3. FETCH METHODS
  Future<void> fetchTasks(BuildContext context) async {
    await _performFetch(() => http.get(
      Uri.parse(ApiService.taskUrl),
      headers: _getHeaders(null), // Token added inside helper
    ), context);
  }

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

  Map<String, String> _getHeaders(String? token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Helper getters for UI Tabs
  List<dynamic> get onSiteTasks => tasks.where((t) => t['service_type'] == 'on_site').toList();
  List<dynamic> get remoteTasks => tasks.where((t) => t['service_type'] == 'remote').toList();
}