import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helawork/freelancer/provider/submission_provider.dart';

class SubmitTaskScreen extends StatefulWidget {
  final int taskId;
  const SubmitTaskScreen({super.key, required this.taskId});

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController repoUrlController = TextEditingController();
  TextEditingController commitHashController = TextEditingController();
  TextEditingController stagingUrlController = TextEditingController();
  TextEditingController liveDemoController = TextEditingController();
  TextEditingController apkUrlController = TextEditingController();
  TextEditingController testflightController = TextEditingController();
  TextEditingController adminUsernameController = TextEditingController();
  TextEditingController adminPasswordController = TextEditingController();
  TextEditingController accessInstructionsController = TextEditingController();
  TextEditingController deploymentInstructionsController = TextEditingController();
  TextEditingController testInstructionsController = TextEditingController();
  TextEditingController releaseNotesController = TextEditingController();
  TextEditingController revisionNotesController = TextEditingController();

  bool checklistTestsPassing = false;
  bool checklistDeployedStaging = false;
  bool checklistDocumentation = false;
  bool checklistNoCriticalBugs = false;

  PlatformFile? zipFile;
  PlatformFile? screenshots;
  PlatformFile? videoDemo;

  @override
  Widget build(BuildContext context) {
    final submissionProvider = Provider.of<SubmissionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Task"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: submissionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(repoUrlController, 'Repository URL'),
                    _buildTextField(commitHashController, 'Commit Hash'),
                    _buildTextField(stagingUrlController, 'Staging URL'),
                    _buildTextField(liveDemoController, 'Live Demo URL'),
                    _buildTextField(apkUrlController, 'APK Download URL'),
                    _buildTextField(testflightController, 'TestFlight Link'),
                    const SizedBox(height: 12),
                    _buildTextField(adminUsernameController, 'Admin Username'),
                    _buildTextField(adminPasswordController, 'Admin Password', obscure: true),
                    _buildTextField(accessInstructionsController, 'Access Instructions', maxLines: 3),
                    _buildTextField(deploymentInstructionsController, 'Deployment Instructions', maxLines: 3),
                    _buildTextField(testInstructionsController, 'Test Instructions', maxLines: 3),
                    _buildTextField(releaseNotesController, 'Release Notes', maxLines: 3),
                    _buildTextField(revisionNotesController, 'Revision Notes', maxLines: 3),
                    const SizedBox(height: 16),
                    Text("Upload Files", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildFilePicker("ZIP File", zipFile, (file) => setState(() => zipFile = file)),
                    _buildFilePicker("Screenshots", screenshots, (file) => setState(() => screenshots = file)),
                    _buildFilePicker("Video Demo", videoDemo, (file) => setState(() => videoDemo = file)),
                    const SizedBox(height: 16),
                    Text("Checklist", style: Theme.of(context).textTheme.titleMedium),
                    CheckboxListTile(
                      value: checklistTestsPassing,
                      title: const Text("All tests passing"),
                      onChanged: (val) => setState(() => checklistTestsPassing = val ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    CheckboxListTile(
                      value: checklistDeployedStaging,
                      title: const Text("Deployed to staging"),
                      onChanged: (val) => setState(() => checklistDeployedStaging = val ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    CheckboxListTile(
                      value: checklistDocumentation,
                      title: const Text("Documentation complete"),
                      onChanged: (val) => setState(() => checklistDocumentation = val ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    CheckboxListTile(
                      value: checklistNoCriticalBugs,
                      title: const Text("No critical bugs"),
                      onChanged: (val) => setState(() => checklistNoCriticalBugs = val ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await submissionProvider.submitTask(
                              taskId: widget.taskId,
                              repoUrl: repoUrlController.text,
                              commitHash: commitHashController.text,
                              stagingUrl: stagingUrlController.text,
                              liveDemoUrl: liveDemoController.text,
                              apkUrl: apkUrlController.text,
                              testflightLink: testflightController.text,
                              adminUsername: adminUsernameController.text,
                              adminPassword: adminPasswordController.text,
                              accessInstructions: accessInstructionsController.text,
                              deploymentInstructions: deploymentInstructionsController.text,
                              testInstructions: testInstructionsController.text,
                              releaseNotes: releaseNotesController.text,
                              revisionNotes: revisionNotesController.text,
                              checklistTestsPassing: checklistTestsPassing,
                              checklistDeployedStaging: checklistDeployedStaging,
                              checklistDocumentation: checklistDocumentation,
                              checklistNoCriticalBugs: checklistNoCriticalBugs,
                              zipFile: zipFile,
                              screenshots: screenshots,
                              videoDemo: videoDemo,
                            );
                          }
                        },
                        child: const Text("Submit Task"),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFilePicker(String label, PlatformFile? file, Function(PlatformFile) onPicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.isNotEmpty) {
            onPicked(result.files.first);
          }
        },
        icon: const Icon(Icons.upload_file),
        label: Text(file != null ? "Uploaded: ${file.name}" : label),
      ),
    );
  }
}
