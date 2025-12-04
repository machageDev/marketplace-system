import 'package:flutter/material.dart';
import 'package:helawork/services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService walletService;
  String? _token;

  double balance = 0.0;
  bool loading = true;

  WalletProvider._internal({
    required this.walletService,
  });

  factory WalletProvider.create({
    required WalletService walletService,
    required String token,
  }) {
    final provider = WalletProvider._internal(walletService: walletService);
    provider.initialize(token);
    return provider;
  }

  void initialize(String token) {
    _token = token;
    loadWallet();
  }

  // Update token when it changes (e.g., after login)
  void updateToken(String newToken) {
    _token = newToken;
    loadWallet();
  }

  // Load wallet balance
  Future<void> loadWallet() async {
    if (_token == null) return;
    
    loading = true;
    notifyListeners();

    try {
      final bal = await walletService.getBalance(_token!);
      balance = bal ?? 0.0;
    } catch (e) {
      balance = 0.0;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Top-up wallet (returns payment URL)
  Future<String?> topUp(double amount) async {
    if (amount <= 0 || _token == null) return null;
    return await walletService.topUp(_token!, amount);
  }

  // Withdraw funds
  Future<bool> withdraw(double amount) async {
    if (amount <= 0 || amount > balance || _token == null) return false;

    final success = await walletService.withdraw(_token!, amount);
    if (success) await loadWallet();
    return success;
  }
}