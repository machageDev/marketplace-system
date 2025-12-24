import 'package:flutter/material.dart';
import 'package:helawork/payment_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String email;
  final String freelancerName;
  final String serviceDescription;
  final String freelancerPhotoUrl;
  final String currency;
  final PaymentService paymentService;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.email,
    required this.freelancerName,
    required this.serviceDescription,
    required this.freelancerPhotoUrl,
    this.currency = 'KSH',
    required this.paymentService, required String authToken,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _paymentInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      print('PAYMENT DEBUG');
      print('Order ID: "${widget.orderId}"');
      print('Email: "${widget.email}"');
      print('Order ID is empty: ${widget.orderId.isEmpty}');
      print('Email is empty: ${widget.email.isEmpty}');
      
      if (widget.orderId.isEmpty) {
        setState(() {
          _errorMessage = 'Order ID is missing. Please try again.';
          _isLoading = false;
        });
        return;
      }
      
      if (widget.email.isEmpty) {
        setState(() {
          _errorMessage = 'Email is required for payment.';
          _isLoading = false;
        });
        return;
      }
      
      print('Proceeding with payment...');
      
      final response = await widget.paymentService.initializePayment(
        orderId: widget.orderId,
        email: widget.email,
      );
      
      print('Payment result: $response');
      
      if (response['status'] == true) {
        final authUrl = response['data']['authorization_url'];
        
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
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _handlePaymentResponse(String url) {
    if (url.contains('/api/payment/verify/')) {
      if (url.contains('success') || !url.contains('failed')) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
      }
    }
    
    if (url.contains('callback') && url.contains('success')) {
      Navigator.pop(context, true);
    } else if (url.contains('callback') && url.contains('failed')) {
      Navigator.pop(context, false);
    }
  }

  void _retryPayment() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _paymentInitialized = false;
    });
    _initializePayment();
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

  String _formatAmount(double amount) {
    return '${_getCurrencySymbol()}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _errorMessage != null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Colors.blueAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Payment Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(widget.freelancerPhotoUrl),
                                  radius: 24,
                                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Paying: ${widget.freelancerName}',
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
                                          color: Colors.blueAccent.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                _buildAmountRow(
                                  'Service Amount', 
                                  _formatAmount(widget.amount * 0.9),
                                ),
                                const SizedBox(height: 12),
                                _buildAmountRow(
                                  'Platform Fee (10%)', 
                                  _formatAmount(widget.amount * 0.1),
                                ),
                                const Divider(height: 20, color: Colors.blueAccent),
                                _buildAmountRow(
                                  'TOTAL AMOUNT', 
                                  _formatAmount(widget.amount), 
                                  isTotal: true
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You will be redirected to complete payment securely',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Stack(
                      children: [
                        if (_paymentInitialized) WebViewWidget(controller: controller),
                        if (_isLoading)
                          Container(
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _paymentInitialized 
                                        ? 'Processing payment...' 
                                        : 'Initializing payment...',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
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
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.8),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.8),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}