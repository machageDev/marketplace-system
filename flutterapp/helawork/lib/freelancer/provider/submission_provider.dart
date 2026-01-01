import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helawork/api_service.dart';


class SubmissionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String errorMessage = '';
  List<Map<String, dynamic>> submissions = [];

  Future<void> submitTask({
    required String taskId,
    required String title, 
    required String description,  
    String? repoUrl,
    String? commitHash,
    String? stagingUrl,
    String? liveDemoUrl,
    String? apkUrl,
    String? testflightLink,
    String? adminUsername,
    String? adminPassword,
    String? accessInstructions,
    String? deploymentInstructions,
    String? testInstructions,
    String? releaseNotes,
    String? revisionNotes,
    required bool checklistTestsPassing,
    required bool checklistDeployedStaging,
    required bool checklistDocumentation,
    required bool checklistNoCriticalBugs,
    PlatformFile? zipFile,
    PlatformFile? screenshots,
    PlatformFile? videoDemo,
  }) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      print('Provider: Submitting task $taskId');
      print('Provider: Title: $title');
      print('Provider: Description: $description');

      final result = await _apiService.submitTask(
        taskId: taskId,
        title: title,  
        description: description,  
        repoUrl: repoUrl,
        commitHash: commitHash,
        stagingUrl: stagingUrl,
        liveDemoUrl: liveDemoUrl,
        apkUrl: apkUrl,
        testflightLink: testflightLink,
        adminUsername: adminUsername,
        adminPassword: adminPassword,
        accessInstructions: accessInstructions,
        deploymentInstructions: deploymentInstructions,
        testInstructions: testInstructions,
        releaseNotes: releaseNotes,
        revisionNotes: revisionNotes,
        checklistTestsPassing: checklistTestsPassing,
        checklistDeployedStaging: checklistDeployedStaging,
        checklistDocumentation: checklistDocumentation,
        checklistNoCriticalBugs: checklistNoCriticalBugs,
        zipFile: zipFile,
        screenshots: screenshots,
        videoDemo: videoDemo,
      );

      print('Provider: Submission result: $result');

      if (result['success'] == true) {
        // Add to submissions list
        if (result['data'] != null) {
          submissions.add(result['data']);
        }
        
        errorMessage = '';
        
        print('Provider: Submission successful!');
      } else {
        errorMessage = result['message'] ?? 'Submission failed';
        print('Provider: Submission failed: $errorMessage');
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      print('Provider: Exception: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubmissions() async {
    isLoading = true;
    notifyListeners();

    try {
      submissions = await _apiService.fetchSubmissions();
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}