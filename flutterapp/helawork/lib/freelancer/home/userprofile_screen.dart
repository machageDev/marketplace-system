import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/user_profile_provoder.dart';
import 'package:helawork/freelancer/widgets/skill_badge.dart';
import 'package:helawork/freelancer/widgets/portfolio_card.dart';
import 'package:helawork/freelancer/widgets/work_passport_summary.dart';
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

  // Define consistent dark colors
  static const Color backgroundColor = Color(0xFF0A0A0A); // Very dark background
  static const Color cardColor = Color(0xFF1A1A1A); // Dark cards
  static const Color surfaceColor = Color(0xFF252525); // Surface elements
  static const Color accentColor = Color(0xFF333333); // Subtle accent
  static const Color borderColor = Color(0xFF444444); // Borders
  static const Color textColor = Color(0xFFE0E0E0); // Light grey text
  static const Color secondaryTextColor = Color(0xFF888888); // Medium grey
  static const Color iconColor = Color(0xFFAAAAAA); // Icon color
  static const Color highlightColor = Color(0xFF555555); // Highlights/hover

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
        _pickedImage = null;
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
      backgroundColor: backgroundColor,
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
          CircularProgressIndicator(color: highlightColor),
          const SizedBox(height: 20),
          Text(
            'Loading your profile...',
            style: TextStyle(color: textColor, fontSize: 16),
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
            Icon(
              Icons.error_outline,
              color: highlightColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add, color: textColor),
              label: Text(
                'Create Profile',
                style: TextStyle(color: textColor),
              ),
              onPressed: () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditScreen(UserProfileProvider provider, BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        title: Text(
          provider.profileExists ? 'Edit Profile' : 'Create Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (provider.profileExists)
            IconButton(
              icon: Icon(Icons.close, color: textColor),
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
                      backgroundColor: surfaceColor,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (provider.profile['profile_picture'] != null
                              ? NetworkImage(provider.profile['profile_picture'])
                              : null) as ImageProvider?,
                      child: _pickedImage == null && provider.profile['profile_picture'] == null
                          ? Icon(Icons.person, size: 60, color: secondaryTextColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(Icons.edit, size: 20, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tap to change profile picture',
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Bio
              _buildTextField(
                label: "Bio",
                initialValue: provider.profile['bio'] ?? '',
                onChanged: (val) => provider.setProfileField('bio', val),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // Skills
              _buildTextField(
                label: "Skills (comma-separated)",
                initialValue: provider.profile['skills'] ?? '',
                onChanged: (val) => provider.setProfileField('skills', val),
              ),
              const SizedBox(height: 15),

              // Experience
              _buildTextField(
                label: "Experience",
                initialValue: provider.profile['experience'] ?? '',
                onChanged: (val) => provider.setProfileField('experience', val),
                maxLines: 4,
              ),
              const SizedBox(height: 15),

              // Portfolio Link
              _buildTextField(
                label: "Portfolio Link",
                initialValue: provider.profile['portfolio_link'] ?? '',
                onChanged: (val) => provider.setProfileField('portfolio_link', val),
              ),
              const SizedBox(height: 15),

              // Hourly Rate
              _buildTextField(
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
                    backgroundColor: accentColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: borderColor),
                  ),
                  child: provider.isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(textColor),
                          ),
                        )
                      : Text(
                          provider.profileExists ? 'UPDATE PROFILE' : 'CREATE PROFILE',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w600,
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(color: secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
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
          backgroundColor: cardColor,
          expandedHeight: 200,
          pinned: true,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'My Profile',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    surfaceColor.withOpacity(0.9),
                    backgroundColor,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                        color: surfaceColor,
                      ),
                      child: ClipOval(
                        child: profile['profile_picture'] != null
                            ? Image.network(
                                profile['profile_picture'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 50, color: secondaryTextColor);
                                },
                              )
                            : Icon(Icons.person, size: 50, color: secondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Service Provider',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
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
              icon: Icon(Icons.edit, color: textColor),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            ),
            IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Icon(Icons.refresh, color: textColor),
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
                // Work Passport Summary (TOP PRIORITY - Credibility Snapshot)
                if (profile['work_passport_data'] != null) _buildWorkPassportSection(provider),
                
                // Verified Skills Section (Competence Proof)
                if (provider.verifiedSkills.isNotEmpty) _buildVerifiedSkillsSection(provider),
                
                // Portfolio Showcase Section (Evidence)
                if (provider.portfolioItems.isNotEmpty) _buildPortfolioSection(provider),
                
                // Bio Section
                if (profile['bio'] != null && profile['bio'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.description,
                    title: 'About Me',
                    content: profile['bio'],
                  ),
                
                // Experience Section
                if (profile['experience'] != null && profile['experience'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.timeline,
                    title: 'Experience',
                    content: profile['experience'],
                  ),
                
                // Skills Section (existing text-based skills - fallback only)
                if (profile['skills'] != null && profile['skills'].toString().isNotEmpty)
                  _buildProfileSection(
                    icon: Icons.work,
                    title: 'Skills',
                    content: profile['skills'],
                    isSkills: true,
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
                        style: TextStyle(
                          color: secondaryTextColor,
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
                      icon: Icon(Icons.edit, color: textColor),
                      label: Text(
                        'Edit Profile',
                        style: TextStyle(color: textColor),
                      ),
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: borderColor),
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

  Widget _buildTextField({
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
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highlightColor, width: 2),
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
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    trimmedSkill,
                    style: TextStyle(color: textColor),
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
                style: TextStyle(
                  color: highlightColor,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(
              content,
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16, height: 1.5),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifiedSkillsSection(UserProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                'Verified Skills',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: provider.verifiedSkills.map((userSkill) {
              return SkillBadge(userSkill: userSkill);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(UserProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                'Portfolio Showcase',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...provider.portfolioItems.map((item) {
            return PortfolioCard(portfolioItem: item);
          }),
        ],
      ),
    );
  }

  Widget _buildWorkPassportSection(UserProfileProvider provider) {
    final workPassportData = provider.profile['work_passport_data'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: WorkPassportSummary(workPassportData: workPassportData),
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