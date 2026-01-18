import 'package:flutter/material.dart';
import 'package:helawork/api_config.dart';
import 'package:helawork/client/home/client_payment_screen.dart';
import 'package:helawork/client/provider/client_contract_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientContractsScreen extends StatefulWidget {
  const ClientContractsScreen({super.key});

  @override
  State<ClientContractsScreen> createState() => _ClientContractsScreenState();
}

class _ClientContractsScreenState extends State<ClientContractsScreen> {
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _backgroundColor = Colors.white;
  final Color _greenColor = const Color(0xFF4CAF50);

  String? token;

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("user_token");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientContractProvider>(context, listen: false)
          .fetchEmployerContracts();
    });
  }

  String _getStatusText(Map<String, dynamic> c) {
    final isPaid = c['is_paid'] == true || c['is_paid'] == 1;
    final isCompleted = c['is_completed'] == true || c['is_completed'] == 1;
    final service = c['service_type'] ?? 'remote';

    if (!isPaid) return "Awaiting Escrow Payment";
    if (isPaid && !isCompleted) {
      return service == 'on_site'
          ? "Awaiting OTP Handshake"
          : "In Escrow – Pending Release";
    }
    if (isPaid && isCompleted) return "Paid & Completed";

    return "Unknown";
  }

  Color _getStatusColor(Map<String, dynamic> c) {
    final isPaid = c['is_paid'] == true || c['is_paid'] == 1;
    final isCompleted = c['is_completed'] == true || c['is_completed'] == 1;

    if (isPaid && isCompleted) return _greenColor;
    if (!isPaid) return Colors.red;
    return _primaryBlue;
  }

  String _getActionButtonText(Map<String, dynamic> c) {
    final isPaid = c['is_paid'] == true || c['is_paid'] == 1;
    final isCompleted = c['is_completed'] == true || c['is_completed'] == 1;
    final service = c['service_type'] ?? 'remote';

    if (!isPaid) return "Pay into Escrow";

    if (isPaid && !isCompleted) {
      return service == 'on_site'
          ? "Show Verification Code"
          : "Release Payment";
    }

    return "Completed";
  }

  void _showOTPDialog(BuildContext context, String? otp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Handshake Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Give this code to the worker:"),
            const SizedBox(height: 20),
            Text(
              otp ?? "------",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showReleaseConfirmation(
      BuildContext context, int contractId, String taskTitle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Release Payment"),
        content: Text(
          "Release payment for \"$taskTitle\"?\nThis will transfer funds to the freelancer.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Release"),
            onPressed: () async {
              Navigator.pop(context);
              await _releasePayment(contractId);
            },
          )
        ],
      ),
    );
  }

  Future<void> _releasePayment(int contractId) async {
    try {
      final url = "${AppConfig.getBaseUrl()}/api/contracts/release-payment/";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
        body: {"contract_id": contractId.toString()},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment released successfully."),
            backgroundColor: Colors.green,
          ),
        );

        Provider.of<ClientContractProvider>(context, listen: false)
            .fetchEmployerContracts();
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error releasing payment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToPaymentScreen(
      BuildContext context, Map<String, dynamic> c) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email") ?? "";

    if (email.isEmpty) {
      _promptEmailEntry(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          orderId: c['contract_id'].toString(),
          amount: double.parse(c['amount'].toString()),
          email: email,
          freelancerName: c['freelancer_name'] ?? "",
          serviceDescription: c['task_title'] ?? "",
          freelancerPhotoUrl: c['freelancer_photo'] ?? "",
          currency: "KES", freelancerId: '', contractId: '', taskTitle: '', isValidOrderId: false,
        ),
      ),
    );
  }

  Future<void> _promptEmailEntry(BuildContext context) async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Email"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString("user_email", controller.text.trim());
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> c) {
    final contractId = c['contract_id'];
    final serviceType = c['service_type'] ?? 'remote';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c['task_title'] ?? "Task",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Freelancer: ${c['freelancer_name']}"),
            const SizedBox(height: 6),
            Text("Amount: KES ${c['amount']}"),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(c),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusText(c),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(_getActionButtonText(c)),
              onPressed: () {
                final isPaid = c['is_paid'] == true || c['is_paid'] == 1;
                final isCompleted =
                    c['is_completed'] == true || c['is_completed'] == 1;

                if (!isPaid) {
                  _navigateToPaymentScreen(context, c);
                } else if (isPaid && !isCompleted) {
                  if (serviceType == 'on_site') {
                    _showOTPDialog(context, c['verification_code']);
                  } else {
                    _showReleaseConfirmation(
                        context, contractId, c['task_title']);
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientContractProvider>(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("My Contracts"),
        backgroundColor: _primaryBlue,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.contracts.isEmpty
              ? const Center(child: Text("No active contracts yet."))
              : ListView.builder(
                  itemCount: provider.contracts.length,
                  itemBuilder: (_, index) =>
                      _buildContractCard(provider.contracts[index]),
                ),
    );
  }
}
