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
  bool _isLoading = false;
  String? _errorMessage;

  List<Contract> get contracts => _contracts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get token from AuthProvider
  String? _getToken(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      debugPrint("Error getting token: $e");
      return null;
    }
  }

  // Fetch all contracts
  Future<void> fetchContracts(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _getToken(context);
      if (token == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      debugPrint("Fetching contracts...");

      
      final url = Uri.parse('${ApiService.baseUrl}/api/freelancer/contracts/');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Contracts API Response: ${response.statusCode}");
      debugPrint("Contracts API Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true) {
          List<dynamic> contractsData = data['contracts'] ?? [];
          _contracts = contractsData.map((json) => Contract.fromJson(json)).toList();
          debugPrint("Loaded ${_contracts.length} contracts");
        } else {
          throw Exception(data['error'] ?? "Failed to load contracts");
        }
      } else if (response.statusCode == 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Failed to load contracts: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching contracts: $e");
      _errorMessage = "Failed to load contracts: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

  // Accept a contract
  Future<void> acceptContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      if (token == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      debugPrint("Accepting contract $contractId");

      await _apiService.acceptContract(token, contractId);

      // Refresh contracts after acceptance
      await fetchContracts(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract accepted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error accepting contract: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      rethrow;
    }
  }

  // Reject a contract
  Future<void> rejectContract(BuildContext context, int contractId) async {
    try {
      final token = _getToken(context);
      if (token == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      debugPrint("Rejecting contract $contractId");

      await _apiService.rejectContract(token, contractId);

      // Refresh contracts after rejection
      await fetchContracts(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract rejected.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error rejecting contract: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      rethrow;
    }
  }

  // Get pending contracts (employer accepted, freelancer not accepted)
  List<Contract> get pendingContracts {
    return _contracts
        .where((contract) => contract.employerAccepted && !contract.freelancerAccepted)
        .toList();
  }

  // Get active contracts (both accepted)
  List<Contract> get activeContracts {
    return _contracts
        .where((contract) => contract.employerAccepted && contract.freelancerAccepted)
        .toList();
  }

  // Get contract by ID
  Contract? getContractById(int contractId) {
    try {
      return _contracts.firstWhere((contract) => contract.contractId == contractId);
    } catch (e) {
      return null;
    }
  }

  // Clear all data
  void clear() {
    _contracts = [];
    _errorMessage = null;
    notifyListeners();
  }
}