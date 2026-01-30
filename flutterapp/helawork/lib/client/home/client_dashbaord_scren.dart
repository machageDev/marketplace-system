import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/home/client_contract_screen.dart';
import 'package:helawork/client/home/client_submittedtask.dart'; // Make sure this import exists
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
      _buildPaymentPlaceholder(),
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
          
          // QUICK ACTIONS SECTION - WITH NUMBERS
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickActionsWithNumbers(context),
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

  Widget _buildQuickActionsWithNumbers(BuildContext context) {
    // Use 3 columns instead of 2 for better spacing
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, // Changed from 2 to 3
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9, // Square-ish cards
      children: [
        // TASKS CARD
        _buildMinimalActionCard(
          title: 'Tasks',
          number: provider.totalTasks.toString(),
          icon: Icons.work_outline,
          color: Colors.blueAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TasksScreen(),
              ),
            );
          },
        ),
        
        // PROPOSALS CARD
        _buildMinimalActionCard(
          title: 'Proposals',
          number: provider.pendingProposals.toString(),
          icon: Icons.message_outlined,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientProposalsScreen(),
              ),
            );
          },
        ),
        
        // ACTIVE JOBS CARD
        _buildMinimalActionCard(
          title: 'Active',
          number: provider.ongoingTasks.toString(),
          icon: Icons.play_circle_fill,
          color: Colors.teal,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Showing ${provider.ongoingTasks} active jobs')),
            );
          },
        ),
        
        // CONTRACTS CARD
        _buildMinimalActionCard(
          title: 'Contracts',
          number: 'View',
          icon: Icons.assignment_outlined,
          color: Colors.green,
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
        ),
        
        // COMPLETED CARD
        _buildMinimalActionCard(
          title: 'Completed',
          number: provider.completedTasks.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.purple,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Showing ${provider.completedTasks} completed tasks')),
            );
          },
        ),
        
        // SUBMISSIONS CARD
        _buildMinimalActionCard(
          title: 'Review',
          number: 'Work',
          icon: Icons.task_outlined,
          color: Colors.red,
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
        ),
      ],
    );
  }

  Widget _buildMinimalActionCard({
    required String title,
    required String number,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6), // Minimal padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon at the top
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              // Number in center
              Text(
                number,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Title at bottom
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 9,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}