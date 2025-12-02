import 'package:flutter/material.dart';
import 'package:helawork/clients/models/contract_model.dart';
import 'package:helawork/services/api_sercice.dart';

class ClientContractProvider with ChangeNotifier {
  ContractModel? _contract;
  bool _isLoading = false;

  ContractModel? get contract => _contract;
  bool get isLoading => _isLoading;

  Future<void> fetchContract(String token, String contractId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService(token: token);
      final data = await apiService.getContract(int.parse(contractId) as String); // ✅ fixed
      _contract = ContractModel.fromJson(data);
    } catch (e) {
      print("Error fetching contract: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptContract(String token, String contractId) async {
    try {
      final apiService = ApiService(token: token);
      await apiService.acceptContract(int.parse(contractId)); // ✅ fixed
      _contract?.employerAccepted = true;
      notifyListeners();
    } catch (e) {
      print("Error accepting contract: $e");
    }
  }
}
