import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_submission_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SubmittedTasksScreen extends StatefulWidget {
  const SubmittedTasksScreen({super.key});

  @override
  State<SubmittedTasksScreen> createState() => _SubmittedTasksScreenState();
}

class _SubmittedTasksScreenState extends State<SubmittedTasksScreen> {
  // BLUE & WHITE COLOR SCHEME
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _lightBlue = const Color(0xFF42A5F5);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _subtitleColor = const Color(0xFF666666);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFF9800);
  
  final TextEditingController _revisionNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubmissionProvider>(context, listen: false).fetchSubmissions();
    });
  }
  
  @override
  void dispose() {
    _revisionNotesController.dispose();
    super.dispose();
  }
  
  // Helper methods
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'approved': return 'Approved';
      case 'revisions_requested': return 'Revisions Requested';
      default: return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return _primaryBlue;
      case 'under_review': return _lightBlue;
      case 'approved': return _successColor;
      case 'revisions_requested': return _warningColor;
      default: return _primaryBlue;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return Icons.upload_file;
      case 'under_review': return Icons.remove_red_eye;
      case 'approved': return Icons.check_circle;
      case 'revisions_requested': return Icons.autorenew;
      default: return Icons.description;
    }
  }
  
  // Dialogs - FIXED with proper context handling
  void _showApproveDialog(BuildContext context, Map<String, dynamic> submission) {
    final submissionId = submission['submission_id'];
    final taskTitle = submission['task_title'] ?? 'Task';
    final freelancerName = submission['freelancer_name'] ?? 'Freelancer';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this submission?'),
            const SizedBox(height: 12),
            Text('Task: $taskTitle', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Freelancer: $freelancerName'),
            const SizedBox(height: 16),
            const Text('This will:'),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('Mark contract as completed')]),
            Row(children: [Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('Make payment available')]),
            Row(children: [Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('Allow rating')]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _approveSubmissionWithContext(context, submissionId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
  
  void _showRevisionDialog(BuildContext context, Map<String, dynamic> submission) {
    final submissionId = submission['submission_id'];
    final taskTitle = submission['task_title'] ?? 'Task';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Revisions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Task: $taskTitle', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('What needs to be revised?'),
              const SizedBox(height: 8),
              TextField(
                controller: _revisionNotesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Provide clear feedback on what needs to be changed...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _revisionNotesController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _requestRevisionWithContext(context, submissionId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );
  }
  
  void _showSubmissionDetails(BuildContext context, Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submission Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Task', submission['task_title']),
              _buildDetailRow('Freelancer', submission['freelancer_name']),
              _buildDetailRow('Status', _getStatusText(submission['status'])),
              _buildDetailRow('Submitted', submission['submitted_date'] != null 
                  ? DateFormat('MMM d, yyyy').format(DateTime.parse(submission['submitted_date'])) 
                  : 'N/A'),
              
              if (submission['description'] != null) ...[
                const SizedBox(height: 12),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(submission['description']),
              ],
              
              if (submission['repo_url'] != null) _buildUrlRow('Repository', submission['repo_url']),
              if (submission['live_demo_url'] != null) _buildUrlRow('Live Demo', submission['live_demo_url']),
              if (submission['staging_url'] != null) _buildUrlRow('Staging', submission['staging_url']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: _textColor)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? 'N/A', style: TextStyle(color: _subtitleColor))),
        ],
      ),
    );
  }
  
  Widget _buildUrlRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: _textColor)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Launch URL
              },
              child: Text(
                url,
                style: TextStyle(color: _primaryBlue, decoration: TextDecoration.underline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // FIXED: Actions with proper context handling
  Future<void> _approveSubmissionWithContext(BuildContext context, int submissionId) async {
    try {
      // Close dialog first
      Navigator.pop(context);
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Approving submission...'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Get provider with correct context
      final provider = Provider.of<SubmissionProvider>(context, listen: false);
      await provider.approveSubmission(submissionId);
      
      // Refresh data
      await provider.fetchSubmissions();
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Submission approved! Contract marked as completed.'),
          backgroundColor: _successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _requestRevisionWithContext(BuildContext context, int submissionId) async {
    if (_revisionNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide revision notes')),
      );
      return;
    }
    
    try {
      final notes = _revisionNotesController.text;
      
      // Close dialog first
      Navigator.pop(context);
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sending revision request...'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Get provider with correct context
      final provider = Provider.of<SubmissionProvider>(context, listen: false);
      await provider.requestRevision(submissionId, notes);
      
      // Clear controller
      _revisionNotesController.clear();
      
      // Refresh data
      await provider.fetchSubmissions();
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Revision request sent to freelancer.'),
          backgroundColor: _primaryBlue,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Main Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Review Submissions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<SubmissionProvider>(context, listen: false).fetchSubmissions();
            },
          )
        ],
      ),
      body: Consumer<SubmissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.submissions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)),
            );
          }
          
          if (provider.errorMessage.isNotEmpty && provider.submissions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.fetchSubmissions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final submissions = provider.submissions;
          final stats = provider.getStats();
          final pendingReview = provider.pendingReview;
          
          return RefreshIndicator(
            onRefresh: () => provider.fetchSubmissions(),
            color: _primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsCards(stats),
                  const SizedBox(height: 20),
                  
                  if (pendingReview.isEmpty)
                    _buildEmptyState()
                  else
                    Column(
                      children: [
                        _buildSectionHeader('Pending Review (${pendingReview.length})'),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingReview.length,
                          itemBuilder: (context, index) {
                            return _buildSubmissionCard(context, pendingReview[index]);
                          },
                        ),
                      ],
                    ),
                  
                  if (submissions.length > pendingReview.length) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Other Submissions'),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: submissions.length - pendingReview.length,
                      itemBuilder: (context, index) {
                        final otherSubmissions = submissions.where((s) => 
                          !['submitted', 'under_review'].contains(s['status']?.toString().toLowerCase())
                        ).toList();
                        return _buildSubmissionCard(context, otherSubmissions[index]);
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // UI Components - UPDATED FOR PENDING CARD
  Widget _buildStatsCards(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total', stats['total'] ?? 0, Icons.assignment, _primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Pending', stats['pending'] ?? 0, Icons.access_time, _primaryBlue), // Changed to primary blue
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('In Review', stats['under_review'] ?? 0, Icons.remove_red_eye, _lightBlue),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // White background for all cards
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)), // Light blue border
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Light blue tint for icon background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18), // Blue icon
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor, // Dark text color
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _subtitleColor, // Grey subtitle
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubmissionCard(BuildContext context, Map<String, dynamic> submission) {
    final status = submission['status']?.toString() ?? 'submitted';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return Card(
      elevation: 2, // Added slight elevation for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _primaryBlue.withOpacity(0.3), // BLUE BORDER - Main change here
          width: 1.5, // Thicker border
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white, // White card background
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    submission['task_title'] ?? 'Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1), // Light status color background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor), // Blue status icon
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: statusColor, // Blue status text
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Freelancer & Date
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: _subtitleColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Freelancer: ${submission['freelancer_name'] ?? 'Unknown'}',
                    style: TextStyle(color: _subtitleColor),
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: _subtitleColor),
                const SizedBox(width: 8),
                Text(
                  submission['submitted_date'] != null
                      ? DateFormat('MMM d').format(DateTime.parse(submission['submitted_date']))
                      : 'N/A',
                  style: TextStyle(color: _subtitleColor, fontSize: 12),
                ),
              ],
            ),
            
            // Description preview
            if (submission['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                submission['description'].length > 100
                    ? '${submission['description'].substring(0, 100)}...'
                    : submission['description'],
                style: TextStyle(color: _subtitleColor, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons - FIXED with direct method calls
            if (['submitted', 'under_review'].contains(status.toLowerCase())) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSubmissionDetails(context, submission),
                      icon: Icon(Icons.visibility, size: 18, color: _primaryBlue),
                      label: Text('View Details', style: TextStyle(color: _primaryBlue)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primaryBlue), // Blue border on button
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(context, submission),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRevisionDialog(context, submission),
                      icon: Icon(Icons.autorenew, size: 18),
                      label: const Text('Revisions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue, // Blue button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSubmissionDetails(context, submission),
                  icon: Icon(Icons.visibility, size: 18, color: _primaryBlue),
                  label: Text('View Details', style: TextStyle(color: _primaryBlue)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryBlue), // Blue border on button
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white, // White background
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No submissions to review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submissions will appear here when freelancers submit their work',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtitleColor),
          ),
        ],
      ),
    );
  }
}