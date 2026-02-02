
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/freelancer/model/contract_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:helawork/freelancer/provider/contract_provider.dart';

class DashboardProvider with ChangeNotifier {
  String? userName;
  String? profilePictureUrl; 
  List<Map<String, dynamic>> activeTasks = [];
  List<Map<String, dynamic>> completedTasksList = [];
  bool isLoading = false;
  String? error;

  int totalTasks = 0;
  int pendingProposals = 0;
  int ongoingTasks = 0;
  int completedTasks = 0;

  // Task selection tracking
  Map<String, dynamic>? _selectedTaskForSubmission;
  String? _selectedTaskId;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> loadData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
      
      // Load active tasks from contracts
      await _loadTasksFromContracts(context);
      
      // Load completed/approved tasks from API
      await _loadCompletedTasks();

      if (userName == null || userName!.isEmpty) {
        userName = await ApiService.getLoggedInUserName();
        await _saveUserData();
      }

      if (profilePictureUrl == null || profilePictureUrl!.isEmpty) {
        await _loadProfilePictureFromAPI();
      }

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

  Future<void> _loadCompletedTasks() async {
    try {
      print('🔄 Loading completed tasks...');
      completedTasksList = await ApiService.getFreelancerCompletedTasks();
      print('✅ Loaded ${completedTasksList.length} completed tasks');
    } catch (e) {
      print('❌ Error loading completed tasks: $e');
      completedTasksList = [];
    }
  }

  Future<void> _loadTasksFromContracts(BuildContext context) async {
    try {
      print('🔄 Loading tasks from ContractProvider...');
      
      final contractProvider = Provider.of<ContractProvider>(context, listen: false);
      
      if (contractProvider.contracts.isEmpty) {
        await contractProvider.fetchContracts(context);
      }
      
      activeTasks.clear();
      
      for (var contract in contractProvider.activeContracts) {
        try {
          final taskData = contract.task;
          final taskId = taskData['task_id']?.toString() ?? 
                        taskData['id']?.toString() ?? 
                        taskData['task']?.toString() ?? 
                        contract.contractId.toString();
          
          if (taskId.isNotEmpty && taskId != 'null') {
            final taskTitle = contract.taskTitle;
            
            activeTasks.add({
              'task_id': taskId,
              'id': taskId,
              'title': taskTitle,
              'description': taskData['description']?.toString() ?? '',
              'status': _determineTaskStatus(contract),
              'budget': contract.budget.toString(),
              'deadline': taskData['deadline']?.toString() ?? taskData['end_date']?.toString(),
              'contract_id': contract.contractId.toString(),
              'employer_name': contract.employerName,
              'start_date': contract.startDate,
              'end_date': contract.endDate,
              'is_accepted': contract.isFullyAccepted,
              'can_accept': contract.canAccept,
              'contract_status': contract.status,
              'is_active': contract.isActive,
              'is_fully_accepted': contract.isFullyAccepted,
            });
            
            print('✅ Added user task from contract: $taskTitle (ID: $taskId)');
          }
        } catch (e) {
          print('⚠️ Error processing contract ${contract.contractId}: $e');
        }
      }
      
      print('📊 Total user tasks from contracts: ${activeTasks.length}');
      
    } catch (e) {
      print('❌ Error loading tasks from contracts: $e');
    }
  }

  String _determineTaskStatus(Contract contract) {
  if (!contract.isActive) return 'Cancelled';
  
  // Use the actual task status from the backend if available
  final backendStatus = (contract.task['status'] ?? '').toString().toLowerCase();
  if (backendStatus == 'completed') return 'Completed';
  if (backendStatus == 'awaiting_confirmation') return 'Submitted';

  if (contract.isFullyAccepted) {
    return 'In Progress'; // Don't look at the endDate here!
  }
  
  if (contract.employerAccepted && !contract.freelancerAccepted) {
    return 'Pending Acceptance';
  }
  return contract.status;
}
bool canSubmitTask(String taskId) {
    // 1. Find the task in our local list
    final task = getTaskById(taskId);
    if (task == null) {
      print('DEBUG: Task $taskId not found in activeTasks');
      return false;
    }

    // 2. Extract and normalize the status and service type
    final status = (task['status'] ?? '').toString().toLowerCase();
    final serviceType = (task['service_type'] ?? 'remote').toString().toLowerCase();
    
    // 3. Logic: 
    // - Must be a REMOTE task
    // - Status must be 'in progress', 'active', 'accepted', or 'assigned'
    bool isRemote = serviceType.contains('remote');
    bool isWorkable = status.contains('progress') || 
                      status.contains('active') || 
                      status.contains('accepted') || 
                      status.contains('assigned');
    
    // 4. Block already submitted or finished tasks
    bool isFinished = status.contains('complete') || 
                      status.contains('submitted') || 
                      status.contains('confirmation');

    print('DEBUG: Task $taskId | Status: $status | Remote: $isRemote | Allowed: ${isRemote && isWorkable && !isFinished}');

    return isRemote && isWorkable && !isFinished;
  }

