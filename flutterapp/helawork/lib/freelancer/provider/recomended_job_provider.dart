import 'package:flutter/material.dart';
import 'package:helawork/services/api_sercice.dart';


class RecommendedJobsProvider with ChangeNotifier {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _jobs = [];

  bool get loading => _loading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  List<dynamic> get jobs => _jobs;

  // Fetch recommended jobs
  Future<void> fetchRecommendedJobs(String token) async {
    try {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      final results = await ApiService.fetchRecommendedJobs(token);
      
      _jobs = results;
      _loading = false;
      notifyListeners();
    } catch (error) {
      _loading = false;
      _hasError = true;
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  // Clear all data
  void clear() {
    _jobs = [];
    _loading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  // Filter jobs by search query
  List<dynamic> filterJobs(String query) {
    if (query.isEmpty) return _jobs;
    
    return _jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final description = (job['description'] ?? '').toString().toLowerCase();
      final employer = job['employer'] ?? {};
      final employerName = (employer['company_name'] ?? employer['username'] ?? '').toString().toLowerCase();
      final searchLower = query.toLowerCase();
      
      return title.contains(searchLower) ||
             description.contains(searchLower) ||
             employerName.contains(searchLower);
    }).toList();
  }
}