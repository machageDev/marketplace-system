import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helawork/api_service.dart';


class SubmissionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String errorMessage = '';
  List<Map<String, dynamic>> submissions = [];

  Future<void> submitTask({
    required String taskId,
    required String title, 
    required String description,  
    String? url,            // The single consolidated URL
    PlatformFile? zipFile,   // The code/assets
    PlatformFile? document,  // The documentation/proof
  }) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final result = await _apiService.submitTask(
        taskId: taskId,
        title: title,  
        description: description,  
        url: url,
        zipFile: zipFile,
        document: document,
      );

      if (result['success'] == true) {
        if (result['data'] != null) {
          submissions.add(result['data']);
        }
        errorMessage = '';
      } else {
        errorMessage = result['message'] ?? 'Submission failed';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }  
  
Future<void> fetchSubmissions(String taskId) async {
    isLoading = true;
    notifyListeners();

    try {
      // Pass the taskId to the API service
      final allSubmissions = await _apiService.fetchSubmissions();
      
      // Filter locally to ensure the UI only shows submissions for THIS specific task
      submissions = allSubmissions
          .where((s) => s['task'].toString() == taskId)
          .toList();
          
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}