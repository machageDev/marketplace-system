import 'package:flutter/material.dart';
import 'package:helawork/clients/home/client_task_screen.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/task_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDeadline;
  bool _isUrgent = false;

  final List<Map<String, String>> _categories = [
    {'value': 'web', 'label': 'Web Development'},
    {'value': 'mobile', 'label': 'Mobile Development'},
    {'value': 'design', 'label': 'Design'},
    {'value': 'writing', 'label': 'Content Writing'},
    {'value': 'marketing', 'label': 'Digital Marketing'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() => _selectedDeadline = picked);
    }
  }

  void _createTask() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors above'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final result = await taskProvider.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      budget: _budgetController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetController.text.trim()),
      deadline: _selectedDeadline,
      skills: _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
      isUrgent: _isUrgent,
    );

    if (mounted) {
      if (result['success'] == true) {
        _showSuccessDialog(result['message'] ?? 'Task created successfully!');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Task Created'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TasksScreen()),
              );
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a task title';
    if (value.length > 255) return 'Title must be less than 255 characters';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a task description';
    if (value.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Please select a category';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header Card with Blue Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Task',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This task will be visible to all freelancers',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Card with Blue Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Title Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Task Title *',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                hintText: 'Enter a clear task title',
                              ),
                              validator: _validateTitle,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Description *',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                hintText: 'Describe your task in detail',
                              ),
                              validator: _validateDescription,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  border: InputBorder.none,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Select a category', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ..._categories
                                      .map((cat) => DropdownMenuItem(
                                            value: cat['value'],
                                            child: Text(cat['label']!),
                                          )),
                                ],
                                onChanged: (val) => setState(() => _selectedCategory = val),
                                validator: _validateCategory,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Budget Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Budget (Ksh)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                prefixText: 'Ksh ',
                                hintText: 'Optional',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Deadline Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDeadline == null
                                          ? 'Select deadline (optional)'
                                          : "${_selectedDeadline!.toLocal()}".split(' ')[0],
                                      style: TextStyle(
                                        color: _selectedDeadline == null ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, color: Colors.blueAccent),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Skills Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _skillsController,
                              decoration: const InputDecoration(
                                labelText: 'Required Skills',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                hintText: 'e.g., Flutter, Django, UI/UX (optional)',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Urgent Switch
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              title: const Text('Mark as Urgent'),
                              subtitle: const Text('Highlight this task to freelancers'),
                              value: _isUrgent,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) => setState(() => _isUrgent = v),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: taskProvider.isLoading ? null : _createTask,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: taskProvider.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Create Task',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: taskProvider.isLoading
                                      ? null
                                      : () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const TasksScreen()),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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