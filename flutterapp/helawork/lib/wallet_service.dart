import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  final String baseUrl = "http://192.168.100.188:8000/api/wallet"; // change to your backend IP

  Future<double?> getBalance(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/balance/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.parse(data['balance'].toString());
    } else {
      return null;
    }
  }

  Future<bool> withdraw(String token, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/withdraw/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'amount': amount}),
    );

    return response.statusCode == 200;
  }

  Future<String?> topUp(String token, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/topup/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['payment_link'];
    } else {
      return null;
    }
  }
}