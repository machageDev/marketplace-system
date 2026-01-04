// client_contract_provider.dart
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class ClientContractProvider with ChangeNotifier {
  // State
  List<dynamic> _contracts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<dynamic> get contracts => _contracts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ============ FETCH EMPLOYER CONTRACTS ============
  
  Future<void> fetchEmployerContracts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      debugPrint("🔍 Fetching employer contracts...");
      
      // Get contracts that need completion (paid but not completed)
      final response = await ApiService.getEmployerPendingCompletions();
      
      _contracts = response;
      debugPrint("✅ Loaded ${_contracts.length} employer contracts");
      
      if (_contracts.isEmpty) {
        _errorMessage = "No contracts found. Contracts will appear here after freelancers complete work and payment is made.";
      }
      
    } catch (e) {
      _errorMessage = "Failed to load contracts: ${e.toString()}";
      _contracts = [];
      debugPrint("❌ Error fetching employer contracts: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // ============ MARK CONTRACT AS COMPLETED ============

  Future<void> markContractCompleted(int contractId) async {
    try {
      debugPrint("📝 Marking contract $contractId as completed...");
      
      await ApiService.markContractCompleted(contractId);
      
      // Refresh the list after completion
      await fetchEmployerContracts();
      
      debugPrint("✅ Contract $contractId marked as completed");
      
    } catch (e) {
      _errorMessage = "Failed to mark contract as completed: ${e.toString()}";
      debugPrint("❌ Error marking contract completed: $e");
      rethrow;
    }
  }

  // ============ UTILITY METHODS ============

  // Get contracts ready for completion (paid but not completed)
  List<dynamic> get readyForCompletion {
    return _contracts.where((contract) => 
      contract['can_complete'] == true
    ).toList();
  }

  // Get pending contracts (not paid yet)
  List<dynamic> get pendingContracts {
    return _contracts.where((contract) => 
      contract['can_complete'] == false
    ).toList();
  }

  // Get contract by ID
  Map<String, dynamic>? getContractById(int contractId) {
    try {
      return _contracts.firstWhere(
        (contract) => contract['contract_id'] == contractId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint("Error getting contract by ID: $e");
      return null;
    }
  }

  // Get contract statistics
  Map<String, int> getContractStats() {
    final readyCount = readyForCompletion.length;
    final pendingCount = pendingContracts.length;
    final totalCount = _contracts.length;
    
    return {
      'total': totalCount,
      'ready': readyCount,
      'pending': pendingCount,
    };
  }

  // Clear error
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _contracts = [];
    _errorMessage = '';
    notifyListeners();
  }
}