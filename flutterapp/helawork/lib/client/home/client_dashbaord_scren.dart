import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/home/client_contract_screen.dart';
import 'package:helawork/client/home/client_submittedtask.dart';
import 'package:helawork/client/provider/auth_provider.dart' as client_auth;
import 'package:helawork/client/provider/client_proposal_provider.dart' as client_proposal;
import 'package:helawork/client/provider/client_submission_provider.dart';
import 'package:helawork/client/provider/client_task_provider.dart' as client_task;
import 'package:helawork/client/provider/client_contract_provider.dart' as client_contract;
import 'package:helawork/client/screen/client_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:helawork/client/home/client_proposal_screen.dart';
import 'package:helawork/client/home/client_rating_screen.dart';   
import 'package:helawork/client/home/client_task_scren.dart';
import 'package:helawork/client/provider/client_dashboard_provider.dart' as client_dashboard;


class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardTab(),
      const TasksScreen(),
      const ClientProposalsScreen(),  
      _buildPaymentPlaceholder(), // Keep this as placeholder
      const ClientRatingScreen(), 
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<client_dashboard.DashboardProvider>(context, listen: false)
          .loadDashboard();
    });
  }

  Widget _buildPaymentPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Payment Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payments are handled through the Contracts section\n\nGo to Contracts to view and make payments',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to Contracts screen for payments
              final contractProvider = Provider.of<client_contract.ClientContractProvider>(context, listen: false);
              contractProvider.fetchEmployerContracts();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientContractsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assignment),
            label: const Text('Go to Contracts'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              client_dashboard.DashboardProvider(apiService: ApiService()),
        ),
        ChangeNotifierProvider(
          create: (_) => client_auth.AuthProvider(apiService: ApiService()),
        ),
        ChangeNotifierProvider(
          create: (_) => client_task.TaskProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              client_proposal.ClientProposalProvider(apiService: ApiService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              client_contract.ClientContractProvider(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Client Dashboard',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          elevation: 2,
          centerTitle: true,
        ),
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          elevation: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              label: 'Proposals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_rounded),
              label: 'Payment', 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              label: 'Ratings',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<client_dashboard.DashboardProvider>(context);

    if (provider.isLoading) return _buildLoadingState();
    if (provider.errorMessage.isNotEmpty) return _buildErrorState(provider);

    return DashboardContent(provider: provider);
  }

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Loading dashboard...',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      );

  Widget _buildErrorState(client_dashboard.DashboardProvider provider) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Failed to load dashboard',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.loadDashboard,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}

class DashboardContent extends StatelessWidget {
  final client_dashboard.DashboardProvider provider;
  const DashboardContent({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 20),
          _buildStatsGrid(context),
          const SizedBox(height: 24),
          // Updated Contracts & Submissions Section
          _buildContractsAndSubmissionsSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ClientProfileScreen(profile:0),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 30,
                child: Text(
                  provider.userName.isNotEmpty
                      ? provider.userName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Welcome back, ${provider.userName}!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                },
                child: StatCard(
                  title: 'Total Tasks',
                  value: provider.totalTasks.toString(),
                  color1: Colors.blue,
                  color2: Colors.lightBlueAccent,
                  icon: Icons.work_outline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Showing ${provider.ongoingTasks} active jobs')),
                  );
                },
                child: StatCard(
                  title: 'Active Jobs',
                  value: provider.ongoingTasks.toString(),
                  color1: Colors.teal,
                  color2: Colors.tealAccent,
                  icon: Icons.play_circle_fill,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Showing ${provider.completedTasks} completed tasks')),
                  );
                },
                child: StatCard(
                  title: 'Completed',
                  value: provider.completedTasks.toString(),
                  color1: Colors.green,
                  color2: Colors.lightGreen,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientProposalsScreen(),
                    ),
                  );
                },
                child: StatCard(
                  title: 'Proposals',
                  value: provider.pendingProposals.toString(),
                  color1: Colors.orange,
                  color2: Colors.deepOrangeAccent,
                  icon: Icons.list_alt_outlined,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContractsAndSubmissionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Contracts & Submissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        
        // View All Contracts Card
        GestureDetector(
          onTap: () {
            final contractProvider = Provider.of<client_contract.ClientContractProvider>(context, listen: false);
            contractProvider.fetchEmployerContracts();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientContractsScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View All Contracts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your service agreements and payments',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
        
        // Review Submitted Tasks Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => SubmissionProvider(),
                  child: const SubmittedTasksScreen(),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.task_outlined, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review Submitted Tasks',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Approve work or request revisions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1, color2]),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}