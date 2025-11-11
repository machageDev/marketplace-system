import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required paymentUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final String publicKey = "FLWPUBK_TEST-xxxxxxxxxxxxxxxxxxxxxxxx-X"; // Replace with your public key
  final String currency = "KES"; // Use "KES" for Kenyan Shilling

  void makePayment(BuildContext context) async {
    // Create Customer
    final Customer customer = Customer(
      name: "Client Helawork",
      phoneNumber: "0712345678",
      email: "client@helawork.com",
    );

    // Create payment object
    final Flutterwave flutterwave = Flutterwave(
      
      publicKey: publicKey,
      currency: currency,
      amount: "2000", // amount as a string
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      isTestMode: true, // change to false in production
      customer: customer,
      paymentOptions: "card,mpesa,ussd,banktransfer",
      customization: Customization(
        title: "Helawork Wallet Top-Up",
        description: "Top-up your Helawork wallet",
      ),
      redirectUrl: "https://your-backend.com/payment/verify",
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);

      if (response.success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful!")),
        );
        print("Payment successful: ${response.status}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed or cancelled.")),
        );
        print("Payment failed or cancelled: ${response.status}");
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
      print("Payment error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Wallet Top Up",
          style: TextStyle(color: Colors.blueAccent),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => makePayment(context),
          child: const Text(
            "Pay with Flutterwave",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
