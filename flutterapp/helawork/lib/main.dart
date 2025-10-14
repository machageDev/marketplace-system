import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:helawork/freelancer/provider/contract_provider.dart';
import 'package:helawork/freelancer/provider/dashbaord_provider.dart';
import 'package:helawork/freelancer/provider/forgot_password_provider.dart';
import 'package:helawork/freelancer/provider/proposal_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:helawork/freelancer/provider/task_provider.dart';
import 'package:helawork/freelancer/provider/user_profile_provider.dart';
//import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:helawork/freelancer/screens/login_screen.dart';
import 'package:provider/provider.dart';

// Import your providers

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🧩 Initialize Stripe
  //Stripe.publishableKey = 'pk_test_YourPublishableKeyHere'; 
  //await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),    
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),  
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()) , 
        ChangeNotifierProvider(create: (_) => ProposalProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()..fetchContracts()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),        


        
      ],
      child: MyApp(),
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
      home: RoleSelectionScreen(),
    );
  }
}

//  Role Selection Screen
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
                        builder: (_) => LoginScreen(), // Removed const
                      ),
                    );
                  },
                  child: const Text('Client', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
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
                        builder: (_) => LoginScreen(), 
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
