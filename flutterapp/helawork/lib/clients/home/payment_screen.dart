import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  Future<String?> initializePayment(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.188:8000/api/initialize-payment/'),
        body: {'amount': amount.toString()},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Flutterwave returns the payment link under data.link
        return jsonResponse['data']['link'];
      } else {
        print('Payment initialization failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error initializing payment: $e');
      return null;
    }
  }
}
