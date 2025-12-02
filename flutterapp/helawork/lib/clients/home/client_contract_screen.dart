import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/contract_provider.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/models/contract_model.dart';

class ClientContractScreen extends StatefulWidget {
  final String token;
  final String contractId;

  const ClientContractScreen({
    super.key,
    required this.token,
    required this.contractId,
  });

  @override
  State<ClientContractScreen> createState() => _ClientContractScreenState();
}

class _ClientContractScreenState extends State<ClientContractScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ClientContractProvider>(context, listen: false)
          .fetchContract(widget.token, widget.contractId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contract Agreement"),
        backgroundColor: Colors.indigo,
      ),
      body: Consumer<ClientContractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final ContractModel? contract = provider.contract;
          if (contract == null) {
            return const Center(
              child: Text("No contract details available."),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Text(
                      "Contract Agreement",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow("Task:", contract.taskTitle),
                    _buildInfoRow(
                        "Freelancer:", contract.freelancerUsername),
                    _buildInfoRow(
                        "Start Date:", contract.startDate),
                    _buildInfoRow("End Date:",
                        contract.endDate ?? "Not set"),

                    const SizedBox(height: 10),
                    _buildStatusRow("Employer Accepted:",
                        contract.employerAccepted),
                    _buildStatusRow("Freelancer Accepted:",
                        contract.freelancerAccepted),
                    _buildStatusRow("Contract Active:",
                        contract.isActive),

                    const SizedBox(height: 20),
                    if (contract.employerAccepted == false)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await provider.acceptContract(
                              widget.token, widget.contractId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("You have agreed to this contract ✅"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Agree to Contract"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "You have already agreed to this contract ✅",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String title, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              status ? "✅ Yes" : "❌ No",
              style: TextStyle(
                color: status ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
