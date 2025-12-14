import 'package:flutter/material.dart';
import 'package:helawork/freelancer/models/contract_model.dart';
import 'package:helawork/freelancer/provider/contract_provider.dart';
import 'package:provider/provider.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    _hasFetched = false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);

    if (!_hasFetched && !provider.isLoading && provider.contracts.isEmpty) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchContracts(context); // Pass context here
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "My Contracts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF007bff),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007bff),
              ),
            )
          : provider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          provider.fetchContracts(context); // Pass context
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007bff),
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : provider.contracts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No contracts available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "When employers accept your proposals,\ncontracts will appear here",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              provider.fetchContracts(context); // Pass context
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007bff),
                            ),
                            child: const Text(
                              "Refresh",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.contracts.length,
                      itemBuilder: (context, index) {
                        final contract = provider.contracts[index];
                        return _buildContractCard(context, contract, provider);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          provider.fetchContracts(context); // Pass context
        },
        backgroundColor: const Color(0xFF007bff),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, Contract contract, ContractProvider provider) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.taskTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0056b3),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: contract.isAccepted 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: contract.isAccepted ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    contract.isAccepted ? 'Active' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: contract.isAccepted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Acceptance status
            Row(
              children: [
                _buildAcceptanceStatus('Employer', contract.employerAccepted),
                const SizedBox(width: 16),
                _buildAcceptanceStatus('You', contract.freelancerAccepted),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Contract details
            _buildDetailRow('Employer', contract.employerName),
            _buildDetailRow('Start Date', contract.formattedStartDate),
            if (contract.endDate != null)
              _buildDetailRow('End Date', contract.formattedEndDate!),
            
            const SizedBox(height: 12),
            
            // Budget
            if (contract.task['budget'] != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Budget: \$${contract.task['budget']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (contract.canAccept)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAcceptContractDialog(context, contract.contractId, provider);
                      },
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Accept Contract'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showRejectContractDialog(context, contract.contractId, provider);
                      },
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            
            if (contract.isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to task management
                    Navigator.pushNamed(context, '/my-tasks');
                  },
                  icon: const Icon(Icons.assignment, size: 20),
                  label: const Text('View Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007bff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptanceStatus(String label, bool accepted) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accepted ? Colors.green : Colors.grey,
          ),
          child: Icon(
            accepted ? Icons.check : Icons.pending,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptContractDialog(BuildContext context, int contractId, ContractProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Contract'),
        content: const Text(
          'By accepting this contract, you agree to complete the task according to the terms and conditions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.acceptContract(context, contractId); // Pass context
              } catch (e) {
                // Error is already shown by provider
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectContractDialog(BuildContext context, int contractId, ContractProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Contract'),
        content: const Text(
          'Are you sure you want to reject this contract? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.rejectContract(context, contractId); // Pass context
              } catch (e) {
                // Error is already shown by provider
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}