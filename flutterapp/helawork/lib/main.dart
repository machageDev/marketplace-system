
import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/auth_provider.dart' as client_auth;
import 'package:helawork/clients/provider/dashboard_provider.dart' as client_dashboard;
import 'package:helawork/freelancer/provider/auth_provider.dart' as freelancer_auth;
import 'package:helawork/freelancer/provider/contract_provider.dart';
import 'package:helawork/freelancer/provider/dashbaord_provider.dart' as freelancer_dashboard;
import 'package:helawork/freelancer/provider/forgot_password_provider.dart';
import 'package:helawork/freelancer/provider/proposal_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:helawork/freelancer/provider/user_profile_provider.dart';
import 'package:helawork/freelancer/screens/login_screen.dart'; // Freelancer login
import 'package:helawork/clients/screens/client_login_screen.dart'; // Client login - ADD THIS IMPORT
import 'package:helawork/services/api_sercice.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Freelancer Providers
        ChangeNotifierProvider(create: (_) => freelancer_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),    
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),  
        ChangeNotifierProvider(create: (_) => freelancer_dashboard.DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()), 
        ChangeNotifierProvider(create: (_) => ProposalProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()..fetchContracts()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),        
        
        // Client Providers
        ChangeNotifierProvider(create: (_) => client_dashboard.DashboardProvider(apiService: ApiService())),
        ChangeNotifierProvider(create: (_) => client_auth.AuthProvider(apiService: ApiService())),
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

// Role Selection Screen
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea( 
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login As',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                // CLIENT BUTTON - Goes to Client Login Screen
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientLoginScreen(), // CHANGED TO CLIENT LOGIN
                      ),
                    );
                  },
                  child: const Text('Client', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                // FREELANCER BUTTON - Goes to Freelancer Login Screen
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(), // KEPT AS FREELANCER LOGIN
                      ),
                    );
                  },
                  child: const Text('Freelancer', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}