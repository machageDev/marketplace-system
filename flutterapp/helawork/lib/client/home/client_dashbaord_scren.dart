import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/home/client_contract_screen.dart';
import 'package:helawork/client/home/client_payment_screen.dart';
import 'package:helawork/client/provider/auth_provider.dart' as client_auth;
import 'package:helawork/client/provider/client_proposal_provider.dart' as client_proposal;
import 'package:helawork/client/provider/client_task_provider.dart' as client_task;
import 'package:helawork/client/provider/client_contract_provider.dart' as client_contract;
import 'package:helawork/client/screen/client_profile_screen.dart';
import 'package:helawork/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:helawork/client/home/client_proposal_screen.dart';
import 'package:helawork/client/home/client_rating_screen.dart';
import 'package:helawork/client/home/client_task_scren.dart';
import 'package:helawork/client/provider/client_dashboard_provider.dart' as client_dashboard;
import 'package:shared_preferences/shared_preferences.dart';

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
    _navigateToPaymentWithOrder();
  }

  void _navigateToPaymentWithOrder() async {
    try {
      print('🔍 Starting payment navigation...');
      
      final orderData = await _getOrderDataForPayment();
      print('📊 Order data received: ${orderData != null ? "NOT NULL" : "NULL"}');
      
      if (orderData != null) {
        print('✅ Order data details:');
        print('   Order ID: ${orderData['id']}');
        print('   Amount: ${orderData['amount']}');
        print('   Freelancer Name: ${orderData['freelancerName']}');
        print('   Freelancer ID: ${orderData['freelancerId']}');
        print('   Freelancer Email: ${orderData['freelancerEmail']}');
        
        // Validate required data
        if (orderData['id']?.isEmpty == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order ID is missing')),
          );
          return;
        }
        
        if (orderData['freelancerId']?.isEmpty == true) {
          print('❌ ERROR: Freelancer ID is empty');
          print('❌ Here is what we got:');
          print('   - Order ID: ${orderData['id']}');
          print('   - Freelancer Name: ${orderData['freelancerName']}');
          print('   - Freelancer Email: ${orderData['freelancerEmail']}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot process payment: Freelancer information is missing')),
          );
          return;
        }
        
        // Get auth token and email
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';
        final userEmail = prefs.getString('user_email') ?? '';
        
        print('✅ All data valid, navigating to PaymentScreen...');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              orderId: orderData['id']!,
              amount: orderData['amount'] ?? 0.0,
              freelancerName: orderData['freelancerName'] ?? 'Freelancer',
              serviceDescription: orderData['serviceDescription'] ?? 'Service',
              freelancerPhotoUrl: orderData['freelancerPhotoUrl'] ?? '',
              freelancerId: orderData['freelancerId']!,
              freelancerEmail: orderData['freelancerEmail'] ?? '',
              currency: orderData['currency'] ?? 'KSH', 
              email: userEmail, 
              authToken: token, 
              paymentService: 1,
            ),
          ),
        );
      } else {
        print('❌ No order data received');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No orders available for payment')),
        );
      }
    } catch (e) {
      print('❌ Error in payment navigation: $e');
      print('Stack trace: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

Future<Map<String, dynamic>?> _getOrderDataForPayment() async {
  try {
    print('🔍 Fetching order data for payment...');
    
    final paymentService = PaymentService();
    
    // Try to get pending orders
    try {
      final orders = await paymentService.getPendingOrders();
      print('📋 Found ${orders.length} pending orders');
      
      if (orders.isNotEmpty) {
        final order = orders.first;
        
        // DEBUG: Print the entire order structure
        print('📋 ORDER STRUCTURE:');
        print('Order Type: ${order.runtimeType}');
        
        order.forEach((key, value) {
          print('   $key: ${value.runtimeType} = $value');
        });
              
        // Check if freelancer exists and what fields it has
        if (order['freelancer'] != null) {
          print('📋 FREELANCER STRUCTURE:');
          final freelancer = order['freelancer'];
          if (freelancer is Map<String, dynamic>) {
            freelancer.forEach((key, value) {
              print('   $key: ${value.runtimeType} = $value');
            });
          } else {
            print('Freelancer is not a Map: ${freelancer.toString()}');
          }
        } else {
          print('❌ No freelancer object found in order');
          
          // Check for other possible freelancer fields
          print('🔍 Looking for freelancer in other fields...');
          order.forEach((key, value) {
            if (key.toString().toLowerCase().contains('freelancer')) {
              print('   Found freelancer-related field: $key = $value');
            }
          });
        }
        
        print('✅ Using first pending order');
        
        // Extract freelancer data safely - TRY DIFFERENT FIELD NAMES
        final freelancer = order['freelancer'];
        final freelancerId = freelancer?['id']?.toString() ?? 
                             freelancer?['freelancer_id']?.toString() ?? 
                             freelancer?['user_id']?.toString() ?? 
                             freelancer?['userId']?.toString() ?? 
                             freelancer?['freelancerId']?.toString() ?? 
                             '';
        
        print('📋 Trying to get freelancer ID:');
        print('   From freelancer["id"]: ${freelancer?["id"]}');
        print('   From freelancer["freelancer_id"]: ${freelancer?["freelancer_id"]}');
        print('   From freelancer["user_id"]: ${freelancer?["user_id"]}');
        print('   From freelancer["userId"]: ${freelancer?["userId"]}');
        print('   From freelancer["freelancerId"]: ${freelancer?["freelancerId"]}');
        print('   Final freelancerId: $freelancerId');
        
        final freelancerName = freelancer?['name']?.toString() ?? 
                              freelancer?['full_name']?.toString() ?? 
                              freelancer?['username']?.toString() ?? 
                              freelancer?['firstName']?.toString() ?? 
                              freelancer?['lastName']?.toString() ?? 
                              'Freelancer';
        final freelancerEmail = freelancer?['email']?.toString() ?? '';
        
        // Extract order data safely
        final orderId = order['order_id']?.toString() ?? 
                       order['id']?.toString() ?? 
                       order['orderId']?.toString() ?? 
                       '';
        final amount = order['amount'] != null 
            ? (order['amount'] is num ? order['amount'].toDouble() : double.tryParse(order['amount'].toString()) ?? 0.0)
            : 0.0;
        
        // Debug the extracted values
        print('📋 EXTRACTED VALUES:');
        print('   orderId: $orderId');
        print('   amount: $amount');
        print('   freelancerName: $freelancerName');
        print('   freelancerEmail: $freelancerEmail');
        
        return {
          'id': orderId,
          'amount': amount,
          'freelancerName': freelancerName,
          'serviceDescription': order['task']?['title']?.toString() ?? 
                              order['service_description']?.toString() ?? 
                              order['task_title']?.toString() ?? 
                              order['description']?.toString() ?? 
                              'Service',
          'freelancerPhotoUrl': order['freelancer_photo']?.toString() ?? 
                               order['freelancerPhotoUrl']?.toString() ?? 
                               order['profile_picture']?.toString() ?? 
                               '',
          'freelancerId': freelancerId,
          'freelancerEmail': freelancerEmail,
          'currency': order['currency']?.toString() ?? 'KSH',
        };
      } else {
        print('❌ No pending orders found');
      }
    } catch (e) {
      print('⚠️ Error getting pending orders: $e');
      print('Stack trace: ${e.toString()}');
    }
    
    // Fallback: Try to get any user orders from ApiService
    try {
      print('🔍 Trying fallback: Getting user orders from ApiService...');
      final userOrders = await ApiService().getUserOrders();
      print('📋 Found ${userOrders.length} user orders');
      
      if (userOrders.isNotEmpty) {
        // Find first order with pending payment status
        final pendingOrder = userOrders.firstWhere(
          (order) => order['status'] == 'pending' || 
                    order['status'] == 'awaiting_payment' ||
                    order['status'] == 'completed',
          orElse: () => userOrders.first,
        );
        
        // Debug the pending order structure
        print('📋 PENDING ORDER STRUCTURE:');
        pendingOrder.forEach((key, value) {
          print('   $key: ${value.runtimeType} = $value');
        });
        
        print('✅ Using user order: ${pendingOrder['order_id'] ?? pendingOrder['id']}');
        
        // Extract freelancer data safely
        final freelancer = pendingOrder['freelancer'];
        final freelancerId = freelancer?['id']?.toString() ?? '';
        final freelancerName = freelancer?['name']?.toString() ?? 'Freelancer';
        final freelancerEmail = freelancer?['email']?.toString() ?? '';
        
        // Extract order data safely
        final orderId = pendingOrder['order_id']?.toString() ?? pendingOrder['id']?.toString() ?? '';
        final amount = pendingOrder['amount'] != null 
            ? (pendingOrder['amount'] is num ? pendingOrder['amount'].toDouble() : double.tryParse(pendingOrder['amount'].toString()) ?? 0.0)
            : 0.0;
        
        return {
          'id': orderId,
          'amount': amount,
          'freelancerName': freelancerName,
          'serviceDescription': pendingOrder['task']?['title']?.toString() ?? 
                              pendingOrder['service_description']?.toString() ?? 
                              pendingOrder['serviceDescription']?.toString() ?? 
                              'Service',
          'freelancerPhotoUrl': pendingOrder['freelancer_photo']?.toString() ?? 
                               pendingOrder['freelancerPhotoUrl']?.toString() ?? 
                               '',
          'freelancerId': freelancerId,
          'freelancerEmail': freelancerEmail,
          'currency': pendingOrder['currency']?.toString() ?? 'KSH',
        };
      }
    } catch (e) {
      print('⚠️ Error getting user orders: $e');
      print('Stack trace: ${e.toString()}');
    }
    
    print('❌ No orders found for payment');
    return null;
    
  } catch (e) {
    print('❌ ERROR in _getOrderDataForPayment: $e');
    print('Stack trace: ${e.toString()}');
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
          SectionCard(
            title: 'Contracts',
            icon: Icons.assignment_turned_in_outlined,
            isClickable: true,
            child: _buildContractsSection(context),
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

  Widget _buildContractsSection(BuildContext context) {
    final contractProvider = Provider.of<client_contract.ClientContractProvider>(context, listen: false);
    
    return GestureDetector(
      onTap: () {
        contractProvider.fetchEmployerContracts();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClientContractsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View All Contracts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your service agreements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Contracts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View and manage all your service agreements with freelancers. '
                          'Contracts will appear here after you accept proposals.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
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

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final bool isClickable;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    required this.icon,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
                const Spacer(),
                if (isClickable)
                  const Icon(Icons.arrow_forward_ios, 
                    size: 16, 
                    color: Colors.blueAccent
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