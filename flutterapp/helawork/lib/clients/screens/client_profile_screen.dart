import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/client_profile_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  final int employerId;
  const ClientProfileScreen({super.key, required this.employerId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final Color blue = const Color(0xFF007BFF);
  final Color white = Colors.white;

  @override
  void initState() {
    super.initState();
    Provider.of<ClientProfileProvider>(context, listen: false)
        .fetchProfile(widget.employerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text("Employer Profile"),
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: true,
      ),
      body: Consumer<ClientProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.profile;
          if (profile == null) {
            return const Center(child: Text("No profile data found."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profile['profile_picture'] != null
                          ? NetworkImage(profile['profile_picture'])
                          : const AssetImage('assets/images/default_user.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile['company_name'] ?? 'No Company Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(profile['contact_email'] ?? '',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(profile['phone_number'] ?? '',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Edit feature coming soon!")),
                        );
                      },
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
