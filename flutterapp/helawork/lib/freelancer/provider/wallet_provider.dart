import 'package:flutter/material.dart';
import 'package:helawork/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService walletService;
  String? _token;

  double balance = 0.0;
  bool loading = true;
  Map<String, dynamic>? _walletData; 

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

  // Update token when it changes
  void updateToken(String newToken) {
    _token = newToken;
    loadWallet();
  }

  // ✅ ADD THIS GETTER
  bool get hasBankAccount {
    // Check from wallet data if bank is verified
    return _walletData?['bank_verified'] == true || 
           _walletData?['paystack_recipient_code'] != null;
  }

  // Get bank details (optional)
  Map<String, dynamic>? get bankInfo {
    if (!hasBankAccount) return null;
    return {
      'bank_name': _walletData?['bank_name'],
      'account_last_4': _walletData?['account_last_4'],
      'verified_at': _walletData?['bank_verified_at'],
    };
  }

  // Update loadWallet to store full data
  Future<void> loadWallet() async {
    if (_token == null) return;
    
    loading = true;
    notifyListeners();

    try {
      // Call API to get full wallet data including bank info
      final walletResponse = await walletService.getWalletData(_token!);
      
      if (walletResponse != null) {
        // Store the full data
        _walletData = walletResponse;
        
        // Extract balance
        balance = (walletResponse['balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        balance = 0.0;
        _walletData = null;
      }
    } catch (e) {
      balance = 0.0;
      _walletData = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Top-up wallet
  Future<String?> topUp(double amount) async {
    if (amount <= 0 || _token == null) return null;
    return await walletService.topUp(_token!, amount);
  }

  // Withdraw funds
  Future<bool> withdraw(double amount) async {
    if (amount <= 0 || amount > balance || _token == null) return false;
    
    // Optional: Check if bank is registered before withdrawing
    if (!hasBankAccount) {
      throw Exception('Bank account is required for withdrawal');
    }

    final success = await walletService.withdraw(_token!, amount);
    if (success) await loadWallet();
    return success;
  }

  // ✅ ADD THIS: Update bank account status after registration
  void updateBankAccountStatus(Map<String, dynamic> bankData) {
    _walletData ??= {};
    
    _walletData!.addAll({
      'bank_verified': true,
      'bank_name': bankData['bank_name'],
      'account_last_4': bankData['account_last_4'],
      'paystack_recipient_code': bankData['recipient_code'],
      'bank_verified_at': DateTime.now().toIso8601String(),
    });
    
    notifyListeners();
  }
}