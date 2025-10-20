import 'package:flutter/material.dart';
import 'package:helawork/clients/models/contract_model.dart';
import 'package:helawork/services/api_sercice.dart';


class ClientContractProvider with ChangeNotifier {
  ContractModel? _contract;
  bool _isLoading = false;

  ContractModel? get contract => _contract;
  bool get isLoading => _isLoading;

  Future<void> fetchContract(int contractId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.apigetContract(contractId);
      _contract = ContractModel.fromJson(data);
    } catch (e) {
      print("Error fetching contract: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptContract(int contractId) async {
    try {
      await ApiService.bobacceptContract(contractId);
      _contract?.employerAccepted = true;
      notifyListeners();
    } catch (e) {
      print("Error accepting contract: $e");
    }
  }
}
