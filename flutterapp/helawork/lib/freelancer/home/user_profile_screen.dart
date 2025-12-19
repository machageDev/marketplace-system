import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/user_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isEditing = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    await Provider.of<UserProfileProvider>(context, listen: false).loadProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    await _loadProfile();
    setState(() => _isRefreshing = false);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _pickedImage = null; // Clear picked image when cancelling edit
      }
    });
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<UserProfileProvider>(context, listen: false)
          .saveProfile(context);
      
      if (success && context.mounted) {
        setState(() => _isEditing = false);
        await _refreshProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Consumer<UserProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.profile.isEmpty && !_isEditing) {
            return _buildLoadingScreen();
          }

          if (provider.errorMessage.isNotEmpty && !provider.profileExists && !_isEditing) {
            return _buildErrorScreen(provider, context);
          }

          if (!provider.profileExists || _isEditing) {
            return _buildEditScreen(provider, context);
          }

          return _buildViewScreen(provider, context);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 20),
          const Text(
            'Loading your profile...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(UserProfileProvider provider, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
              onPressed: () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditScreen(UserProfileProvider provider, BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          provider.profileExists ? 'Edit Profile' : 'Create Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (provider.profileExists)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF1E1E2C),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (provider.profile['profile_picture'] != null
                              ? NetworkImage(provider.profile['profile_picture'])
                              : null) as ImageProvider?,
                      child: _pickedImage == null && provider.profile['profile_picture'] == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap to change profile picture',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Bio
              _buildTextField(
                context,
                label: "Bio",
                initialValue: provider.profile['bio'] ?? '',
                onChanged: (val) => provider.setProfileField('bio', val),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // Skills
              _buildTextField(
                context,
                label: "Skills (comma-separated)",
                initialValue: provider.profile['skills'] ?? '',
                onChanged: (val) => provider.setProfileField('skills', val),
              ),
              const SizedBox(height: 15),

              // Experience
              _buildTextField(
                context,
                label: "Experience",
                initialValue: provider.profile['experience'] ?? '',
                onChanged: (val) => provider.setProfileField('experience', val),
                maxLines: 4,
              ),
              const SizedBox(height: 15),

              // Portfolio Link
              _buildTextField(
                context,
                label: "Portfolio Link",
                initialValue: provider.profile['portfolio_link'] ?? '',
                onChanged: (val) => provider.setProfileField('portfolio_link', val),
              ),
              const SizedBox(height: 15),

              // Hourly Rate
              _buildTextField(
                context,
                label: "Hourly Rate (\$ per hour)",
                initialValue: provider.profile['hourly_rate']?.toString() ?? '',
                keyboardType: TextInputType.number,
                onChanged: (val) => provider.setProfileField('hourly_rate', val),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () => _saveProfile(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          provider.profileExists ? 'UPDATE PROFILE' : 'CREATE PROFILE',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),

              // Cancel Button (only when editing existing profile)
              if (provider.profileExists)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _loadProfile();
                    },
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewScreen(UserProfileProvider provider, BuildContext context) {
    final profile = provider.profile;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF1E1E2C),
          expandedHeight: 200,
          pinned: true,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A73E8).withOpacity(0.8),
                    const Color(0xFF0F111A),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      backgroundImage: profile['profile_picture'] != null
                          ? NetworkImage(profile['profile_picture'])
                          : null,
                      child: profile['profile_picture'] == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Freelancer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            ),
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isRefreshing ? null : _refreshProfile,
              tooltip: 'Refresh',
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio Section
                if (profile['bio'] != null && profile['bio'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.description,
                    title: 'About Me',
                    content: profile['bio'],
                  ),
                
                // Skills Section
                if (profile['skills'] != null && profile['skills'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.work,
                    title: 'Skills',
                    content: profile['skills'],
                    isSkills: true,
                  ),
                
                // Experience Section
                if (profile['experience'] != null && profile['experience'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.timeline,
                    title: 'Experience',
                    content: profile['experience'],
                  ),
                
                // Portfolio Link
                if (profile['portfolio_link'] != null && profile['portfolio_link'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.link,
                    title: 'Portfolio',
                    content: profile['portfolio_link'],
                    isLink: true,
                  ),
                
                // Hourly Rate
                if (profile['hourly_rate'] != null)
                  _buildProfileSection(
                    icon: Icons.attach_money,
                    title: 'Hourly Rate',
                    content: '\$${profile['hourly_rate']}/hour',
                  ),
                
                // Last Updated
                if (profile['updated_at'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        'Last updated: ${_formatDate(profile['updated_at'])}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                
                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
      validator: (val) =>
          val == null || val.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String content,
    bool isSkills = false,
    bool isLink = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A73E8), size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isSkills)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: content.split(',').map((skill) {
                final trimmedSkill = skill.trim();
                if (trimmedSkill.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1A73E8)),
                  ),
                  child: Text(
                    trimmedSkill,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            )
          else if (isLink)
            GestureDetector(
              onTap: () {
                // Handle link tap
              },
              child: Text(
                content,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(
              content,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
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
}