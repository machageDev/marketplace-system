import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/client_profile_provider.dart';
import 'package:helawork/clients/screens/edit_profile_screen.dart'; // You'll need to create this

class ClientProfileScreen extends StatefulWidget {
  final int employerId;
  const ClientProfileScreen({super.key, required this.employerId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProfileProvider>(context, listen: false)
          .fetchProfile(widget.employerId);
    });
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    await Provider.of<ClientProfileProvider>(context, listen: false)
        .fetchProfile(widget.employerId);
    setState(() => _isRefreshing = false);
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          employerId: widget.employerId,
          currentProfile: Provider.of<ClientProfileProvider>(context).profile,
        ),
      ),
    ).then((value) {
      // Refresh profile after editing
      if (value == true) {
        _refreshProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientProfileProvider>(context);
    final themeBlue = Color(0xFF1976D2);
    final themeWhite = Colors.white;
    final themeGrey = Colors.grey[200];

    return Scaffold(
      backgroundColor: themeGrey,
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!provider.isLoading && provider.profile != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 22),
              onPressed: () => _navigateToEditScreen(context),
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
                : const Icon(Icons.refresh, size: 22),
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
    if (provider.isLoading && provider.profile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null && provider.profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              color: themeBlue,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Profile Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'You need to create a profile to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
              onPressed: () => _navigateToEditScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeBlue,
                foregroundColor: themeWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      backgroundColor: themeWhite,
      color: themeBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with edit button
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: themeBlue.withOpacity(0.1),
                            radius: 30,
                            child: Icon(
                              Icons.business,
                              color: themeBlue,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.profile!['company_name'] ?? 'No Name',
                                  style: TextStyle(
                                    color: themeBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (provider.profile!['business_type'] != null)
                                  const SizedBox(height: 4),
                                if (provider.profile!['business_type'] != null)
                                  Text(
                                    provider.profile!['business_type'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Contact Information Section
                      _buildSectionTitle('Contact Information', themeBlue),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        provider.profile!['contact_email'] ?? 'Not provided',
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        provider.profile!['phone_number'] ?? 'Not provided',
                      ),
                      _buildInfoRow(
                        Icons.location_on,
                        'Address',
                        provider.profile!['address'] ?? 'Not provided',
                      ),
                      
                      // Business Information Section
                      if (provider.profile!['website'] != null || 
                          provider.profile!['tax_id'] != null)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildSectionTitle('Business Information', themeBlue),
                            const SizedBox(height: 12),
                            if (provider.profile!['website'] != null)
                              _buildInfoRow(
                                Icons.language,
                                'Website',
                                provider.profile!['website'],
                              ),
                            if (provider.profile!['tax_id'] != null)
                              _buildInfoRow(
                                Icons.badge,
                                'Tax ID',
                                provider.profile!['tax_id'],
                              ),
                            if (provider.profile!['industry'] != null)
                              _buildInfoRow(
                                Icons.category,
                                'Industry',
                                provider.profile!['industry'],
                              ),
                          ],
                        ),
                      
                      // Additional Information
                      if (provider.profile!['description'] != null)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildSectionTitle('About', themeBlue),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                provider.profile!['description'],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Last Updated Info
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  provider.profile!['updated_at'] != null
                      ? 'Last updated: ${_formatDate(provider.profile!['updated_at'])}'
                      : '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          height: 2,
          width: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Color(0xFF1976D2).withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}