import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/client_profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final int employerId;
  final Map<String, dynamic>? currentProfile;
  final bool isNewProfile;
  
  const EditProfileScreen({
    super.key,
    required this.employerId,
    this.currentProfile,
    this.isNewProfile = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize form data with current profile values
    if (widget.currentProfile != null) {
      _formData.addAll(widget.currentProfile!);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final provider = Provider.of<ClientProfileProvider>(context, listen: false);
      final success = await provider.saveProfile(widget.employerId, _formData);

      setState(() => _isSaving = false);

      if (success && context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isNewProfile 
                ? 'Profile created successfully!' 
                : 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF1976D2);
    const themeWhite = Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isNewProfile ? 'Create Profile' : 'Edit Profile',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(themeBlue),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.business,
                      size: 40,
                      color: Color(0xFF1976D2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isNewProfile 
                          ? 'Complete your business profile to get started'
                          : 'Update your business information',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Required Fields Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Company Name
              TextFormField(
                initialValue: _formData['company_name'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Company Name *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['company_name'] = value,
              ),
              const SizedBox(height: 16),

              // Business Type
              TextFormField(
                initialValue: _formData['business_type'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Business Type (e.g., LLC, Sole Proprietorship)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSaved: (value) => _formData['business_type'] = value,
              ),
              const SizedBox(height: 16),

              // Contact Information Section
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                initialValue: _formData['contact_email'] ?? '',
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onSaved: (value) => _formData['contact_email'] = value,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                initialValue: _formData['phone_number'] ?? '',
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['phone_number'] = value,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                initialValue: _formData['address'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSaved: (value) => _formData['address'] = value,
              ),
              const SizedBox(height: 24),

              // Optional Information Section
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Website
              TextFormField(
                initialValue: _formData['website'] ?? '',
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Website',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSaved: (value) => _formData['website'] = value,
              ),
              const SizedBox(height: 16),

              // Tax ID
              TextFormField(
                initialValue: _formData['tax_id'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Tax ID/VAT Number',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSaved: (value) => _formData['tax_id'] = value,
              ),
              const SizedBox(height: 16),

              // Industry
              TextFormField(
                initialValue: _formData['industry'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Industry',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSaved: (value) => _formData['industry'] = value,
              ),
              const SizedBox(height: 16),

              // Description/About
              TextFormField(
                initialValue: _formData['description'] ?? '',
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'About Your Business',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  alignLabelWithHint: true,
                ),
                onSaved: (value) => _formData['description'] = value,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    foregroundColor: themeWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isNewProfile ? 'CREATE PROFILE' : 'SAVE CHANGES',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}