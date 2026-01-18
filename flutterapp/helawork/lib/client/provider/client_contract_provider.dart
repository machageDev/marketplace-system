import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientContractProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> contracts = [];

  String get baseUrl => AppConfig.getBaseUrl();

  // ======================================================
  // Fetch Employer Contracts
  // ======================================================
  Future<void> fetchEmployerContracts() async {
    try {
      isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      final response = await http.get(
        Uri.parse("$baseUrl/api/employer/contracts/"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true && data["contracts"] is List) {
        contracts = List<Map<String, dynamic>>.from(data["contracts"]);
      } else {
        contracts = [];
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching contracts: $e");
      contracts = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ======================================================
  // Release Escrow Payment
  // ======================================================
  Future<bool> releasePayment(int contractId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/release-payment/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"contract_id": contractId.toString()},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        await fetchEmployerContracts();
        return true;
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      if (kDebugMode) print("Error releasing payment: $e");
      return false;
    }
  }

  // ======================================================
  // Mark On-Site Contract Completed
  // ======================================================
  Future<bool> markContractCompleted(int contractId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/contracts/<int:contract_id>/mark-completed/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"contract_id": contractId.toString()},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        await fetchEmployerContracts();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print("Error completing contract: $e");
    }
    return false;
  }

  // ======================================================
  // Confirm Escrow Funding
  // ======================================================
  Future<bool> confirmEscrowFunding(String orderId, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/confirm-escrow/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"order_id": orderId, "amount": amount.toString()},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        await fetchEmployerContracts();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print("Error confirming escrow: $e");
    }
    return false;
  }

  // ======================================================
  // Clear Contract Data
  // ======================================================
  void clearContracts() {
    contracts = [];
    notifyListeners();
  }
}