  void _calculateDashboardStats() {
    totalTasks = activeTasks.length;
    
    ongoingTasks = activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('progress') || 
             status == 'in_progress' ||
             status == 'active';
    }).length;
    
    completedTasks = completedTasksList.length;

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

  // Task selection methods
  void selectTaskForSubmission(String taskId) {
    final task = getTaskById(taskId);
    if (task != null && task.isNotEmpty) {
      _selectedTaskId = taskId;
      _selectedTaskForSubmission = Map<String, dynamic>.from(task);
      notifyListeners();
    } else {
      _selectedTaskId = null;
      _selectedTaskForSubmission = null;
    }
  }

  void clearTaskSelection() {
    _selectedTaskId = null;
    _selectedTaskForSubmission = null;
    notifyListeners();
  }

  Map<String, dynamic>? get selectedTaskForSubmission => _selectedTaskForSubmission;
  String? get selectedTaskId => _selectedTaskId;

  Map<String, dynamic>? getTaskById(String taskId) {
    for (var task in activeTasks) {
      final taskIdFromTask = task['task_id']?.toString();
      final idFromTask = task['id']?.toString();
      
      if ((taskIdFromTask != null && taskIdFromTask == taskId) ||
          (idFromTask != null && idFromTask == taskId)) {
        return task;
      }
    }
    return null;
  }

 
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

  List<Map<String, dynamic>> getTasksForSubmission() {
    return activeTasks.where((task) {
      final taskId = task['task_id']?.toString() ?? task['id']?.toString();
      return taskId != null && canSubmitTask(taskId);
    }).toList();
  }

  String? getFirstTaskId() {
    final availableTasks = getTasksForSubmission();
    if (availableTasks.isNotEmpty) {
      return availableTasks.first['task_id']?.toString() ?? 
             availableTasks.first['id']?.toString();
    }
    return null;
  }

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

  Future<void> _loadProfilePictureFromAPI() async {
    try {
      final token = await _secureStorage.read(key: "auth_token");
      if (token == null) return;
      
      final response = await ApiService.getUserProfile(token);
      if (response != null && response['success'] == true) {
        final profile = response['profile'];
        if (profile != null && profile['profile_picture'] != null) {
          profilePictureUrl = profile['profile_picture'];
          await _saveUserData();
        }
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> refreshProfilePicture() async {
    await _loadProfilePictureFromAPI();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
    profilePictureUrl = prefs.getString('profilePictureUrl');
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) await prefs.setString('userName', userName!);
    if (profilePictureUrl != null) await prefs.setString('profilePictureUrl', profilePictureUrl!);
  }

  Future<void> updateUserProfile(String name, String profileUrl) async {
    userName = name;
    profilePictureUrl = profileUrl;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('profilePictureUrl');
    userName = null;
    profilePictureUrl = null;
    activeTasks.clear();
    completedTasksList.clear();
    _selectedTaskId = null;
    _selectedTaskForSubmission = null;
    notifyListeners();
  }

  Future<void> refresh(BuildContext context) async {
    await loadData(context);
  }

  bool get hasError => error != null;
  bool get hasTasks => activeTasks.isNotEmpty;
  bool get isLoaded => !isLoading && error == null;
  
  List<Map<String, dynamic>> get ongoingTaskList {
    return activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('progress') || 
             status == 'in_progress' ||
             status == 'active';
    }).toList();
  }
  
  List<Map<String, dynamic>> get pendingTaskList {
    return activeTasks.where((t) {
      final status = (t["status"]?.toString() ?? "").toLowerCase();
      return status.contains('pending') || 
             status == 'pending_acceptance';
    }).toList();
  }
  
  int get inProgress => ongoingTasks;
  int get completed => completedTasks;

  Null get activeContracts => null;

  Null get pendingTasks => null;
}