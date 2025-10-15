// lib/clients/screens/create_task_screen.dart
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

  String _selectedCategory = '';
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
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _createTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final result = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        budget: _budgetController.text.trim().isEmpty ? null : double.parse(_budgetController.text.trim()),
        deadline: _selectedDeadline,
        skills: _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
        isUrgent: _isUrgent,
      );

      if (result['success'] == true && mounted) {
        _showSuccessDialog(result['message'] ?? 'Task created successfully!');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Created'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TasksScreen(),
                  ),
                );
              },
              child: const Text('View Tasks'),
            ),
          ],
        );
      },
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a task title';
    }
    if (value.length > 255) {
      return 'Title must be less than 255 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a task description';
    }
    if (value.length < 50) {
      return 'Please provide a more detailed description (at least 50 characters)';
    }
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue, Colors.lightBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create New Task',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This task will be immediately visible to all freelancers',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Visible to Freelancers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (taskProvider.errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              taskProvider.errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Main Form Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionHeader(
                            'Basic Information',
                            Icons.info,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),

                          // Task Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title *',
                              hintText: 'e.g., Website Development, Mobile App Design, Content Writing Service',
                              border: OutlineInputBorder(),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            maxLength: 255,
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a clear and descriptive title (max 255 characters)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Task Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Task Description *',
                              hintText: 'Describe the task in detail including specific requirements, deliverables, timeline, and instructions...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            maxLines: 6,
                            validator: _validateDescription,
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Be specific about requirements, deliverables, and expectations. Clear descriptions attract better proposals.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_descriptionController.text.length} characters',
                                style: TextStyle(
                                  color: _descriptionController.text.length < 50
                                      ? Colors.red
                                      : _descriptionController.text.length < 100
                                          ? Colors.orange
                                          : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Category & Budget Section
                          _buildSectionHeader(
                            'Category & Budget',
                            Icons.category,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              // Category Dropdown
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category *',
                                    border: OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                  ),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category['value'],
                                      child: Text(category['label']!),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                  validator: _validateCategory,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Budget Field
                              Expanded(
                                child: TextFormField(
                                  controller: _budgetController,
                                  decoration: const InputDecoration(
                                    labelText: 'Budget (Ksh)',
                                    prefixText: 'Ksh ',
                                    border: OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose the most relevant category. Estimated budget is optional and may attract more proposals with varying prices.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Timeline & Requirements Section
                          _buildSectionHeader(
                            'Timeline & Requirements',
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              // Deadline Picker
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Deadline',
                                      border: OutlineInputBorder(),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDeadline == null
                                              ? 'Select a date'
                                              : '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: _selectedDeadline == null
                                                ? Colors.grey.shade400
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Skills Field
                              Expanded(
                                child: TextFormField(
                                  controller: _skillsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Required Skills',
                                    hintText: 'e.g., Python, Django, React, Graphic Design, SEO',
                                    border: OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set a realistic deadline for task completion. Separate multiple skills with commas.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Additional Options Section
                          _buildSectionHeader(
                            'Additional Options',
                            Icons.settings,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),

                          SwitchListTile(
                            title: const Text(
                              'Mark as Urgent',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'This task will be highlighted to freelancers as high priority',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            value: _isUrgent,
                            onChanged: (value) {
                              setState(() {
                                _isUrgent = value;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          const SizedBox(height: 32),

                          // Form Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This task will be immediately visible to freelancers after creation',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const TasksScreen(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.close),
                                        SizedBox(width: 8),
                                        Text('Cancel'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: taskProvider.isLoading ? null : _createTask,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: taskProvider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Row(
                                            children: [
                                              Icon(Icons.add),
                                              SizedBox(width: 8),
                                              Text('Create Task'),
                                            ],
                                          ),
                                  ),
                                ],
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}