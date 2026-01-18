import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:helawork/freelancer/model/proposal_model.dart';

class ProposalProvider with ChangeNotifier {
  List<Proposal> _proposals = [];
  bool _isLoading = false;
  String? error;

  List<Proposal> get proposals => _proposals;
  bool get isLoading => _isLoading;

  Future<void> fetchProposals() async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      _proposals = await ApiService.fetchProposals();
      print(' Loaded ${_proposals.length} proposals');
    } catch (e) {
      error = "Failed to load proposals: $e";
      print(' Error loading proposals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProposal(Proposal proposal, {PlatformFile? pdfFile}) async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      print(' Sending proposal to API...');
      
      Proposal submittedProposal;
      
      if (pdfFile != null) {
        // Validate PDF file
        if (pdfFile.bytes == null) {
          throw Exception("PDF file bytes are null - file may be corrupted");
        }
        
        // Call submitProposal WITH PDF file
        submittedProposal = await ApiService.submitProposal(
          proposal, 
          pdfFile: pdfFile // This is now non-nullable
        );
      } else {
        // Call submitProposal WITHOUT PDF file
        submittedProposal = await ApiService.submitProposalWithoutPdf(proposal);
      }
      
      print(' API call successful, adding to local list');
      _proposals.insert(0, submittedProposal);
      error = null;
      
      print(' Proposal added successfully');
      
    } catch (e) {
      print(' Error in addProposal: $e');
      error = "Failed to add proposal: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
      print(' Loading state set to false');
    }
  }
  
  List<Proposal> getProposalsByFreelancer(int freelancerId) {
    return _proposals.where((p) => p.freelancerId == freelancerId).toList();
  }

  List<Proposal> getProposalsByTask(int taskId) {
    return _proposals.where((p) => p.taskId == taskId).toList();
  }
}