import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/wallet_screen.dart';
import 'package:helawork/services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService walletService;
  final String token;

  double balance = 0.0;
  bool loading = true;

  WalletProvider({required this.walletService, required this.token, required WalletScreen child}) {
    loadWallet();
  }

  // Load wallet balance from backend
  Future<void> loadWallet() async {
    loading = true;
    notifyListeners();

    try {
      double? bal = await walletService.getBalance(token);
      balance = bal ?? 0.0;
    } catch (e) {
      balance = 0.0;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Top-up wallet
  Future<String?> topUp(double amount) async {
    if (amount <= 0) return null;
    return await walletService.topUp(token, amount);
  }

  // Withdraw from wallet
  Future<bool> withdraw(double amount) async {
    if (amount <= 0 || amount > balance) return false;
    bool success = await walletService.withdraw(token, amount);
    if (success) {
      await loadWallet(); // Refresh balance
    }
    return success;
  }
}
