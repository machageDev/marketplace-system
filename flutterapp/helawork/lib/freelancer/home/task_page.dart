import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:helawork/freelancer/home/task_detail.dart';
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
  
  // For Recommended Jobs
  bool _loadingRecommendedJobs = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _recommendedJobs = [];
  String? _userToken; // You'll need to get this from somewhere
  
  // Add your baseUrl here
  final String baseUrl = "YOUR_BASE_URL_HERE"; // Replace with your actual base URL

  // HELPER METHOD: Check if task is taken
  bool _isTaskTaken(Map<String, dynamic> task) {
    return task['assigned_user'] != null ||
           (task['status'] != null && task['status'] != 'open');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch all tasks
    Future.microtask(() =>
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(context));
    
    // Listen to search controller changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to get token when dependencies change
    _getTokenAndLoadRecommendedJobs();
  }

  Future<void> _getTokenAndLoadRecommendedJobs() async {
    // Try to get token from wherever you store it
    // This could be from SharedPreferences, AuthProvider, etc.
    // Example: final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // _userToken = authProvider.token;
    
    // For now, you need to implement how to get the token
    // Once you have the token, load recommended jobs
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

  // Your API function
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
    
    // Filter tasks when provider data changes or search query changes
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
            Tab(
              icon: Icon(Icons.list),
              text: 'All Tasks',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Recommended',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar - Shared between both tabs
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
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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
          
          // Show search results count if searching
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tabController.index == 0
                      ? 'Search results: ${_filteredTasks.length}'
                      : 'Search results: ${_filteredRecommendedJobs.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: const Text('Clear Search'),
                  ),
                ],
              ),
            ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Tasks
                _buildAllTasksTab(taskProvider),
                
                // Tab 2: Recommended Jobs
                _buildRecommendedJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: All Tasks
  Widget _buildAllTasksTab(TaskProvider taskProvider) {
    return RefreshIndicator(
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
    );
  }

  // Tab 2: Recommended Jobs
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
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error Loading Recommendations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadRecommendedJobs();
                        },
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
                          Icon(
                            Icons.star_border,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No recommended jobs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Complete your profile to get personalized recommendations',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              _loadRecommendedJobs();
                            },
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

  // Reusable Task Card Widget
  Widget _buildTaskCard(Map<String, dynamic> task, {bool isRecommended = false}) {
    final employer = task['employer'] ?? {};
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, recommendation badge, and status
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
                              Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isRecommended) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Untitled Task',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTaskStatus(task),
              ],
            ),
            const SizedBox(height: 8),
            
            // Task Description
            Text(
              task['description'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Client Information
            _buildClientSection(employer),
            
            const SizedBox(height: 12),
            
            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Calculate if task is taken
                  final bool isTaken = _isTaskTaken(task);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        taskId: task['task_id'] ?? task['id'] ?? 0,
                        task: task,
                        employer: employer,
                        isTaken: isTaken, // 👈 PASS TAKEN STATE
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(isRecommended ? 'View Job Details' : 'View Task Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for when no search results found
  Widget _buildNoResults(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No $type found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try different keywords',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
            },
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
                Text(
                  'Posted by:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (employer['contact_email'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.email, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        employer['contact_email'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
                      Text(
                        employer['phone'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          IconButton(
            onPressed: () {
              _showClientProfile(context, employer);
            },
            icon: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
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
        child: Text(
          displayName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  Widget _buildTaskStatus(Map<String, dynamic> task) {
    final bool isTaken = _isTaskTaken(task);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isTaken) {
      statusColor = Colors.red;
      statusText = 'Taken';
      statusIcon = Icons.lock;
    } else {
      statusColor = Colors.green;
      statusText = 'Open';
      statusIcon = Icons.lock_open;
    }

    return Container(
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
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (email != null) ...[
                _buildProfileItem(Icons.email, 'Email', email),
                const SizedBox(height: 8),
              ],
              if (phone != null) ...[
                _buildProfileItem(Icons.phone, 'Phone', phone),
                const SizedBox(height: 8),
              ],
              _buildProfileItem(Icons.info, 'Bio', bio),
              const SizedBox(height: 8),
              if (companyName != null && username != null) ...[
                _buildProfileItem(Icons.person, 'Username', username),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}