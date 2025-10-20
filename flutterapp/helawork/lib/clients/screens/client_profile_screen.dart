// lib/clients/screens/client_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/client_profile_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  final int employerId;
  const ClientProfileScreen({super.key, required this.employerId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProfileProvider>(context, listen: false)
          .fetchProfile(widget.employerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientProfileProvider>(context);
    final themeBlue = const Color(0xFF1976D2); // your Helawork blue
    final themeWhite = Colors.white;

    return Scaffold(
      backgroundColor: themeWhite,
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : provider.profile == null
                  ? const Center(
                      child: Text('No profile data available'),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileRow(
                                  "Company Name",
                                  provider.profile!['company_name'] ?? 'N/A',
                                  themeBlue),
                              _buildProfileRow(
                                  "Email",
                                  provider.profile!['contact_email'] ?? 'N/A',
                                  themeBlue),
                              _buildProfileRow(
                                  "Phone",
                                  provider.profile!['phone_number'] ?? 'N/A',
                                  themeBlue),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProfileRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
