import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_dashbaord_scren.dart';
import 'package:helawork/client/home/client_task_detail_screen.dart';
import 'package:helawork/client/home/create_task_screen.dart';
import 'package:helawork/client/provider/client_task_provider.dart';
import 'package:provider/provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _secondaryColor = const Color(0xFF42A5F5);
  final Color _backgroundColor = const Color(0xFFF8FAFD);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _subtitleColor = const Color(0xFF666666);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFF9800);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _infoColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchEmployerTasks(context);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return _successColor;
      case 'in_progress':
      case 'in progress':
        return _warningColor;
      case 'completed':
        return _primaryColor;
      case 'cancelled':
        return _dangerColor;
      case 'pending':
        return _infoColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.lock_open;
      case 'in_progress':
      case 'in progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String _getTaskTitle(dynamic task) =>
      (task is Map<String, dynamic>) ? (task['title'] ?? 'Untitled Task') : 'Untitled Task';

  String _getTaskCategory(dynamic task) =>
      (task is Map<String, dynamic>)
          ? (task['category'] ?? task['category_display'] ?? 'Uncategorized')
          : 'Uncategorized';

  double? _getTaskBudget(dynamic task) {
    if (task is Map<String, dynamic>) {
      final budget = task['budget'];
      if (budget != null) {
        if (budget is double) return budget;
        if (budget is int) return budget.toDouble();
        if (budget is String) return double.tryParse(budget);
      }
    }
    return null;
  }

  String _getTaskStatus(dynamic task) =>
      (task is Map<String, dynamic>) ? (task['status'] ?? 'open') : 'open';

  String _getTaskDescription(dynamic task) =>
      (task is Map<String, dynamic>) ? (task['description'] ?? 'No description') : 'No description';

  String _getTaskSkills(dynamic task) =>
      (task is Map<String, dynamic>) ? (task['required_skills'] ?? task['skills'] ?? 'Not specified') : 'Not specified';

  int _getTaskId(dynamic task) =>
      (task is Map<String, dynamic>) ? (task['task_id'] ?? task['id'] ?? 0) : 0;

  // FIXED: Improved service type detection
  String _getServiceType(dynamic task) {
    if (task is! Map<String, dynamic>) return 'remote';
    
    // Debug: Print all task data to understand structure
    print('\n=== TASK SCREEN: Checking task data ===');
    print('Task title: ${task['title']}');
    print('All task keys: ${task.keys.toList()}');
    
    // Check service_type first (from formattedTasks)
    final serviceType = task['service_type']?.toString().toLowerCase();
    print('Found service_type: "$serviceType"');
    
    // Check display_type (from formattedTasks)
    final displayType = task['display_type']?.toString().toLowerCase();
    print('Found display_type: "$displayType"');
    
    // Check location_address
    final location = task['location_address']?.toString();
    print('Found location_address: "$location"');
    
    // Priority 1: Check if service_type is explicitly 'on_site'
    if (serviceType == 'on_site') {
      print('Result: on_site (from service_type)');
      return 'on_site';
    }
    
    // Priority 2: Check display_type for 'on-site' indicators
    if (displayType != null && 
        (displayType.contains('on') || displayType.contains('site'))) {
      print('Result: on_site (from display_type: $displayType)');
      return 'on_site';
    }
    
    // Priority 3: Check if location_address suggests on-site
    if (location != null && 
        location.isNotEmpty && 
        location != 'null' && 
        location != 'No location provided' && 
        location != 'Remote Task') {
      print('Result: on_site (from location_address: $location)');
      return 'on_site';
    }
    
    // Default to remote
    print('Result: remote (default)');
    return serviceType ?? 'remote';
  }


  void _viewTaskDetails(dynamic task, BuildContext context) {
    final taskId = _getTaskId(task);
    if (taskId > 0) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TaskDetailScreen(
            taskId: taskId,
            task: task,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot view task details'),
          backgroundColor: _dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Delete task function
  Future<void> _deleteTask(BuildContext context, dynamic task) async {
    final taskId = _getTaskId(task);
    final taskTitle = _getTaskTitle(task);
    
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Delete Task'),
          ],
        ),
        content: Text('Are you sure you want to delete "$taskTitle"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await taskProvider.deleteTask(context, taskId);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$taskTitle" has been deleted'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the task list
        taskProvider.fetchEmployerTasks(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: _dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('My Tasks',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20)),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 22),
            ),
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).fetchEmployerTasks(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Refreshing tasks...'),
                  backgroundColor: _primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const CreateTaskScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        },
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Create Task",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primaryColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) return _buildLoadingState();
          if (taskProvider.errorMessage.isNotEmpty) return _buildErrorState(taskProvider);

          final tasks = taskProvider.tasks;
          final totalTasks = tasks.length;
          final openTasks = tasks.where((task) => _getTaskStatus(task) == 'open').length;
          final inProgressTasks = tasks.where((task) => _getTaskStatus(task) == 'in_progress' || _getTaskStatus(task) == 'in progress').length;
          final completedTasks = tasks.where((task) => _getTaskStatus(task) == 'completed').length;

          // Debug: Check what tasks we're getting
          print('\n=== TASK SCREEN: UI BUILD ===');
          print('Number of tasks: $totalTasks');
          for (var i = 0; i < tasks.length; i++) {
            final task = tasks[i];
            final serviceType = _getServiceType(task);
            print('Task [$i]: ${task['title']}');
            print('  service_type from UI: $serviceType');
            print('  task object keys: ${task is Map ? task.keys.toList() : "Not a map"}');
          }

          return RefreshIndicator(
            color: _primaryColor,
            backgroundColor: _backgroundColor,
            onRefresh: () async {
              await taskProvider.fetchEmployerTasks(context);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: 20),
                  _buildStatsGrid(totalTasks, openTasks, inProgressTasks, completedTasks),
                  const SizedBox(height: 24),
                  _buildTasksSection(tasks),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------ Loading and Error States ------------------

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: _primaryColor,
              backgroundColor: _primaryColor.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 20),
          Text('Loading your tasks...',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColor)),
          const SizedBox(height: 8),
          Text('Please wait a moment',
              style: TextStyle(fontSize: 14, color: _subtitleColor)),
        ],
      ),
    );
  }

  Widget _buildErrorState(TaskProvider taskProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _dangerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 64, color: _dangerColor),
            ),
            const SizedBox(height: 24),
            Text('Oops! Something went wrong',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _dangerColor)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(taskProvider.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: _subtitleColor)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:()=> taskProvider.fetchEmployerTasks(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ UI Sections ------------------

  Widget _buildWelcomeHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Dashboard',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Manage all your posted tasks in one place',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const ClientDashboardScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int total, int open, int inProgress, int completed) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildSimpleStatCard('Total', total.toString(), Icons.assignment, _primaryColor),
        _buildSimpleStatCard('Open', open.toString(), Icons.lock_open, _successColor),
        _buildSimpleStatCard('In Progress', inProgress.toString(), Icons.autorenew, _warningColor),
        _buildSimpleStatCard('Completed', completed.toString(), Icons.check_circle, _infoColor),
      ],
    );
  }

  Widget _buildSimpleStatCard(String title, String value, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Optional: Add filter functionality
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: _subtitleColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection(List<dynamic> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_turned_in,
                      color: _primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('All Tasks',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textColor)),
                ),
                if (tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${tasks.length} tasks',
                        style: TextStyle(
                            fontSize: 13,
                            color: _primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            tasks.isNotEmpty
                ? ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasks[index]);
                    },
                  )
                : _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final budget = _getTaskBudget(task);
    final status = _getTaskStatus(task);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final serviceType = _getServiceType(task);
    final isOnSite = serviceType == 'on_site';
    final isTaskCompleted = status.toLowerCase() == 'completed';

    // Debug for this specific task
    print('\n=== BUILDING TASK CARD ===');
    print('Task: ${_getTaskTitle(task)}');
    print('Service Type: $serviceType');
    print('Is On-Site: $isOnSite');

    return GestureDetector(
      onTap: () => _viewTaskDetails(task, context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getTaskTitle(task),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Service Type Indicator (FIXED)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnSite ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnSite ? Icons.location_on : Icons.laptop,
                        color: isOnSite ? Colors.orange[700] : Colors.blue[700],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnSite ? 'On-Site Task' : 'Remote Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOnSite ? Colors.orange[800] : Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  _getTaskDescription(task),
                  style: TextStyle(
                      fontSize: 13,
                      color: _subtitleColor,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Details row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (budget != null)
                      _buildDetailChip(
                          Icons.attach_money,
                          'Ksh ${budget.toStringAsFixed(0)}',
                          _primaryColor),
                    _buildDetailChip(Icons.category,
                        _getTaskCategory(task), _infoColor),
                    if (_getTaskSkills(task).isNotEmpty &&
                        _getTaskSkills(task) != 'Not specified')
                      _buildDetailChip(
                          Icons.code,
                          _getTaskSkills(task).length > 15
                              ? '${_getTaskSkills(task).substring(0, 15)}...'
                              : _getTaskSkills(task),
                          _warningColor),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Action buttons row (View Details + Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View Details button
                    GestureDetector(
                      onTap: () => _viewTaskDetails(task, context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Details',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                size: 10, color: _primaryColor),
                          ],
                        ),
                      ),
                    ),
                    
                    // Delete button (only show for non-completed tasks)
                    if (!isTaskCompleted)
                      GestureDetector(
                        onTap: () => _deleteTask(context, task),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _dangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 14, color: _dangerColor),
                              const SizedBox(width: 6),
                              Text('Delete',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _dangerColor,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    
                    // Show message for completed tasks
                    if (isTaskCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_add,
                size: 50, color: _primaryColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text('No tasks yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textColor)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Start by creating your first task to get freelancers working for you',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: _subtitleColor,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateTaskScreen()),
              );
            },
            icon: const Icon(Icons.add_task, size: 18),
            label: const Text('Create First Task',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}