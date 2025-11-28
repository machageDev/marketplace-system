import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String email;
  final String freelancerName;
  final String serviceDescription;
  final String freelancerPhotoUrl;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.email,
    required this.freelancerName,
    required this.serviceDescription,
    required this.freelancerPhotoUrl,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    final paymentUrl = 'http://192.168.100.188:8000/payment/${widget.orderId}?email=${Uri.encodeComponent(widget.email)}&amount=${widget.amount}';
    
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _isLoading = true);
        },
        onPageFinished: (String url) {
          setState(() => _isLoading = false);
          if (url.contains('payment-success')) {
            Navigator.pop(context, true);
          } else if (url.contains('payment-failed')) {
            Navigator.pop(context, false);
          }
        },
      ))
      ..loadRequest(Uri.parse(paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Confirm Payment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // PAYMENT SUMMARY SECTION
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
                    
                    // Freelancer Info
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
                    
                    // Amount Breakdown
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
                            '₦${(widget.amount * 0.9).toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          _buildAmountRow(
                            'Platform Fee (10%)', 
                            '₦${(widget.amount * 0.1).toStringAsFixed(2)}',
                          ),
                          const Divider(height: 20, color: Colors.blueAccent),
                          _buildAmountRow(
                            'TOTAL AMOUNT', 
                            '₦${widget.amount.toStringAsFixed(2)}', 
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
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.blueAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
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
          
          // WEBVIEW SECTION - Fixed Height
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
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
                              'Loading secure payment...',
                              style: TextStyle(
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
          
          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
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