import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_task_scren.dart';
import 'package:helawork/client/provider/client_task_provider.dart';
import 'package:provider/provider.dart';

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
  final _addressController = TextEditingController();

  // New Hybrid Fields
  String _serviceType = 'remote'; // Default (Upwork style)
  String _paymentType = 'fixed';  // Default
  String? _selectedCategory;
  DateTime? _selectedDeadline;
  bool _isUrgent = false;

  final List<Map<String, String>> _categories = [
    {'value': 'web', 'label': 'Web Development'},
    {'value': 'mobile', 'label': 'Mobile Development'},
    {'value': 'design', 'label': 'Design'},
    {'value': 'cleaning', 'label': 'Cleaning & Housekeeping'},
    {'value': 'handyman', 'label': 'Handyman & Repairs'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  void _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    final result = await taskProvider.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      serviceType: _serviceType,
      paymentType: _paymentType,
      budget: double.tryParse(_budgetController.text.trim()),
      deadline: _selectedDeadline,
      skills: _skillsController.text.trim(),
      isUrgent: _isUrgent,
      locationAddress: _serviceType == 'on_site' ? _addressController.text.trim() : null,
      // Note: For TaskRabbit functionality, you'd pass actual lat/lng here
      latitude: null, 
      longitude: null,
    );

    if (mounted) {
      if (result['success'] == true) {
        _showSuccessDialog(result['message']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
            },
            child: const Text('View My Tasks'),
          ),
        ],
      ),
    );
  }

  // UI Components
  Widget _buildTextField({required TextEditingController controller, required String label, String? hint, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  // Build Service Type Selector Card
  Widget _buildServiceTypeCard({required String type, required String label, required IconData icon}) {
    bool isSelected = _serviceType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _serviceType = type),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellow[600] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.amber[900] : Colors.grey[700],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.amber[900] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.amber[900],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TaskProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Post a Task'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    'Post a New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose between remote (digital) or on-site (physical) service',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 1. SERVICE TYPE SELECTOR (Hybrid Logic)
                      const Text(
                        "What kind of service is this? *",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Service Type Cards
                      Row(
                        children: [
                          _buildServiceTypeCard(
                            type: 'remote',
                            label: 'Remote\n(Digital Work)',
                            icon: Icons.computer,
                          ),
                          const SizedBox(width: 15),
                          _buildServiceTypeCard(
                            type: 'on_site',
                            label: 'On-Site\n(Physical Work)',
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // 2. FORM FIELDS
                      _buildTextField(
                        controller: _titleController,
                        label: "Task Title *",
                        validator: (v) => v!.isEmpty ? "Enter title" : null,
                      ),

                      // Dynamic Address Field (Only for TaskRabbit style)
                      if (_serviceType == 'on_site')
                        _buildTextField(
                          controller: _addressController,
                          label: "Exact Location Address *",
                          hint: "Street, City, House No.",
                          validator: (v) => (_serviceType == 'on_site' && v!.isEmpty) ? "Location is required for on-site tasks" : null,
                        ),

                      _buildTextField(
                        controller: _descriptionController,
                        label: "Description *",
                        maxLines: 4,
                        validator: (v) => v!.length < 10 ? "Description too short" : null,
                      ),

                      // Category Dropdown
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Category *",
                            contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select a category', style: TextStyle(color: Colors.grey)),
                            ),
                            ..._categories.map((c) => DropdownMenuItem(
                                  value: c['value'],
                                  child: Text(c['label']!),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          validator: (v) => v == null ? "Please select a category" : null,
                        ),
                      ),

                      // Payment Type & Budget
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Budget (Ksh)",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                  prefixText: 'Ksh ',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _paymentType,
                                underline: Container(),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'fixed', child: Text("Fixed")),
                                  DropdownMenuItem(value: 'hourly', child: Text("Hourly")),
                                ],
                                onChanged: (v) => setState(() => _paymentType = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Deadline
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
                            labelText: 'Required Skills (optional)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintText: 'e.g., Flutter, Cleaning, Plumbing',
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
                          subtitle: const Text('Highlight this task to service providers'),
                          value: _isUrgent,
                          activeThumbColor: Colors.blueAccent,
                          activeTrackColor: Colors.blueAccent.withOpacity(0.5),
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
                              onPressed: isLoading ? null : _createTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Post Task Now',
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
                              onPressed: isLoading
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
            ),
          ],
        ),
      ),
    );
  }
}