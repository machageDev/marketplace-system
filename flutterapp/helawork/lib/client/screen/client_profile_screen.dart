import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_profile_provider.dart';
import 'package:helawork/client/screen/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ClientProfileScreen extends StatefulWidget {
  final int employerId;
  
  const ClientProfileScreen({super.key, required this.employerId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isRefreshing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    if (_initialized) return;
    
    print('=== DEBUG: Loading profile ===');
    print('Widget employerId: ${widget.employerId}');
    
    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    print('Provider employerId before set: ${provider.employerId}');
    
    // FIRST: Set the employerId in the provider
    provider.setEmployerId(widget.employerId);
    print('Provider employerId after set: ${provider.employerId}');
    
    // THEN: Fetch the profile
    provider.fetchProfile();
    
    _initialized = true;
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    
    print('=== DEBUG: Refreshing profile ===');
    print('Widget employerId: ${widget.employerId}');
    
    final provider = Provider.of<ClientProfileProvider>(context, listen: false);
    
    // Make sure employerId is set
    provider.setEmployerId(widget.employerId);
    
    // Then fetch profile
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
          employerId: widget.employerId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _refreshProfile();
      }
    });
  }

  void _showEmailVerificationDialog(BuildContext context) {
    final TextEditingController tokenController = TextEditingController();
    
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
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Verification Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<ClientProfileProvider>(context, listen: false);
              final success = await provider.verifyEmail(tokenController.text);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email verified successfully')),
                );
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
    final TextEditingController codeController = TextEditingController();
    
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
              controller: codeController,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<ClientProfileProvider>(context, listen: false);
              final success = await provider.verifyPhone(codeController.text);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone verified successfully')),
                );
                _refreshProfile();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _navigateToIdUpload(BuildContext context) {
    // Implement ID upload
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload ID Document'),
        content: const Text('ID upload functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          color: themeBlue.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.business,
                            size: 50,
                            color: themeBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.profile!['company_name'] ?? 'Your Business',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            if (provider.profile!['business_type'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  provider.profile!['business_type'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
            
            _buildVerificationStatus(provider.profile!),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.profile!['bio'] != null)
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
                          provider.profile!['bio'],
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
                  
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: provider.profile!['contact_email'] ?? 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: provider.profile!['phone_number'] ?? 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    value: '${provider.profile!['city'] ?? ''}, ${provider.profile!['country'] ?? ''}'.trim(),
                  ),
                  
                  if (provider.profile!['website'] != null || 
                      provider.profile!['tax_id'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Business Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (provider.profile!['website'] != null)
                          _buildContactCard(
                            icon: Icons.language_outlined,
                            title: 'Website',
                            value: provider.profile!['website'],
                          ),
                        if (provider.profile!['website'] != null) const SizedBox(height: 12),
                        
                        if (provider.profile!['tax_id'] != null)
                          _buildContactCard(
                            icon: Icons.badge_outlined,
                            title: 'Tax ID',
                            value: provider.profile!['tax_id'],
                          ),
                        if (provider.profile!['tax_id'] != null) const SizedBox(height: 12),
                        
                        if (provider.profile!['industry'] != null)
                          _buildContactCard(
                            icon: Icons.category_outlined,
                            title: 'Industry',
                            value: provider.profile!['industry'],
                          ),
                      ],
                    ),
                ],
              ),
            ),
            
            if (provider.profile!['updated_at'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Profile updated ${_formatDate(provider.profile!['updated_at'])}',
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
    final isVerified = profile['is_verified'] ?? false;

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
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildVerificationItem(
            icon: Icons.email_outlined,
            label: 'Email',
            isVerified: emailVerified,
            onVerify: emailVerified ? null : () {
              _showEmailVerificationDialog(context);
            },
          ),
          
          const SizedBox(height: 8),
          
          _buildVerificationItem(
            icon: Icons.phone_outlined,
            label: 'Phone',
            isVerified: phoneVerified,
            onVerify: phoneVerified ? null : () {
              _showPhoneVerificationDialog(context);
            },
          ),
          
          const SizedBox(height: 8),
          
          _buildVerificationItem(
            icon: Icons.badge_outlined,
            label: 'ID Document',
            isVerified: idVerified,
            onVerify: idVerified ? null : () {
              _navigateToIdUpload(context);
            },
          ),
          
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Fully Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String label,
    required bool isVerified,
    VoidCallback? onVerify,
  }) {
    return Row(
      children: [
        Icon(icon, color: isVerified ? Colors.green : Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isVerified ? Colors.black87 : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!isVerified && onVerify != null)
          ElevatedButton(
            onPressed: onVerify,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          )
        else if (isVerified)
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Verified',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
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
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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