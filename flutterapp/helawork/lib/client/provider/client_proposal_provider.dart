import 'package:flutter/foundation.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/models/client_proposal.dart';

class ClientProposalProvider with ChangeNotifier {
  List<ClientProposal> _proposals = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService;
  
  // Stores the raw backend response (contains order_id, amount, etc.)
  Map<String, dynamic>? _lastResponse;
  bool _isProcessingPayment = false;
  
  ClientProposalProvider({required ApiService apiService}) : _apiService = apiService;
  
  List<ClientProposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastResponse => _lastResponse;
  bool get isProcessingPayment => _isProcessingPayment;
  Future<void> loadProposals() async {
  _isLoading = true;
  _errorMessage = '';
  notifyListeners();

  try {
    final response = await _apiService.getFreelancerProposals();
    _proposals = response.map<ClientProposal>((json) => ClientProposal.fromJson(json)).toList();
  } catch (e) {
    _errorMessage = 'Failed to load proposals: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
 
  /// Corrected for MANUAL Navigation
  Future<bool> acceptProposal(String proposalId) async {
    _isLoading = true;
    _errorMessage = '';
    _lastResponse = null; 
    notifyListeners();

    try {
      print('🔐 Accepting proposal: $proposalId');
      final response = await _apiService.acceptProposal(proposalId);
      
      // Store the response so the Screen can grab order_id and amount
      _lastResponse = response;
      
      if (response['success'] == true) {
        // Update local status so the UI reflects 'Accepted'
        final index = _proposals.indexWhere((p) => p.id == proposalId);
        if (index != -1) {
          _proposals[index] = _proposals[index].copyWith(status: 'accepted');
        }
        
        // We return true. The SCREEN will now see success and 
        // manually navigate to PaymentScreen using data in _lastResponse.
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to accept proposal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper to get manual payment details for the PaymentScreen
  Map<String, dynamic>? getManualPaymentData() {
    if (_lastResponse == null) return null;
    
    return {
      'order_id': _lastResponse!['order_id']?.toString() ?? '',
      'amount': _lastResponse!['amount'] ?? _lastResponse!['data']?['order_amount'] ?? 0.0,
      'task_title': _lastResponse!['task_title'] ?? _lastResponse!['data']?['task_title'] ?? '',
    };
  }

  // Rest of your helper methods...
  void startPaymentProcess() {
    _isProcessingPayment = true;
    notifyListeners();
  }
  
  void completePaymentProcess() {
    _isProcessingPayment = false;
    _lastResponse = null;
    notifyListeners();
  }

  Future<bool> rejectProposal(String proposalId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.rejectProposal(proposalId);
      if (response['success'] == true) {
        final index = _proposals.indexWhere((p) => p.id == proposalId);
        if (index != -1) {
          _proposals[index] = _proposals[index].copyWith(status: 'rejected');
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}