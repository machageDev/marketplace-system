import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmployerProfileScreen extends StatefulWidget {
  final String employerId;
  final String employerName;

  const EmployerProfileScreen({
    super.key,
    required this.employerId,
    required this.employerName,
  });

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  Map<String, dynamic>? _employerProfile;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;
  String? _userToken;

  // Dark color scheme like SubmitTaskScreen
  final Color _primaryColor = const Color(0xFF1E3A8A); // Dark blue
  final Color _secondaryColor = const Color(0xFF3B82F6); // Blue
  final Color _backgroundColor = const Color(0xFF0F172A); // Dark background
  final Color _cardColor = const Color(0xFF1E293B); // Dark card
  final Color _textColor = Colors.white;
  final Color _subtitleColor = const Color(0xFF94A3B8); // Light gray
  final Color _successColor = const Color(0xFF10B981); // Green
  final Color _warningColor = const Color(0xFFF59E0B); // Amber
  final Color _dangerColor = const Color(0xFFEF4444); 
// Blue

  @override
  void initState() {
    super.initState();
    _getTokenAndLoadProfile();
  }

  Future<void> _getTokenAndLoadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userToken = prefs.getString('user_token');
    
    if (_userToken != null) {
      await _loadEmployerProfile();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Please login to view profile';
      });
    }
  }

  Future<void> _loadEmployerProfile() async {
    if (_userToken == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Authentication required';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse("https://marketplace-system-1.onrender.com/freelancer/employer-profile/${widget.employerId}/"),
       // Uri.parse("http://192.168.100.188:8000/freelancer/employer-profile/${widget.employerId}/"),
        headers: {"Authorization": "Bearer $_userToken"},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _employerProfile = data["profile"];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = data["message"] ?? 'Failed to load profile';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Employer profile not found';
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load profile: $error';
      });
    }
  }

  Widget _buildProfileHeader() {
    final profilePic = _employerProfile?['profile_picture'];
    final displayName = _employerProfile?['full_name'] ?? 
                       _employerProfile?['username'] ?? 
                       widget.employerName;
    final contactEmail = _employerProfile?['contact_email'];
    final phone = _employerProfile?['phone_number'];
    
    final isVerified = _employerProfile?['verification_status'] == 'verified' || 
                      (_employerProfile?['email_verified'] == true && 
                       _employerProfile?['phone_verified'] == true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profilePic != null && profilePic.isNotEmpty
                      ? NetworkImage(profilePic) as ImageProvider<Object>?
                      : null,
                  child: profilePic == null || profilePic.isEmpty
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        )
                      : null,
                ),
                if (isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Display name with verification badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            // Username if different from display name
            if (_employerProfile?['username'] != null && 
                _employerProfile?['username'] != displayName)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '@${_employerProfile?['username']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Contact info cards
            if (contactEmail != null || phone != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (contactEmail != null)
                    _buildContactCard(
                      Icons.email,
                      'Email',
                      contactEmail,
                    ),
                  if (phone != null)
                    _buildContactCard(
                      Icons.phone,
                      'Phone',
                      phone,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _subtitleColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _subtitleColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 13,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Employer Profile',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20)),
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEmployerProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: _secondaryColor,
                      backgroundColor: _secondaryColor.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Loading profile...',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _dangerColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.error_outline,
                              size: 64, color: _dangerColor),
                        ),
                        const SizedBox(height: 24),
                        Text('Oops! Something went wrong',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _dangerColor)),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(_errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15, color: _subtitleColor)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadEmployerProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _employerProfile == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 80, color: _subtitleColor),
                          const SizedBox(height: 20),
                          Text('No profile data available',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor)),
                          const SizedBox(height: 10),
                          Text('This employer has not created a profile yet',
                              style: TextStyle(
                                  fontSize: 14, color: _subtitleColor)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEmployerProfile,
                      color: _secondaryColor,
                      backgroundColor: _backgroundColor,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 20),
                            
                            // Personal Information Section
                            _buildProfileSection('Personal Information', Icons.person, [
                              _buildInfoItem('Full Name', _employerProfile?['full_name'] ?? '', icon: Icons.person_outline),
                              _buildInfoItem('Username', '@${_employerProfile?['username'] ?? ''}', icon: Icons.alternate_email),
                              if (_employerProfile?['bio'] != null && _employerProfile?['bio'].isNotEmpty)
                                _buildInfoItem('Bio', _employerProfile?['bio'] ?? '', icon: Icons.info),
                            ]),
                            
                            // Contact Information
                            _buildProfileSection('Contact Information', Icons.contact_phone, [
                              _buildInfoItem('Email', _employerProfile?['contact_email'] ?? '', icon: Icons.email),
                              _buildInfoItem('Phone', _employerProfile?['phone_number'] ?? '', icon: Icons.phone),
                              if (_employerProfile?['alternate_phone'] != null && _employerProfile?['alternate_phone'].isNotEmpty)
                                _buildInfoItem('Alt Phone', _employerProfile?['alternate_phone'] ?? '', icon: Icons.phone_iphone),
                              _buildInfoItem('Address', _employerProfile?['address'] ?? '', icon: Icons.location_on),
                              _buildInfoItem('City', _employerProfile?['city'] ?? '', icon: Icons.location_city),
                            ]),
                            
                            // Professional Details
                            if ((_employerProfile?['profession'] != null && _employerProfile?['profession'].isNotEmpty) ||
                                (_employerProfile?['skills'] != null && _employerProfile?['skills'].isNotEmpty))
                              _buildProfileSection('Professional Details', Icons.work, [
                                if (_employerProfile?['profession'] != null && _employerProfile?['profession'].isNotEmpty)
                                  _buildInfoItem('Profession', _employerProfile?['profession'] ?? '', icon: Icons.business_center),
                                if (_employerProfile?['skills'] != null && _employerProfile?['skills'].isNotEmpty)
                                  _buildInfoItem('Skills', _employerProfile?['skills'] ?? '', icon: Icons.code),
                              ]),
                            
                            // Social Links
                            if (_employerProfile?['linkedin_url'] != null || 
                                _employerProfile?['twitter_url'] != null)
                              _buildProfileSection('Social Links', Icons.link, [
                                if (_employerProfile?['linkedin_url'] != null)
                                  _buildSocialLinkItem(
                                    Icons.link,
                                    'LinkedIn',
                                    _employerProfile?['linkedin_url'],
                                    Colors.blue,
                                  ),
                                if (_employerProfile?['twitter_url'] != null)
                                  _buildSocialLinkItem(
                                    Icons.link,
                                    'Twitter',
                                    _employerProfile?['twitter_url'],
                                    Colors.lightBlue,
                                  ),
                              ]),
                            
                            // Verification Status
                            _buildProfileSection('Verification Status', Icons.verified, [
                              Row(
                                children: [
                                  Icon(
                                    _employerProfile?['verification_status'] == 'verified' 
                                        ? Icons.verified 
                                        : Icons.pending,
                                    size: 18,
                                    color: _employerProfile?['verification_status'] == 'verified' 
                                        ? _successColor 
                                        : _warningColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _employerProfile?['verification_status'] == 'verified'
                                          ? 'Fully Verified Employer'
                                          : 'Verification Pending',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _employerProfile?['verification_status'] == 'verified'
                                            ? _successColor
                                            : _warningColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildVerificationBadge(
                                    'Email',
                                    _employerProfile?['email_verified'] == true,
                                    Icons.email,
                                    _successColor,
                                  ),
                                  _buildVerificationBadge(
                                    'Phone',
                                    _employerProfile?['phone_verified'] == true,
                                    Icons.phone,
                                    _successColor,
                                  ),
                                  _buildVerificationBadge(
                                    'ID',
                                    _employerProfile?['id_verified'] == true,
                                    Icons.badge,
                                    _successColor,
                                  ),
                                ],
                              ),
                            ]),
                            
                            // Statistics Section
                            _buildProfileSection('Statistics', Icons.analytics, [
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildStatItem(
                                    'Tasks Posted',
                                    (_employerProfile?['total_tasks'] ?? 0).toString(),
                                    Icons.assignment,
                                    Colors.green,
                                  ),
                                  _buildStatItem(
                                    'Total Spent',
                                    'Ksh ${(_employerProfile?['total_spent'] ?? 0).toStringAsFixed(0)}',
                                    Icons.attach_money,
                                    Colors.orange,
                                  ),
                                  _buildStatItem(
                                    'Avg Rating',
                                    (_employerProfile?['avg_freelancer_rating'] ?? 0).toStringAsFixed(1),
                                    Icons.star,
                                    Colors.amber,
                                  ),
                                  _buildStatItem(
                                    'Member Since',
                                    _formatDate(_employerProfile?['created_at']),
                                    Icons.calendar_today,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ]),
                            
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSocialLinkItem(IconData icon, String platform, String? url, Color color) {
    return GestureDetector(
      onTap: () {
        // Could launch URL here
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              '$platform: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Expanded(
              child: Text(
                url ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String label, bool isVerified, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? color.withOpacity(0.1) : _subtitleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? color : _subtitleColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isVerified ? color : _subtitleColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isVerified ? color : _subtitleColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isVerified ? Icons.check_circle : Icons.circle,
            size: 10,
            color: isVerified ? color : _subtitleColor,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}