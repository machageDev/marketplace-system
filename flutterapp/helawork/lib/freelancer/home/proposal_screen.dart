import 'package:flutter/material.dart';
import 'package:helawork/freelancer/model/proposal_model.dart';
import 'package:helawork/freelancer/provider/proposal_provider.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
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
  final _bidAmountController = TextEditingController();
  final _coverLetterController = TextEditingController();
  int? selectedTaskId;
  int _estimatedDays = 7;
  
  PlatformFile? _selectedCoverLetterPdf;
  bool _isPdfPicked = false;
  bool _isPdfUploading = false;

  @override
  void initState() {
    super.initState();
    print('ProposalsScreen initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    print('_loadInitialData started');
    if (!mounted) return;
    
    final proposalProvider = Provider.of<ProposalProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    try {
      print('Fetching proposals...');
      await proposalProvider.fetchProposals();
      print('Fetching tasks...');
      await taskProvider.fetchTasksForProposals(context);
      print('Initial data loaded successfully');
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> _pickCoverLetterPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, 
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedCoverLetterPdf = result.files.single;
          _isPdfPicked = true;
        });
        print('Cover letter PDF selected: ${_selectedCoverLetterPdf!.name}');
        print('File size: ${_selectedCoverLetterPdf!.size} bytes');
      } else {
        print('No PDF file selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No PDF file selected"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error picking PDF file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error selecting PDF file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearCoverLetterPdf() {
    setState(() {
      _selectedCoverLetterPdf = null;
      _isPdfPicked = false;
    });
    print('Cover letter PDF cleared');
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _coverLetterController.dispose();
    super.dispose();
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
                if (!showCreateForm) {
                  _resetForm();
                }
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

  Widget _buildCreateForm(ProposalProvider proposalProvider, TaskProvider taskProvider) {
    if (taskProvider.availableTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No available tasks",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              "All tasks are currently assigned or approved",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Select Task",
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedTaskId,
                items: taskProvider.availableTasks
                    .map((task) => DropdownMenuItem<int>(
                          value: task['id'],
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 48.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task['title'] ?? 'Untitled Task',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (task['employer']?['company_name'] != null)
                                  Text(
                                    'Client: ${task['employer']?['company_name']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
                validator: (val) => val == null ? 'Please select a task' : null,
                onChanged: (val) {
                  setState(() {
                    selectedTaskId = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _bidAmountController,
                decoration: const InputDecoration(
                  labelText: "Bid Amount",
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a bid amount';
                  }
                  if (double.tryParse(val) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Estimated Completion Days",
                  border: OutlineInputBorder(),
                ),
                initialValue: _estimatedDays,
                items: [7, 10, 14, 21, 30, 45, 60]
                    .map((days) => DropdownMenuItem<int>(
                          value: days,
                          child: Text('$days days'),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _estimatedDays = val ?? 7;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  labelText: "Cover Letter (Text)",
                  border: OutlineInputBorder(),
                  hintText: "Describe your proposal...",
                ),
                maxLines: 4,
                minLines: 2,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your cover letter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cover Letter PDF (Optional)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Upload additional cover letter as PDF",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _isPdfPicked
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCoverLetterPdf!.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${(_selectedCoverLetterPdf!.size / 1024).toStringAsFixed(2)} KB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                                  onPressed: _clearCoverLetterPdf,
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _pickCoverLetterPdf,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload PDF (Optional)"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (proposalProvider.isLoading || _isPdfUploading) 
                      ? null 
                      : _submitProposal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: (proposalProvider.isLoading || _isPdfUploading)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Submit Proposal",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProposal() async {
    final proposalProvider = Provider.of<ProposalProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    print('_submitProposal method started');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation FAILED');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the form errors"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedTaskId == null) {
      print('No task selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a task"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isPdfUploading = true;
      });

      final task = taskProvider.availableTasks.firstWhere(
        (task) => task['id'] == selectedTaskId,
        orElse: () => {'title': 'Selected Task'}
      );
      final taskTitle = task['title'] ?? 'Selected Task';

      final proposal = Proposal(
        taskId: selectedTaskId!,
        freelancerId: 1,
        coverLetter: _coverLetterController.text,
        bidAmount: double.parse(_bidAmountController.text),
        estimatedDays: _estimatedDays,
        status: "pending",
        title: taskTitle,
      );

      print('Submitting proposal...');
      print('Task ID: ${proposal.taskId}');
      print('Bid Amount: ${proposal.bidAmount}');
      print('Estimated Days: ${proposal.estimatedDays}');
      print('Cover Letter: ${proposal.coverLetter}');
      print('PDF File: ${_selectedCoverLetterPdf?.name}');
      
      await proposalProvider.addProposal(
        proposal, 
        pdfFile: _selectedCoverLetterPdf
      );
      
      print('Proposal submitted successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Proposal submitted successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _resetForm();
      setState(() {
        showCreateForm = false;
      });

    } catch (e, stackTrace) {
      print('ERROR in _submitProposal: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting proposal: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isPdfUploading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _bidAmountController.clear();
    _coverLetterController.clear();
    setState(() {
      selectedTaskId = null;
      _estimatedDays = 7;
      _selectedCoverLetterPdf = null;
      _isPdfPicked = false;
      _isPdfUploading = false;
    });
  }

  Widget _buildProposalsList(ProposalProvider provider) {
    if (provider.proposals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No proposals yet",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              "Tap the + button to create your first proposal",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<ProposalProvider>(context, listen: false).fetchProposals(),
      child: ListView.builder(
        itemCount: provider.proposals.length,
        itemBuilder: (context, index) {
          final proposal = provider.proposals[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proposal.title != null)
                    Text(
                      proposal.title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "Task ID: ${proposal.taskId}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bid: \$${proposal.bidAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Estimated Days: ${proposal.estimatedDays}",
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  if (proposal.coverLetter != null && proposal.coverLetter!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cover Letter:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          proposal.coverLetter!.length > 150
                              ? "${proposal.coverLetter!.substring(0, 150)}..."
                              : proposal.coverLetter!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "Status: ${proposal.status}",
                    style: TextStyle(
                      color: proposal.status.toLowerCase() == "accepted"
                          ? Colors.green
                          : proposal.status.toLowerCase() == "rejected"
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (proposal.submittedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Submitted: ${proposal.submittedAt!.toString().split(' ')[0]}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}