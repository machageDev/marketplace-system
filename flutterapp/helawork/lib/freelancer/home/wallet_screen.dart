import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'checkout_page.dart';
import 'bank_registration_screen.dart'; // Add this import

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, required String token});

  // Navigation methods
  void _navigateToBankRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BankRegistrationScreen(),
      ),
    ).then((refresh) {
      if (refresh == true) {
        // Reload wallet data if bank was successfully added
        final wallet = Provider.of<WalletProvider>(context, listen: false);
        wallet.loadWallet();
      }
    });
  }

  void _showNoBankAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Account Required'),
        content: const Text(
          'You need to register a bank account before you can withdraw funds.\n\n'
          'This ensures your payments go directly to your verified bank account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToBankRegistration(context);
            },
            child: const Text('Add Bank Account'),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void showWithdrawDialog(BuildContext context, WalletProvider wallet) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  void showTopUpDialog(BuildContext context, WalletProvider wallet) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(context);
              String? url = await wallet.topUp(amount);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutPage(
                    paymentUrl: url ?? '',
                    onSuccess: wallet.loadWallet,
                  ),
                ),
              );
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: wallet.loadWallet,
          ),
        ],
      ),
      body: wallet.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Balance Card
                    Card(
                      color: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'KES ${wallet.balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.blueAccent,
                              ),
                            ),
                            // Bank Status Indicator (Optional)
                            if (wallet.hasBankAccount)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.green.shade400,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Bank account verified',
                                      style: TextStyle(
                                        color: Colors.green.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Action Buttons Row - FIXED WITH WRAP
                    Wrap(
                      spacing: 12, // Horizontal spacing between buttons
                      runSpacing: 12, // Vertical spacing if buttons wrap
                      alignment: WrapAlignment.center,
                      children: [
                        // Bank Registration Button
                        SizedBox(
                          width: 140, // Fixed width for buttons
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToBankRegistration(context),
                            icon: const Icon(Icons.account_balance, size: 20),
                            label: const Text('Add Bank', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: wallet.hasBankAccount 
                                  ? Colors.grey.shade300 
                                  : Colors.green,
                              foregroundColor: wallet.hasBankAccount 
                                  ? Colors.grey.shade600 
                                  : Colors.white,
                            ),
                          ),
                        ),
                        
                        // Top Up Button
                        SizedBox(
                          width: 140,
                          child: ElevatedButton.icon(
                            onPressed: () => showTopUpDialog(context, wallet),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('Top Up', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        
                        // Withdraw Button
                        SizedBox(
                          width: 140,
                          child: ElevatedButton.icon(
                            onPressed: wallet.hasBankAccount
                                ? () => showWithdrawDialog(context, wallet)
                                : () => _showNoBankAlert(context),
                            icon: const Icon(Icons.arrow_circle_down_outlined, size: 20),
                            label: const Text('Withdraw', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: wallet.hasBankAccount
                                  ? null
                                  : Colors.grey.shade300,
                              foregroundColor: wallet.hasBankAccount
                                  ? null
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Alternative: Single column layout for very small screens
                    /* Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToBankRegistration(context),
                            icon: const Icon(Icons.account_balance),
                            label: const Text('Add Bank Account'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showTopUpDialog(context, wallet),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Top Up Wallet'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: wallet.hasBankAccount
                                ? () => showWithdrawDialog(context, wallet)
                                : () => _showNoBankAlert(context),
                            icon: const Icon(Icons.arrow_circle_down_outlined),
                            label: const Text('Withdraw Funds'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ), */
                    
                    // Additional Info (Optional)
                    if (!wallet.hasBankAccount) ...[
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.orange.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank Account Required',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add your bank details to withdraw your earnings',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}