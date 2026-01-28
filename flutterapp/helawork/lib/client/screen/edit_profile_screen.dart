import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentProfile;
  final bool isNewProfile;
  final int employerId;
  
  const EditProfileScreen({
    super.key,
    this.currentProfile,
    this.isNewProfile = false,
    required this.employerId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isSaving = false;
  
  // ADD THESE FOR PICTURE UPLOAD
  File? _selectedProfileImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.currentProfile != null) {
      _formData.addAll(widget.currentProfile!);
      // Remove 'country' if it exists in currentProfile
      _formData.remove('country');
    }
  }

  // ADD THESE PICTURE UPLOAD METHODS
  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });
        
        // Automatically upload after selection
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeProfilePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });
        
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedProfileImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final provider = Provider.of<ClientProfileProvider>(context, listen: false);
      final success = await provider.uploadProfilePicture(_selectedProfileImage!.path);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the current profile data
        setState(() {
          _selectedProfileImage = null;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isUploadingImage = false);
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1976D2)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  _pickProfileImage();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  _takeProfilePhoto();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final provider = Provider.of<ClientProfileProvider>(context, listen: false);
      
      // Remove fields that don't exist in Django model
      final cleanFormData = Map<String, dynamic>.from(_formData);
      
      // EXPLICITLY REMOVE 'country' field
      cleanFormData.remove('country');
      
      // Keep only fields that exist in Django model
      final validFields = [
        'full_name',
        'contact_email',
        'phone_number',
        'alternate_phone',
        'city',
        'address',
        'profession',
        'skills',
        'bio',
        'linkedin_url',
        'twitter_url',
        'id_number'  // For verification
      ];
      
      // Create filtered data with only valid fields
      final filteredData = <String, dynamic>{};
      for (final field in validFields) {
        if (cleanFormData.containsKey(field)) {
          filteredData[field] = cleanFormData[field] ?? '';
        }
      }
      
      // Handle skills as comma-separated string
      if (filteredData.containsKey('skills') && filteredData['skills'] is List) {
        filteredData['skills'] = (filteredData['skills'] as List).join(', ');
      }

      // DEBUG: Print what's being sent
      print('DEBUG: Sending data to Django: $filteredData');
      
      final success = await provider.saveProfile(filteredData);

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

    // ADDED: Function to navigate to create profile from another screen
    void navigateToCreateProfile() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            currentProfile: null,
            isNewProfile: true,
            employerId: 0,
          ),
        ),
      );
    }

    return Scaffold(
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
          // ADDED: CREATE BUTTON (only when not creating new profile)
          if (!widget.isNewProfile)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('New Profile'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Create New Profile'),
                      content: const Text('Are you sure you want to create a new profile? This will not delete your current profile.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            navigateToCreateProfile();
                          },
                          child: const Text('Create New'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: themeBlue,
                ),
              ),
            ),
          
          if (_isSaving || _isUploadingImage)
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
              // ADDED: WELCOME MESSAGE FOR NEW PROFILE
              if (widget.isNewProfile)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: themeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: themeBlue, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Your Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in your details to complete your profile. Required fields are marked with *',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // ADDED: PROFILE PICTURE SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Profile Picture with upload functionality
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                              color: themeBlue.withOpacity(0.1),
                            ),
                            child: _isUploadingImage
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                    ),
                                  )
                                : _selectedProfileImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: Image.file(
                                          _selectedProfileImage!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : widget.currentProfile?['profile_picture'] != null && 
                                      widget.currentProfile!['profile_picture'].isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(60),
                                            child: Image.network(
                                              widget.currentProfile!['profile_picture'],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: themeBlue,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: themeBlue,
                                            ),
                                          ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: themeBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      widget.isNewProfile 
                          ? 'Add profile picture (optional)'
                          : 'Tap to change profile picture',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Full Name (Required in Django model)
              TextFormField(
                initialValue: _formData['full_name'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['full_name'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Profession
              TextFormField(
                initialValue: _formData['profession'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Profession/Role',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.work_outline, color: Colors.grey),
                ),
                onSaved: (value) => _formData['profession'] = value?.trim(),
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

              // Email (Required in Django model)
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
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onSaved: (value) => _formData['contact_email'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Phone (Required in Django model)
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
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['phone_number'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Alternate Phone (Optional in Django model)
              TextFormField(
                initialValue: _formData['alternate_phone'] ?? '',
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Alternate Phone',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.phone_iphone_outlined, color: Colors.grey),
                ),
                onSaved: (value) => _formData['alternate_phone'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Location Information Section
              const Text(
                'Location Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // City (Required in Django model)
              TextFormField(
                initialValue: _formData['city'] ?? '',
                decoration: InputDecoration(
                  labelText: 'City *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['city'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Address (Required in Django model)
              TextFormField(
                initialValue: _formData['address'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Address *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.home_outlined, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
                onSaved: (value) => _formData['address'] = value?.trim(),
              ),
              const SizedBox(height: 24),

              // Additional Information Section
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Skills
              TextFormField(
                initialValue: _formData['skills'] ?? '',
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Skills (comma-separated)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'e.g., Web Development, Graphic Design, Marketing',
                  prefixIcon: const Icon(Icons.work_outline, color: Colors.grey),
                ),
                onSaved: (value) => _formData['skills'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Bio/About
              TextFormField(
                initialValue: _formData['bio'] ?? '',
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'About/Bio',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  alignLabelWithHint: true,
                  hintText: 'Tell about yourself and what services you need',
                  prefixIcon: const Icon(Icons.description_outlined, color: Colors.grey),
                ),
                onSaved: (value) => _formData['bio'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Social Media Section
              const Text(
                'Social Media (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // LinkedIn URL
              TextFormField(
                initialValue: _formData['linkedin_url'] ?? '',
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'LinkedIn Profile URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.link_outlined, color: Colors.grey),
                ),
                onSaved: (value) => _formData['linkedin_url'] = value?.trim(),
              ),
              const SizedBox(height: 16),

              // Twitter URL
              TextFormField(
                initialValue: _formData['twitter_url'] ?? '',
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Twitter Profile URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.link_outlined, color: Colors.grey),
                ),
                onSaved: (value) => _formData['twitter_url'] = value?.trim(),
              ),
              const SizedBox(height: 32),

              // ID Number (for verification)
              const Text(
                'Verification (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add ID number for account verification',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _formData['id_number'] ?? '',
                decoration: InputDecoration(
                  labelText: 'ID Number',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: themeBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: 'National ID, Passport, or Driver\'s License',
                  prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey),
                ),
                onSaved: (value) => _formData['id_number'] = value?.trim(),
              ),
              const SizedBox(height: 32),

              // ADDED: CREATE BUTTON AT BOTTOM TOO
              if (!widget.isNewProfile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: themeBlue, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Need another profile?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new profile for a different business or purpose',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        onPressed: navigateToCreateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          foregroundColor: themeWhite,
                        ),
                      ),
                    ],
                  ),
                ),

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