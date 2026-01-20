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

  // ======================================================
  // Fetch Employer Contracts
  // ======================================================
  Future<void> fetchEmployerContracts() async {
    try {
      isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      print("🔍 Fetching contracts from: $baseUrl/api/employer/contracts/");
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/employer/contracts/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("📊 Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📋 Response keys: ${data.keys}");
        
        if (data["status"] == true && data["contracts"] is List) {
          final contractsList = data["contracts"] as List;
          print("✅ Found ${contractsList.length} contracts");
          
          // Convert each JSON to ContractModel
          contracts = contractsList.map<ContractModel>((json) {
            try {
              return ContractModel.fromJson(json);
            } catch (e) {
              print("❌ Error parsing contract: $e");
              print("❌ Problematic JSON: $json");
              return ContractModel.fromJson({});
            }
          }).where((contract) => contract.contractId != 0).toList();
          
          // Debug first contract
          if (contracts.isNotEmpty) {
            final first = contracts.first;
            print("📝 First contract debug:");
            print("   ID: ${first.contractId}");
            print("   Order ID: ${first.orderId}");
            print("   Order Status: ${first.orderStatus}");
            print("   Title: ${first.taskTitle}");
            print("   Service Type: ${first.serviceType}");
            print("   Paid: ${first.isPaid}");
            print("   Completed: ${first.isCompleted}");
            print("   Has valid order ID: ${first.hasValidOrderId}");
          }
        } else {
          print("❌ API returned false status or no contracts");
          contracts = [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        print("Response body: ${response.body}");
        contracts = [];
      }
    } catch (e, stackTrace) {
      print("❌ Error fetching contracts: $e");
      print("Stack trace: $stackTrace");
      contracts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // Release Payment to Freelancer
  // ======================================================
  Future<Map<String, dynamic>> releasePayment(int contractId) async {
    try {
      print("💸 Releasing payment for contract: $contractId");
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/api/contracts/release-payment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {"contract_id": contractId.toString()},
      );

      print("📊 Release response: ${response.statusCode}");
      print("📋 Release body: ${response.body}");
      
      final data = jsonDecode(response.body);
      
      if (data["status"] == true) {
        print("✅ Payment released successfully");
        // Refresh contracts
        await fetchEmployerContracts();
        return {
          "success": true, 
          "message": data["message"] ?? "Payment released successfully"
        };
      } else {
        print("❌ Release failed: ${data['message']}");
        return {
          "success": false, 
          "message": data["message"] ?? "Release failed"
        };
      }
    } catch (e) {
      print("❌ Error in releasePayment: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  // ======================================================
  // Generate Verification Code for On-Site Contract
  // ======================================================
  Future<Map<String, dynamic>> generateVerificationCode(int contractId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      print("🔐 Generating verification code for contract: $contractId");
      
      final response = await http.post(
        Uri.parse('${baseUrl}/api/contracts/$contractId/generate-verification-code/'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"contract_id": contractId.toString()}),
      );

      print("📊 Generate code response: ${response.statusCode}");
      print("📋 Response body: ${response.body}");
      
      final data = jsonDecode(response.body);
      
      if (data["status"] == true) {
        print("✅ Verification code generated");
        await fetchEmployerContracts(); // Refresh to get new code
        return {
          "success": true, 
          "code": data["verification_code"],
          "message": data["message"] ?? "Code generated successfully"
        };
      } else {
        return {
          "success": false, 
          "message": data["message"] ?? "Failed to generate code"
        };
      }
    } catch (e) {
      print("❌ Error generating verification code: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  // ======================================================
  // Verify On-Site Completion
  // ======================================================
  Future<Map<String, dynamic>> verifyOnSiteCompletion(int contractId, String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("user_token") ?? "";

      print("✅ Verifying on-site completion for contract: $contractId with code: $code");
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/contracts/$contractId/verify-otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"verification_code": code}),
      );

      print("📊 Verify response: ${response.statusCode}");
      print("📋 Verify body: ${response.body}");
      
      final data = jsonDecode(response.body);
      
      if (data["status"] == true) {
        print("✅ On-site completion verified");
        await fetchEmployerContracts();
        return {
          "success": true, 
          "message": data["message"] ?? "Verification successful"
        };
      } else {
        return {
          "success": false, 
          "message": data["message"] ?? "Verification failed"
        };
      }
    } catch (e) {
      print("❌ Error in verifyOnSiteCompletion: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  // ======================================================
  // Get Contract by ID
  // ======================================================
  ContractModel? getContractById(int contractId) {
    try {
      return contracts.firstWhere((contract) => contract.contractId == contractId);
    } catch (e) {
      return null;
    }
  }

  // ======================================================
  // Clear Contracts
  // ======================================================
  void clearContracts() {
    contracts.clear();
    notifyListeners();
  }
}