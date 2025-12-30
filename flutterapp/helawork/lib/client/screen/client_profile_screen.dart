import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_profile_provider.dart';
import 'package:helawork/client/screen/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key, required int profile});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isRefreshing = false;
  bool _initialized = false;
  
  // Profile Picture Upload Variables
  File? _selectedProfileImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  
  // Verification Controllers
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailTokenController = TextEditingController();
  final TextEditingController _phoneCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    if (_initialized) return;
    
    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    
    // Just fetch the profile - no need to set employerId
    provider.fetchProfile();
    
    _initialized = true;
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    
    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    
    await provider.fetchProfile();
    
    setState(() => _isRefreshing = false);
  }

  void _navigateToEditScreen(BuildContext context, bool isNewProfile) {
    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentProfile: provider.profile,
          isNewProfile: isNewProfile,
          employerId: provider.profile?['id'] ?? 0,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _refreshProfile();
      }
    });
  }

  // ================== PROFILE PICTURE UPLOAD METHODS ==================
  
  Future<void> _pickProfileImage() async {
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
      
      await _uploadProfileImage();
    }
  }

  Future<void> _takeProfilePhoto() async {
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
        
        await _refreshProfile();
        setState(() => _selectedProfileImage = null);
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takeProfilePhoto();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ================== VERIFICATION METHODS ==================
  
  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the verification token sent to your email'),
            const SizedBox(height: 16),
            TextField(
              controller: _emailTokenController,
              decoration: const InputDecoration(
                labelText: 'Verification Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _emailTokenController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<ClientProfileProvider>(context, listen: false);
              final success = await provider.verifyEmail(_emailTokenController.text);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email verified successfully')),
                );
                _emailTokenController.clear();
                _refreshProfile();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showPhoneVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Phone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit code sent to your phone'),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _phoneCodeController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<ClientProfileProvider>(context, listen: false);
              final success = await provider.verifyPhone(_phoneCodeController.text);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone verified successfully')),
                );
                _phoneCodeController.clear();
                _refreshProfile();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showIdNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update ID Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your National ID, Passport, or Driver\'s License number'),
            const SizedBox(height: 16),
            TextField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1234567890',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _idNumberController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_idNumberController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter ID number')),
                );
                return;
              }
              
              final provider = Provider.of<ClientProfileProvider>(context, listen: false);
              final success = await provider.updateIdNumber(_idNumberController.text);
              
              if (success && mounted) {
                Navigator.pop(context);
                _idNumberController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID number updated successfully')),
                );
                _refreshProfile();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientProfileProvider>(context);
    const themeBlue = Color(0xFF1976D2);
    const themeWhite = Colors.white;

    return Scaffold(
      backgroundColor: themeWhite,
      appBar: AppBar(
        backgroundColor: themeWhite,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!provider.isLoading && provider.profile != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 22),
              onPressed: () => _navigateToEditScreen(context, false),
              tooltip: 'Edit Profile',
            ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                  )
                : const Icon(Icons.refresh, size: 22, color: Colors.black),
            onPressed: _isRefreshing ? null : _refreshProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(provider, themeBlue, themeWhite),
    );
  }

  Widget _buildBody(
      ClientProfileProvider provider, Color themeBlue, Color themeWhite) {
    if (provider.isLoading && provider.profile == null && !provider.hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.hasError && provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _refreshProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  foregroundColor: themeWhite,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.profile == null) {
      return _buildCreateProfileUI(themeBlue, themeWhite);
    }

    return _buildProfileUI(provider, themeBlue, themeWhite);
  }

  Widget _buildCreateProfileUI(Color themeBlue, Color themeWhite) {
    return RefreshIndicator(
      onRefresh: _refreshProfile,
      backgroundColor: themeWhite,
      color: themeBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Create your profile to showcase your business and connect with freelancers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _navigateToEditScreen(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      foregroundColor: themeWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Create Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Why Create a Profile?'),
                      content: const Text(
                        'A complete profile helps freelancers understand your business needs better. It increases trust and helps you find the right talent for your projects.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Why is this important?',
                  style: TextStyle(
                    color: themeBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileUI(ClientProfileProvider provider, Color themeBlue, Color themeWhite) {
    final profile = provider.profile!;
    
    return RefreshIndicator(
      onRefresh: _refreshProfile,
      backgroundColor: themeWhite,
      color: themeBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: themeWhite,
              child: Column(
                children: [
                  // PROFILE PICTURE WITH UPLOAD FUNCTIONALITY
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
                              : provider.profilePictureUrl != null && provider.profilePictureUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.network(
                                        provider.profilePictureUrl!,
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
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading profile picture: $error');
                                          print('URL attempted: ${provider.profilePictureUrl}');
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
                    provider.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  
                  if (profile['profession'] != null && profile['profession'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        profile['profession'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _navigateToEditScreen(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(height: 8, color: Colors.grey[100]),
            
            // VERIFICATION STATUS SECTION
            _buildVerificationStatus(profile),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BIO SECTION - Removed if empty or null
                  if (profile['bio'] != null && profile['bio'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile['bio'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // EMAIL - Required field
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: provider.contactEmail,
                    isVerified: profile['email_verified'] ?? false,
                  ),
                  const SizedBox(height: 12),
                  
                  // PHONE - Required field
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: provider.phoneNumber,
                    isVerified: profile['phone_verified'] ?? false,
                  ),
                  
                  // ALTERNATE PHONE - Only show if exists
                  if (profile['alternate_phone'] != null && profile['alternate_phone'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildContactCard(
                        icon: Icons.phone_outlined,
                        title: 'Alternate Phone',
                        value: profile['alternate_phone'],
                        isVerified: false,
                      ),
                    ),
                  
                  // ADDRESS AND CITY - Combined
                  if (provider.city.isNotEmpty || provider.address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildContactCard(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: '${provider.city}${provider.city.isNotEmpty && provider.address.isNotEmpty ? ', ' : ''}${provider.address}',
                      ),
                    ),
                  
                  // SKILLS - Show if exists
                  if (profile['skills'] != null && profile['skills'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildContactCard(
                        icon: Icons.work_outline,
                        title: 'Skills',
                        value: profile['skills'],
                      ),
                    ),
                  
                  // SOCIAL MEDIA LINKS - Show if exists
                  if (profile['linkedin_url'] != null && profile['linkedin_url'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildContactCard(
                        icon: Icons.link,
                        title: 'LinkedIn',
                        value: profile['linkedin_url'],
                      ),
                    ),
                  
                  if (profile['twitter_url'] != null && profile['twitter_url'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildContactCard(
                        icon: Icons.link,
                        title: 'Twitter',
                        value: profile['twitter_url'],
                      ),
                    ),
                  
                  // ID NUMBER - Show only if exists
                  if (profile['id_number'] != null && profile['id_number'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Verification Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildContactCard(
                          icon: Icons.badge_outlined,
                          title: 'ID Number',
                          value: profile['id_number'],
                          isVerified: profile['id_verified'] ?? false,
                        ),
                      ],
                    ),
                  
                  // STATS SECTION - FIXED: Using provider getters
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Grid - FIXED OVERFLOW
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.4, // Adjusted for better fit
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          _buildStatCard(
                            title: 'Projects',
                            value: '${profile['total_projects_posted'] ?? 0}',
                            icon: Icons.work_outline,
                          ),
                          _buildStatCard(
                            title: 'Total Spent',
                            value: 'KSh ${provider.totalSpent.toStringAsFixed(2)}',
                            icon: Icons.monetization_on_outlined,
                          ),
                          _buildStatCard(
                            title: 'Avg Rating',
                            value: '${provider.avgFreelancerRating.toStringAsFixed(1)}/5',
                            icon: Icons.star_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // LAST UPDATED TIMESTAMP
            if (profile['updated_at'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Profile updated ${_formatDate(profile['updated_at'])}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatus(Map<String, dynamic> profile) {
    final emailVerified = profile['email_verified'] ?? false;
    final phoneVerified = profile['phone_verified'] ?? false;
    final idVerified = profile['id_verified'] ?? false;
    final verificationStatus = profile['verification_status'] ?? 'unverified';
    final idNumber = profile['id_number'];
    
    // Calculate progress based on verification status
    int total = 3; // email, phone, id
    int verified = 0;
    if (emailVerified) verified++;
    if (phoneVerified) verified++;
    if (idVerified) verified++;
    int progress = ((verified / total) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(verificationStatus.toUpperCase()),
                backgroundColor: verificationStatus == 'verified'
                    ? Colors.green
                    : verificationStatus == 'pending'
                        ? Colors.orange
                        : Colors.grey,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 100 ? Colors.green : const Color(0xFF1976D2),
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progress == 100 ? Colors.green : const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildVerificationItem(
            icon: Icons.email_outlined,
            label: 'Email Verification',
            isVerified: emailVerified,
            onVerify: emailVerified ? null : () {
              _showEmailVerificationDialog(context);
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildVerificationItem(
            icon: Icons.phone_outlined,
            label: 'Phone Verification',
            isVerified: phoneVerified,
            onVerify: phoneVerified ? null : () {
              _showPhoneVerificationDialog(context);
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildVerificationItem(
            icon: Icons.badge_outlined,
            label: 'ID Number Verification',
            isVerified: idVerified,
            value: idNumber,
            onVerify: idVerified ? null : () {
              _showIdNumberDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String label,
    required bool isVerified,
    String? value,
    VoidCallback? onVerify,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isVerified ? Colors.green : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isVerified ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (value != null && value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isVerified && onVerify != null)
              ElevatedButton(
                onPressed: onVerify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Verify'),
              )
            else if (isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withOpacity(0.1) : const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isVerified ? Colors.green : const Color(0xFF1976D2),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isVerified)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Icon(Icons.verified, color: Colors.green, size: 14),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1976D2),
            size: 22, // Reduced from 24
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14, // Reduced from 16
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced from 12
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else {
        return '${(difference.inDays / 365).floor()} years ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _emailTokenController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }
}