import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/freelancer/model/contract_model.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class ContractProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Contract> _contracts = [];
  List<Contract> _filteredContracts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Contract> get contracts => _filteredContracts;
  List<Contract> get allContracts => _contracts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper to get Auth Token
  String? _getToken(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      debugPrint("Error getting token: $e");
      return null;
    }
  }

  // Filter contracts to show only relevant ones
  void _filterContracts() {
    _filteredContracts = _contracts.where((contract) {
      return contract.shouldShowInList;
    }).toList();
    
    // Sort: pending acceptance first, then awaiting action, then completed
    _filteredContracts.sort((a, b) {
      // First: contracts needing acceptance
      if (a.canAccept && !b.canAccept) return -1;
      if (!a.canAccept && b.canAccept) return 1;
      
      // Second: contracts needing OTP verification
      if (a.needsOtpVerification && !b.needsOtpVerification) return -1;
      if (!a.needsOtpVerification && b.needsOtpVerification) return 1;
      
      // Third: contracts needing work submission
      if (a.needsWorkSubmission && !b.needsWorkSubmission) return -1;
      if (!a.needsWorkSubmission && b.needsWorkSubmission) return 1;
      
      // Fourth: completed contracts (show newest first)
      if (a.isPaidAndCompleted && !b.isPaidAndCompleted) return 1;
      if (!a.isPaidAndCompleted && b.isPaidAndCompleted) return -1;
      
      // Finally: sort by start date (newest first)
      try {
        final aDate = DateTime.parse(a.startDate);
        final bDate = DateTime.parse(b.startDate);
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });
  }

  // --- FETCH ALL CONTRACTS ---
  Future<void> fetchContracts(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _getToken(context);
      if (token == null) throw Exception("Not authenticated. Please login again.");

      final url = Uri.parse('${ApiService.baseUrl}/api/freelancer/contracts/');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true) {
          // Map all lists from Django response
          List<dynamic> pending = data['pending_contracts'] ?? [];
          List<dynamic> active = data['active_contracts'] ?? [];
          List<dynamic> completed = data['completed_contracts'] ?? [];
          
          // Combine them into one list
          List<dynamic> combined = [...pending, ...active, ...completed];
          
          _contracts = combined.map((json) => Contract.fromJson(json))
              .where((contract) => contract.contractId != 0)
              .toList();
          
          // Filter contracts to show only relevant ones
          _filterContracts();
          
          debugPrint("✅ Loaded ${_contracts.length} contracts (${_filteredContracts.length} filtered)");
        } else {
          throw Exception(data['error'] ?? "Failed to parse contract data");
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Fetch Error: $e");
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- VERIFY ON-SITE COMPLETION (OTP HANDSHAKE) ---
  Future<bool> verifyContractOTP(BuildContext context, int contractId, String otpCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = _getToken(context);
      if (token == null) throw Exception("Session expired");

      final url = Uri.parse('${ApiService.baseUrl}/api/contracts/$contractId/verify-completion/');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'completion_code': otpCode}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        await fetchContracts(context);
        return true;
      } else {
        throw Exception(data['error'] ?? "Incorrect code. Please try again.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ACCEPT CONTRACT ---
  Future<void> acceptContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      await _apiService.acceptContract(token!, contractId);
      await fetchContracts(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract accepted!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("Accept Error: $e");
    }
  }

  // --- REJECT CONTRACT ---
  Future<void> rejectContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      await _apiService.rejectContract(token!, contractId);
      await fetchContracts(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract rejected'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      debugPrint("Reject Error: $e");
    }
  }

  // --- GETTERS FOR DASHBOARD ---
  List<Contract> get activeContracts => _contracts.where((c) => c.isAccepted).toList();
  List<Contract> get pendingContracts => _contracts.where((c) => c.canAccept).toList();

  void clear() {
    _contracts = [];
    _filteredContracts = [];
    _errorMessage = null;
    notifyListeners();
  }
}