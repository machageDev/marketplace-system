import 'package:flutter/material.dart';
import 'package:helawork/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService walletService;
  
  // Internal State
  String? _token;
  double _balance = 0.0;
  bool _loading = false;
  Map<String, dynamic>? _walletData;

  // Getters for UI
  double get balance => _balance;
  bool get loading => _loading;
  String? get token => _token;
  Map<String, dynamic>? get walletData => _walletData;

  WalletProvider._internal({required this.walletService});

  /// Factory constructor used for dependency injection
  factory WalletProvider.create({
    required WalletService walletService,
    required String token,
  }) {
    final provider = WalletProvider._internal(walletService: walletService);
    if (token.isNotEmpty) {
      provider._token = token;
      provider.initialize(token);
    }
    return provider;
  }

  // --- INITIALIZATION & TOKEN MANAGEMENT ---

  void initialize(String token) {
    if (token.isEmpty) {
      debugPrint("⚠️ WalletProvider: Attempted to initialize with empty token.");
      return;
    }
    _token = token;
    loadWallet(token: token);
  }

  void updateToken(String newToken) {
    if (newToken.isEmpty) return;
    _token = newToken;
    loadWallet(token: newToken);
  }

 /// Updated to check the exact keys we set in the Django Shell
  bool get hasBankAccount {
    if (_walletData == null) return false;
    return _walletData?['bank_verified'] == true || 
           _walletData?['is_paystack_setup'] == true || // <--- ADD THIS
           (_walletData?['bank_name'] != null && _walletData?['bank_name'] != "Not Linked");
  }

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
  Future<void> loadWallet({String? token}) async {
    String? authToken = (token != null && token.isNotEmpty) ? token : _token;

    // FIX: Guard against null token to stop logs spamming
    if (authToken == null || authToken.isEmpty) {
      debugPrint("⏳ WalletProvider: Waiting for token...");
      return; 
    }

    _loading = true;
    notifyListeners();

    try {
      debugPrint("🛰️ Syncing Wallet for Micah (Token: ${authToken.substring(0, 5)}...)");
      
      final responseBody = await walletService.getWalletData(authToken);
      
      if (responseBody != null) {
        // FIX: Navigate into the 'data' key sent by Django
        final dynamic nestedData = responseBody['data'];

        if (nestedData != null && nestedData is Map<String, dynamic>) {
          _walletData = nestedData;
          // FIX: Convert String from Django to Double safely
          _balance = double.tryParse(nestedData['balance']?.toString() ?? '0') ?? 0.0;
        } else {
          _walletData = responseBody;
          _balance = double.tryParse(responseBody['balance']?.toString() ?? '0') ?? 0.0;
        }

        _token = authToken; 
        debugPrint("✅ WALLET UPDATED: KES $_balance");
      }
    } catch (e) {
      debugPrint("❌ WalletProvider Error: $e");
    } finally {
      _loading = false;
      notifyListeners(); // Essential for UI Refresh
    }
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