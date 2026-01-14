import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class SubmissionProvider with ChangeNotifier {
  // State
  List<dynamic> _submissions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  List<dynamic> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
 // In submission_provider.dart - update fetchSubmissions

Future<void> fetchSubmissions() async {
  _isLoading = true;
  _errorMessage = '';
  notifyListeners();
  
  try {
    debugPrint("📋 Fetching submissions for review...");
    _submissions = await ApiService.getEmployerSubmissions();
    debugPrint(" Loaded ${_submissions.length} submissions");
    
    if (_submissions.isEmpty) {
      _errorMessage = "No submissions found. Submissions will appear here when freelancers submit their work.";
    }
    
  } catch (e) {
    _errorMessage = "Failed to load submissions: ${e.toString()}";
    _submissions = [];
    debugPrint("❌ Error fetching submissions: $e");
  }
  
  _isLoading = false;
  notifyListeners();
}
  
  // Approve submission
  Future<void> approveSubmission(int submissionId) async {
    try {
      debugPrint("✅ Approving submission $submissionId...");
      await ApiService.approveSubmission(submissionId);
      
      // Remove from list after approval
      _submissions.removeWhere((sub) => sub['submission_id'] == submissionId);
      notifyListeners();
      
      debugPrint("✅ Submission $submissionId approved");
      
    } catch (e) {
      _errorMessage = "Failed to approve submission: ${e.toString()}";
      debugPrint("❌ Error approving submission: $e");
      rethrow;
    }
  }
  
  // Request revisions
  Future<void> requestRevision(int submissionId, String notes) async {
    try {
      debugPrint("🔄 Requesting revision for submission $submissionId...");
      await ApiService.requestRevision(submissionId, notes);
      
      // Remove from list after revision request
      _submissions.removeWhere((sub) => sub['submission_id'] == submissionId);
      notifyListeners();
      
      debugPrint("✅ Revision requested for submission $submissionId");
      
    } catch (e) {
      _errorMessage = "Failed to request revision: ${e.toString()}";
      debugPrint("❌ Error requesting revision: $e");
      rethrow;
    }
  }
  
  // Get submissions by status
  List<dynamic> getSubmissionsByStatus(String status) {
    return _submissions.where((sub) => 
      (sub['status']?.toString().toLowerCase() ?? '') == status.toLowerCase()
    ).toList();
  }
  
  // Get pending review submissions
  List<dynamic> get pendingReview {
    return _submissions.where((sub) => 
      ['submitted', 'under_review'].contains(sub['status']?.toString().toLowerCase())
    ).toList();
  }
  
  // Get statistics
  Map<String, int> getStats() {
    final pending = getSubmissionsByStatus('submitted').length;
    final underReview = getSubmissionsByStatus('under_review').length;
    final total = _submissions.length;
    
    return {
      'total': total,
      'pending': pending,
      'under_review': underReview,
    };
  }
  
  // Clear error
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  // Clear all data
  void clear() {
    _submissions = [];
    _errorMessage = '';
    notifyListeners();
  }
}