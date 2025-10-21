// In TaskDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/client_profile_provider.dart';
import 'package:provider/provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic> task;
  final Map<String, dynamic> employer;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.task,
    required this.employer,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadEmployerProfile();
  }

  void _loadEmployerProfile() {
    final employerId = widget.employer['id'];
    if (employerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ClientProfileProvider>(context, listen: false)
            .fetchProfile(employerId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background like TaskPage
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Theme.of(context).colorScheme.primary, // Same as TaskPage
        elevation: 0,
      ),
      body: Consumer<ClientProfileProvider>(
        builder: (context, clientProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Task details section
                _buildTaskDetails(),

                // Client Section with API data
                _buildClientSection(context, clientProvider),
                
                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskDetails() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Text(
              widget.task['title'] ?? 'Untitled Task',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Task Status
            _buildTaskStatus(widget.task),
            const SizedBox(height: 20),

            // Task Description
            _buildDetailSectionText(
              'Description',
              widget.task['description'] ?? 'No description provided',
            ),
            const SizedBox(height: 20),

            // Task Details
            _buildTaskDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatus(Map<String, dynamic> task) {
    final isApproved = task['is_approved'] ?? false;
    final isAssigned = task['assigned_user'] != null;
    
    Color statusColor = Colors.orange;
    String statusText = 'Available';
    String statusDescription = 'This task is available for application';

    if (isAssigned && !isApproved) {
      statusColor = Colors.blue;
      statusText = 'Assigned';
      statusDescription = 'This task has been assigned to a freelancer';
    } else if (isApproved) {
      statusColor = Colors.green;
      statusText = 'Approved';
      statusDescription = 'This task has been completed and approved';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionText(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16, 
            height: 1.5, 
            color: Colors.grey[700]
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.task['budget'] != null)
          _buildDetailItem('Budget', '\$${widget.task['budget']}'),
        if (widget.task['deadline'] != null)
          _buildDetailItem('Deadline', widget.task['deadline']),
        if (widget.task['category'] != null)
          _buildDetailItem('Category', widget.task['category']),
        if (widget.task['skills'] != null)
          _buildDetailItem('Required Skills', widget.task['skills']),
        if (widget.task['created_at'] != null)
          _buildDetailItem('Posted On', widget.task['created_at']),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  Widget _buildClientSection(BuildContext context, ClientProfileProvider clientProvider) {
    // Use API data if available, otherwise fallback to task data
    final profileData = clientProvider.profile ?? widget.employer;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (clientProvider.isLoading)
              const CircularProgressIndicator(),
            
            if (clientProvider.errorMessage != null)
              Text('Error: ${clientProvider.errorMessage}', style: const TextStyle(color: Colors.red)),

            if (!clientProvider.isLoading && clientProvider.profile != null)
              _buildClientProfile(profileData),
          ],
        ),
      ),
    );
  }

  Widget _buildClientProfile(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildProfileDetail('Company', profile['company_name'] ?? 'No company'),
              _buildProfileDetail('Email', profile['email'] ?? 'No email'),
              _buildProfileDetail('Bio', profile['bio'] ?? 'No bio'),
              // Add more profile fields from API
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isApproved = widget.task['is_approved'] ?? false;
    final isAssigned = widget.task['assigned_user'] != null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!isAssigned && !isApproved) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement apply for task functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apply for task functionality coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Apply for Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Tasks'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}