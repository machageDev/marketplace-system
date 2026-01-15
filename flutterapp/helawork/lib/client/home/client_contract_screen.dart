import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_contract_provider.dart';
import 'package:helawork/client/home/client_payment_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add this validation function at the top of your file
bool _isValidUuid(String value) {
  final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
  return uuidRegex.hasMatch(value);
}

class ClientContractsScreen extends StatefulWidget {
  const ClientContractsScreen({super.key});

  @override
  State<ClientContractsScreen> createState() => _ClientContractsScreenState();
}

class _ClientContractsScreenState extends State<ClientContractsScreen> {
  // BLUE & WHITE COLOR SCHEME
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _lightBlue = const Color(0xFF42A5F5);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _subtitleColor = const Color(0xFF666666);
  final Color _greenColor = const Color(0xFF4CAF50); // For paid status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientContractProvider>(context, listen: false)
          .fetchEmployerContracts();
    });
  }

  // ============ COMPLETION DIALOG ============
  void _showCompletionDialog(BuildContext context, int contractId, String taskTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text(
          'Are you sure you want to mark "$taskTitle" as completed?\n\n'
          'Once marked as completed, you will be able to proceed with payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _completeContract(context, contractId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeContract(BuildContext context, int contractId) async {
    final provider = Provider.of<ClientContractProvider>(context, listen: false);
    
    try {
      await provider.markContractCompleted(contractId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contract marked as completed!'),
          backgroundColor: _primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Refresh the list
      await provider.fetchEmployerContracts();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============ HELPER METHODS ============
  String _getStatusText(Map<String, dynamic> contract) {
    try {
      final isCompleted = contract['is_completed'] == true || contract['is_completed'] == 1;
      final isPaid = contract['is_paid'] == true || contract['is_paid'] == 1;
      final contractStatus = contract['contract_status']?.toString() ?? '';

      if (isCompleted && isPaid) {
        return 'Paid & Completed';
      } else if (isCompleted && !isPaid) {
        return 'Needs Payment';
      } else if (contractStatus.toLowerCase() == 'active') {
        return 'In Progress';
      } else if (contractStatus.toLowerCase() == 'pending') {
        return 'Pending';
      } else if (contractStatus.isNotEmpty) {
        return contractStatus;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  Color _getStatusColor(Map<String, dynamic> contract) {
    try {
      final isCompleted = contract['is_completed'] == true || contract['is_completed'] == 1;
      final isPaid = contract['is_paid'] == true || contract['is_paid'] == 1;

      if (isCompleted && isPaid) {
        return _greenColor; // Green for completed & paid
      } else if (isCompleted && !isPaid) {
        return _primaryBlue; // Blue for needs payment
      } else {
        return _lightBlue; // Light blue for in-progress/pending
      }
    } catch (e) {
      return _lightBlue;
    }
  }

  String _getActionButtonText(Map<String, dynamic> contract) {
    try {
      final isCompleted = contract['is_completed'] == true || contract['is_completed'] == 1;
      final isPaid = contract['is_paid'] == true || contract['is_paid'] == 1;

      if (isCompleted && !isPaid) {
        return 'Make Payment';
      } else if (!isCompleted) {
        return 'Mark as Completed';
      } else {
        return 'View Details';
      }
    } catch (e) {
      return 'View Details';
    }
  }

  // ============ NAVIGATE TO PAYMENT SCREEN ============
Future<void> _navigateToPaymentScreen(BuildContext context, Map<String, dynamic> contract) async {
  try {
    final contractId = contract['contract_id']?.toString() ?? '0';
    final taskTitle = contract['task_title']?.toString() ?? 'Task';
    final amount = double.tryParse(contract['amount']?.toString() ?? '0') ?? 0.0;
    final freelancerName = contract['freelancer_name']?.toString() ?? 'Freelancer';
    final freelancerId = contract['freelancer_id']?.toString() ?? '0';
    
    // Get freelancer email
    final freelancerEmail = contract['freelancer_email']?.toString() ?? '';
    
    // Get freelancer photo
    final freelancerPhotoUrl = contract['freelancer_photo']?.toString() ?? '';
    
    // Get user data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    final authToken = prefs.getString('user_token') ?? '';
    
    // DEBUG: Check what we're getting
    print('📦 Navigate to Payment DEBUG INFO:');
    print('   Contract ID: $contractId');
    print('   Amount: $amount');
    print('   Freelancer: $freelancerName ($freelancerId)');
    print('   Freelancer Email: $freelancerEmail');
    print('   User Email from SharedPreferences: $email');
    print('   Auth Token from SharedPreferences: ${authToken.isNotEmpty ? "FOUND" : "NOT FOUND"}');
    
    // Check if email is empty - show error if it is
    if (email.isEmpty) {
      print('❌ ERROR: User email is empty!');
      
      // Show a dialog to enter email
      final enteredEmail = await _showEmailInputDialog(context);
      if (enteredEmail != null && enteredEmail.isNotEmpty) {
        // Save the entered email
        await prefs.setString('user_email', enteredEmail);
        
        print('✅ User entered email: $enteredEmail');
        
        // Get order from API and proceed with payment
        await _getOrderAndProceed(
          context: context,
          contractId: contractId,
          taskTitle: taskTitle,
          amount: amount,
          freelancerName: freelancerName,
          freelancerId: freelancerId,
          freelancerEmail: freelancerEmail,
          freelancerPhotoUrl: freelancerPhotoUrl,
          email: enteredEmail,
          authToken: authToken,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is required for payment. Please enter your email.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // All good, get order from API and proceed with payment
    await _getOrderAndProceed(
      context: context,
      contractId: contractId,
      taskTitle: taskTitle,
      amount: amount,
      freelancerName: freelancerName,
      freelancerId: freelancerId,
      freelancerEmail: freelancerEmail,
      freelancerPhotoUrl: freelancerPhotoUrl,
      email: email,
      authToken: authToken,
    );
    
  } catch (e) {
    print('❌ Error navigating to payment: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error opening payment: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Helper method to get order from API and proceed
Future<void> _getOrderAndProceed({
  required BuildContext context,
  required String contractId,
  required String taskTitle,
  required double amount,
  required String freelancerName,
  required String freelancerId,
  required String freelancerEmail,
  required String freelancerPhotoUrl,
  required String email,
  required String authToken,
}) async {
  String orderId = '';
  double orderAmount = amount;
  
  try {
    print('📡 Calling get-order-for-contract API for contract $contractId');
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    // Make API call to get order for contract
    final orderResponse = await _callGetOrderApi(
      authToken: authToken,
      contractId: contractId,
    );
    
    // Close loading
    Navigator.pop(context);
    
    if (orderResponse['status'] == true) {
      orderId = orderResponse['order']['order_id']?.toString() ?? '';
      orderAmount = orderResponse['order']['amount']?.toDouble() ?? amount;
      
      print('✅ Got order ID from API: $orderId');
      print('✅ Valid UUID: ${_isValidUuid(orderId)}');
      print('✅ Order amount: $orderAmount');
    } else {
      throw Exception('Failed to get order: ${orderResponse['message']}');
    }
  } catch (e) {
    // Close loading if still open
    if (Navigator.canPop(context)) Navigator.pop(context);
    
    print('❌ Error getting order: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create payment order: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Validate the order ID (after getting it from API)
  if (!_isValidUuid(orderId)) {
    print('❌ ERROR: Invalid order ID from API: $orderId');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid order ID from server.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Proceed to payment with valid order ID
  _proceedWithPayment(
    context,
    contractId: contractId,
    taskTitle: taskTitle,
    orderId: orderId,
    amount: orderAmount,
    freelancerName: freelancerName,
    freelancerId: freelancerId,
    freelancerEmail: freelancerEmail,
    freelancerPhotoUrl: freelancerPhotoUrl,
    email: email,
    authToken: authToken,
  );
}

// API call to get order for contract
Future<Map<String, dynamic>> _callGetOrderApi({
  required String authToken,
  required String contractId,
}) async {
  try {
    // Call your Django backend API
    // Update the URL to match your Django server
    //final url = Uri.parse('https://marketplace-system-1.onrender.com/contracts/$contractId/order/');
    final url = Uri.parse('http://192.168.100.188:8000/contracts/$contractId/order/');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );
    
    print('🔵 API Response Status: ${response.statusCode}');
    print('🔵 API Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get order. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ API Call Error: $e');
    rethrow;
  }
}

// Helper method to show email input dialog
Future<String?> _showEmailInputDialog(BuildContext context) async {
  String? email;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Email Address'),
      content: TextField(
        onChanged: (value) => email = value,
        decoration: const InputDecoration(
          hintText: 'your.email@example.com',
          labelText: 'Email',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (email != null && email!.isNotEmpty && email!.contains('@')) {
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid email address'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return email;
}

// Helper method to actually navigate to payment screen
void _proceedWithPayment(
  BuildContext context, {
  required String contractId,
  required String taskTitle,
  required String orderId,
  required double amount,
  required String freelancerName,
  required String freelancerId,
  required String freelancerEmail,
  required String freelancerPhotoUrl,
  required String email,
  required String authToken,
}) {
  print('✅ Proceeding to PaymentScreen with:');
  print('   Contract ID: $contractId');
  print('   Order ID: $orderId');
  print('   Amount: $amount');
  print('   Email: $email');
  print('   Auth Token: ${authToken.isNotEmpty ? "Present" : "Missing"}');
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentScreen(
        orderId: orderId,
        amount: amount,
        freelancerName: freelancerName,
        freelancerId: freelancerId,
        contractId: contractId,
        taskTitle: taskTitle,
        isValidOrderId: true,
        freelancerEmail: freelancerEmail,
        freelancerPhotoUrl: freelancerPhotoUrl,
        email: email,
        authToken: authToken,
        serviceDescription: taskTitle,
      ),
    ),
  );
}

  // ============ MAIN BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Contracts & Payments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<ClientContractProvider>(context, listen: false)
                  .fetchEmployerContracts();
            },
          )
        ],
      ),
      body: Consumer<ClientContractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.contracts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)),
            );
          }

          if (provider.errorMessage.isNotEmpty && provider.contracts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.fetchEmployerContracts();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final contracts = provider.contracts;
          
          // Filter: Show ALL contracts except paid & completed
          final activeContracts = contracts.where((c) {
            try {
              final isCompleted = c['is_completed'] == true || c['is_completed'] == 1;
              final isPaid = c['is_paid'] == true || c['is_paid'] == 1;
              return !(isCompleted && isPaid);
            } catch (e) {
              return true; // Include if there's an error
            }
          }).toList();

          // Statistics
          final stats = _calculateStats(contracts);

          return RefreshIndicator(
            onRefresh: () => provider.fetchEmployerContracts(),
            color: _primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsCards(stats),
                  const SizedBox(height: 20),
                  
                  if (activeContracts.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeContracts.length,
                      itemBuilder: (context, index) {
                        return _buildContractCard(context, activeContracts[index]);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ STATS CALCULATION ============
  Map<String, int> _calculateStats(List<dynamic> contracts) {
    int toComplete = 0;
    int toPay = 0;
    int paid = 0;

    for (var contract in contracts) {
      try {
        final isCompleted = contract['is_completed'] == true || contract['is_completed'] == 1;
        final isPaid = contract['is_paid'] == true || contract['is_paid'] == 1;

        if (isCompleted && isPaid) {
          paid++;
        } else if (isCompleted && !isPaid) {
          toPay++;
        } else {
          toComplete++;
        }
      } catch (e) {
        toComplete++; // Default to "to complete" if there's an error
      }
    }

    return {
      'total': contracts.length,
      'toComplete': toComplete,
      'toPay': toPay,
      'paid': paid,
    };
  }

  // ============ UI COMPONENTS ============
  Widget _buildStatsCards(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('To Complete', stats['toComplete'] ?? 0, 
              Icons.check_circle_outline, _lightBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('To Pay', stats['toPay'] ?? 0, 
              Icons.payment, _primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Paid', stats['paid'] ?? 0, 
              Icons.verified, _greenColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, Map<String, dynamic> contract) {
    try {
      final contractId = int.tryParse(contract['contract_id']?.toString() ?? '0') ?? 0;
      final taskTitle = contract['task_title']?.toString() ?? 'Task';
      final freelancerName = contract['freelancer_name']?.toString() ?? 'Freelancer';
      final amount = double.tryParse(contract['amount']?.toString() ?? '0') ?? 0.0;
      final isCompleted = contract['is_completed'] == true || contract['is_completed'] == 1;
      final isPaid = contract['is_paid'] == true || contract['is_paid'] == 1;
      final completedDate = contract['completed_date']?.toString();
      final paymentDate = contract['payment_date']?.toString();

      final statusText = _getStatusText(contract);
      final statusColor = _getStatusColor(contract);
      final actionButtonText = _getActionButtonText(contract);

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _lightBlue.withOpacity(0.5), width: 1.5),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      taskTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Freelancer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: _subtitleColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Freelancer: $freelancerName',
                      style: TextStyle(color: _subtitleColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Amount Info
              Row(
                children: [
                  Icon(Icons.attach_money_rounded, size: 16, color: _subtitleColor),
                  const SizedBox(width: 8),
                  Text(
                    'KSh ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isPaid && paymentDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: _greenColor),
                    const SizedBox(width: 8),
                    Text(
                      'Paid: ${_formatDate(paymentDate)}',
                      style: TextStyle(color: _greenColor, fontSize: 12),
                    ),
                  ],
                ],
              ),

              if (isCompleted && completedDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: _lightBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Completed: ${_formatDate(completedDate)}',
                      style: TextStyle(color: _lightBlue, fontSize: 12),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action Button - Shows different actions based on contract state
              if (!isPaid || !isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isCompleted && !isPaid) {
                        // Navigate to payment screen
                        _navigateToPaymentScreen(context, contract);
                      } else if (!isCompleted) {
                        // Mark as completed
                        _showCompletionDialog(context, contractId, taskTitle);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted && !isPaid ? _primaryBlue : _lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(actionButtonText),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Return an error card if there's an issue with the contract data
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error loading contract',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There was an error loading this contract. Please try refreshing.',
                style: TextStyle(color: _subtitleColor),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Helper method to safely format dates
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'All contracts are settled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No contracts need completion or payment',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtitleColor),
          ),
        ],
      ),
    );
  }
}