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
      backgroundColor: const Color(0xFF0F111A), // Dark background from login
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text like login screen
          ),
        ),
        backgroundColor: const Color(0xFF1E1E2C), // Input field color from login
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white), // White icons
      ),
      body: Consumer<ClientProfileProvider>(
        builder: (context, clientProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Task Card
                _buildMainTaskCard(),
                const SizedBox(height: 16),

                // Description Section
                _buildDescriptionCard(),
                const SizedBox(height: 16),

                // Task Details Section
                _buildTaskDetailsCard(),
                const SizedBox(height: 16),

                // Client Information
                _buildClientSection(context, clientProvider),
                
                // Action Buttons
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainTaskCard() {
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C), // Input field color from login
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.task['title'] ?? 'Untitled Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white, // White text
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2), // Darker green background
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[300], // Lighter green text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description preview
            Text(
              widget.task['description'] ?? 'No description provided',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[400], // Lighter grey for better contrast
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            // Budget and Deadline
            if (widget.task['budget'] != null || widget.task['deadline'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F111A).withOpacity(0.5), // Darker background
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (widget.task['budget'] != null) ...[
                      Icon(Icons.attach_money, size: 16, color: Colors.green[400]), // Green money icon
                      const SizedBox(width: 4),
                      Text(
                        '\$${widget.task['budget']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // White text
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (widget.task['deadline'] != null) ...[
                      Icon(Icons.calendar_today, size: 16, color: Colors.orange[400]), // Orange calendar icon
                      const SizedBox(width: 4),
                      Text(
                        widget.task['deadline'],
                        style: TextStyle(
                          color: Colors.grey[300], // Lighter grey
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C), // Input field color from login
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task['description'] ?? 'No description provided',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[300], // Lighter grey for better readability
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsCard() {
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C), // Input field color from login
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                if (widget.task['category'] != null)
                  _buildDetailItem('Category', widget.task['category']),
                if (widget.task['skills'] != null)
                  _buildDetailItem('Required Skills', widget.task['skills']),
                if (widget.task['created_at'] != null)
                  _buildDetailItem('Posted On', widget.task['created_at']),
              ],
            ),
          ],
        ),
      ),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[400], // Medium grey for labels
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white, // White text for values
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(BuildContext context, ClientProfileProvider clientProvider) {
    final profileData = clientProvider.profile ?? widget.employer;
    
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C), // Input field color from login
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
              ),
            ),
            const SizedBox(height: 12),
            
            if (clientProvider.isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.orange)), // Orange loading like login
            
            if (clientProvider.errorMessage != null)
              Text('Error loading client profile', 
                   style: TextStyle(color: Colors.red[300])), // Lighter red for dark theme

            if (!clientProvider.isLoading)
              _buildClientProfile(profileData),
          ],
        ),
      ),
    );
  }

  Widget _buildClientProfile(Map<String, dynamic> profile) {
    final companyName = profile['company_name'];
    final username = profile['username'];
    final email = profile['email'] ?? profile['contact_email'];
    final phone = profile['phone'];
    
    String displayName = companyName ?? username ?? 'Client';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A).withOpacity(0.5), // Darker background
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Client header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2), // Orange accent like login
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.orange, // Orange icon like login
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posted by:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400], // Medium grey
                      ),
                    ),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white, // White text
                      ),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400], // Medium grey
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Additional client info
          if (phone != null)
            _buildClientDetailRow('Phone', phone),
          if (profile['bio'] != null)
            _buildClientDetailRow('Bio', profile['bio']!),
        ],
      ),
    );
  }

  Widget _buildClientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400], // Medium grey
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[300], // Lighter grey
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isApproved = widget.task['is_approved'] ?? false;
    final isAssigned = widget.task['assigned_user'] != null;

    return Column(
      children: [
        if (!isAssigned && !isApproved)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Apply for task functionality coming soon!'),
                    backgroundColor: Colors.orange, // Orange like login
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Orange button like login
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply for Task',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: Colors.grey[600]!), // Darker border for dark theme
            ),
            child: Text(
              'Back to Tasks',
              style: TextStyle(
                color: Colors.grey[300], // Light grey text
              ),
            ),
          ),
        ),
      ],
    );
  }
}