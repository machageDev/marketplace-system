import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/auth_provider.dart' as client_auth;
import 'package:helawork/clients/provider/client_profile_provider.dart';
import 'package:helawork/clients/provider/client_proposal_provider.dart' as client_proposal;
//import 'package:helawork/clients/provider/contract_provider.dart';
import 'package:helawork/clients/provider/dashboard_provider.dart' as client_dashboard;
//import 'package:helawork/clients/provider/employer_rating_provider.dart';
import 'package:helawork/clients/provider/rating_provider.dart' as client_rating;
import 'package:helawork/clients/provider/task_provider.dart' as client_task;
import 'package:helawork/freelancer/provider/auth_provider.dart' as freelancer_auth;
import 'package:helawork/freelancer/provider/contract_provider.dart';
import 'package:helawork/freelancer/provider/dashbaord_provider.dart' as freelancer_dashboard;
import 'package:helawork/freelancer/provider/forgot_password_provider.dart';
import 'package:helawork/freelancer/provider/proposal_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart' as freelancer_rating;
import 'package:helawork/freelancer/provider/submission_provider.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:helawork/freelancer/provider/user_profile_provider.dart';
import 'package:helawork/freelancer/screens/login_screen.dart'; 
import 'package:helawork/clients/screens/client_login_screen.dart'; 
import 'package:helawork/services/api_sercice.dart';
import 'package:helawork/services/wallet_service.dart';
import 'package:provider/provider.dart';
import 'package:helawork/freelancer/provider/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(
    MultiProvider(
      providers: [
        // Service Providers (formerly Freelancers)
         ChangeNotifierProvider(
          create: (_) => WalletProvider.create(
            walletService: WalletService(),  // Create WalletService instance
            token: '', // You'll need to pass the actual token here or update it later
          ),
        ),
        ChangeNotifierProvider(create: (_) => freelancer_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),    
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),  
        ChangeNotifierProvider(create: (_) => freelancer_dashboard.DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()), 
        ChangeNotifierProvider(create: (_) => ProposalProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => freelancer_rating.RatingProvider()),
        ChangeNotifierProvider(create: (_) => SubmissionProvider()),
        


        // Task Posters (formerly Clients)
        ChangeNotifierProvider(create: (_) => client_dashboard.DashboardProvider(apiService: ApiService())),
        ChangeNotifierProvider(create: (_) => client_auth.AuthProvider(apiService: ApiService())), 
        ChangeNotifierProvider(create: (_) => client_task.TaskProvider()),
        ChangeNotifierProvider(create: (_) => client_proposal.ClientProposalProvider(apiService: ApiService())), 
        ChangeNotifierProvider(create: (_) => ClientProfileProvider()),
      
        //ChangeNotifierProvider(create: (_) => EmployerRatingProvider()),
        ChangeNotifierProvider(create: (_) => client_rating.ClientRatingProvider()),
        
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HELAWORK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const RoleSelectionScreen(),
    );
  }
}

// Enhanced Role Selection Screen
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo and Welcome Section
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HELAWORK',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your Secure Marketplace',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Benefits Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Secure & Trusted Platform',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Verified Professionals',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.payment, color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Safe Payment System',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect with top talent or find amazing opportunities in our secure marketplace designed for success.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Role Selection Title
                const Text(
                  'Continue As',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your role to get started',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),

                // Task Poster Button (People who need services)
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClientLoginScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_center,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Task Poster',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Post projects and hire professionals',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Service Provider Button (People who provide services)
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Service Provider',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Find work and provide services',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Footer Text
                Text(
                  'Join thousands of professionals already on HELAWORK',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}