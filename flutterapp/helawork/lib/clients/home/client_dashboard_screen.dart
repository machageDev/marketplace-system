import 'package:flutter/material.dart';
import 'package:helawork/clients/home/client_proposal_screen.dart';
import 'package:helawork/clients/home/client_rating_screen.dart';
import 'package:helawork/clients/home/client_task_screen.dart';
import 'package:helawork/clients/home/payment_screen.dart';
import 'package:helawork/clients/screens/client_profile_screen.dart';
import 'package:helawork/clients/provider/client_proposal_provider.dart' as client_proposal;
import 'package:helawork/clients/provider/dashboard_provider.dart' as client_dashboard;
import 'package:helawork/clients/provider/auth_provider.dart' as client_auth;
import 'package:helawork/clients/provider/task_provider.dart' as client_task;
import 'package:helawork/services/api_sercice.dart';
import 'package:helawork/services/payment_service.dart';
import 'package:provider/provider.dart';

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
      const ClientRatingScreen(employerId: 0), 
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
            'Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an order to make payment',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handlePaymentNavigation,
            child: const Text('Make Payment'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentNavigation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
        content: const Text('Please select an order with pending payment to proceed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPaymentWithOrder();
            },
            child: const Text('Select Order'),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentWithOrder() async {
    final orderData = await _getOrderDataForPayment();
    
    if (orderData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            orderId: orderData['id'],
            amount: orderData['amount'],
            email: orderData['email'],
            freelancerName: orderData['freelancerName'],
            serviceDescription: orderData['serviceDescription'],
            freelancerPhotoUrl: orderData['freelancerPhotoUrl'],
            paymentService: PaymentService(authToken: ''), authToken: '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders available for payment')),
      );
    }
  }

  // THIS METHOD SHOULD BE HERE IN _ClientDashboardScreenState
  Future<Map<String, dynamic>?> _getOrderDataForPayment() async {
    try {
      // Get actual orders from API
      final orders = await ApiService().getOrdersForPayment();
      
      if (orders.isNotEmpty) {
        // Use the first order that needs payment
        final order = orders.first;
        
        // Map the API response to your PaymentScreen expected format
        return {
          'id': order['order_id'] ?? order['id'] ?? '',
          'amount': order['amount'] != null ? double.parse(order['amount'].toString()) : 0.0,
          'email': order['email'] ?? '',
          'freelancerName': order['freelancer_name'] ?? order['freelancerName'] ?? 'Freelancer',
          'serviceDescription': order['service_description'] ?? order['serviceDescription'] ?? 'Service',
          'freelancerPhotoUrl': order['freelancer_photo'] ?? order['freelancerPhotoUrl'] ?? '',
        };
      }
      
      // If no orders from API, try getting user orders
      final userOrders = await ApiService().getUserOrders();
      if (userOrders.isNotEmpty) {
        final order = userOrders.firstWhere(
          (order) => order['status'] == 'pending' || order['status'] == 'awaiting_payment',
          orElse: () => userOrders.first,
        );
        
        return {
          'id': order['order_id'] ?? order['id'] ?? '',
          'amount': order['amount'] != null ? double.parse(order['amount'].toString()) : 0.0,
          'email': order['email'] ?? '',
          'freelancerName': order['freelancer_name'] ?? order['freelancerName'] ?? 'Freelancer',
          'serviceDescription': order['service_description'] ?? order['serviceDescription'] ?? 'Service',
          'freelancerPhotoUrl': order['freelancer_photo'] ?? order['freelancerPhotoUrl'] ?? '',
        };
      }
      
      return null;
      
    } catch (e) {
      print('Error fetching order data: $e');
      return null;
    }
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

// ... REST OF YOUR CODE (DashboardTab, DashboardContent, StatCard, SectionCard remain the same) ...
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
          _buildStatsGrid(),
          const SizedBox(height: 24),
          const SectionCard(
            title: 'Contracts',
            icon: Icons.assignment_turned_in_outlined,
            child: Center(
              child: Text(
                'No contracts yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
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
                        const ClientProfileScreen(employerId:0),
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

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        StatCard(
            title: 'Total Tasks',
            value: provider.totalTasks.toString(),
            color1: Colors.blue,
            color2: Colors.lightBlueAccent,
            icon: Icons.work_outline),
        StatCard(
            title: 'Active Jobs',
            value: provider.ongoingTasks.toString(),
            color1: Colors.teal,
            color2: Colors.tealAccent,
            icon: Icons.play_circle_fill),
        StatCard(
            title: 'Completed',
            value: provider.completedTasks.toString(),
            color1: Colors.green,
            color2: Colors.lightGreen,
            icon: Icons.check_circle_outline),
        StatCard(
            title: 'Proposals',
            value: provider.pendingProposals.toString(),
            color1: Colors.orange,
            color2: Colors.deepOrangeAccent,
            icon: Icons.list_alt_outlined),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Row(children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent)),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}