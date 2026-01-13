import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/api_service.dart';
import 'package:intl/intl.dart';

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
  List<dynamic> _ratings = [];
  bool _isLoading = true;
  bool _loadingRatings = false;
  String _errorMessage = '';
  String _ratingsError = '';
  static const blueColor = Colors.blue;
  static const whiteColor = Colors.white;
  static const lightBlueColor = Color(0xFFE3F2FD);
  static const mediumBlueColor = Color(0xFF1976D2);
  static const darkBlueColor = Color(0xFF0D47A1);

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
        
        // Load ratings after profile is loaded
        _loadRatings();
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

  Future<void> _loadRatings() async {
    setState(() {
      _loadingRatings = true;
      _ratingsError = '';
    });

    try {
      final response = await ApiService.getFreelancerRatings(widget.freelancerId);
      
      if (response['success'] == true) {
        setState(() {
          _ratings = response['ratings'] ?? [];
          _loadingRatings = false;
        });
      } else {
        setState(() {
          _ratingsError = response['message'] ?? 'Failed to load ratings';
          _loadingRatings = false;
        });
      }
    } catch (e) {
      setState(() {
        _ratingsError = e.toString();
        _loadingRatings = false;
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

              // Work Passport Summary (Performance Review Section)
              if (workPassport.isNotEmpty)
                _buildWorkPassportSection(workPassport),

              // Ratings & Reviews Section
              _buildRatingsSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Build Work Passport Section (Performance Review)
  Widget _buildWorkPassportSection(Map<String, dynamic> workPassportData) {
    // Try to extract extended data from work passport
    Map<String, dynamic>? extendedData;
    
    if (workPassportData.containsKey('category_scores') || 
        workPassportData.containsKey('performance_tags')) {
      extendedData = workPassportData;
    } else if (workPassportData['extended_data'] != null) {
      try {
        if (workPassportData['extended_data'] is String) {
          extendedData = jsonDecode(workPassportData['extended_data']);
        } else if (workPassportData['extended_data'] is Map) {
          extendedData = Map<String, dynamic>.from(workPassportData['extended_data']);
        }
      } catch (e) {
        print('Error parsing extended_data: $e');
      }
    }

    if (extendedData == null) return const SizedBox.shrink();

    final categoryScores = extendedData['category_scores'] ?? {};
    final performanceTags = (extendedData['performance_tags'] as List?) ?? [];
    final calculatedComposite = extendedData['calculated_composite']?.toString() ?? "0.0";
    final wouldRecommend = extendedData['would_recommend'] == true;
    final wouldRehire = extendedData['would_rehire'] == true;

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
                      Icons.work_outline,
                      color: darkBlueColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Performance Review',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: darkBlueColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          calculatedComposite,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: darkBlueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category Scores
              if (categoryScores.isNotEmpty) ...[
                Text(
                  'Detailed Ratings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...categoryScores.entries.map((entry) {
                  final score = entry.value is num ? entry.value.toDouble() : 0.0;
                  return _buildCategoryProgressBar(
                    _formatCategoryName(entry.key),
                    score,
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],

              // Performance Tags
              if (performanceTags.isNotEmpty) ...[
                Text(
                  'Highlights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: performanceTags.map((tag) {
                    final tagString = tag.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCategoryName(tagString),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Recommendation Status
              Row(
                children: [
                  if (wouldRecommend)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (wouldRecommend && wouldRehire) const SizedBox(width: 8),
                  if (wouldRehire)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.work_history,
                            size: 14,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Would Rehire',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Ratings Section
  Widget _buildRatingsSection() {
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
                      Icons.reviews,
                      color: darkBlueColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ratings & Reviews',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: darkBlueColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loadingRatings)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                      color: blueColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_ratingsError.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _ratingsError,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadRatings,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: blueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_ratings.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Reviews Yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to review this freelancer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Summary stats
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightBlueColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_ratings.length} Reviews',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlueColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Average: ${_calculateAverageRating().toStringAsFixed(1)}/5.0',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkBlueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ratings List
                    ..._ratings.map((rating) => _buildEnhancedRatingCard(rating)).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Rating Card with proper JSON handling
Widget _buildEnhancedRatingCard(Map<String, dynamic> rating) {
  // Parse basic rating info
  final employerName = rating['employer_name'] ?? 
                      rating['rater_name'] ?? 
                      rating['rater']?['name'] ?? 
                      rating['user']?['name'] ?? 
                      'Anonymous';
  
  final employerAvatar = rating['employer_avatar'] ?? 
                        rating['rater_avatar'] ?? 
                        rating['rater']?['profile_picture'] ?? 
                        rating['user']?['profile_picture'];
  
  // Parse rating value from multiple possible fields
  double ratingValue = 0.0;
  if (rating['rating'] != null) {
    ratingValue = (rating['rating'] ?? 0).toDouble();
  } else if (rating['score'] != null) {
    ratingValue = (rating['score'] ?? 0).toDouble();
  }
  
  // Get comment/review text
  String comment = rating['comment']?.toString() ?? '';
  String review = rating['review']?.toString() ?? '';
  final displayComment = comment.isNotEmpty ? comment : review;
  
  // Get task title
  String taskTitle = rating['task_title']?.toString() ?? 
                    rating['task']?['title']?.toString() ?? 
                    'Task';
  
  DateTime? createdAt;
  if (rating['created_at'] != null) {
    if (rating['created_at'] is String) {
      createdAt = DateTime.tryParse(rating['created_at']);
    }
  }

  // PARSE EXTENDED DATA - Check multiple sources
  Map<String, dynamic> extendedData = {};
  
  // 1. Check direct extended_data field
  if (rating['extended_data'] != null) {
    try {
      if (rating['extended_data'] is String && (rating['extended_data'] as String).isNotEmpty) {
        extendedData = jsonDecode(rating['extended_data']);
      } else if (rating['extended_data'] is Map) {
        extendedData = Map<String, dynamic>.from(rating['extended_data']);
      }
    } catch (e) {
      print('Error parsing direct extended_data: $e');
    }
  }
  
  // 2. Check work_passport_data field
  if (extendedData.isEmpty && rating['work_passport_data'] != null) {
    try {
      if (rating['work_passport_data'] is Map) {
        final wpData = Map<String, dynamic>.from(rating['work_passport_data']);
        if (wpData['extended_data'] != null) {
          if (wpData['extended_data'] is String && (wpData['extended_data'] as String).isNotEmpty) {
            extendedData = jsonDecode(wpData['extended_data']);
          } else if (wpData['extended_data'] is Map) {
            extendedData = Map<String, dynamic>.from(wpData['extended_data']);
          }
        }
      }
    } catch (e) {
      print('Error parsing work_passport_data: $e');
    }
  }
  
  // 3. Check for __EXTENDED_DATA__ marker in review text (legacy format)
  if (extendedData.isEmpty && displayComment.isNotEmpty) {
    try {
      final markerIndex = displayComment.indexOf('__EXTENDED_DATA__:');
      if (markerIndex != -1) {
        final jsonString = displayComment.substring(markerIndex + '__EXTENDED_DATA__:'.length).trim();
        extendedData = jsonDecode(jsonString);
      }
    } catch (e) {
      print('Error parsing __EXTENDED_DATA__ marker: $e');
    }
  }
  
  // 4. Check for direct category_scores and performance_tags in rating object
  if (extendedData.isEmpty) {
    extendedData = {};
    if (rating['category_scores'] != null && rating['category_scores'] is Map) {
      extendedData['category_scores'] = Map<String, dynamic>.from(rating['category_scores']);
    }
    if (rating['performance_tags'] != null && rating['performance_tags'] is List) {
      extendedData['performance_tags'] = List<dynamic>.from(rating['performance_tags']);
    }
    if (rating['would_recommend'] != null) {
      extendedData['would_recommend'] = rating['would_recommend'];
    }
    if (rating['would_rehire'] != null) {
      extendedData['would_rehire'] = rating['would_rehire'];
    }
    if (rating['calculated_composite'] != null) {
      extendedData['calculated_composite'] = rating['calculated_composite'];
    }
  }

  // Extract data from extendedData
  final categoryScores = extendedData['category_scores'] ?? {};
  final performanceTags = (extendedData['performance_tags'] as List?) ?? [];
  final wouldRecommend = extendedData['would_recommend'] == true;
  final wouldRehire = extendedData['would_rehire'] == true;
  
  // Calculate composite score
  String? calculatedComposite;
  if (extendedData['calculated_composite'] != null) {
    calculatedComposite = extendedData['calculated_composite'].toString();
  } else if (categoryScores.isNotEmpty && categoryScores is Map) {
    final scores = categoryScores.values.where((s) => s is num).map((s) => (s as num).toDouble());
    if (scores.isNotEmpty) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      calculatedComposite = avg.toStringAsFixed(1);
    }
  }

  // Clean comment text (remove extended data marker if present)
  String cleanComment = displayComment;
  if (displayComment.contains('__EXTENDED_DATA__:')) {
    cleanComment = displayComment.substring(0, displayComment.indexOf('__EXTENDED_DATA__:')).trim();
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: whiteColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with employer info and rating
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employer Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlueColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: blueColor.withOpacity(0.3)),
                ),
                child: employerAvatar != null && employerAvatar.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          employerAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                employerName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlueColor,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          employerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: darkBlueColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Employer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBlueColor,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Task Title
                    Text(
                      taskTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingValue.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkBlueColor,
                        ),
                      ),
                    ],
                  ),
                  // Visual Stars
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < ratingValue.floor() 
                          ? Icons.star 
                          : (index < ratingValue ? Icons.star_half : Icons.star_border),
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Category Scores with Progress Bars (if available)
        if (categoryScores.isNotEmpty && categoryScores is Map)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Detailed Ratings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...categoryScores.entries.map((entry) {
                  final score = entry.value is num ? entry.value.toDouble() : 0.0;
                  return _buildCategoryProgressBar(
                    _formatCategoryName(entry.key),
                    score,
                  );
                }).toList(),
                const SizedBox(height: 12),
              ],
            ),
          ),

        // Performance Tags (if available)
        if (performanceTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Strengths',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: performanceTags.map((tag) {
                    final tagString = tag.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCategoryName(tagString),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

        // Comment (if available)
        if (cleanComment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    cleanComment,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Footer with recommendation badges
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightBlueColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              // Verified badge if would_recommend is true
              if (wouldRecommend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (wouldRecommend && wouldRehire) const SizedBox(width: 8),
              
              // Would rehire badge
              if (wouldRehire)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_history,
                        size: 14,
                        color: Colors.purple[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Would Rehire',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Composite score badge (if available)
              if (calculatedComposite != null && calculatedComposite.isNotEmpty)
                Row(
                  children: [
                    if (wouldRecommend || wouldRehire) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assessment,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Score: $calculatedComposite',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              
              const Spacer(),
              
              // Overall rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ratingValue.toStringAsFixed(1)}/5.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
     
    ),
  );}

  // Helper: Build category progress bar
  Widget _buildCategoryProgressBar(String category, double score) {
    final percentage = (score / 5.0) * 100;
    Color barColor = Colors.green;
    
    if (percentage < 60) barColor = Colors.orange;
    if (percentage < 40) barColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/5.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 6,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth * (percentage / 100),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper: Format category name (e.g., "workQuality" -> "Work Quality")
  String _formatCategoryName(String name) {
    final formatted = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}'
    ).trim();
    
    if (formatted.isEmpty) return name;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  // Helper Methods
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  double _calculateAverageRating() {
    if (_ratings.isEmpty) return 0.0;
    
    double total = 0;
    int count = 0;
    
    for (final rating in _ratings) {
      double value = 0.0;
      if (rating['rating'] != null) {
        value = (rating['rating'] ?? 0).toDouble();
      } else if (rating['score'] != null) {
        value = (rating['score'] ?? 0).toDouble();
      }
      
      if (value > 0) {
        total += value;
        count++;
      }
    }
    
    return count > 0 ? total / count : 0.0;
  }

  // Existing helper methods
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