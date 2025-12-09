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

  // ========== REQUIRED FIELDS ==========
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // ========== OPTIONAL FIELDS ==========
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
        automaticallyImplyLeading: true, // Changed back to show back arrow
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
                    // ========== REQUIRED SECTION ==========
                    const Text(
                      "Required Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title (REQUIRED)
                    _buildRequiredTextField(
                      titleController,
                      'Submission Title *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        if (value.length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    
                    // Description (REQUIRED)
                    _buildRequiredTextField(
                      descriptionController,
                      'Description *',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        if (value.length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ========== OPTIONAL SECTION ==========
                    const Text(
                      "Optional Submission Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Repository Section
                    const Text(
                      "Code Repository",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    _buildTextField(repoUrlController, 'Repository URL (optional)'),
                    _buildTextField(commitHashController, 'Commit Hash (optional)'),
                    
                    const SizedBox(height: 12),
                    
                    // Deployment URLs Section
                    const Text(
                      "Deployment URLs",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    _buildTextField(stagingUrlController, 'Staging URL (optional)'),
                    _buildTextField(liveDemoController, 'Live Demo URL (optional)'),
                    _buildTextField(apkUrlController, 'APK Download URL (optional)'),
                    _buildTextField(testflightController, 'TestFlight Link (optional)'),
                    
                    const SizedBox(height: 12),
                    
                    // Admin Access Section
                    const Text(
                      "Admin Access (Optional)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    _buildTextField(adminUsernameController, 'Admin Username'),
                    _buildTextField(adminPasswordController, 'Admin Password', obscure: true),
                    
                    // Instructions Section
                    const SizedBox(height: 12),
                    const Text(
                      "Instructions & Notes",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    _buildTextField(accessInstructionsController, 'Access Instructions', maxLines: 3),
                    _buildTextField(deploymentInstructionsController, 'Deployment Instructions', maxLines: 3),
                    _buildTextField(testInstructionsController, 'Test Instructions', maxLines: 3),
                    _buildTextField(releaseNotesController, 'Release Notes', maxLines: 3),
                    _buildTextField(revisionNotesController, 'Revision Notes (if resubmitting)', maxLines: 3),
                    
                    const SizedBox(height: 16),
                    
                    // ========== FILE UPLOADS ==========
                    Row(
                      children: [
                        const Text(
                          "Upload Files",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "(At least one method required: URL or File)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    _buildFilePicker(
                      "ZIP File (Source Code)",
                      zipFile,
                      (file) => setState(() => zipFile = file),
                    ),
                    _buildFilePicker(
                      "Screenshots",
                      screenshots,
                      (file) => setState(() => screenshots = file),
                    ),
                    _buildFilePicker(
                      "Video Demo",
                      videoDemo,
                      (file) => setState(() => videoDemo = file),
                    ),
                    
                    // File upload status
                    if (zipFile != null || screenshots != null || videoDemo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          "Files ready: ${[
                            if (zipFile != null) zipFile!.name,
                            if (screenshots != null) screenshots!.name,
                            if (videoDemo != null) videoDemo!.name,
                          ].join(', ')}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    // ========== CHECKLIST ==========
                    const SizedBox(height: 16),
                    const Text(
                      "Checklist",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Checklist items with improved styling
                    _buildCheckboxItem(
                      "All tests passing",
                      checklistTestsPassing,
                      (val) => setState(() => checklistTestsPassing = val ?? false),
                    ),
                    _buildCheckboxItem(
                      "Deployed to staging",
                      checklistDeployedStaging,
                      (val) => setState(() => checklistDeployedStaging = val ?? false),
                    ),
                    _buildCheckboxItem(
                      "Documentation complete",
                      checklistDocumentation,
                      (val) => setState(() => checklistDocumentation = val ?? false),
                    ),
                    _buildCheckboxItem(
                      "No critical bugs",
                      checklistNoCriticalBugs,
                      (val) => setState(() => checklistNoCriticalBugs = val ?? false),
                    ),
                    
                    // Checklist summary
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            _isChecklistComplete() ? Icons.check_circle : Icons.error,
                            color: _isChecklistComplete() ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isChecklistComplete() 
                                ? "All checklist items completed" 
                                : "Some checklist items pending",
                            style: TextStyle(
                              color: _isChecklistComplete() ? Colors.green : Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // ========== SUBMIT BUTTON ==========
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () => _submitTask(context, submissionProvider),
                        child: const Text(
                          "Submit Task",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    
                    // Error message
                    if (submissionProvider.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          submissionProvider.errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // ========== HELPER METHODS ==========
  
  bool _isChecklistComplete() {
    return checklistTestsPassing && 
           checklistDeployedStaging && 
           checklistDocumentation && 
           checklistNoCriticalBugs;
  }

  void _submitTask(BuildContext context, SubmissionProvider submissionProvider) async {
    // Validate required fields
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    
    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return;
    }
    
    // Validate at least one submission method
    bool hasUrl = repoUrlController.text.isNotEmpty ||
                  stagingUrlController.text.isNotEmpty ||
                  liveDemoController.text.isNotEmpty ||
                  apkUrlController.text.isNotEmpty ||
                  testflightController.text.isNotEmpty;
    
    bool hasFile = zipFile != null || screenshots != null || videoDemo != null;
    
    if (!hasUrl && !hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least one: URL or file upload'),
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      try {
        await submissionProvider.submitTask(
          taskId: widget.taskId,
          title: titleController.text,  // ADDED - REQUIRED
          description: descriptionController.text,  // ADDED - REQUIRED
          repoUrl: repoUrlController.text.isNotEmpty ? repoUrlController.text : null,
          commitHash: commitHashController.text.isNotEmpty ? commitHashController.text : null,
          stagingUrl: stagingUrlController.text.isNotEmpty ? stagingUrlController.text : null,
          liveDemoUrl: liveDemoController.text.isNotEmpty ? liveDemoController.text : null,
          apkUrl: apkUrlController.text.isNotEmpty ? apkUrlController.text : null,
          testflightLink: testflightController.text.isNotEmpty ? testflightController.text : null,
          adminUsername: adminUsernameController.text.isNotEmpty ? adminUsernameController.text : null,
          adminPassword: adminPasswordController.text.isNotEmpty ? adminPasswordController.text : null,
          accessInstructions: accessInstructionsController.text.isNotEmpty ? accessInstructionsController.text : null,
          deploymentInstructions: deploymentInstructionsController.text.isNotEmpty ? deploymentInstructionsController.text : null,
          testInstructions: testInstructionsController.text.isNotEmpty ? testInstructionsController.text : null,
          releaseNotes: releaseNotesController.text.isNotEmpty ? releaseNotesController.text : null,
          revisionNotes: revisionNotesController.text.isNotEmpty ? revisionNotesController.text : null,
          checklistTestsPassing: checklistTestsPassing,
          checklistDeployedStaging: checklistDeployedStaging,
          checklistDocumentation: checklistDocumentation,
          checklistNoCriticalBugs: checklistNoCriticalBugs,
          zipFile: zipFile,
          screenshots: screenshots,
          videoDemo: videoDemo,
        );

        // Check if submission was successful
        if (submissionProvider.errorMessage.isEmpty) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back after a delay
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Check if widget is still mounted before navigating
          if (mounted) {
            Navigator.pop(context, true); // Pass true to indicate success
          }
        } else {
          // Show error from provider
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${submissionProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== WIDGET BUILDERS ==========
  
  Widget _buildRequiredTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue, // Highlight required fields
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.blue[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          hintText: 'Optional',
          hintStyle: const TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String title, bool value, Function(bool?) onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: CheckboxListTile(
        value: value,
        title: Text(title),
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        secondary: Icon(
          value ? Icons.check_circle : Icons.radio_button_unchecked,
          color: value ? Colors.green : Colors.grey,
        ),
        tileColor: value ? Colors.green[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFilePicker(String label, PlatformFile? file, Function(PlatformFile) onPicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            Icons.attach_file,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            file != null ? file.name : label,
            style: TextStyle(
              fontWeight: file != null ? FontWeight.bold : FontWeight.normal,
              color: file != null ? Colors.green : Colors.black87,
            ),
          ),
          subtitle: file != null
              ? Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12),
                )
              : null,
          trailing: file != null
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() {
                    if (label.contains('ZIP')) zipFile = null;
                    if (label.contains('Screenshot')) screenshots = null;
                    if (label.contains('Video')) videoDemo = null;
                  }),
                )
              : null,
          onTap: () async {
            final result = await FilePicker.platform.pickFiles();
            if (result != null && result.files.isNotEmpty) {
              onPicked(result.files.first);
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    titleController.dispose();
    descriptionController.dispose();
    repoUrlController.dispose();
    commitHashController.dispose();
    stagingUrlController.dispose();
    liveDemoController.dispose();
    apkUrlController.dispose();
    testflightController.dispose();
    adminUsernameController.dispose();
    adminPasswordController.dispose();
    accessInstructionsController.dispose();
    deploymentInstructionsController.dispose();
    testInstructionsController.dispose();
    releaseNotesController.dispose();
    revisionNotesController.dispose();
    super.dispose();
  }
}