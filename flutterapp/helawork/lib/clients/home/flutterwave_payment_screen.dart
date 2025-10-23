import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlutterwavePaymentScreen extends StatelessWidget {
  final String paymentUrl;

  const FlutterwavePaymentScreen({super.key, required this.paymentUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(paymentUrl)),
      ),
    );
  }
}
