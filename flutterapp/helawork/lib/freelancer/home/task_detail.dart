import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_profile_provider.dart';
import 'package:helawork/freelancer/home/proposal_screen.dart';
import 'package:provider/provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic> task;
  final Map<String, dynamic> employer;
  final bool isTaken;
  final bool isFromContract;
  final Map<String, dynamic>? assignedFreelancer;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.task,
    required this.employer,
    required this.isTaken,
    required this.isFromContract,
    this.assignedFreelancer,
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
        Provider.of<ClientProfileProvider>(context, listen: false).fetchProfile();
      });
    }
  }

  void _navigateToProposalScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProposalsScreen(
          taskId: widget.taskId,
          task: widget.task,
          employer: widget.employer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = widget.task['service_type']?.toString() ?? 'remote';
    final isOnSite = serviceType == 'on_site';
    final locationAddress = widget.task['location_address']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ClientProfileProvider>(
        builder: (context, clientProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMainTaskCard(isOnSite, locationAddress),
                const SizedBox(height: 16),
                _buildDescriptionCard(),
                const SizedBox(height: 16),
                _buildTaskDetailsCard(),
                const SizedBox(height: 16),
                _buildClientSection(context, clientProvider),
                const SizedBox(height: 24),
                _buildActionButtons(context),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainTaskCard(bool isOnSite, String? locationAddress) {
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOnSite ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnSite ? Icons.location_on : Icons.laptop,
                    size: 14,
                    color: isOnSite ? Colors.orange[300] : Colors.blue[300],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnSite ? "📍 ON-SITE TASK" : "💻 REMOTE TASK",
                    style: TextStyle(
                      color: isOnSite ? Colors.orange[300] : Colors.blue[300],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title and Status - FIXED OVERFLOW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.task['title']?.toString() ?? 'Untitled Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isTaken ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: widget.isTaken ? Colors.red : Colors.green),
                  ),
                  child: Text(
                    widget.isTaken ? 'Taken' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isTaken ? Colors.red[300] : Colors.green[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (isOnSite && locationAddress != null && locationAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_pin, size: 14, color: Colors.orange[300]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Location: $locationAddress",
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              widget.task['description']?.toString() ?? 'No description provided',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Budget and Deadline - FIXED OVERFLOW & KSH
            if (widget.task['budget'] != null || widget.task['deadline'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F111A).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Wrap( // Changed Row to Wrap to handle small screens
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (widget.task['budget'] != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 16, color: Colors.green[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Ksh ${widget.task['budget'].toString()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    if (widget.task['deadline'] != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.orange[400]),
                          const SizedBox(width: 4),
                          Text(
                            widget.task['deadline'].toString(),
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ],
                      ),
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
      color: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task['description']?.toString() ?? 'No description provided',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsCard() {
    final serviceType = widget.task['service_type']?.toString();
    final paymentType = widget.task['payment_type']?.toString();

    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildDetailItem('Category', widget.task['category']?.toString() ?? 'N/A'),
            _buildDetailItem('Skills', widget.task['skills']?.toString() ?? widget.task['required_skills']?.toString() ?? 'Not specified'),
            _buildDetailItem('Service', serviceType == 'on_site' ? 'On-Site' : 'Remote'),
            _buildDetailItem('Payment', paymentType == 'fixed' ? 'Fixed Price' : 'Hourly'),
            _buildDetailItem('Posted', widget.task['created_at']?.toString() ?? 'Recently'),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[400]),
            ),
          ),
          Expanded( // FIXED OVERFLOW
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
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
      color: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (clientProvider.isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.orange))
            else if (clientProvider.errorMessage != null)
              Text('Error loading profile', style: TextStyle(color: Colors.red[300]))
            else
              _buildClientProfile(profileData),
          ],
        ),
      ),
    );
  }

  Widget _buildClientProfile(Map<String, dynamic> profile) {
    final displayName = profile['company_name']?.toString() ?? profile['username']?.toString() ?? 'Client';
    final email = (profile['email'] ?? profile['contact_email'])?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                radius: 20,
                child: const Icon(Icons.person, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded( // FIXED OVERFLOW
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Posted by:', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email != null)
                      Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (widget.isTaken) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[300], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This task has been assigned to another freelancer.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isTaken ? null : _navigateToProposalScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isTaken ? Colors.grey[800] : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(widget.isTaken ? 'Task Taken' : 'Apply for Task'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[700]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Back to Tasks', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}