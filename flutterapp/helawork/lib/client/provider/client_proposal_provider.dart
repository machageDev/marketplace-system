import 'package:flutter/foundation.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/client/models/client_proposal.dart';

class ClientProposalProvider with ChangeNotifier {
  List<ClientProposal> _proposals = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService;

  ClientProposalProvider({required ApiService apiService}) : _apiService = apiService;

  List<ClientProposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

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
    notifyListeners();

    try {
      final response = await _apiService.acceptProposal(proposalId);
      
      if (response['success'] == true) {
        // Update the proposal status locally
        final index = _proposals.indexWhere((p) => p.id == proposalId);
        if (index != -1) {
          _proposals[index] = _proposals[index].copyWith(status: 'accepted');
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to accept proposal';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to accept proposal: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}