import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helawork/services/api_sercice.dart';


class SubmissionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String errorMessage = '';
  List<Map<String, dynamic>> submissions = [];

  Future<void> submitTask({
    required int taskId,
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
    notifyListeners();

    try {
      final result = await _apiService.submitTask(
        taskId: taskId,
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

      submissions.add(result);
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
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
