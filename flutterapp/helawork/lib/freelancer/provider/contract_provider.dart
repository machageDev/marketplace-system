// lib/freelancer/provider/contract_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/services/api_sercice.dart';
import 'auth_provider.dart';
import '../models/contract_model.dart';

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

  Future<void> fetchContracts(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _getToken(context);
      if (token == null) {
        throw Exception("Not authenticated. Please login again.");
      }

      debugPrint("Fetching contracts with token: ${token.substring(0, 20)}...");

      final response = await _apiService.fetchFreelancerContracts(token);
      
      if (response['status'] == true) {
        List<dynamic> contractsData = response['contracts'] ?? [];
        _contracts = contractsData.map((json) => Contract.fromJson(json)).toList();
        debugPrint("Loaded ${_contracts.length} contracts");
      } else {
        throw Exception(response['error'] ?? "Failed to load contracts");
      }
    } catch (e) {
      debugPrint("Error fetching contracts: $e");
      _errorMessage = "Failed to load contracts: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

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
    return _contracts.where((contract) => 
      contract.employerAccepted && !contract.freelancerAccepted
    ).toList();
  }

  // Get active contracts (both accepted)
  List<Contract> get activeContracts {
    return _contracts.where((contract) => 
      contract.employerAccepted && contract.freelancerAccepted
    ).toList();
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