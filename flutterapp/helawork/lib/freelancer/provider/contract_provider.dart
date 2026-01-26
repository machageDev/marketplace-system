import 'dart:convert';
import 'dart:developer' as developer;
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

  String? _getToken(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      developer.log("Error getting token: $e", name: 'ContractProvider');
      return null;
    }
  }

  void _filterContracts() {
    _filteredContracts = _contracts.where((contract) {
      return contract.shouldShowInList;
    }).toList();
    
    _filteredContracts.sort((a, b) {
      if (a.canAccept && !b.canAccept) return -1;
      if (!a.canAccept && b.canAccept) return 1;
      
      if (a.needsOtpVerification && !b.needsOtpVerification) return -1;
      if (!a.needsOtpVerification && b.needsOtpVerification) return 1;
      
      if (a.needsWorkSubmission && !b.needsWorkSubmission) return -1;
      if (!a.needsWorkSubmission && b.needsWorkSubmission) return 1;
      
      try {
        final aDate = DateTime.parse(a.startDate);
        final bDate = DateTime.parse(b.startDate);
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });
  }

  Future<void> fetchContracts(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _getToken(context);
      if (token == null) throw Exception("Not authenticated. Please login again.");

      final url = Uri.parse('${ApiService.baseUrl}/api/freelancer/contracts/');

      developer.log("🔍 Fetching Dashboard from: $url", name: 'ContractProvider');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true && data['contracts'] is List) {
          List<dynamic> list = data['contracts'];
          
          _contracts = list.map((json) {
            try {
              return Contract.fromJson(json);
            } catch (e) {
              developer.log("❌ Parsing error: $e", name: 'ContractProvider');
              return null;
            }
          })
          .whereType<Contract>()
          .toList();
          
          _filterContracts();
          developer.log("✅ Loaded ${_contracts.length} contracts for Micah", name: 'ContractProvider');
        } else {
          throw Exception(data['error'] ?? "Failed to parse dashboard data");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      developer.log("❌ Fetch Error: $e", name: 'ContractProvider');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- OTP HANDSHAKE (FIXED KEY NAME) ---
  Future<bool> verifyContractOTP(BuildContext context, int contractId, String otpCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = _getToken(context);
      final url = Uri.parse('${ApiService.baseUrl}/api/contracts/$contractId/verify-completion/');

      // FIX: Changed 'verification_code' to 'otp_code' to match your Django view
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'otp_code': otpCode}), 
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchContracts(context); // Refresh the UI
        return true;
      } else {
        throw Exception(data['message'] ?? "Verification failed.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      await _apiService.acceptContract(token!, contractId);
      await fetchContracts(context); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer Accepted!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> rejectContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      await _apiService.rejectContract(token!, contractId);
      await fetchContracts(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer Rejected'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  List<Contract> get activeContracts => _contracts.where((c) => c.freelancerAccepted && !c.isCompleted).toList();
  List<Contract> get pendingContracts => _contracts.where((c) => !c.freelancerAccepted).toList();

  void clear() {
    _contracts = [];
    _filteredContracts = [];
    _errorMessage = null;
    notifyListeners();
  }
}