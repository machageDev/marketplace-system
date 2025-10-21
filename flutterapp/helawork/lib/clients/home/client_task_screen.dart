import 'package:flutter/material.dart';
import 'package:helawork/clients/home/client_dashboard_screen.dart';
import 'package:helawork/clients/home/client_task_detail_screen.dart';
import 'package:helawork/clients/home/create_task_screen.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/task_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchEmployerTasks();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.blueAccent;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
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

  void _viewTaskDetails(dynamic task, BuildContext context) {
    final taskId = _getTaskId(task);
    if (taskId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            taskId: taskId, 
            task: task, 
            employer: task['employer'] ?? {}, // ✅ FIXED: Correct syntax
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot view task details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).fetchEmployerTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing tasks...')),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
        },
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Create Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildStatsGrid(totalTasks, openTasks, inProgressTasks, completedTasks),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'Your Tasks',
                  icon: Icons.assignment_outlined,
                  child: tasks.isNotEmpty
                      ? Column(
                          children: tasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildTaskCard(task),
                          )).toList(),
                        )
                      : const EmptyState(icon: Icons.assignment, message: 'No tasks yet'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------ Loading and Error States ------------------

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 16),
          Text('Loading tasks...', style: TextStyle(color: Colors.black54)),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Failed to load tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text(taskProvider.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: taskProvider.fetchEmployerTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ UI Sections ------------------

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Task Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Manage and track all your posted tasks', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard, color: Colors.white, size: 28),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        StatCard(title: 'Total Tasks', value: total.toString(), color1: Colors.blue, color2: Colors.lightBlueAccent, icon: Icons.work_outline),
        StatCard(title: 'Open Tasks', value: open.toString(), color1: Colors.green, color2: Colors.lightGreen, icon: Icons.lock_open),
        StatCard(title: 'In Progress', value: inProgress.toString(), color1: Colors.orange, color2: Colors.deepOrangeAccent, icon: Icons.autorenew),
        StatCard(title: 'Completed', value: completed.toString(), color1: Colors.teal, color2: Colors.tealAccent, icon: Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final budget = _getTaskBudget(task);
    final status = _getTaskStatus(task);
    final skills = _getTaskSkills(task);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewTaskDetails(task, context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getTaskTitle(task),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(_getTaskDescription(task), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              // Category, Budget, Skills
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildDetailChip(Icons.category, _getTaskCategory(task)),
                  if (status.toLowerCase() == 'open')
                    _buildDetailChip(Icons.attach_money, budget != null ? 'Ksh ${budget.toStringAsFixed(0)}' : 'Budget: Not specified'),
                  if (status.toLowerCase() == 'open')
                    _buildDetailChip(Icons.code, skills.isNotEmpty ? skills : 'Skills: Not specified'),
                  if (status.toLowerCase() != 'open') ...[
                    if (budget != null) _buildDetailChip(Icons.attach_money, 'Ksh ${budget.toStringAsFixed(0)}'),
                    _buildDetailChip(Icons.code, skills.isNotEmpty ? skills : 'Skills: Not specified'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 11))]),
    );
  }
}

// ------------------ Reusable Widgets ------------------

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color1;
  final Color color2;
  final IconData icon;
  const StatCard({super.key, required this.title, required this.value, required this.color1, required this.color2, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color1, color2]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  const SectionCard({super.key, required this.title, required this.child, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: Colors.blueAccent), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent))]),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 50, color: Colors.grey.shade400), const SizedBox(height: 8), Text(message, style: TextStyle(color: Colors.grey.shade600))]));
  }
}