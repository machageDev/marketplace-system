
import 'package:flutter/foundation.dart';
import 'package:helawork/clients/models/client_proposal.dart' show Proposal;
import 'package:helawork/services/api_sercice.dart';

class ProposalsProvider with ChangeNotifier {
  List<Proposal> _proposals = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService;

  ProposalsProvider({required ApiService apiService}) : _apiService = apiService;

  List<Proposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadProposals() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.getFreelancerProposals();
      _proposals = (response).map((json) => Proposal.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load proposals: $e';
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
}