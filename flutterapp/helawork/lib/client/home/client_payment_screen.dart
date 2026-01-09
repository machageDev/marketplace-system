import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:helawork/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String freelancerName;
  final String serviceDescription;
  final String freelancerPhotoUrl;
  final String currency;
  final String freelancerId;
  final String freelancerEmail;
  final String email;
  final String authToken;
  final String contractId;
  final String taskTitle;
  final bool isValidOrderId;

  PaymentScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.freelancerName,
    this.serviceDescription = '',
    this.freelancerPhotoUrl = '',
    this.currency = 'KSH',
    required this.freelancerId,
    this.freelancerEmail = '',
    this.email = '',
    this.authToken = '',
    required this.contractId,
    required this.taskTitle,
    required this.isValidOrderId,
  }) : super(key: key) {
    // Runtime validation
    if (orderId.isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Order ID cannot be empty');
    }
    if (!isValidOrderId) {
      throw ArgumentError.value(isValidOrderId, 'isValidOrderId', 'Must be true for valid orders');
    }
  }

  String get effectiveServiceDescription {
    if (serviceDescription.isNotEmpty) return serviceDescription;
    return taskTitle;
  }

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _paymentInitialized = false;
  String? _errorMessage;
  bool _isPaymentComplete = false;
  String? _employerEmail;
  PaymentService? _paymentService;
  Map<String, dynamic>? _paymentVerification;

  @override
  void initState() {
    super.initState();
    
    // Validate order ID immediately
    if (!widget.isValidOrderId || !_isValidUuid(widget.orderId)) {
      setState(() {
        _errorMessage = 'Invalid order ID. Please use a valid order ID from backend.';
        _isLoading = false;
      });
      return;
    }
    
    _verifyAndInitializePayment();
  }

  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }

  Future<void> _verifyAndInitializePayment() async {
    try {
      print('🔍 VERIFYING PAYMENT DETAILS...');
      print('📋 Contract ID: ${widget.contractId}');     
      print('📋 Order ID: ${widget.orderId} (Valid UUID: ${_isValidUuid(widget.orderId)})');
      print('👤 Freelancer ID: ${widget.freelancerId}');
      print('📝 Service: ${widget.effectiveServiceDescription}');
      
      final prefs = await SharedPreferences.getInstance();
      String token = widget.authToken;
      if (token.isEmpty) {
        token = prefs.getString('user_token') ?? '';
      }
      
      if (token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      
      _employerEmail = widget.email;
      if (_employerEmail!.isEmpty) {
        _employerEmail = prefs.getString('user_email') ?? '';
      }
      
      print('✅ Employer Email: $_employerEmail');
      
      if (_employerEmail == null || _employerEmail!.isEmpty) {
        final enteredEmail = await _showEmailInputDialog();
        if (enteredEmail != null && enteredEmail.isNotEmpty) {
          _employerEmail = enteredEmail;
          await prefs.setString('user_email', enteredEmail);
        } else {
          setState(() {
            _errorMessage = 'Email is required for payment.';
            _isLoading = false;
          });
          return;
        }
      }
      
      _paymentService = PaymentService(authToken: token);
      
      String freelancerPaystackAccount = 'default_account';
      
      if (widget.freelancerId.isNotEmpty && widget.freelancerId != '0') {
        print('✅ Verifying order payment...');
        
        final verification = await _paymentService!.verifyOrderPayment(
          orderId: widget.orderId,
          freelancerId: widget.freelancerId,
        );
        
        print('✅ Verification response: ${verification['status']}');
        print('✅ Verification message: ${verification['message']}');
        
        if (verification['status'] == true) {
          _paymentVerification = verification['data'];
          freelancerPaystackAccount = _paymentVerification?['freelancer_paystack_account'] ?? 'default_account';
          print('✅ Freelancer account: $freelancerPaystackAccount');
        } else {
          print('⚠️ Warning: ${verification['message']}');
        }
      } else {
        print('⚠️ Freelancer ID not provided, trying to fetch from order...');
        freelancerPaystackAccount = await _getFreelancerPaystackAccount();
      }
      
      print('💰 INITIALIZING PAYMENT');
      print('   Order: ${widget.orderId}');
      print('   Amount: ${widget.amount}');
      print('   Email: $_employerEmail');
      print('   Freelancer Account: $freelancerPaystackAccount');
      
      final response = await _paymentService!.initializePayment(
        orderId: widget.orderId,
        email: _employerEmail!,
        freelancerPaystackAccount: freelancerPaystackAccount,
      );
      
      print('✅ Payment response: ${response['status']}');
      print('✅ Payment message: ${response['message']}');
      
      if (response['status'] == true) {
        final authUrl = response['data']['authorization_url'];
        
        if (authUrl == null || authUrl.isEmpty) {
          setState(() {
            _errorMessage = 'Invalid payment URL received';
            _isLoading = false;
          });
          return;
        }
        
        if (!authUrl.contains('http')) {
          print('❌ ERROR: Invalid authorization URL: $authUrl');
          setState(() {
            _errorMessage = 'Invalid payment URL format';
            _isLoading = false;
          });
          return;
        }
        
        print('✅ Payment URL: $authUrl');
        
        controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
              _handlePaymentResponse(url);
            },
            onWebResourceError: (error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Payment loading error: ${error.description}';
              });
            },
            onNavigationRequest: (navigation) {
              print('🌐 Navigation to: ${navigation.url}');
              
              if (navigation.url.contains('paystack.co')) {
                return NavigationDecision.navigate;
              }
              
              if (navigation.url.contains('callback') || 
                  navigation.url.contains('verify') ||
                  navigation.url.contains('success') ||
                  navigation.url.contains('failed') ||
                  navigation.url.contains('cancel') ||
                  navigation.url.contains('close')) {
                _handlePaymentResponse(navigation.url);
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ))
          ..loadRequest(Uri.parse(authUrl));
          
        setState(() {
          _paymentInitialized = true;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Payment initialization failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ERROR in _verifyAndInitializePayment: $e');
      print('❌ Stack trace: ${e.toString()}');
      setState(() {
        _errorMessage = 'Error initializing payment: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String?> _showEmailInputDialog() async {
    String? email;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Email for Payment'),
        content: TextField(
          onChanged: (value) => email = value,
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
            border: OutlineInputBorder(),
            labelText: 'Email',
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

  Future<String> _getFreelancerPaystackAccount() async {
    try {
      final pendingOrders = await _paymentService!.getPendingOrders();
      
      for (var order in pendingOrders) {
        final orderId = order['order_id']?.toString() ?? order['id']?.toString();
        if (orderId == widget.orderId) {
          return order['freelancer_paystack_account'] ?? 
                 order['paystack_subaccount'] ??
                 order['freelancer']?['paystack_subaccount'] ??
                 'default_account';
        }
      }
      
      return 'default_account';
    } catch (e) {
      print('⚠️ Error getting freelancer account: $e');
      return 'default_account';
    }
  }

  void _handlePaymentResponse(String url) {
    print('🔗 Handling payment response: $url');
    
    if (url.contains('success') || url.contains('completed')) {
      _completePayment(true);
    } else if (url.contains('failed') || url.contains('canceled') || url.contains('cancelled')) {
      _completePayment(false);
    } else if (url.contains('close')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment window closed. Check your email for payment confirmation.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, false);
    }
  }

  void _completePayment(bool success) async {
    if (_isPaymentComplete) return;
    
    _isPaymentComplete = true;
    
    if (success) {
      try {
        if (_paymentService != null) {
          print('✅ Verifying payment for order: ${widget.orderId}');
          final verification = await _paymentService!.verifyPayment(widget.orderId);
          print('✅ Verification result: ${verification['status']}');
          print('✅ Verification message: ${verification['message']}');
          
          if (verification['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Payment successful! Order completed.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Payment may have succeeded but verification failed: ${verification['message']}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('⚠️ Error verifying payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment appears successful! Please check your order status.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Payment failed or was cancelled. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, false);
    }
  }

  void _retryPayment() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _paymentInitialized = false;
      _isPaymentComplete = false;
    });
    _verifyAndInitializePayment();
  }

  void _cancelPayment() {
    Navigator.pop(context, false);
  }

  String _getCurrencySymbol() {
    switch (widget.currency) {
      case 'USD':
        return '\$';
      case 'KSH':
        return 'KSh';
      default:
        return 'KSh';
    }
  }

  int _convertToCents(double amountKsh) {
    return (amountKsh * 100).round();
  }

  String _formatAmount(double amount) {
    return '${_getCurrencySymbol()}${amount.toStringAsFixed(2)}';
  }

  Widget _buildVerificationBadge() {
    final hasFreelancerId = widget.freelancerId.isNotEmpty && widget.freelancerId != '0';
    final isValidOrder = widget.isValidOrderId && _isValidUuid(widget.orderId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasFreelancerId && isValidOrder ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFreelancerId && isValidOrder ? Colors.green.shade100 : Colors.orange.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFreelancerId && isValidOrder ? Icons.verified : Icons.warning,
            color: hasFreelancerId && isValidOrder ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFreelancerId && isValidOrder ? 'Ready to Pay' : 'Payment Info Incomplete',
                  style: TextStyle(
                    color: hasFreelancerId && isValidOrder ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order: ${widget.orderId.substring(0, 8)}...',
                  style: TextStyle(
                    color: hasFreelancerId && isValidOrder ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 11,
                  ),
                ),
                if (!hasFreelancerId || !isValidOrder)
                  Text(
                    !isValidOrder ? 'Invalid order ID' : 'Missing freelancer ID',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCents = _convertToCents(widget.amount);
    final int freelancerCents = _convertToCents(widget.amount * 0.9);
    final int platformCents = _convertToCents(widget.amount * 0.1);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelPayment,
        ),
      ),
      body: SafeArea(
        child: _errorMessage != null
            ? _buildErrorState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top content section - this can scroll
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildVerificationBadge(),
                                          
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundImage: widget.freelancerPhotoUrl.isNotEmpty
                                                    ? NetworkImage(widget.freelancerPhotoUrl)
                                                    : null,
                                                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                                child: widget.freelancerPhotoUrl.isEmpty
                                                    ? const Icon(Icons.person, color: Colors.blueAccent)
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget.freelancerName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.blueAccent,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      widget.effectiveServiceDescription,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (widget.freelancerEmail.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        widget.freelancerEmail,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.receipt, color: Colors.blueAccent, size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Contract #${widget.contractId}',
                                                            style: TextStyle(
                                                              color: Colors.blueAccent,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Order #${widget.orderId.substring(0, 8)}...',
                                                            style: const TextStyle(
                                                              color: Colors.blueAccent,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.email, color: Colors.green, size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Paying from:',
                                                            style: TextStyle(
                                                              color: Colors.green.shade700,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                          Text(
                                                            _employerEmail ?? 'Loading...',
                                                            style: const TextStyle(
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.w500,
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
                                          
                                          const SizedBox(height: 16),
                                          
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info, color: Colors.blueAccent, size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '90/10 Split Payment',
                                                        style: TextStyle(
                                                          color: Colors.blueAccent,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '90% to freelancer, 10% platform fee',
                                                        style: TextStyle(
                                                          color: Colors.blueAccent,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          _buildAmountRowWithCents(
                                            'Service Fee (To ${widget.freelancerName})',
                                            widget.amount * 0.9,
                                            freelancerCents,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildAmountRowWithCents(
                                            'Platform Fee (10%)',
                                            widget.amount * 0.1,
                                            platformCents,
                                          ),
                                          const Divider(height: 20, thickness: 1),
                                          _buildAmountRowWithCents(
                                            'TOTAL AMOUNT',
                                            widget.amount,
                                            totalCents,
                                            isTotal: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Fixed height webview section
                            Container(
                              height: 300, // Fixed height for webview
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  if (_paymentInitialized)
                                    WebViewWidget(controller: controller),
                                  
                                  if (_isLoading)
                                    Container(
                                      color: Colors.white,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _paymentInitialized 
                                                  ? 'Loading payment gateway...' 
                                                  : 'Preparing payment...',
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Cancel button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              child: OutlinedButton(
                                onPressed: _cancelPayment,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Cancel Payment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Payment initialization failed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (!widget.isValidOrderId || !_isValidUuid(widget.orderId))
              const Column(
                children: [
                  Text(
                    'Note: Invalid order ID detected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please use a valid order ID from backend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _retryPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _cancelPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRowWithCents(String label, double amountKsh, int cents, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isTotal ? Colors.blueAccent : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                ),
              ),
            ),
            Text(
              _formatAmount(amountKsh),
              style: TextStyle(
                color: isTotal ? Colors.blueAccent : Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize: isTotal ? 18 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            '($cents cents)',
            style: TextStyle(
              color: isTotal ? Colors.blueAccent.withOpacity(0.8) : Colors.grey[600],
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}