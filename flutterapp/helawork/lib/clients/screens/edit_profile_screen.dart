import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/client_profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final int employerId;
  final Map<String, dynamic>? currentProfile;

  const EditProfileScreen({
    super.key,
    required this.employerId,
    this.currentProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize form data with current profile or empty values
    _formData = {
      'company_name': widget.currentProfile?['company_name'] ?? '',
      'contact_email': widget.currentProfile?['contact_email'] ?? '',
      'phone_number': widget.currentProfile?['phone_number'] ?? '',
      'address': widget.currentProfile?['address'] ?? '',
      'website': widget.currentProfile?['website'] ?? '',
      'business_type': widget.currentProfile?['business_type'] ?? '',
      'industry': widget.currentProfile?['industry'] ?? '',
      'tax_id': widget.currentProfile?['tax_id'] ?? '',
      'description': widget.currentProfile?['description'] ?? '',
    };
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    
    try {
      final success = await provider.updateProfile(widget.employerId, _formData);
      
      if (success) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${provider.errorMessage ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF1976D2);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: Text(
          widget.currentProfile == null ? 'Create Profile' : 'Edit Profile',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Required Fields
              _buildTextField(
                label: 'Company Name *',
                fieldName: 'company_name',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Contact Email *',
                fieldName: 'contact_email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Phone Number *',
                fieldName: 'phone_number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Address',
                fieldName: 'address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              
              // Optional Fields
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              
              _buildTextField(
                label: 'Website',
                fieldName: 'website',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              _buildTextField(
                label: 'Business Type',
                fieldName: 'business_type',
                icon: Icons.category,
              ),
              _buildTextField(
                label: 'Industry',
                fieldName: 'industry',
                icon: Icons.work,
              ),
              _buildTextField(
                label: 'Tax ID',
                fieldName: 'tax_id',
                icon: Icons.badge,
              ),
              _buildTextField(
                label: 'Description',
                fieldName: 'description',
                icon: Icons.description,
                maxLines: 4,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.currentProfile == null 
                              ? 'Create Profile' 
                              : 'Update Profile',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String fieldName,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: _formData[fieldName],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2).withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 0,
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onSaved: (value) {
          _formData[fieldName] = value?.trim() ?? '';
        },
      ),
    );
  }
}