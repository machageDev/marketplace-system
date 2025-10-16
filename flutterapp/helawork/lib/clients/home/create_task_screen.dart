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
    print('=== CREATE TASK STARTED ===');
    
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors above'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if category is selected
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      print('❌ Category not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Form validation passed');
    print('📝 Task data:');
    print('   Title: ${_titleController.text}');
    print('   Category: $_selectedCategory');
    print('   Description length: ${_descriptionController.text.length}');
    print('   Budget: ${_budgetController.text}');
    print('   Deadline: $_selectedDeadline');
    print('   Skills: ${_skillsController.text}');
    print('   Urgent: $_isUrgent');

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      print('🚀 Calling taskProvider.createTask...');
      
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

      print('📦 Task creation result: $result');

      if (mounted) {
        if (result['success'] == true) {
          print('✅ Task created successfully!');
          _showSuccessDialog(result['message'] ?? 'Task created successfully!');
        } else {
          print('❌ Task creation failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create task'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    if (value == null || value.isEmpty) {
      print('❌ Title validation failed: Empty');
      return 'Please enter a task title';
    }
    if (value.length > 255) {
      print('❌ Title validation failed: Too long');
      return 'Title must be less than 255 characters';
    }
    print('✅ Title validation passed');
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      print('❌ Description validation failed: Empty');
      return 'Please enter a task description';
    }
    if (value.length < 10) { // Reduced from 50 to 10 for testing
      print('❌ Description validation failed: Too short (${value.length} chars)');
      return 'Please provide a more detailed description (at least 10 characters)';
    }
    print('✅ Description validation passed (${value.length} chars)');
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      print('❌ Category validation failed: Not selected');
      return 'Please select a category';
    }
    print('✅ Category validation passed: $value');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Task',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This task will be visible to all freelancers',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter a clear task title',
                            ),
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              border: OutlineInputBorder(),
                              hintText: 'Describe your task in detail (at least 10 characters)',
                            ),
                            validator: _validateDescription,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(),
                              hintText: 'Select a category',
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
                                      ))
                                  .toList(),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedCategory = val);
                              print('Category changed to: $val');
                            },
                            validator: _validateCategory,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Budget (Ksh)',
                              border: OutlineInputBorder(),
                              prefixText: 'Ksh ',
                              hintText: 'Optional',
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Deadline',
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDeadline == null
                                        ? 'Select date (optional)'
                                        : "${_selectedDeadline!.toLocal()}".split(' ')[0],
                                    style: TextStyle(
                                      color: _selectedDeadline == null ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _skillsController,
                            decoration: const InputDecoration(
                              labelText: 'Required Skills',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., Flutter, Django, UI/UX (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Mark as Urgent'),
                            subtitle: const Text('Highlight this task to freelancers'),
                            value: _isUrgent,
                            onChanged: (v) => setState(() => _isUrgent = v),
                          ),
                          const SizedBox(height: 24),

                          // Buttons column to prevent overflow
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: taskProvider.isLoading ? null : _createTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
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
                                    : const Text('Create Task'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: taskProvider.isLoading 
                                    ? null 
                                    : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                          
                          // Debug info
                          const SizedBox(height: 20),
                          Card(
                            color: Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Category: $_selectedCategory'),
                                  Text('Description length: ${_descriptionController.text.length}'),
                                  Text('Title length: ${_titleController.text.length}'),
                                ],
                              ),
                            ),
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