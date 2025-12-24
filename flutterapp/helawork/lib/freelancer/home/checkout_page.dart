import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback? onSuccess;

  const CheckoutPage({super.key, required this.paymentUrl, this.onSuccess});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => isLoading = true),
          onPageFinished: (url) {
            setState(() => isLoading = false);
            if (url.contains('success') || url.contains('completed')) {
              widget.onSuccess?.call();
              if (context.mounted) Navigator.pop(context);
            } else if (url.contains('cancel') || url.contains('failed')) {
              if (context.mounted) Navigator.pop(context);
            }
          },
          onWebResourceError: (error) {
            setState(() => isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment error: ${error.description}")),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            ),
        ],
      ),
    );
  }
}