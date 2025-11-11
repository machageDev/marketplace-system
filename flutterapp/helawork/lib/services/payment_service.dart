import 'package:flutter/material.dart';
import 'package:helawork/clients/home/flutterwave_payment_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  Future<void> makePayment(BuildContext context, double amount) async {
    final response = await http.post(
      Uri.parse('http://192.168.100.188:8000/api/initialize-payment/'),
      body: {'amount': amount.toString()},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final paymentLink = jsonResponse['data']['link'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(paymentUrl: paymentLink),
        ),
      );
    } else {
      print('Payment initialization failed: ${response.body}');
    }
  }
}
