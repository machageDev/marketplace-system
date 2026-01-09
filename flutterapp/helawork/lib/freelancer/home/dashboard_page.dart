import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/contract_screen.dart';
import 'package:helawork/freelancer/home/rating_screen.dart';
import 'package:helawork/freelancer/home/submitting_task.dart';
import 'package:helawork/freelancer/home/task_page.dart';
import 'package:helawork/freelancer/home/userprofile_screen.dart';
import 'package:helawork/freelancer/home/wallet_screen.dart';
import 'package:helawork/freelancer/provider/dashboard_provider.dart';
import 'package:intl/intl.dart';
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
    const WalletScreen(token: ''),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadData(context);
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
      _showTaskSelectionDialog(dashboard);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showTaskSelectionDialog(DashboardProvider dashboard) {
    final allTasks = dashboard.activeTasks;
    if (allTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active tasks to submit'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Task to Submit (${allTasks.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              final taskId = task["task_id"]?.toString() ?? task["id"]?.toString() ?? '';
              final title = task["title"] ?? "Untitled Task";
              final status = task["status"] ?? "Unknown";
              final budget = task["budget"] ?? task["price"] ?? "N/A";
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[300]!)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_getStatusIcon(status), color: Colors.white, size: 20),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Status: $status", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (budget != "N/A") Text("Budget: $budget", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500)),
                      Text("ID: $taskId", style: TextStyle(color: Colors.blue[700], fontSize: 10)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSubmitTask(taskId);
                  },
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))],
      ),
    );
  }

  void _showCompletedTasksDialog(DashboardProvider dashboard) {
    final completedTasks = dashboard.completedTasksList;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Completed Tasks (${completedTasks.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: completedTasks.isEmpty
              ? const Center(child: Text('No completed tasks'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return _buildCompletedTaskItem(task);
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  Widget _buildCompletedTaskItem(Map<String, dynamic> task) {
    final title = task["title"] ?? "Untitled Task";
    final budget = task["budget"] ?? "0";
    final employer = task["employer"]?["name"] ?? "Unknown";
    final completedAt = task["completed_at"];
    final hasPayment = task["payment_status"] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[300]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: hasPayment ? Colors.green : Colors.purple, borderRadius: BorderRadius.circular(8)),
          child: Icon(hasPayment ? Icons.payment : Icons.check_circle, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Employer: $employer", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
            Text("Budget: \$$budget", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500)),
            if (completedAt != null) Text("Completed: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(completedAt))}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            if (hasPayment) Text("✅ Payment Received", style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains("completed")) return Colors.green;
    if (lowerStatus.contains("in progress")) return Colors.orange;
    if (lowerStatus.contains("pending")) return Colors.yellow[700]!;
    if (lowerStatus.contains("approved")) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains("completed")) return Icons.check_circle;
    if (lowerStatus.contains("in progress")) return Icons.timelapse;
    if (lowerStatus.contains("pending")) return Icons.pending;
    if (lowerStatus.contains("approved")) return Icons.thumb_up;
    return Icons.task;
  }

  void _navigateToSubmitTask(String taskId) {
    if (taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Task ID is missing.'), backgroundColor: Colors.red));
      return;
    }
    
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final task = dashboardProvider.getTaskById(taskId);
    
    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Task not found: $taskId'),
          const SizedBox(height: 4),
          Text('Available tasks: ${dashboardProvider.activeTasks.length}', style: const TextStyle(fontSize: 12)),
        ]),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    
    if (!dashboardProvider.canSubmitTask(taskId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('This task cannot be submitted. Status: ${task['status']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    
    dashboardProvider.selectTaskForSubmission(taskId);
    final taskDetails = dashboardProvider.getTaskDetailsForSubmission(taskId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitTaskScreen(
          taskId: taskId,
          taskTitle: taskDetails?['title'] ?? task['title'] ?? 'Untitled Task',
          contractId: taskDetails?['contract_id'] ?? task['contract_id'],
          budget: taskDetails?['budget'] ?? task['budget'] ?? '0',
        ),
      ),
    );
  }

  Widget _buildHomePage(DashboardProvider dashboard) {
    if (dashboard.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
    if (dashboard.error != null) return Center(child: Text(dashboard.error!, style: TextStyle(color: Colors.red.shade400)));

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
            _buildStatsCards(dashboard),
            const SizedBox(height: 20),
            _buildQuickActionsSection(),
            const SizedBox(height: 20),
            _buildRatingsSection(),
            const SizedBox(height: 20),
            _buildContractsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            GestureDetector(
              onTap: () => setState(() { _selectedIndex = 1; }),
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search, color: Colors.blue, size: 28),
                    SizedBox(height: 8),
                    Text("Browse Tasks", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                final dashboard = Provider.of<DashboardProvider>(context, listen: false);
                _showTaskSelectionDialog(dashboard);
              },
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.upload, color: Colors.green, size: 28),
                    SizedBox(height: 8),
                    Text("Submit Task", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(DashboardProvider dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            GestureDetector(
              onTap: () => setState(() { _selectedIndex = 1; }),
              child: _buildStatCard("Active Tasks", dashboard.activeTasks.length.toString(), Icons.task, Colors.green),
            ),
            GestureDetector(
              onTap: () => setState(() { _selectedIndex = 1; }),
              child: _buildStatCard("Total Tasks", dashboard.totalTasks.toString(), Icons.assignment, Colors.blue),
            ),
            GestureDetector(
              onTap: () => setState(() { _selectedIndex = 1; }),
              child: _buildStatCard("In Progress", dashboard.ongoingTasks.toString(), Icons.timelapse, Colors.orange),
            ),
            GestureDetector(
              onTap: () {
                if (dashboard.completedTasksList.isNotEmpty) {
                  _showCompletedTasksDialog(dashboard);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No completed tasks yet'), backgroundColor: Colors.orange));
                }
              },
              child: _buildStatCard("Completed", dashboard.completedTasks.toString(), Icons.check_circle, Colors.purple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(DashboardProvider dashboard) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
          child: CircleAvatar(
            radius: 25,
            backgroundImage: dashboard.profilePictureUrl != null && dashboard.profilePictureUrl!.isNotEmpty ? NetworkImage(dashboard.profilePictureUrl!) : null,
            backgroundColor: dashboard.profilePictureUrl != null ? Colors.transparent : Colors.grey[700],
            child: dashboard.profilePictureUrl == null || dashboard.profilePictureUrl!.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dashboard.userName ?? "Guest User", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text("Dashboard", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ratings & Reviews", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RatingsScreen())),
          child: Card(
            color: Colors.grey[900],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow),
                  SizedBox(width: 12),
                  Text("View Ratings", style: TextStyle(color: Colors.white)),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Contracts", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractScreen())),
          child: Card(
            color: Colors.grey[900],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.article, color: Colors.blue),
                  SizedBox(width: 12),
                  Text("View Contracts", style: TextStyle(color: Colors.white)),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
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
            title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
            actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => dashboard.loadData(context))],
          ),
          body: SafeArea(child: _selectedIndex == 0 ? _buildHomePage(dashboard) : _pages[_selectedIndex]),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[900],
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
              BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Submit Task"),
            ],
          ),
        );
      },
    );
  }
}