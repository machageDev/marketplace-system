import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

  // Loading & error states
  bool isLoading = false;
  String _errorMessage = '';

  // Dashboard data
  Map<String, dynamic> dashboardData = {
    'statistics': {
      'total_tasks': 0,
      'pending_proposals': 0,
      'ongoing_tasks': 0,
      'completed_tasks': 0,
      'total_spent': 0,
    },
    'recent_tasks': [],
    'recent_proposals': [],
    'employer_info': {},
  };

  // Cached username
  String _userName = '';

  DashboardProvider({required this.apiService}) {
    // Automatically attempt to load dashboard on provider init
    initialize();
  }

  // Getter for error message
  String get errorMessage => _errorMessage;

  // Getter for username
  String get userName => _userName.isNotEmpty ? _userName : 'User';

  // Initialize: ensures token exists before loading dashboard
  Future<void> initialize() async {
    final token = await ApiService.getUserToken();
    if (token == null || token.isEmpty) {
      _errorMessage = "Token not found. Please login.";
      notifyListeners();
      return;
    }
    await loadDashboard();
  }

  // Load dashboard data
  Future<void> loadDashboard() async {
    isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await apiService.fetchDashboardData();

      final data = response['data'] ?? response;

      // Extract statistics & tasks
      dashboardData = {
        'statistics': data['statistics'] ?? {},
        'recent_tasks': data['recent_tasks'] ?? [],
        'recent_proposals': data['recent_proposals'] ?? [],
        'employer_info': data['employer_info'] ?? {},
      };

      // Save username from API or fallback to SharedPreferences
      final employerInfo = dashboardData['employer_info'];
      _userName = employerInfo['username'] ?? '';

      if (_userName.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _userName = prefs.getString('userName') ?? 'User';
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userName);
      }
    } catch (e) {
      _errorMessage = e.toString();

      // fallback username on error
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('userName') ?? 'User';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Getters for statistics
  Map<String, dynamic> get statistics => dashboardData['statistics'] ?? {};
  List<dynamic> get recentTasks => dashboardData['recent_tasks'] ?? [];
  List<dynamic> get recentProposals => dashboardData['recent_proposals'] ?? [];
  Map<String, dynamic> get employerInfo => dashboardData['employer_info'] ?? {};

  int get totalTasks => statistics['total_tasks'] ?? 0;
  int get pendingProposals => statistics['pending_proposals'] ?? 0;
  int get ongoingTasks => statistics['ongoing_tasks'] ?? 0;
  int get completedTasks => statistics['completed_tasks'] ?? 0;
  int get totalSpent => statistics['total_spent'] ?? 0;
}
