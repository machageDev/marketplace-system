import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/freelancer/model/contract_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:helawork/freelancer/provider/contract_provider.dart';

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

  // ========== NEW: Task selection tracking ==========
  Map<String, dynamic>? _selectedTaskForSubmission;
  String? _selectedTaskId;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.100.188:8000';

  Future<void> loadData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
      
      // Get tasks from contracts (using ContractProvider)
      await _loadTasksFromContracts(context);
      
      // Get the response for regular tasks (optional)
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
      
      // Merge API tasks with contract tasks
      _mergeTasks(tasks);

      _calculateDashboardStats();

      error = null;
    } catch (e) {
      error = "Failed to load dashboard: $e";
      print('Dashboard load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // FIXED: Corrected task data access based on your Contract model
  Future<void> _loadTasksFromContracts(BuildContext context) async {
    try {
      print('🔄 Loading tasks from ContractProvider...');
      
      // Get ContractProvider
      final contractProvider = Provider.of<ContractProvider>(context, listen: false);
      
      // Fetch contracts if not loaded
      if (contractProvider.contracts.isEmpty) {
        await contractProvider.fetchContracts(context);
      }
      
      // Clear existing activeTasks first
      activeTasks.clear();
      
      // Extract tasks from ACTIVE contracts
      for (var contract in contractProvider.activeContracts) {
        try {
          // CORRECTED: Access task data from the Map
          final taskData = contract.task; // This is a Map<String, dynamic>
          
          // Get task ID from various possible fields
          final taskId = taskData['task_id']?.toString() ?? 
                        taskData['id']?.toString() ?? 
                        taskData['task']?.toString() ?? 
                        contract.contractId.toString();
          
          if (taskId.isNotEmpty && taskId != 'null') {
            // Get task title using the getter from Contract model
            final taskTitle = contract.taskTitle;
            
            activeTasks.add({
              'task_id': taskId,
              'id': taskId,
              'title': taskTitle,
              'description': taskData['description']?.toString() ?? '',
              'status': _determineTaskStatus(contract),
              'budget': contract.budget?.toString() ?? '0',
              'deadline': taskData['deadline']?.toString() ?? taskData['end_date']?.toString(),
              'contract_id': contract.contractId.toString(),
              'employer_name': contract.employerName,
              'start_date': contract.startDate,
              'end_date': contract.endDate,
              'is_accepted': contract.isFullyAccepted,
              'can_accept': contract.canAccept,
              // Store contract status for validation
              'contract_status': contract.status,
              'is_active': contract.isActive,
              'is_fully_accepted': contract.isFullyAccepted,
            });
            
            print('✅ Added task from contract: $taskTitle (ID: $taskId, Status: ${contract.status})');
          }
        } catch (e) {
          print('⚠️ Error processing contract ${contract.contractId}: $e');
        }
      }
      
      print('📊 Total tasks from contracts: ${activeTasks.length}');
      
      // Also load from API as fallback
      await _loadTasksFromApi();
      
    } catch (e) {
      print('❌ Error loading tasks from contracts: $e');
    }
  }

  // Helper to determine task status from contract
  String _determineTaskStatus(Contract contract) {
    if (!contract.isActive) return 'Cancelled';
    if (contract.isFullyAccepted) {
      if (contract.endDate != null) {
        return 'Completed';
      }
      return 'In Progress';
    }
    if (contract.employerAccepted && !contract.freelancerAccepted) {
      return 'Pending Acceptance';
    }
    return contract.status;
  }

  // Load tasks from API as fallback
  Future<void> _loadTasksFromApi() async {
    try {
      final token = await _secureStorage.read(key: "auth_token");
      if (token == null) return;

      // Try to get assigned tasks from API
      final response = await http.get(
        Uri.parse('$baseUrl/api/contracts/freelancer/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['contracts'] is List) {
          final contracts = data['contracts'];
          
          for (var contractData in contracts) {
            try {
              if (contractData['task'] != null) {
                final task = contractData['task'];
                final taskId = task['task_id']?.toString() ?? 
                              task['id']?.toString() ??
                              contractData['contract_id']?.toString();
                
                if (taskId != null && taskId.isNotEmpty) {
                  // Check if task already exists
                  final exists = activeTasks.any((t) => t['task_id'] == taskId);
                  if (!exists) {
                    activeTasks.add({
                      'task_id': taskId,
                      'id': taskId,
                      'title': task['title'] ?? task['task_title'] ?? 'Untitled Task',
                      'description': task['description'] ?? '',
                      'status': _getApiTaskStatus(contractData),
                      'budget': task['budget']?.toString() ?? '0',
                      'deadline': task['deadline']?.toString(),
                      'contract_id': contractData['contract_id']?.toString(),
                      'employer_name': contractData['employer']?['name'] ?? 
                                      contractData['employer']?['company_name'] ?? 
                                      'Unknown',
                    });
                  }
                }
              }
            } catch (e) {
              print('Error processing API contract: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading tasks from API: $e');
    }
  }

  // Helper to get status from API contract data
  String _getApiTaskStatus(Map<String, dynamic> contractData) {
    if (contractData['is_fully_accepted'] == true) {
      return 'In Progress';
    }
    if (contractData['employer_accepted'] == true && contractData['freelancer_accepted'] == false) {
      return 'Pending Acceptance';
    }
    return contractData['status']?.toString() ?? 'Pending';
  }

  // Merge API tasks with contract tasks
  void _mergeTasks(List<Map<String, dynamic>> apiTasks) {
    for (var apiTask in apiTasks) {
      final apiTaskId = apiTask['task_id']?.toString() ?? apiTask['id']?.toString();
      if (apiTaskId != null) {
        // Check if task already exists in activeTasks
        final exists = activeTasks.any((task) => 
          task['task_id']?.toString() == apiTaskId || 
          task['id']?.toString() == apiTaskId
        );
        
        if (!exists) {
          activeTasks.add({
            'task_id': apiTaskId,
            'id': apiTaskId,
            'title': apiTask['title'] ?? 'Untitled Task',
            'description': apiTask['description'] ?? '',
            'status': apiTask['status'] ?? 'In Progress',
            'budget': apiTask['budget']?.toString() ?? '0',
            'deadline': apiTask['deadline'],
            'employer_name': apiTask['employer_name'] ?? 'Unknown',
          });
        }
      }
    }
    
    // Take only 5 tasks for display (if needed)
    if (activeTasks.length > 5) {
      activeTasks = activeTasks.take(5).toList();
    }
  }

  // ========== FIXED: Task selection methods ==========
  
  // Select a task for submission
  void selectTaskForSubmission(String taskId) {
    print('🎯 Selecting task for submission: $taskId');
    
    final task = getTaskById(taskId);
    if (task != null && task.isNotEmpty) {
      _selectedTaskId = taskId;
      _selectedTaskForSubmission = Map<String, dynamic>.from(task);
      
      print('✅ Task selected: ${task['title']}');
      print('   Status: ${task['status']}');
      print('   Contract: ${task['contract_id']}');
      
      notifyListeners();
    } else {
      print('❌ Task not found: $taskId');
      _selectedTaskId = null;
      _selectedTaskForSubmission = null;
    }
  }

  // Clear task selection
  void clearTaskSelection() {
    _selectedTaskId = null;
    _selectedTaskForSubmission = null;
    notifyListeners();
  }

  // Get the selected task
  Map<String, dynamic>? get selectedTaskForSubmission => _selectedTaskForSubmission;
  String? get selectedTaskId => _selectedTaskId;

  // ========== FIXED: Better getTaskById method ==========
  Map<String, dynamic>? getTaskById(String taskId) {
    print('🔍 Looking for task with ID: "$taskId"');
    
    if (taskId.isEmpty) {
      print('❌ Empty task ID');
      return null;
    }
    
    // Try to find the task
    for (var task in activeTasks) {
      final taskIdFromTask = task['task_id']?.toString();
      final idFromTask = task['id']?.toString();
      
      print('   Checking task: ${task['title']}');
      print('     task_id: $taskIdFromTask');
      print('     id: $idFromTask');
      
      if ((taskIdFromTask != null && taskIdFromTask == taskId) ||
          (idFromTask != null && idFromTask == taskId)) {
        print('✅ Found matching task!');
        return task;
      }
    }
    
    print('❌ No task found with ID: "$taskId"');
    print('📋 Available tasks:');
    for (var task in activeTasks) {
      print('   - ${task['title']} (task_id: ${task['task_id']}, id: ${task['id']})');
    }
    
    return null;
  }

  // ========== NEW: Validate if task can be submitted ==========
  bool canSubmitTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      print('❌ Cannot submit: Task not found');
      return false;
    }
    
    final status = (task['status']?.toString() ?? '').toLowerCase();
    final isAccepted = task['is_accepted'] == true || 
                      task['is_fully_accepted'] == true;
    final isActive = task['is_active'] != false;
    
    print('📋 Task validation:');
    print('   Status: $status');
    print('   Accepted: $isAccepted');
    print('   Active: $isActive');
    
    // Valid for submission if:
    // 1. Task is active
    // 2. Task is accepted/fully accepted
    // 3. Status is "In Progress" or similar
    // 4. Not completed or cancelled
    
    final canSubmit = isActive && 
                     isAccepted &&
                     (status.contains('progress') || 
                      status.contains('active')) &&
                     !status.contains('complete') &&
                     !status.contains('cancelled');
    
    print('✅ Can submit: $canSubmit');
    return canSubmit;
  }

  // ========== NEW: Get task details for submission ==========
  Map<String, dynamic>? getTaskDetailsForSubmission(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return null;
    
    return {
      'task_id': task['task_id'] ?? taskId,
      'title': task['title'] ?? 'Untitled Task',
      'description': task['description'] ?? '',
      'budget': task['budget'] ?? '0',
      'deadline': task['deadline'],
      'contract_id': task['contract_id'],
      'employer_name': task['employer_name'] ?? 'Unknown',
      'status': task['status'] ?? 'Unknown',
    };
  }

  // Get tasks for submission (used by DashboardPage)
  List<Map<String, dynamic>> getTasksForSubmission() {
    print('📋 Getting tasks for submission: ${activeTasks.length} available');
    
    // Filter only tasks that can be submitted
    final availableTasks = activeTasks.where((task) {
      final taskId = task['task_id']?.toString() ?? task['id']?.toString();
      return taskId != null && canSubmitTask(taskId);
    }).toList();
    
    print('📋 Available tasks for submission: ${availableTasks.length}');
    return availableTasks;
  }

  // Get first available task ID
  String? getFirstTaskId() {
    final availableTasks = getTasksForSubmission();
    
    if (availableTasks.isNotEmpty) {
      final taskId = availableTasks.first['task_id']?.toString() ?? 
                    availableTasks.first['id']?.toString();
      print('🔍 First available task ID: $taskId');
      return taskId;
    }
    
    print('❌ No active tasks found for submission');
    return null;
  }

  // Get task by contract ID
  Map<String, dynamic>? getTaskByContractId(String contractId) {
    try {
      return activeTasks.firstWhere(
        (task) => task['contract_id']?.toString() == contractId,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }

  void _calculateDashboardStats() {
    totalTasks = activeTasks.length;
    
    ongoingTasks = activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('progress') || 
             status == 'in_progress' ||
             status == 'active';
    }).length;
    
    completedTasks = activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('complete') || 
             status == 'completed' ||
             status == 'finished';
    }).length;

    pendingProposals = activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('pending') || 
             status == 'pending_acceptance';
    }).length;
    
    print('📊 Dashboard stats - Total: $totalTasks, '
          'Ongoing: $ongoingTasks, '
          'Completed: $completedTasks, '
          'Pending Proposals: $pendingProposals');
  }

  Future<http.Response> _makeTasksApiCall() async {
    try {
      final String? token = await _secureStorage.read(key: "auth_token");
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please log in.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/task'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Tasks API response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error making tasks API call: $e');
      rethrow;
    }
  }

  Future<void> _loadProfilePictureFromAPI() async {
    try {
      print('Loading profile picture from API...');
      
      final token = await _secureStorage.read(key: "auth_token");
      
      if (token == null) {
        print('No auth token found');
        return;
      }
      
      final response = await ApiService.getUserProfile(token);
      
      if (response != null && response['success'] == true) {
        final profile = response['profile'];
        if (profile != null && profile['profile_picture'] != null) {
          profilePictureUrl = profile['profile_picture'];
          print('Profile picture loaded: $profilePictureUrl');
          await _saveUserData();
        } else {
          print('No profile picture found in user profile');
        }
      } else {
        print('Failed to load profile: ${response?['message']}');
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
    activeTasks.clear();
    _selectedTaskId = null;
    _selectedTaskForSubmission = null;
    notifyListeners();
    print('User data cleared from dashboard');
  }

  Future<void> refresh(BuildContext context) async {
    await loadData(context);
  }

  bool get hasError => error != null;
  bool get hasTasks => activeTasks.isNotEmpty;
  bool get isLoaded => !isLoading && error == null;
  
  // Get only active/ongoing tasks
  List<Map<String, dynamic>> get ongoingTaskList {
    return activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('progress') || 
             status == 'in_progress' ||
             status == 'active';
    }).toList();
  }
  
  // Get pending tasks (awaiting acceptance)
  List<Map<String, dynamic>> get pendingTaskList {
    return activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('pending') || 
             status == 'pending_acceptance';
    }).toList();
  }
}