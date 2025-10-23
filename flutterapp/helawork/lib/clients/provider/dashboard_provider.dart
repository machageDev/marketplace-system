import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

  bool isLoading = true;
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

  String _errorMessage = '';
  String _userName = '';

  DashboardProvider({required this.apiService}) {
    print("=== DASHBOARD PROVIDER INITIALIZED ===");
    _loadDashboard();
  }

  Future<void> loadDashboard() async {
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    print("=== LOADING DASHBOARD ===");
    isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print("1. Calling apiService.fetchDashboardData()...");
      final response = await apiService.fetchDashboardData();
      print("2. API call completed, received response: $response");
      
      // Extract the data from the success wrapper
      final data = response['data'] ?? response;
      print("2.1 Extracted dashboard data: $data");
      
      // Handle different API response structures
      if (data.containsKey('statistics') || data.containsKey('recent_tasks')) {
        print("3. Using direct structure");
        dashboardData = {
          'statistics': {
            'total_tasks': data['statistics']?['total_tasks'] ?? data['total_tasks'] ?? 0,
            'pending_proposals': data['statistics']?['pending_proposals'] ?? data['pending_proposals'] ?? 0,
            'ongoing_tasks': data['statistics']?['ongoing_tasks'] ?? data['ongoing_tasks'] ?? 0,
            'completed_tasks': data['statistics']?['completed_tasks'] ?? data['completed_tasks'] ?? 0,
            'total_spent': data['statistics']?['total_spent'] ?? data['total_spent'] ?? 0,
          },
          'recent_tasks': data['recent_tasks'] ?? data['tasks'] ?? [],
          'recent_proposals': data['recent_proposals'] ?? data['proposals'] ?? [],
          'employer_info': data['employer_info'] ?? data['user_info'] ?? {},
        };
      } else {
        print("3. Using fallback structure");
        dashboardData = {
          'statistics': {
            'total_tasks': data['total_tasks'] ?? 0,
            'pending_proposals': data['pending_proposals'] ?? 0,
            'ongoing_tasks': data['ongoing_tasks'] ?? 0,
            'completed_tasks': data['completed_tasks'] ?? 0,
            'total_spent': data['total_spent'] ?? 0,
          },
          'recent_tasks': data['recent_tasks'] ?? [],
          'recent_proposals': data['recent_proposals'] ?? [],
          'employer_info': data['employer_info'] ?? {},
        };
      }
      
      // CAPTURE THE ACTUAL LOGGED-IN USER NAME FROM API
      final employerInfo = dashboardData['employer_info'];
      if (employerInfo != null && employerInfo['username'] != null) {
        _userName = employerInfo['username'].toString();
        print("4. Captured user name from API: $_userName");
        
        // Save to SharedPreferences for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userName);
        print("5. Saved user name to SharedPreferences: $_userName");
      } else {
        // Fallback: try to load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('userName');
        if (savedName != null && savedName.isNotEmpty) {
          _userName = savedName;
          print("6. Loaded user name from SharedPreferences: $_userName");
        } else {
          _userName = 'User'; // Final fallback
          print("7. Using fallback user name: $_userName");
        }      }
      
      print("8. Dashboard data updated: $dashboardData");
      
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      print("=== DASHBOARD LOAD ERROR ===");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      
      // Try to load user name from SharedPreferences on error
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('userName');
      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
        print("Loaded user name from cache after error: $_userName");
      }
    } finally {
      isLoading = false;
      print("9. Loading completed. isLoading: $isLoading, error: $_errorMessage, user: $_userName");
      notifyListeners();
    }
  }

  // Getters
  Map<String, dynamic> get statistics => dashboardData['statistics'] ?? {};
  List<dynamic> get recentTasks => dashboardData['recent_tasks'] ?? [];
  List<dynamic> get recentProposals => dashboardData['recent_proposals'] ?? [];
  Map<String, dynamic> get employerInfo => dashboardData['employer_info'] ?? {};
  String get errorMessage => _errorMessage;
  
  // User name getter - returns the actual captured name
  String get userName => _userName.isNotEmpty ? _userName : 'User';

  int get totalTasks => statistics['total_tasks'] ?? 0;
  int get pendingProposals => statistics['pending_proposals'] ?? 0;
  int get ongoingTasks => statistics['ongoing_tasks'] ?? 0;
  int get completedTasks => statistics['completed_tasks'] ?? 0;
  int get totalSpent => statistics['total_spent'] ?? 0;
}