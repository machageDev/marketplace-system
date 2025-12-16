import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:helawork/freelancer/home/task_detail.dart';
import 'package:helawork/freelancer/home/submitting_task.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:provider/provider.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredTasks = [];
  List<Map<String, dynamic>> _filteredRecommendedJobs = [];
  
  bool _loadingRecommendedJobs = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _recommendedJobs = [];
  String? _userToken;
  
  final String baseUrl = "YOUR_BASE_URL_HERE";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch tasks
    Future.microtask(() =>
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(context));
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getTokenAndLoadRecommendedJobs();
  }

  Future<void> _getTokenAndLoadRecommendedJobs() async {
    // Implement token retrieval
    if (_userToken != null) {
      await _loadRecommendedJobs();
    }
  }

  Future<void> _loadRecommendedJobs() async {
    if (_userToken == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Authentication required';
        _loadingRecommendedJobs = false;
      });
      return;
    }

    setState(() {
      _loadingRecommendedJobs = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final results = await fetchRecommendedJobs(_userToken!);
      
      setState(() {
        _recommendedJobs = results;
        _loadingRecommendedJobs = false;
        _filteredRecommendedJobs = _filterTasks(
          _recommendedJobs.cast<Map<String, dynamic>>(), 
          _searchQuery
        );
      });
    } catch (error) {
      setState(() {
        _loadingRecommendedJobs = false;
        _hasError = true;
        _errorMessage = 'Failed to load recommended jobs: $error';
      });
    }
  }

  // ✅ UPDATED: Use backend fields to check if task is taken
  bool _isTaskTaken(Map<String, dynamic> task) {
    // Get values from task (provided by backend)
    final isTaken = task['is_taken'] == true;
    final hasContract = task['has_contract'] == true;
    final overallStatus = (task['overall_status'] ?? '').toString().toLowerCase();
    final assignedFreelancer = task['assigned_freelancer'];
    final assignedUser = task['assigned_user'];
    
    // Debug
    print('\n🔍 Checking if task "${task['title']}" is taken:');
    print('  is_taken: $isTaken');
    print('  has_contract: $hasContract');
    print('  overall_status: $overallStatus');
    print('  assigned_freelancer: ${assignedFreelancer != null ? "Exists" : "None"}');
    print('  assigned_user: ${assignedUser != null ? "Exists" : "None"}');
    
    // Task is taken if ANY of these are true
    final bool taken = isTaken || 
                       hasContract || 
                       overallStatus == 'taken' || 
                       assignedFreelancer != null ||
                       assignedUser != null;
    
    print('  Result: ${taken ? "✅ TAKEN" : "❌ OPEN"}');
    return taken;
  }

  bool _isTaskAssignedToMe(Map<String, dynamic> task) {
    final status = (task['status'] ?? '').toString().toLowerCase();
    return status == 'in_progress' || status == 'assigned';
  }

  // ✅ UPDATED: Get freelancer from task data (provided by backend)
  Map<String, dynamic>? _getAssignedFreelancer(Map<String, dynamic> task) {
    // First try assigned_freelancer (from backend)
    final assignedFreelancer = task['assigned_freelancer'];
    if (assignedFreelancer is Map<String, dynamic>) {
      print('✅ Using assigned_freelancer from task API');
      return assignedFreelancer;
    }
    
    // Then try assigned_user
    final assignedUser = task['assigned_user'];
    if (assignedUser is Map<String, dynamic>) {
      return assignedUser;
    }
    
    // Fallback: check if we can get name from employer
    final employer = task['employer'] ?? {};
    if (employer['username'] != null) {
      return {'name': employer['username']};
    }
    
    return null;
  }

  String _getFreelancerName(Map<String, dynamic>? freelancer) {
    if (freelancer == null) return 'Another freelancer';
    
    return freelancer['name']?.toString() ?? 
           freelancer['username']?.toString() ?? 
           freelancer['email']?.toString().split('@').first ?? 
           'Another freelancer';
  }

  Future<List<dynamic>> fetchRecommendedJobs(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/freelancer/recommended-jobs/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == true) {
        return data["recommended"];
      }
    }
    return [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTasks(List<Map<String, dynamic>> allTasks, String query) {
    if (query.isEmpty) return allTasks;
    
    return allTasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();
      final description = (task['description'] ?? '').toString().toLowerCase();
      final employer = task['employer'] ?? {};
      final employerName = (employer['company_name'] ?? employer['username'] ?? '').toString().toLowerCase();
      final searchLower = query.toLowerCase();
      
      return title.contains(searchLower) ||
             description.contains(searchLower) ||
             employerName.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    if (taskProvider.tasks.isNotEmpty) {
      _filteredTasks = _filterTasks(taskProvider.tasks, _searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Jobs'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Tasks'),
            Tab(icon: Icon(Icons.star), text: 'Recommended'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _tabController.index == 0 
                    ? 'Search all tasks...' 
                    : 'Search recommended jobs...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () { _searchController.clear(); },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ✅ SIMPLIFIED: No need for ContractProvider
                RefreshIndicator(
                  onRefresh: () async {
                    await Provider.of<TaskProvider>(context, listen: false).fetchTasks(context);
                  },
                  child: taskProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : taskProvider.tasks.isEmpty
                          ? Center(
                              child: Text(
                                taskProvider.errorMessage.isNotEmpty
                                    ? taskProvider.errorMessage
                                    : 'No tasks available',
                                style: const TextStyle(fontSize: 18),
                              ),
                            )
                          : _filteredTasks.isEmpty && _searchQuery.isNotEmpty
                              ? _buildNoResults('tasks')
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredTasks.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskCard(_filteredTasks[index]);
                                  },
                                ),
                ),
                _buildRecommendedJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, {bool isRecommended = false}) {
    final employer = task['employer'] ?? {};
    final bool isAssignedToMe = _isTaskAssignedToMe(task);
    final bool isTaken = _isTaskTaken(task);
    final assignedFreelancer = _getAssignedFreelancer(task);
    final freelancerName = _getFreelancerName(assignedFreelancer);
    
    // ✅ UPDATED Debug print
    print('\n🎯 Building Task Card: ${task['title']}');
    print('   Task ID: ${task['id']}');
    print('   Backend Fields:');
    print('     - is_taken: ${task['is_taken']}');
    print('     - has_contract: ${task['has_contract']}');
    print('     - overall_status: ${task['overall_status']}');
    print('   Calculated:');
    print('     - Final Is Taken: $isTaken');
    print('     - Freelancer Name: $freelancerName');
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.amber[800]),
                              const SizedBox(width: 4),
                              Text('Recommended',
                                style: TextStyle(fontSize: 12, color: Colors.amber[800], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (isRecommended) const SizedBox(width: 8),
                      Expanded(
                        child: Text(task['title'] ?? 'Untitled Task',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTaskStatus(task, isTaken, isAssignedToMe, freelancerName),
              ],
            ),
            
            // SHOW WHO IT'S ASSIGNED TO (if taken by someone else)
            if (isTaken && !isAssignedToMe)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_off, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Taken by: $freelancerName',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Task Description
            Text(task['description'] ?? '',
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            // Client Information
            _buildClientSection(employer),
            
            const SizedBox(height: 12),
            
            // BUTTON ROW
            Row(
              children: [
                // View Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(
                            taskId: task['task_id'] ?? task['id'] ?? 0,
                            task: task,
                            employer: employer,
                            isTaken: isTaken,
                            isFromContract: false,
                            assignedFreelancer: assignedFreelancer,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // SUBMIT TASK BUTTON
                if (isAssignedToMe)
                  ElevatedButton.icon(
                    onPressed: () {
                      final taskId = task['task_id']?.toString() ?? task['id']?.toString() ?? '';
                      if (taskId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitTaskScreen(taskId: taskId),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot submit: Invalid task ID')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadRecommendedJobs,
      child: _loadingRecommendedJobs
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                      const SizedBox(height: 20),
                      Text('Error Loading Recommendations',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(_errorMessage, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadRecommendedJobs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _recommendedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 20),
                          Text('No recommended jobs',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 10),
                          Text('Complete your profile to get personalized recommendations',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadRecommendedJobs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Recommendations'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredRecommendedJobs.isEmpty && _searchQuery.isNotEmpty
                      ? _buildNoResults('recommended jobs')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecommendedJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredRecommendedJobs[index];
                            return _buildTaskCard(job, isRecommended: true);
                          },
                        ),
    );
  }

  Widget _buildNoResults(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No $type found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text('Try different keywords',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { _searchController.clear(); },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatus(Map<String, dynamic> task, bool isTaken, bool isAssignedToMe, String freelancerName) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isAssignedToMe) {
      statusColor = Colors.blue;
      statusText = 'Assigned to you';
      statusIcon = Icons.assignment_ind;
    } else if (isTaken) {
      statusColor = Colors.red;
      statusText = 'Taken';
      statusIcon = Icons.lock;
    } else {
      statusColor = Colors.green;
      statusText = 'Open';
      statusIcon = Icons.lock_open;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(statusText,
                style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        // Show freelancer name for taken tasks
        if (isTaken && !isAssignedToMe)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(freelancerName,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }

  Widget _buildClientSection(Map<String, dynamic> employer) {
    final companyName = employer['company_name'];
    final username = employer['username'];
    final profilePic = employer['profile_picture'];
    String displayName = companyName ?? username ?? 'Client';
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildClientAvatar(profilePic, displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Posted by:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (employer['contact_email'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.email, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(employer['contact_email']!.toString(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                if (employer['phone'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(employer['phone']!.toString(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () { _showClientProfile(context, employer); },
            icon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
            tooltip: 'View Client Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildClientAvatar(String? profilePic, String displayName) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(profilePic),
        radius: 20,
      );
    } else {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        radius: 20,
        child: Text(displayName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }
  }

  void _showClientProfile(BuildContext context, Map<String, dynamic> employer) {
    final companyName = employer['company_name'];
    final username = employer['username'];
    final profilePic = employer['profile_picture'];
    final email = employer['contact_email'];
    final phone = employer['phone'];
    final bio = employer['bio'] ?? 'No bio available';
    String displayName = companyName ?? username ?? 'Client';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildClientAvatar(profilePic, displayName),
            const SizedBox(width: 12),
            Expanded(child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (email != null) ...[
                _buildProfileItem(Icons.email, 'Email', email.toString()),
                const SizedBox(height: 8),
              ],
              if (phone != null) ...[
                _buildProfileItem(Icons.phone, 'Phone', phone.toString()),
                const SizedBox(height: 8),
              ],
              _buildProfileItem(Icons.info, 'Bio', bio),
              const SizedBox(height: 8),
              if (companyName != null && username != null) ...[
                _buildProfileItem(Icons.person, 'Username', username.toString()),
              ],
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

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}