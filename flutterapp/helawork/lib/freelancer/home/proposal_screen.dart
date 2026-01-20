import 'package:flutter/material.dart';
import 'package:helawork/freelancer/model/proposal_model.dart';
import 'package:helawork/freelancer/provider/proposal_provider.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class ProposalsScreen extends StatefulWidget {
  final int? taskId;
  final Map<String, dynamic>? task;
  final Map<String, dynamic>? employer;

  const ProposalsScreen({
    super.key,
    this.taskId,
    this.task,
    this.employer,
  });

  @override
  State<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  bool showCreateForm = false;
  final _formKey = GlobalKey<FormState>();
  
  // 📝 Removed _coverLetterController (Text field no longer used)
  int? selectedTaskId;
  int _estimatedDays = 7;
  
  PlatformFile? _selectedCoverLetterPdf;
  bool _isPdfPicked = false;
  bool _isPdfUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final proposalProvider = Provider.of<ProposalProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    try {
      await proposalProvider.fetchProposals();
      await taskProvider.fetchTasksForProposals(context);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    // 🗑️ Controller disposal removed
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      selectedTaskId = null;
      _estimatedDays = 7;
      _selectedCoverLetterPdf = null;
      _isPdfPicked = false;
      _isPdfUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final proposalProvider = Provider.of<ProposalProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Proposals"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(showCreateForm ? Icons.list : Icons.add),
            onPressed: () {
              setState(() {
                showCreateForm = !showCreateForm;
                if (!showCreateForm) _resetForm();
              });
            },
          )
        ],
      ),
      body: proposalProvider.isLoading || taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : showCreateForm
              ? _buildCreateForm(proposalProvider, taskProvider)
              : _buildProposalsList(proposalProvider),
    );
  }

  // --- FORM WIDGETS ---

  Widget _buildCreateForm(ProposalProvider proposalProvider, TaskProvider taskProvider) {
    if (taskProvider.availableTasks.isEmpty) {
      return const Center(child: Text("No available tasks to apply for."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Select Task",
                border: OutlineInputBorder(),
              ),
              initialValue: selectedTaskId,
              items: taskProvider.availableTasks.map((task) {
                final id = task['task_id'] ?? task['id'];
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(task['title'] ?? 'Untitled'),
                );
              }).toList(),
              validator: (val) => val == null ? 'Please select a task' : null,
              onChanged: (val) => setState(() => selectedTaskId = val),
            ),
            
            if (selectedTaskId != null) ...[
              const SizedBox(height: 16),
              _buildFixedPriceCard(taskProvider),
              const SizedBox(height: 10),
              _buildLocationInfo(taskProvider),
            ],
            
            const SizedBox(height: 20),
            _buildEstimatedDaysDropdown(),
            const SizedBox(height: 20),
            
            // 📄 Updated PDF Section
            _buildMandatoryPdfSection(),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isPdfUploading || proposalProvider.isLoading) ? null : _submitProposal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: (_isPdfUploading || proposalProvider.isLoading)
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Proposal", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedPriceCard(TaskProvider taskProvider) {
    final task = taskProvider.availableTasks.firstWhere((t) => (t['task_id'] ?? t['id']) == selectedTaskId);
    final budget = task['budget'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Fixed Budget Payment", style: TextStyle(fontSize: 12)),
              Text("KSH $budget", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(TaskProvider taskProvider) {
    final task = taskProvider.availableTasks.firstWhere((t) => (t['task_id'] ?? t['id']) == selectedTaskId);
    if (task['service_type'] != 'on_site') return const SizedBox.shrink();
    return Text("📍 On-Site: ${task['location_address'] ?? 'Location N/A'}", style: const TextStyle(color: Colors.orange));
  }

  Widget _buildEstimatedDaysDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(labelText: "Days to Complete", border: OutlineInputBorder()),
      initialValue: _estimatedDays,
      items: [3, 7, 14, 30].map((d) => DropdownMenuItem(value: d, child: Text("$d Days"))).toList(),
      onChanged: (val) => setState(() => _estimatedDays = val ?? 7),
    );
  }

  // 🆕 New Mandatory PDF Picker Widget
  Widget _buildMandatoryPdfSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _isPdfPicked ? Colors.blue : Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 20),
              const SizedBox(width: 8),
              const Text("Upload Cover Letter (PDF Required)", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _isPdfPicked
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_present, color: Colors.blue),
                  title: Text(_selectedCoverLetterPdf!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() {
                      _isPdfPicked = false;
                      _selectedCoverLetterPdf = null;
                    }),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.upload),
                  label: const Text("Select PDF File"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
          if (!_isPdfPicked)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Please attach your cover letter as a PDF file.", style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['pdf'],
      withData: true, // Important for Mobile/Web providers to access bytes
    );
    if (result != null) {
      setState(() {
        _selectedCoverLetterPdf = result.files.single;
        _isPdfPicked = true;
      });
    }
  }

  Future<void> _submitProposal() async {
    // 🛑 Validate PDF presence
    if (!_isPdfPicked || _selectedCoverLetterPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a PDF cover letter"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || selectedTaskId == null) return;

    final proposalProvider = Provider.of<ProposalProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      setState(() => _isPdfUploading = true);
      
      final task = taskProvider.availableTasks.firstWhere((t) => (t['task_id'] ?? t['id']) == selectedTaskId);

      final proposal = Proposal(
        id: 0,
        taskId: selectedTaskId!,
        freelancerId: int.parse(authProvider.userId ?? "0"),
        // ✅ The "coverLetter" text field is now just the filename or a placeholder
        coverLetter: "PDF Attached: ${_selectedCoverLetterPdf!.name}",
        bidAmount: double.tryParse(task['budget'].toString()) ?? 0.0,
        estimatedDays: _estimatedDays,
        status: "pending",
        title: task['title'] ?? 'Task',
      );

      // Call the provider which handles the API multipart request
      await proposalProvider.addProposal(proposal, pdfFile: _selectedCoverLetterPdf);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proposal submitted!"), backgroundColor: Colors.green));
      _resetForm();
      setState(() => showCreateForm = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isPdfUploading = false);
    }
  }

  // --- LIST WIDGET ---

  Widget _buildProposalsList(ProposalProvider provider) {
    if (provider.proposals.isEmpty) return const Center(child: Text("No proposals found."));

    return RefreshIndicator(
      onRefresh: () => provider.fetchProposals(),
      child: ListView.builder(
        itemCount: provider.proposals.length,
        itemBuilder: (context, index) {
          final p = provider.proposals[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(p.title ?? "Proposal #${p.id}"),
              subtitle: Text("Price: KSH ${p.bidAmount} • Status: ${p.status}"),
              trailing: p.pdfUrl != null ? const Icon(Icons.picture_as_pdf, color: Colors.red) : const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}