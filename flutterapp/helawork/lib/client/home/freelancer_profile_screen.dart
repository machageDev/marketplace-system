import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';

class FreelancerProfileScreen extends StatefulWidget {
  final String freelancerId;

  const FreelancerProfileScreen({
    super.key,
    required this.freelancerId,
  });

  @override
  State<FreelancerProfileScreen> createState() => _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String _errorMessage = '';
  static const blueColor = Colors.blue;
  static const whiteColor = Colors.white;
  static const lightBlueColor = Color(0xFFE3F2FD); // Light blue background
  static const mediumBlueColor = Color(0xFF1976D2); // Medium blue for accents
  static const darkBlueColor = Color(0xFF0D47A1); // Dark blue for text/icons

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getFreelancerProfile(widget.freelancerId);
      
      if (response['success'] == true) {
        setState(() {
          _profileData = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        title: const Text(
          'Freelancer Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: blueColor,
        foregroundColor: whiteColor,
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: whiteColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: blueColor,
                strokeWidth: 3,
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: lightBlueColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Unable to Load Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: darkBlueColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _loadProfile,
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_profileData == null) {
      return Container(
        color: lightBlueColor,
        child: Center(
          child: Text(
            'No profile data available',
            style: TextStyle(
              fontSize: 16,
              color: darkBlueColor.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    final profile = _profileData!['profile'];
    final user = profile['user'] ?? {};
    final workPassport = profile['work_passport_data'] ?? {};
    
    final String name = user['name'] ?? _profileData!['freelancer_name'] ?? 'Unknown';
    final String? profilePictureUrl = profile['profile_picture'];
    final String bio = profile['bio'] ?? '';
    final String skills = profile['skills'] ?? '';
    final String experience = profile['experience'] ?? '';
    final double? hourlyRate = profile['hourly_rate'] != null 
        ? double.tryParse(profile['hourly_rate'].toString()) 
        : null;
    final double avgRating = workPassport['avg_rating']?.toDouble() ?? 0.0;
    final int completedJobs = workPassport['completed_tasks'] ?? 0;
    final int reviewCount = workPassport['review_count'] ?? 0;

    return Container(
      color: lightBlueColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Card(
                elevation: 4,
                shadowColor: blueColor.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [whiteColor, lightBlueColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Profile Picture with blue border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: blueColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: blueColor.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: lightBlueColor,
                            backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : null,
                            child: profilePictureUrl == null || profilePictureUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: mediumBlueColor,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: darkBlueColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              Icons.star,
                              avgRating.toStringAsFixed(1),
                              'Rating',
                              Colors.amber,
                            ),
                            const SizedBox(width: 32),
                            _buildStatItem(
                              Icons.work,
                              completedJobs.toString(),
                              'Jobs',
                              mediumBlueColor,
                            ),
                            const SizedBox(width: 32),
                            _buildStatItem(
                              Icons.reviews,
                              reviewCount.toString(),
                              'Reviews',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bio Section
              if (bio.isNotEmpty) ...[
                _buildSectionCard(
                  'About',
                  Icons.person_outline,
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: blueColor.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Skills Section
              if (skills.isNotEmpty) ...[
                _buildSectionCard(
                  'Skills',
                  Icons.code,
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: blueColor.withOpacity(0.1),
                        ),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: skills.split(',').map((skill) {
                          final trimmedSkill = skill.trim();
                          if (trimmedSkill.isEmpty) return const SizedBox.shrink();
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  lightBlueColor,
                                  blueColor.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: blueColor.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              trimmedSkill,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkBlueColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Experience Section
              if (experience.isNotEmpty) ...[
                _buildSectionCard(
                  'Experience',
                  Icons.business_center,
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: blueColor.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        experience,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Additional Info Card
              Card(
                elevation: 3,
                shadowColor: blueColor.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [whiteColor, lightBlueColor.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (hourlyRate != null)
                          _buildInfoRow(
                            Icons.attach_money,
                            'Hourly Rate',
                            'Ksh ${hourlyRate.toStringAsFixed(2)}/hr',
                            blueColor,
                          ),
                        if (hourlyRate != null) const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.star_rate,
                          'Average Rating',
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : 'No ratings yet',
                          Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.work_outline,
                          'Completed Jobs',
                          completedJobs.toString(),
                          mediumBlueColor,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.reviews_outlined,
                          'Total Reviews',
                          reviewCount.toString(),
                          Colors.green,
                        ),
                      ],
                    ),
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

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: whiteColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      shadowColor: blueColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightBlueColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: blueColor.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: darkBlueColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: darkBlueColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkBlueColor,
            ),
          ),
        ],
      ),
    );
  }
}