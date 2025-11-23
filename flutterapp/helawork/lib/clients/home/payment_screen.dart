import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String email;

  const PaymentScreen({Key? key, required this.amount, required this.email}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final response = await PaymentService.initializePayment(
        amount: widget.amount,
        email: widget.email,
      );
      
      final authorizationUrl = response['authorization_url'];
      
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              // Check for payment completion
              if (request.url.contains('callback')) {
                _verifyPayment(response['reference']);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(authorizationUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _verifyPayment(String reference) async {
    try {
      final response = await PaymentService.verifyPayment(reference);
      
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Successful!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: ${response['message']}')),
        );
        Navigator.pop(context, false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Error: $e')),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Payment'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}