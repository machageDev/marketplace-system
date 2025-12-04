import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'checkout_page.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, required String token});

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);

    void _showWithdrawDialog() {
      final amountController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Withdraw Funds'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount (Max: KES ${wallet.balance.toStringAsFixed(2)})',
              prefixText: 'KES ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                Navigator.pop(context);
                bool success = await wallet.withdraw(amount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Withdrawal successful" : "Withdrawal failed"),
                  ),
                );
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      );
    }

    void _showTopUpDialog() {
      final amountController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Top Up Wallet'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              prefixText: 'KES ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                Navigator.pop(context);
                String? url = await wallet.topUp(amount);
                if (url != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(paymentUrl: url, onSuccess: wallet.loadWallet),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Top-up failed")),
                  );
                }
              },
              child: const Text('Top Up'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: wallet.loadWallet,
          ),
        ],
      ),
      body: wallet.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    color: const Color(0xFF1A1A1A),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('Available Balance', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 15),
                          Text('KES ${wallet.balance.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 40, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showTopUpDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Top Up'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showWithdrawDialog,
                        icon: const Icon(Icons.arrow_circle_down_outlined),
                        label: const Text('Withdraw'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
