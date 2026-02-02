import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helawork/freelancer/provider/submission_provider.dart';

class SubmitTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String budget;

  const SubmitTaskScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.budget, required contractId,
  });

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Consolidate controllers to match simplified API
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  PlatformFile? zipFile;
  PlatformFile? document;

  @override
  void initState() {
    super.initState();
    _titleController.text = "Submission: ${widget.taskTitle}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final provider = Provider.of<SubmissionProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    // Custom Logic: User must provide either a Link OR a Zip file
    if (_urlController.text.isEmpty && zipFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least a project URL or a ZIP file.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await provider.submitTask(
      taskId: widget.taskId,
      title: _titleController.text,
      description: _descriptionController.text,
      url: _urlController.text,
      zipFile: zipFile,
      document: document,
    );

    if (provider.errorMessage.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task submitted successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubmissionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Task"),
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskHeader(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle("Work Details"),
                    _buildTextField(_titleController, "Submission Title", isRequired: true),
                    _buildTextField(_urlController, "Main Project Link (GitHub / Live Demo)", 
                      hint: "https://..."),
                    _buildTextField(
                      _descriptionController, 
                      "Description & Instructions", 
                      isRequired: true, 
                      maxLines: 5,
                      hint: "Describe what you've completed. Include any credentials or testing notes here."
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle("Attachments"),
                    _buildFileTile("Source Code (ZIP)", zipFile, (file) => setState(() => zipFile = file)),
                    _buildFileTile("Documentation / Proof (PDF/Image)", document, (file) => setState(() => document = file)),

                    const SizedBox(height: 40),
                    
                    if (provider.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(provider.errorMessage, style: const TextStyle(color: Colors.red)),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("SUBMIT WORK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI Components ---

  Widget _buildTaskHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.taskTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text("Budget: \$${widget.budget}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: isRequired ? (value) => (value == null || value.isEmpty) ? "Field required" : null : null,
      ),
    );
  }

  Widget _buildFileTile(String label, PlatformFile? selectedFile, Function(PlatformFile) onPicked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(selectedFile == null ? Icons.upload_file : Icons.check_circle, 
             color: selectedFile == null ? Colors.grey : Colors.green),
        title: Text(selectedFile?.name ?? label),
        subtitle: selectedFile != null ? Text("${(selectedFile.size / 1024).toStringAsFixed(1)} KB") : const Text("Tap to select"),
        trailing: selectedFile != null 
          ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() {
              if (label.contains("Source")) zipFile = null; else document = null;
            }))
          : null,
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles();
          if (result != null) onPicked(result.files.first);
        },
      ),
    );
  }
}