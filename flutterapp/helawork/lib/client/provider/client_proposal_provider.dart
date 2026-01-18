import 'package:flutter/foundation.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/models/client_proposal.dart';

class ClientProposalProvider with ChangeNotifier {
  List<ClientProposal> _proposals = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService;
  
  // NEW: Store the last response for payment handling
  Map<String, dynamic>? _lastResponse;
  
  // NEW: Track if we're in payment process
  bool _isProcessingPayment = false;
  
  ClientProposalProvider({required ApiService apiService}) : _apiService = apiService;
  
  List<ClientProposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // NEW: Getter for last response
  Map<String, dynamic>? get lastResponse => _lastResponse;
  
  // NEW: Getter for payment processing status
  bool get isProcessingPayment => _isProcessingPayment;
  
  Future<void> loadProposals() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('Loading employer proposals...');
      final response = await ApiService.getFreelancerProposals();
      
      // Convert to ClientProposal objects
      _proposals = response.map<ClientProposal>((json) {
        return ClientProposal.fromJson(json);
      }).toList();
      
      print('Loaded ${_proposals.length} proposals for employer');
      
    } catch (e) {
      _errorMessage = 'Failed to load proposals: $e';
      print('Error loading proposals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptProposal(String proposalId) async {
    _isLoading = true;
    _errorMessage = '';
    _lastResponse = null; // Reset last response
    notifyListeners();

    try {
      print('🔐 Accepting proposal: $proposalId');
      final response = await _apiService.acceptProposal(proposalId);
      
      // Store the response for payment handling
      _lastResponse = response;
      print('📦 Response stored in provider: ${response.containsKey('requires_payment')}');
      
      if (response['success'] == true) {
        // Update the proposal status locally
        final index = _proposals.indexWhere((p) => p.id == proposalId);
        if (index != -1) {
          _proposals[index] = _proposals[index].copyWith(status: 'accepted');
          notifyListeners();
        }
        
        // NEW: Check if payment is required
        if (response.containsKey('requires_payment') && response['requires_payment'] == true) {
          print('💰 Payment required for this proposal');
          // Don't change isLoading here - we need to show payment UI
          return true; // Return true even though payment is pending
        } else {
          print('✅ Proposal accepted without payment requirement');
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to accept proposal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to accept proposal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NEW: Mark payment as started
  void startPaymentProcess() {
    _isProcessingPayment = true;
    notifyListeners();
  }
  
  // NEW: Mark payment as completed
  void completePaymentProcess() {
    _isProcessingPayment = false;
    _lastResponse = null; // Clear the response after payment
    notifyListeners();
  }
  
  // NEW: Clear payment data
  void clearPaymentData() {
    _lastResponse = null;
    _isProcessingPayment = false;
    notifyListeners();
  }

  Future<bool> rejectProposal(String proposalId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.rejectProposal(proposalId);
      
      if (response['success'] == true) {
        // Update the proposal status locally
        final index = _proposals.indexWhere((p) => p.id == proposalId);
        if (index != -1) {
          _proposals[index] = _proposals[index].copyWith(status: 'rejected');
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to reject proposal';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to reject proposal: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Helper methods
  List<ClientProposal> get pendingProposals {
    return _proposals.where((p) => p.status == 'pending').toList();
  }

  List<ClientProposal> get acceptedProposals {
    return _proposals.where((p) => p.status == 'accepted').toList();
  }

  List<ClientProposal> get rejectedProposals {
    return _proposals.where((p) => p.status == 'rejected').toList();
  }
  
  // NEW: Get proposals by task service type
  List<ClientProposal> get onSiteProposals {
    return _proposals.where((p) => p.taskServiceType == 'on_site').toList();
  }
  
  List<ClientProposal> get remoteProposals {
    return _proposals.where((p) => p.taskServiceType == 'remote').toList();
  }
  
  // NEW: Get proposal by ID
  ClientProposal? getProposalById(String proposalId) {
    try {
      return _proposals.firstWhere((p) => p.id == proposalId);
    } catch (e) {
      return null;
    }
  }
  
  // NEW: Update proposal status locally
  void updateProposalStatus(String proposalId, String status) {
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index != -1) {
      _proposals[index] = _proposals[index].copyWith(status: status);
      notifyListeners();
    }
  }
  
  // NEW: Check if a proposal requires payment
  bool doesProposalRequirePayment(String proposalId) {
    final proposal = getProposalById(proposalId);
    if (proposal == null) return false;
    
    // Only pending proposals can require payment
    if (proposal.status != 'pending') return false;
    
    // Check if we have payment data in last response
    if (_lastResponse != null && 
        _lastResponse!.containsKey('proposal_id') && 
        _lastResponse!['proposal_id'] == proposalId) {
      return _lastResponse!['requires_payment'] == true;
    }
    
    return false;
  }
  
  // NEW: Get payment URL for a proposal
  String? getPaymentUrl(String proposalId) {
    if (_lastResponse != null && 
        _lastResponse!.containsKey('proposal_id') && 
        _lastResponse!['proposal_id'] == proposalId) {
      return _lastResponse!['checkout_url'];
    }
    return null;
  }
  
  // NEW: Get payment data for a proposal
  Map<String, dynamic>? getPaymentData(String proposalId) {
    if (_lastResponse != null && 
        _lastResponse!.containsKey('proposal_id') && 
        _lastResponse!['proposal_id'] == proposalId) {
      return {
        'checkout_url': _lastResponse!['checkout_url'],
        'order_id': _lastResponse!['order_id'],
        'payment_reference': _lastResponse!['payment_reference'],
        'amount': _lastResponse!['data']?['order_amount'] ?? 0,
        'task_title': _lastResponse!['data']?['task_title'] ?? '',
      };
    }
    return null;
  }
}