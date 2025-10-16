import 'package:flutter/material.dart';
import 'package:helawork/clients/home/client_dashboard_screen.dart';
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
        return Colors.blue;
      case 'completed':
        return Colors.cyan;
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






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).fetchEmployerTasks();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Task"),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(taskProvider.errorMessage, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: taskProvider.fetchEmployerTasks,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final tasks = taskProvider.tasks;
          if (tasks.isEmpty) {
            return _buildEmptyState(context);
          }

          final totalTasks = tasks.length;
          final openTasks =
              tasks.where((task) => _getTaskStatus(task) == 'open').length;
          final inProgressTasks = tasks
              .where((task) =>
                  _getTaskStatus(task) == 'in_progress' ||
                  _getTaskStatus(task) == 'in progress')
              .length;
          final completedTasks =
              tasks.where((task) => _getTaskStatus(task) == 'completed').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard('Total Tasks', totalTasks.toString(), Colors.blue),
                    _buildStatCard('Open', openTasks.toString(), Colors.green),
                    _buildStatCard('In Progress', inProgressTasks.toString(), Colors.cyan),
                    _buildStatCard('Completed', completedTasks.toString(), Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTaskTable(tasks, totalTasks),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Manage and track all your posted tasks',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
            );
          },
          icon: const Icon(Icons.dashboard),
          label: const Text("Dashboard"),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTable(List tasks, int totalTasks) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All My Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('$totalTasks tasks', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Budget')),
                DataColumn(label: Text('Status')),
              ],
              rows: tasks.map((task) {
                return DataRow(cells: [
                  DataCell(Text(_getTaskTitle(task))),
                  DataCell(Text(_getTaskCategory(task))),
                  DataCell(Text(_getTaskBudget(task)?.toStringAsFixed(2) ?? 'N/A')),
                  DataCell(
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_getTaskStatus(task)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(_getTaskStatus(task)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No Tasks Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Create your first task to get started!'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Task"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
