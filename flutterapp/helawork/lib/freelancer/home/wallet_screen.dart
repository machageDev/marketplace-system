import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'checkout_page.dart';
import 'bank_registration_screen.dart';

class WalletScreen extends StatefulWidget {
  // REMOVED: final String token;
  const WalletScreen({super.key}); // No token parameter!

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    // Just refresh - token comes from ProxyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  // REMOVED: _initializeWallet() - not needed with ProxyProvider

  // Centralized refresh logic - NO TOKEN PARAMETER
  Future<void> _refreshData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // Check if provider is initialized, if not - wait for ProxyProvider
    if (!walletProvider.initialized) {
      debugPrint("⏳ WalletScreen: Waiting for WalletProvider to initialize...");
      // Try again in 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _refreshData();
      });
      return;
    }
    
    await walletProvider.refresh();
  }

  // --- NAVIGATION METHODS ---
  // NO TOKEN PASSING - ProxyProvider handles it
  void _navigateToBankRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BankRegistrationScreen(token: '',), // No token!
      ),
    ).then((refresh) {
      if (refresh == true) _refreshData();
    });
  }

  // --- DIALOG METHODS ---
  // (These remain the same - they don't need token)
  void _showNoBankAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Account Required'),
        content: const Text(
          'Register a bank account to enable direct withdrawals to your account.',
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
            child: const Text('Add Bank'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletProvider wallet) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Max: KES ${wallet.balance.toStringAsFixed(2)}',
            prefixText: 'KES ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0 || amount > wallet.balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid amount")),
                );
                return;
              }
              Navigator.pop(context);
              bool success = await wallet.withdraw(amount);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? Colors.green : Colors.red,
                    content: Text(success ? "Withdrawal initiated successfully" : "Withdrawal failed"),
                  ),
                );
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WalletProvider wallet) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter amount', prefixText: 'KES '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Minimum top up is KES 10")),
                );
                return;
              }
              Navigator.pop(context);
              String? url = await wallet.topUp(amount);
              if (url != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      paymentUrl: url,
                      onSuccess: _refreshData,
                    ),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not generate payment link")),
                );
              }
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    // Listen to changes in WalletProvider
    final wallet = Provider.of<WalletProvider>(context);
    
    // NO MANUAL INITIALIZATION - ProxyProvider handles it

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: wallet.loading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh), 
            onPressed: wallet.loading ? null : _refreshData,
          ),
        ],
      ),
      body: wallet.loading && wallet.balance == 0 && !wallet.initialized
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildBalanceCard(wallet),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _actionButton(
                          icon: Icons.account_balance,
                          label: wallet.hasBankAccount ? 'Update Bank' : 'Add Bank',
                          color: wallet.hasBankAccount ? Colors.blueGrey : Colors.green,
                          textColor: Colors.white,
                          onPressed: () => _navigateToBankRegistration(context),
                        ),
                        _actionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Top Up',
                          onPressed: () => _showTopUpDialog(context, wallet),
                        ),
                        _actionButton(
                          icon: Icons.arrow_circle_down_outlined,
                          label: 'Withdraw',
                          color: wallet.hasBankAccount ? Colors.blue : Colors.grey.shade400,
                          onPressed: wallet.hasBankAccount
                              ? () => _showWithdrawDialog(context, wallet)
                              : () => _showNoBankAlert(context),
                        ),
                      ],
                    ),
                    if (!wallet.hasBankAccount) ...[
                      const SizedBox(height: 30),
                      _buildWarningBox(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI COMPONENTS --- (These remain exactly the same)
  Widget _buildBalanceCard(WalletProvider wallet) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'KES ${wallet.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            if (wallet.hasBankAccount)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('Bank verified', style: TextStyle(color: Colors.green.shade400)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
  }) {
    return SizedBox(
      width: 155,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.black,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Withdrawals are disabled until you link a verified bank account.',
              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}