import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class DashboardProvider with ChangeNotifier {
  String? userName;
  String? profilePictureUrl; 
  int inProgress = 0;
  int completed = 0;
  List<Map<String, dynamic>> activeTasks = [];
  bool isLoading = false;
  String? error;

  int totalTasks = 0;
  int pendingProposals = 0;
  int ongoingTasks = 0;
  int completedTasks = 0;

  Future<void> loadData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
      
      // Get the response first
      final response = await _makeTasksApiCall();
      
      // Now pass the response to fetchTasks
      final tasksRaw = await ApiService.fetchTasks(response, context: context);

      if (userName == null || userName!.isEmpty) {
        userName = await ApiService.getLoggedInUserName();
        await _saveUserData();
      }

      if (profilePictureUrl == null || profilePictureUrl!.isEmpty) {
        await _loadProfilePictureFromAPI();
      }

      final tasks = List<Map<String, dynamic>>.from(tasksRaw);

      inProgress = tasks.where((t) => t["status"] == "In Progress").length;
      completed = tasks.where((t) => t["status"] == "Completed").length;
      activeTasks = tasks.take(5).toList();

      _calculateDashboardStats(tasks);

      error = null;
    } catch (e) {
      error = "Failed to load dashboard: $e";
      print('Dashboard load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to make the API call
  Future<http.Response> _makeTasksApiCall() async {
    try {
      // Get token directly from SharedPreferences since _getUserToken is private
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please log in.');
      }

      // Make the HTTP request - using your actual base URL
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/tasks/'), // Adjust URL as needed
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Tasks API response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error making tasks API call: $e');
      rethrow;
    }
  }

  void _calculateDashboardStats(List<Map<String, dynamic>> tasks) {
    totalTasks = tasks.length;
    
    ongoingTasks = tasks.where((t) {
      final status = t["status"]?.toString().toLowerCase() ?? "";
      return status == "in progress" || status.contains("progress");
    }).length;
    
    completedTasks = tasks.where((t) {
      final status = t["status"]?.toString().toLowerCase() ?? "";
      return status == "completed" || status.contains("complete");
    }).length;

    pendingProposals = 0;
    
    print('Dashboard stats - Total: $totalTasks, Ongoing: $ongoingTasks, Completed: $completedTasks, Pending Proposals: $pendingProposals');
  }

  Future<void> _loadProfilePictureFromAPI() async {
    try {
      print('Loading profile picture from API...');
      
      final userProfile = await ApiService.getUserProfile();
      if (userProfile != null && userProfile['profile_picture'] != null) {
        profilePictureUrl = userProfile['profile_picture'];
        print('Profile picture loaded: $profilePictureUrl');
        await _saveUserData();
      } else {
        print('No profile picture found in user profile');
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> refreshProfilePicture() async {
    print('Manually refreshing profile picture...');
    await _loadProfilePictureFromAPI();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
    profilePictureUrl = prefs.getString('profilePictureUrl');
    print('Loaded from cache - Name: $userName, Photo: $profilePictureUrl');
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString('userName', userName!);
    }
    if (profilePictureUrl != null) {
      await prefs.setString('profilePictureUrl', profilePictureUrl!);
    }
    print('Saved to cache - Name: $userName, Photo: $profilePictureUrl');
  }

  Future<void> updateUserProfile(String name, String profileUrl) async {
    userName = name;
    profilePictureUrl = profileUrl;
    await _saveUserData();
    notifyListeners();
    print('User profile updated in dashboard');
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('profilePictureUrl');
    userName = null;
    profilePictureUrl = null;
    notifyListeners();
    print('User data cleared from dashboard');
  }

  // Add refresh method
  Future<void> refresh(BuildContext context) async {
    await loadData(context);
  }

  // Add getters for UI
  bool get hasError => error != null;
  bool get hasTasks => activeTasks.isNotEmpty;
  bool get isLoaded => !isLoading && error == null;
}