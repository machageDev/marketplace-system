import 'package:flutter/material.dart';
import 'package:helawork/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService walletService;
  
  // Internal State
  String? _token;
  double _balance = 0.0;
  bool _loading = false;
  bool _initialized = false;
  Map<String, dynamic>? _walletData;

  // Getters for UI
  double get balance => _balance;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get token => _token;
  Map<String, dynamic>? get walletData => _walletData;

  WalletProvider({required this.walletService});

  // --- INITIALIZATION & TOKEN MANAGEMENT ---

  /// Initialize the provider with a token
  void initialize(String token) {
    if (token.isEmpty) {
      debugPrint("⚠️ WalletProvider: Attempted to initialize with empty token.");
      return;
    }
    
    if (_token != token || !_initialized) {
      _token = token;
      _initialized = true;
      debugPrint("✅ WalletProvider initialized with token");
      loadWallet(); // Don't pass token, use _token
    }
  }

  /// Check if provider is ready
  bool get isReady => _token != null && _token!.isNotEmpty && _initialized;

  /// Update token and reload data
  void updateToken(String newToken) {
    if (newToken.isEmpty) return;
    _token = newToken;
    _initialized = true;
    loadWallet();
  }

  /// Check if user has bank account
  bool get hasBankAccount {
    if (_walletData == null) return false;
    return _walletData?['bank_verified'] == true || 
           _walletData?['is_paystack_setup'] == true ||
           (_walletData?['bank_name'] != null && _walletData?['bank_name'] != "Not Linked");
  }

  /// Get bank info
  Map<String, dynamic>? get bankInfo {
    if (!hasBankAccount) return null;
    return {
      'bank_name': _walletData?['bank_name'] ?? 'Linked Account',
      'account_last_4': _walletData?['account_last_4'] ?? '****',
      'verified_at': _walletData?['bank_verified_at'] ?? 'Verified (Test Mode)',
    };
  }
  
  // --- CORE API METHODS ---

  /// Fetches wallet data from the backend
  Future<void> loadWallet() async {
    // Only proceed if we have a valid token
    if (_token == null || _token!.isEmpty) {
      debugPrint("⏳ WalletProvider: No token available yet");
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      debugPrint("🛰️ Syncing Wallet (Token: ${_token!.substring(0, 5)}...)");
      
      final responseBody = await walletService.getWalletData(_token!);
      
      if (responseBody != null) {
        final dynamic nestedData = responseBody['data'];

        if (nestedData != null && nestedData is Map<String, dynamic>) {
          _walletData = nestedData;
          _balance = double.tryParse(nestedData['balance']?.toString() ?? '0') ?? 0.0;
        } else {
          _walletData = responseBody;
          _balance = double.tryParse(responseBody['balance']?.toString() ?? '0') ?? 0.0;
        }

        debugPrint("✅ WALLET UPDATED: KES $_balance");
      }
    } catch (e) {
      debugPrint("❌ WalletProvider Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh wallet data (called from UI)
  Future<void> refresh() async {
    if (_token == null || _token!.isEmpty) {
      debugPrint("! WalletScreen: Cannot refresh, token is empty.");
      return;
    }
    await loadWallet();
  }

  // --- USER ACTIONS ---

  /// Requests a payment URL for topping up the wallet
  Future<String?> topUp(double amount) async {
    if (amount <= 0 || _token == null) {
      debugPrint("❌ Top Up failed: Invalid amount or missing token.");
      return null;
    }
    return await walletService.topUp(_token!, amount);
  }

  /// Initiates a withdrawal to the registered bank account
  Future<bool> withdraw(double amount) async {
    if (amount <= 0 || amount > _balance || _token == null) {
      debugPrint("❌ Withdrawal failed: Insufficient funds.");
      return false;
    }
    
    if (!hasBankAccount) {
      debugPrint("❌ Withdrawal failed: No bank account linked.");
      return false;
    }

    final success = await walletService.withdraw(_token!, amount);
    if (success) {
      await loadWallet(); 
    }
    return success;
  }

  /// Updates local state manually after a successful bank registration
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