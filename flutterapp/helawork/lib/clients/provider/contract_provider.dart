import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/clients/models/contract_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientContractProvider with ChangeNotifier {
  ContractModel? _contract;
  bool _isLoading = false;
  String? _errorMessage;

  ContractModel? get contract => _contract;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String baseUrl = "https://marketplace-system-1.onrender.com";

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_token');
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchContract(String contractId) async { // REMOVED DUPLICATE PARAMETER
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Please login to view contracts");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/contracts/$contractId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _contract = ContractModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Contract not found');
      } else if (response.statusCode == 401) {
        throw Exception('Please login again');
      } else {
        throw Exception('Failed to load contract');
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> acceptContract(String contractId) async { // REMOVED DUPLICATE PARAMETER
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Please login first");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/accept/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchContract(contractId);
      } else if (response.statusCode == 403) {
        throw Exception('Not authorized to accept this contract');
      } else {
        throw Exception('Failed to accept contract');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectContract(String contractId) async { // REMOVED DUPLICATE PARAMETER
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Please login first");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/contracts/$contractId/reject/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _contract = null;
        notifyListeners();
      } else if (response.statusCode == 403) {
        throw Exception('Not authorized to reject this contract');
      } else {
        throw Exception('Failed to reject contract');
      }
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _contract = null;
    _errorMessage = null;
    notifyListeners();
  }
}