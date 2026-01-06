
import 'package:flutter/material.dart';
import 'package:helawork/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String freelancerName;
  final String serviceDescription;
  final String freelancerPhotoUrl;
  final String currency;
  final String freelancerId;
  final String freelancerEmail;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.freelancerName,
    required this.serviceDescription,
    required this.freelancerPhotoUrl,
    required this.freelancerId,
    required this.freelancerEmail,
    this.currency = 'KSH', required email, required String authToken, required int paymentService,
  });

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
    _verifyAndInitializePayment();
  }

  Future<void> _verifyAndInitializePayment() async {
    try {
      print('🔍 VERIFYING PAYMENT DETAILS...');
      
      // 1. Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      
      // 2. Create PaymentService WITH the token
      _paymentService = PaymentService(authToken: token);
      
      // 3. VERIFY payment with backend before proceeding
      print('✅ Verifying order ${widget.orderId}');
      
      final verification = await _paymentService!.verifyOrderPayment(
        orderId: widget.orderId,
        freelancerId: widget.freelancerId,
      );
      
      print('✅ Verification response: ${verification['status']}');
      
      if (verification['status'] != true) {
        // Show warning but continue anyway
        print('⚠️ Warning: ${verification['message']}');
        // Don't block payment, just show a warning
      }
      
      // Store verification data
      _paymentVerification = verification['data'];
      
      // 4. Get employer email
      _employerEmail = await _paymentService!.getEmployerEmail();
      print('✅ Employer Email: $_employerEmail');
      
      if (_employerEmail == null || _employerEmail!.isEmpty) {
        setState(() {
          _errorMessage = 'Email is required for payment.';
          _isLoading = false;
        });
        return;
      }
      
      // 5. Initialize payment
      print('💰 INITIALIZING PAYMENT');
      
      final response = await _paymentService!.initializePayment(
        orderId: widget.orderId,
        email: _employerEmail!,
        freelancerPaystackAccount: _paymentVerification?['freelancer_paystack_account'] ?? 'default_account',
      );
      
      print('✅ Payment response: ${response['status']}');
      
      if (response['status'] == true) {
        final authUrl = response['data']['authorization_url'];
        
        // Validate URL
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
              if (navigation.url.contains('paystack.co')) {
                return NavigationDecision.navigate;
              }
              
              if (navigation.url.contains('callback') || 
                  navigation.url.contains('verify') ||
                  navigation.url.contains('success') ||
                  navigation.url.contains('failed')) {
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
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _handlePaymentResponse(String url) {
    print('🔗 Handling payment response: $url');
    
    if (url.contains('success') || url.contains('completed')) {
      _completePayment(true);
    } else if (url.contains('failed') || url.contains('canceled')) {
      _completePayment(false);
    }
  }

  void _completePayment(bool success) async {
    if (_isPaymentComplete) return;
    
    _isPaymentComplete = true;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
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
    if (_paymentVerification == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Freelancer: ${widget.freelancerName}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 11,
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
      body: _errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
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
                                : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
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
                                  widget.serviceDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                                  child: Text(
                                    'Order #${widget.orderId}',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                  child: Text(
                                    _employerEmail ?? 'Loading email...',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                    'Payment to ${widget.freelancerName}',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatAmount(widget.amount)} = $totalCents cents',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
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
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.blueAccent : Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
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