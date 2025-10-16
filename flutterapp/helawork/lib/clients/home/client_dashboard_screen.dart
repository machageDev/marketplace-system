import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Client Dashboard', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              'Welcome, ${provider.userName}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: provider.loadDashboard,
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            if (provider.isLoading)
              _buildLoadingState()
            else if (provider.errorMessage.isNotEmpty)
              _buildErrorState(provider)
            else
              DashboardContent(provider: provider),
            const Center(child: Text('Tasks Page')),
            const Center(child: Text('Proposals Page')),
            const Center(child: Text('Payments Page')),
            const Center(child: Text('Profile Page')),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Proposals'),
          BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Loading dashboard...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );

  Widget _buildErrorState(DashboardProvider provider) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Failed to load dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              const SizedBox(height: 8),
              Text(provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.loadDashboard,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}

class DashboardContent extends StatelessWidget {
  final DashboardProvider? provider;
  const DashboardContent({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(provider!),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              StatCard(
                title: 'Total Tasks',
                value: provider!.totalTasks.toString(),
                color1: Colors.blueAccent,
                color2: Colors.lightBlueAccent,
                icon: Icons.work_outline,
              ),
              StatCard(
                title: 'Active Jobs',
                value: provider!.ongoingTasks.toString(),
                color1: Colors.teal,
                color2: Colors.tealAccent,
                icon: Icons.play_circle_fill,
              ),
              StatCard(
                title: 'Completed',
                value: provider!.completedTasks.toString(),
                color1: Colors.green,
                color2: Colors.lightGreen,
                icon: Icons.check_circle_outline,
              ),
              StatCard(
                title: 'Proposals',
                value: provider!.pendingProposals.toString(),
                color1: Colors.orange,
                color2: Colors.deepOrangeAccent,
                icon: Icons.list_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Recent Tasks',
            icon: Icons.assignment_outlined,
            child: provider!.recentTasks.isNotEmpty
                ? _buildTasksTable(provider!.recentTasks)
                : const EmptyState(icon: Icons.assignment, message: 'No tasks posted yet'),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Recent Proposals',
            icon: Icons.people_outline,
            child: provider!.recentProposals.isNotEmpty
                ? _buildProposalsList(provider!.recentProposals)
                : const EmptyState(icon: Icons.people_outline, message: 'No new proposals'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(DashboardProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.8), Colors.lightBlueAccent.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30,
              child: Text(
                provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'L',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${provider.userName}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s your dashboard overview',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
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

  Widget _buildTasksTable(List<dynamic> tasks) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Budget', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: tasks.map((task) {
          return DataRow(cells: [
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  task['title']?.toString() ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(task['budget'] != null ? 'Ksh ${task['budget']}' : 'Not set')),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(task['status']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task['status']?.toString() ?? 'Unknown',
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildProposalsList(List<dynamic> proposals) {
    return Column(
      children: proposals.map((proposal) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Text(
                proposal['freelancer_name'] != null
                    ? proposal['freelancer_name'][0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              proposal['freelancer_name']?.toString() ?? 'Unknown Freelancer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Applied for: ${proposal['task_title']?.toString() ?? 'Unknown'} - Ksh ${proposal['bid_amount']?.toString() ?? '0'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            trailing: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Review', style: TextStyle(color: Colors.blueAccent)),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orangeAccent;
      case 'pending':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color1;
  final Color color2;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color1,
    required this.color2,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.8), color2.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}