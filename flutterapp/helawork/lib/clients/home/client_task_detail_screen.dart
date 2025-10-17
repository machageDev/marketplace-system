import 'package:flutter/material.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  final dynamic task;

  const TaskDetailScreen({super.key, required this.taskId, required this.task});

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

  @override
  Widget build(BuildContext context) {
    final title = task['title'] ?? 'Untitled Task';
    final description = task['description'] ?? 'No description';
    final category = task['category'] ?? task['category_display'] ?? 'Uncategorized';
    final skills = task['required_skills'] ?? task['skills'] ?? 'Not specified';
    final budget = task['budget'];
    final status = task['status'] ?? 'open';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Task Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title Card
            Card(
              elevation: 3,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (budget != null)
                          Chip(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            label: Text('Ksh ${budget.toString()}', style: const TextStyle(color: Colors.blueAccent)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Skills Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category & Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          backgroundColor: Colors.grey.shade100,
                          label: Text(category, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                        Chip(
                          backgroundColor: Colors.grey.shade100,
                          label: Text(skills, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Extra Details (Add more if needed)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text(taskId.toString(), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
