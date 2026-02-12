import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/employer_profile_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:helawork/freelancer/home/task_detail.dart';
import 'package:helawork/freelancer/home/submitting_task.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  bool _loadingRecommendedJobs = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _recommendedJobs = [];
  String? _userToken;
  
  final String baseUrl = 'https://marketplace-system-1.onrender.com';
  //final String baseUrl = 'http://192.168.100.188:8000';
  bool _tasksLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_tasksLoaded) {
      _tasksLoaded = true;
      _loadTasks();
    }
    
    _getTokenAndLoadRecommendedJobs();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  Future<void> _loadTasks() async {
    try {
      await Provider.of<TaskProvider>(context, listen: false).fetchTasks(context);
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> _getTokenAndLoadRecommendedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    _userToken = prefs.getString('user_token');
    
    if (_userToken != null) {
      await _loadRecommendedJobs();
    } else {
      setState(() {
        _loadingRecommendedJobs = false;
        _hasError = true;
        _errorMessage = 'Please login to see recommended jobs';
      });
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
      final results = await _fetchRecommendedJobs(_userToken!);
      setState(() {
        _recommendedJobs = results;
        _loadingRecommendedJobs = false;
      });
    } catch (error) {
      setState(() {
        _loadingRecommendedJobs = false;
        _hasError = true;
        _errorMessage = 'Failed to load recommended jobs: $error';
      });
    }
  }

  Future<List<dynamic>> _fetchRecommendedJobs(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/freelancer/recommended-jobs/"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Recommended jobs response: $data");
        
        if (data["status"] == true) {
          final recommended = data["recommended"] ?? [];
          print("Found ${recommended.length} recommended jobs");
          
          for (int i = 0; i < (recommended.length < 3 ? recommended.length : 3); i++) {
            print("Job $i - Title: ${recommended[i]['title']}");
            print("   Match Score: ${recommended[i]['match_score'] ?? 'N/A'}");
            print("   Skills: ${recommended[i]['required_skills']}");
          }
          
          return recommended;
        } else {
          print("API returned false status: ${data['message']}");
          return [];
        }
      } else {
        print('Error fetching recommended jobs: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching recommended jobs: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTasksList(List<Map<String, dynamic>> allTasks, String query) {
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

  List<Map<String, dynamic>> _getRecommendedJobsFiltered() {
    final jobs = _recommendedJobs.whereType<Map<String, dynamic>>().toList();
    return _filterTasksList(jobs, _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    if (taskProvider.tasks.isNotEmpty) {
      _filteredTasks = _filterTasksList(taskProvider.tasks, _searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Jobs'),
        backgroundColor: const Color(0xFF1976D2),
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
                          onPressed: () { 
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
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
                _buildAllTasksTab(taskProvider),
                _buildRecommendedJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTasksTab(TaskProvider taskProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await taskProvider.fetchTasks(context);
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

  Widget _buildRecommendedJobsTab() {
    if (_loadingRecommendedJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Recommendations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRecommendedJobs,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final filteredJobs = _getRecommendedJobsFiltered();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'No recommended jobs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete your profile to get personalized recommendations',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRecommendedJobs,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Recommendations'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendedJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(filteredJobs[index], isRecommended: true);
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, {bool isRecommended = false}) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Use TaskProvider helper methods for consistent display
    final serviceTypeDisplay = taskProvider.getServiceTypeDisplay(task);
    final isOnSite = serviceTypeDisplay.toLowerCase().contains('site') || 
                    serviceTypeDisplay.toLowerCase().contains('physical');
    final serviceTypeColor = taskProvider.getServiceTypeColor(task);
    final serviceTypeIcon = taskProvider.getServiceTypeIcon(task);
    
    final employer = task['employer'] ?? {};
    final bool isAssignedToMe = _isTaskAssignedToMe(task);
    final bool isTaken = _isTaskTaken(task);
    final assignedFreelancer = _getAssignedFreelancer(task);
    final freelancerName = _getFreelancerName(assignedFreelancer);
    final locationAddress = task['location_address'];
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type Badge - Now using provider's helper methods
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: serviceTypeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    serviceTypeIcon,
                    size: 12,
                    color: serviceTypeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    serviceTypeDisplay.toUpperCase(),
                    style: TextStyle(
                      color: serviceTypeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Title and Status Row - Fixed for overflow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Flexible(
                          child: Container(
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
                                Flexible(
                                  child: Text('Recommended',
                                    style: TextStyle(fontSize: 12, color: Colors.amber[800], fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isRecommended) const SizedBox(width: 8),
                      Expanded(
                        child: Text(task['title'] ?? 'Untitled Task',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTaskStatus(task, isTaken, isAssignedToMe, freelancerName),
              ],
            ),
            
            // Show address only if it's on-site
            if (isOnSite && locationAddress != null && locationAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_pin, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Location: $locationAddress",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 8),
            
            Text(task['description'] ?? '',
              maxLines: 3, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            // Clickable client section - Fixed for overflow
            _buildClientSection(employer),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
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
                
                if (isAssignedToMe)
                  ElevatedButton.icon(
                    onPressed: () {
                      final taskId = task['task_id']?.toString() ?? task['id']?.toString() ?? '';
                      if (taskId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitTaskScreen(
                              taskId: taskId, 
                              taskTitle: '', 
                              budget: '', 
                              contractId: null,
                            ),
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
                      backgroundColor: const Color(0xFF1976D2),
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
            onPressed: () { 
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
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
      statusColor = const Color(0xFF1976D2);
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
      mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: Text(statusText,
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        
        if (isTaken && !isAssignedToMe)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(freelancerName,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildClientSection(Map<String, dynamic> employer) {
    final companyName = employer['company_name'];
    final username = employer['username'];
    final profilePic = employer['profile_picture'];
    final employerId = employer['employer_id'] ?? employer['id'];
    String displayName = companyName ?? username ?? 'Client';
    
    return InkWell(
      onTap: () {
        if (employerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployerProfileScreen(
                employerId: employerId.toString(),
                employerName: displayName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot view profile: Employer ID not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            SizedBox(
              width: 40,
              height: 40,
              child: _buildClientAvatar(profilePic, displayName),
            ),
            const SizedBox(width: 12),
            
            // Middle content - takes remaining space
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Posted by:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (employer['contact_email'] != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employer['contact_email']!.toString(),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        Expanded(
                          child: Text(
                            employer['phone']!.toString(),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Profile button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 14, color: const Color(0xFF1976D2)),
                  const SizedBox(width: 4),
                  Text('Profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientAvatar(String? profilePic, String displayName) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(profilePic),
        radius: 16,
      );
    } else {
      return CircleAvatar(
        backgroundColor: const Color(0xFF1976D2),
        radius: 16,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 14
          ),
        ),
      );
    }
  }

  bool _isTaskTaken(Map<String, dynamic> task) {
    final isTaken = task['is_taken'] == true;
    final hasContract = task['has_contract'] == true;
    final overallStatus = (task['overall_status'] ?? '').toString().toLowerCase();
    final assignedFreelancer = task['assigned_freelancer'];
    final assignedUser = task['assigned_user'];
    
    return isTaken || 
           hasContract || 
           overallStatus == 'taken' || 
           assignedFreelancer != null ||
           assignedUser != null;
  }

  bool _isTaskAssignedToMe(Map<String, dynamic> task) {
    final status = (task['status'] ?? '').toString().toLowerCase();
    return status == 'in_progress' || status == 'assigned';
  }

  Map<String, dynamic>? _getAssignedFreelancer(Map<String, dynamic> task) {
    final assignedFreelancer = task['assigned_freelancer'];
    if (assignedFreelancer is Map<String, dynamic>) {
      return assignedFreelancer;
    }
    
    final assignedUser = task['assigned_user'];
    if (assignedUser is Map<String, dynamic>) {
      return assignedUser;
    }
    
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
}