import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/dashbaord_provider.dart';
import 'package:provider/provider.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Client Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.indigo,
            elevation: 2,
            centerTitle: true,
          ),
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    strokeWidth: 3,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats Row - Improved layout
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          StatCard(
                            title: 'Total Tasks',
                            value: provider.dashboardData['total_tasks']?.toString() ?? '0',
                            color: Colors.blue,
                            icon: Icons.work,
                          ),
                          StatCard(
                            title: 'Active Jobs',
                            value: provider.dashboardData['active_jobs']?.toString() ?? '0',
                            color: Colors.green,
                            icon: Icons.play_circle,
                          ),
                          StatCard(
                            title: 'In Progress',
                            value: provider.dashboardData['ongoing_tasks']?.toString() ?? '0',
                            color: Colors.orange,
                            icon: Icons.task,
                          ),
                          StatCard(
                            title: 'Proposals',
                            value: provider.dashboardData['pending_proposals']?.toString() ?? '0',
                            color: Colors.cyan,
                            icon: Icons.list_alt,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Tasks
                      SectionCard(
                        title: 'Recent Tasks',
                        icon: Icons.assignment,
                        child: provider.dashboardData['jobs'] != null &&
                                (provider.dashboardData['jobs'] as List).isNotEmpty
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 0,
                                  columns: const [
                                    DataColumn(
                                        label: Text(
                                      'Title',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Category',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Budget',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Deadline',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Status',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                  ],
                                  rows: (provider.dashboardData['jobs'] as List)
                                      .map(
                                        (job) => DataRow(
                                          cells: [
                                            DataCell(Text(
                                              job['title'] ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            )),
                                            DataCell(Text(
                                              job['category'] ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            )),
                                            DataCell(Text(
                                              job['budget'] != null
                                                  ? 'Ksh ${job['budget'].toString()}'
                                                  : 'Not set',
                                              style: const TextStyle(fontSize: 12),
                                            )),
                                            DataCell(Text(
                                              job['deadline'] ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            )),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(job['status'] ?? ''),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  job['status'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'No tasks posted yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // Recent Proposals
                      SectionCard(
                        title: 'Recent Proposals',
                        icon: Icons.people,
                        child: provider.dashboardData['proposals'] != null &&
                                (provider.dashboardData['proposals'] as List).isNotEmpty
                            ? Column(
                                children: (provider.dashboardData['proposals'] as List)
                                    .map(
                                      (proposal) => Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        elevation: 1,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.indigo.withOpacity(0.1),
                                            child: Text(
                                              proposal['freelancer'][0].toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            proposal['freelancer'],
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            'Applied for: ${proposal['task']} - Ksh ${proposal['bid_amount']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                            ),
                                            child: const Text(
                                              'Review',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.people, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'No new proposals',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        // Handle navigation here
      },
    );
  }
}

// Stat Card Widget - Enhanced
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section Card Widget - Enhanced
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.indigo,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
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