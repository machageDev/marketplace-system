import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:helawork/api_config.dart';
import 'package:helawork/client/models/client_contract_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientContractProvider extends ChangeNotifier {
  bool isLoading = false;
  List<ContractModel> contracts = [];

  String get baseUrl => AppConfig.getBaseUrl();

  // Helper to get token
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_token") ?? "";
  }

  // ======================================================
  // Fetch Employer Contracts
  // ======================================================
  Future<void> fetchEmployerContracts() async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await _getToken();

      print("🔍 Fetching contracts from: $baseUrl/api/employer/contracts/");
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/employer/contracts/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data["status"] == true && data["contracts"] is List) {
          final contractsList = data["contracts"] as List;
          
          contracts = contractsList.map<ContractModel>((json) {
            try {
              return ContractModel.fromJson(json);
            } catch (e) {
              print("❌ Error parsing contract: $e");
              return ContractModel.fromJson({});
            }
          }).where((contract) => contract.contractId != 0).toList();
          
          print("✅ Sync Complete: ${contracts.length} contracts loaded.");
        } else {
          contracts = [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        contracts = [];
      }
    } catch (e) {
      print("❌ Error fetching contracts: $e");
      contracts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // Release Payment to Freelancer (Remote/Manual)
  // ======================================================
  Future<Map<String, dynamic>> releasePayment(int contractId) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/api/contracts/release-payment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {"contract_id": contractId.toString()},
      );

      final data = jsonDecode(response.body);
      
      if (data["status"] == true) {
        await fetchEmployerContracts(); // Refresh local list
        return {"success": true, "message": data["message"] ?? "Payment released"};
      } else {
        return {"success": false, "message": data["message"] ?? "Release failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
Future<Map<String, dynamic>> generateVerificationCode(int contractId) async {
  try {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/contracts/$contractId/generate-verification-code/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"contract_id": contractId.toString()}),
    );

    final data = jsonDecode(response.body);
    
    if (data["status"] == true) {
      String newCode = data["verification_code"].toString();
      
      // Update local list manually to ensure immediate UI update
      int index = contracts.indexWhere((c) => c.contractId == contractId);
      if (index != -1) {
        contracts[index].verificationOtp = newCode;
        // Don't call fetchEmployerContracts here, it might overwrite newCode with null
        // if the Django list serializer doesn't include the field yet.
        notifyListeners(); 
      }

      return {
        "success": true, 
        "code": newCode,
        "message": data["message"] ?? "Code generated"
      };
    } else {
      return {"success": false, "message": data["message"] ?? "Failed to generate code"};
    }
  } catch (e) {
    return {"success": false, "message": "Error: $e"};
  }
}

  
  // ======================================================
  Future<Map<String, dynamic>> verifyOnSiteCompletion(int contractId, String code) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/api/contracts/$contractId/verify-otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"verification_code": code}),
      );

      final data = jsonDecode(response.body);
      
      if (data["status"] == true) {
        await fetchEmployerContracts();
        return {"success": true, "message": data["message"] ?? "Verified successfully"};
      } else {
        return {"success": false, "message": data["message"] ?? "Verification failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // ======================================================
  // Request Refund (When Freelancer Rejects after Payment)
  // ======================================================
  Future<Map<String, dynamic>> requestRefund(int contractId) async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/request-refund/'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || data["status"] == true) {
        await fetchEmployerContracts(); // Refresh to show 'Refunded' or 'Cancelled'
        return {'success': true, 'message': data["message"] ?? 'Refund request submitted'};
      } else {
        return {'success': false, 'message': data["message"] ?? 'Failed to request refund'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // Utilities
  // ======================================================
  ContractModel? getContractById(int contractId) {
    try {
      return contracts.firstWhere((c) => c.contractId == contractId);
    } catch (e) {
      return null;
    }
  }

  void clearContracts() {
    contracts.clear();
    notifyListeners();
  }
}