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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Task", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
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

          if (taskProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    const Text('Failed to load tasks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text(taskProvider.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: taskProvider.fetchEmployerTasks,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
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
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard('Total Tasks', totalTasks.toString(), 
                        Colors.blueAccent, Colors.lightBlueAccent, Icons.assignment),
                    _buildStatCard('Open Tasks', openTasks.toString(), 
                        Colors.green, Colors.lightGreen, Icons.lock_open),
                    _buildStatCard('In Progress', inProgressTasks.toString(), 
                        Colors.orange, Colors.orangeAccent, Icons.autorenew),
                    _buildStatCard('Completed', completedTasks.toString(), 
                        Colors.teal, Colors.tealAccent, Icons.check_circle),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Tasks', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 4),
            Text('Manage and track all your posted tasks',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
            );
          },
          icon: const Icon(Icons.dashboard, color: Colors.blueAccent),
          label: const Text("Dashboard", style: TextStyle(color: Colors.blueAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color1, Color color2, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.8), color2.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTable(List tasks, int totalTasks) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All My Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                Text('$totalTasks tasks', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                  DataColumn(label: Text('Budget', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                ],
                rows: tasks.map((task) {
                  return DataRow(cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(_getTaskTitle(task),
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_getTaskCategory(task),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    DataCell(Text(
                      _getTaskBudget(task) != null ? 
                      'Ksh ${_getTaskBudget(task)!.toStringAsFixed(2)}' : 'Not set',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_getTaskStatus(task)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(_getTaskStatus(task)),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No Tasks Yet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            const Text('Create your first task to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create Your First Task", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}