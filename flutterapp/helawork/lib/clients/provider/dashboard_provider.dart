import 'package:flutter/material.dart';

import 'package:helawork/services/api_sercice.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

  bool isLoading = true;
  Map<String, dynamic> dashboardData = {};

  DashboardProvider({required this.apiService}); // ✅ Constructor with required apiService

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      dashboardData = await apiService.fetchDashboardData();
    } catch (e) {
      dashboardData = {};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}