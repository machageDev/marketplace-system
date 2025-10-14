// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;

// /// StripePaymentProvider handles the full payment process in the app.
// /// It connects to your Django backend to create a Stripe PaymentIntent,
// /// then initializes and shows the payment sheet using the flutter_stripe package.
// class StripePaymentProvider extends ChangeNotifier {
  
//   /// Initiates a payment with the given [amount].
//   /// 
//   /// Steps:
//   /// 1. Calls your Django backend to create a PaymentIntent.
//   /// 2. Initializes Stripe’s PaymentSheet with the client secret.
//   /// 3. Presents the PaymentSheet to the user for payment.
//   Future<void> makePayment(double amount) async {
//     try {
//       // 1️⃣ Create Payment Intent from Django backend (convert to cents)
//       final response = await http.post(
//         Uri.parse('http://127.0.0.1:8000/create-payment-intent/'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'amount': (amount * 100).toInt()}), // Stripe uses cents
//       );

//       if (response.statusCode != 200) {
//         debugPrint('❌ Backend error: ${response.body}');
//         return;
//       }

//       // Decode the backend response to extract the client secret
//       final data = json.decode(response.body);
//       final clientSecret = data['clientSecret'];

//       // 2️⃣ Initialize the Stripe payment sheet
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'Helawork', // Shown in payment popup
//           style: ThemeMode.dark, // Matches your app theme
//         ),
//       );

//       // 3️⃣ Present the payment sheet to the user
//       await Stripe.instance.presentPaymentSheet();

//       debugPrint('✅ Payment successful!');
//     } catch (e) {
//       debugPrint('❌ Payment failed: $e');
//     }
//   }
// }
