import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/contract_screen.dart';
import 'package:helawork/freelancer/home/proposal_screen.dart';
import 'package:helawork/freelancer/home/rating_screen.dart';
import 'package:helawork/freelancer/home/submitting_task.dart';
import 'package:helawork/freelancer/home/task_page.dart';
import 'package:helawork/freelancer/home/userprofile_screen.dart';
import 'package:helawork/freelancer/home/wallet_screen.dart';
import 'package:helawork/freelancer/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SizedBox(), 
    const TaskPage(), 
    const WalletScreen(token: '',),
    const ProposalsScreen(taskId: 0, task: {}, employer: {},), 
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadData(context);
    });
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // Directly navigate to SubmitTaskScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubmitTaskScreen(
            taskId: '', // Empty initially, user will select
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Navigation method - updated
  void _navigateToSubmitTask(String taskId) {
    print('Navigating to SubmitTaskScreen with taskId: $taskId');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitTaskScreen(
          taskId: taskId,
        ),
      ),
    );
  }

  // ================= MAIN DASHBOARD BODY (Home Tab) =================
  Widget _buildHomePage(DashboardProvider dashboard) {
    if (dashboard.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (dashboard.error != null) {
      return Center(
        child: Text(
          dashboard.error!,
          style: TextStyle(color: Colors.red.shade400),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => dashboard.loadData(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(dashboard),
            const SizedBox(height: 20),
            _buildNotificationsSection(dashboard),
            const SizedBox(height: 20),
            _buildStatsCards(dashboard),
            const SizedBox(height: 20),
            _buildRatingsSection(),
            const SizedBox(height: 20),
            _buildContractsSection(),
            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  // ================= USER HEADER =================
  Widget _buildUserHeader(DashboardProvider dashboard) {
    final notificationCount = _getNotificationCount(dashboard);
    
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: 25,
            backgroundImage: dashboard.profilePictureUrl != null && 
                            dashboard.profilePictureUrl!.isNotEmpty
                ? NetworkImage(dashboard.profilePictureUrl!)
                : null,
            backgroundColor: dashboard.profilePictureUrl != null ? 
                            Colors.transparent : Colors.grey[700],
            child: dashboard.profilePictureUrl == null || 
                   dashboard.profilePictureUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            dashboard.userName ?? "Guest User",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        // Notification badge with count
        Stack(
          children: [
            IconButton(
              icon: Icon(
                notificationCount > 0 ? Icons.notifications : Icons.notifications_none,
                color: Colors.white,
              ),
              onPressed: () => _showNotifications(dashboard),
            ),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationCount > 9 ? '9+' : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ================= NOTIFICATIONS SECTION =================
  Widget _buildNotificationsSection(DashboardProvider dashboard) {
    final notifications = _generateNotifications(dashboard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: () => _showNotifications(dashboard),
                child: const Text(
                  "View All",
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (notifications.isEmpty)
          _buildEmptyNotificationCard()
        else
          Column(
            children: notifications.take(3).map((notification) => 
              _buildNotificationCard(notification, dashboard)
            ).toList(),
          ),
      ],
    );
  }

  // ================= STATS CARDS =================
  Widget _buildStatsCards(DashboardProvider dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2, // Reduced from 1.4 to fit better
          children: [
            _buildClickableStatCard(
              "Active Tasks",
              dashboard.activeTasks.length.toString(),
              Icons.task,
              Colors.green,
              () => _onItemTapped(1), // Navigate to Tasks
            ),
            _buildClickableStatCard(
              "Total Tasks",
              dashboard.totalTasks.toString(),
              Icons.assignment,
              Colors.blue,
              () => _onItemTapped(1), // Navigate to Tasks
            ),
            _buildClickableStatCard(
              "In Progress",
              dashboard.ongoingTasks.toString(),
              Icons.timelapse,
              Colors.orange,
              () => _showTasksInProgress(dashboard), // Show filtered tasks
            ),
            _buildClickableStatCard(
              "Completed",
              dashboard.completedTasks.toString(),
              Icons.check_circle,
              Colors.purple,
              () => _navigateToSubmitTask(''), // Navigate to Submit Task
            ),
          ],
        ),
      ],
    );
  }

  // ================= RATINGS SECTION =================
  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ratings & Reviews",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildClickableSectionCard(
          title: "View Ratings",
          icon: Icons.star,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RatingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ================= CONTRACTS SECTION =================
  Widget _buildContractsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Contracts",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildClickableSectionCard(
          title: "View Contracts",
          icon: Icons.article,
          color: Colors.blueGrey.shade700,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContractScreen()),
            );
          },
        ),
      ],
    );
  }

  // ================= NEW CLICKABLE CARD WIDGETS =================

  // Build clickable stat card
  Widget _buildClickableStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              Icon(icon, color: color, size: 22), // Reduced size
              const SizedBox(height: 4), // Reduced spacing
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10, // Reduced font size
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Allow text to wrap
              ),
              const SizedBox(height: 2), // Reduced spacing
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 14, // Reduced size
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build clickable section card (for Ratings & Contracts)
  Widget _buildClickableSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20), // Reduced size
              ),
              const SizedBox(width: 12), // Reduced spacing
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20, // Reduced size
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= NOTIFICATION METHODS =================

  // Generate notifications based on dashboard data
  List<Map<String, dynamic>> _generateNotifications(DashboardProvider dashboard) {
    final notifications = <Map<String, dynamic>>[];
    
    // New proposals notification
    if (dashboard.pendingProposals > 0) {
      notifications.add({
        'type': 'proposal',
        'title': 'New Proposals',
        'message': 'You have ${dashboard.pendingProposals} new proposal(s) waiting for review',
        'icon': Icons.person_add,
        'color': Colors.orange,
        'action': () => _onItemTapped(3), // Navigate to proposals
      });
    }

    // Active tasks notification
    if (dashboard.activeTasks.isNotEmpty) {
      notifications.add({
        'type': 'active_tasks',
        'title': 'Active Tasks',
        'message': 'You have ${dashboard.activeTasks.length} active task(s)',
        'icon': Icons.task,
        'color': Colors.green,
        'action': () => _onItemTapped(1), // Navigate to tasks
      });
    }

    // Tasks in progress notification
    if (dashboard.ongoingTasks > 0) {
      notifications.add({
        'type': 'in_progress',
        'title': 'Tasks in Progress',
        'message': '${dashboard.ongoingTasks} task(s) are currently being worked on',
        'icon': Icons.timelapse,
        'color': Colors.blue,
        'action': () => _showTasksInProgress(dashboard), // Show filtered tasks
      });
    }

    // Completed tasks notification
    if (dashboard.completedTasks > 0) {
      notifications.add({
        'type': 'completed',
        'title': 'Completed Tasks',
        'message': '${dashboard.completedTasks} task(s) have been completed',
        'icon': Icons.check_circle,
        'color': Colors.purple,
        'action': () => _navigateToSubmitTask(''), // Navigate to submit task
      });
    }

    return notifications;
  }

  // Show tasks in progress dialog
  void _showTasksInProgress(DashboardProvider dashboard) {
    final inProgressTasks = dashboard.activeTasks.where((task) {
      final status = task["status"]?.toString().toLowerCase() ?? "";
      return status == "in progress" || status.contains("progress");
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Tasks In Progress (${inProgressTasks.length})",
          style: const TextStyle(color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit height
          ),
          child: inProgressTasks.isEmpty
              ? const Text(
                  "No tasks in progress",
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: inProgressTasks.length,
                  itemBuilder: (context, index) {
                    final task = inProgressTasks[index];
                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.task, color: Colors.orange),
                        title: Text(
                          task["title"] ?? "Untitled Task",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Status: ${task["status"] ?? "Unknown"}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to task details or submit task
                          if (task["task_id"] != null) {
                            _navigateToSubmitTask(task["task_id"].toString());
                          } else {
                            _onItemTapped(1); // Fallback to tasks page
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.green),
            ),
          ),
          if (inProgressTasks.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _onItemTapped(1); // Navigate to tasks page
              },
              child: const Text(
                "View All Tasks",
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  // Get total notification count
  int _getNotificationCount(DashboardProvider dashboard) {
    return _generateNotifications(dashboard).length;
  }

  // Build notification card
  Widget _buildNotificationCard(Map<String, dynamic> notification, DashboardProvider dashboard) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true, // Makes tile more compact
        leading: CircleAvatar(
          radius: 18, // Reduced size
          backgroundColor: notification['color'] as Color,
          child: Icon(
            notification['icon'] as IconData,
            color: Colors.white,
            size: 18, // Reduced size
          ),
        ),
        title: Text(
          notification['title'] as String,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 14, // Reduced font size
          ),
        ),
        subtitle: Text(
          notification['message'] as String,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12, // Reduced font size
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: () {
          final action = notification['action'] as Function?;
          if (action != null) {
            action();
          }
        },
      ),
    );
  }

  // Build empty notification card
  Widget _buildEmptyNotificationCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, color: Colors.grey, size: 30), // Reduced size
            SizedBox(height: 8), // Reduced spacing
            Text(
              "No New Notifications",
              style: TextStyle(color: Colors.grey, fontSize: 14), // Reduced font
            ),
            SizedBox(height: 4), // Reduced spacing
            Text(
              "You're all caught up!",
              style: TextStyle(color: Colors.grey, fontSize: 10), // Reduced font
            ),
          ],
        ),
      ),
    );
  }

  // Show notifications dialog
  void _showNotifications(DashboardProvider dashboard) {
    final notifications = _generateNotifications(dashboard);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "All Notifications",
          style: TextStyle(color: Colors.white, fontSize: 16), // Reduced font
        ),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit height
          ),
          child: notifications.isEmpty
              ? const Text(
                  "No new notifications",
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification, dashboard);
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            elevation: 0,
            title: const Text(
              "Dashboard",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => dashboard.loadData(context),
              ),
            ],
          ),
          body: SafeArea( // Added SafeArea to prevent overflow
            child: _selectedIndex == 0
                ? _buildHomePage(dashboard)
                : _pages[_selectedIndex],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[900],
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task),
                label: "Tasks",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment),
                label: "Payments",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article),
                label: "Proposals",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                label: "SubmitTask",
              )
            ],
          ),
        );
      },
    );
  }
}