import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/task_detail.dart';
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
        provider.fetchContracts(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          "My Contracts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          provider.fetchContracts(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
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
                          Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No contracts available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "When employers accept your proposals,\ncontracts will appear here",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              provider.fetchContracts(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Refresh",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await provider.fetchContracts(context);
                        return;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.contracts.length,
                        itemBuilder: (context, index) {
                          final contract = provider.contracts[index];
                          return _buildContractCard(context, contract, provider);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          provider.fetchContracts(context);
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContractCard(
      BuildContext context, Contract contract, ContractProvider provider) {
    
    // DEBUG: Add this to see what's happening
    print('🔍 CONTRACT CARD DEBUG:');
    print('   ID: ${contract.contractId}');
    print('   Title: ${contract.taskTitle}');
    print('   Employer Accepted: ${contract.employerAccepted}');
    print('   You Accepted: ${contract.freelancerAccepted}');
    print('   canAccept: ${contract.canAccept}');
    print('   isAccepted: ${contract.isAccepted}');
    print('   Status: ${contract.status}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[100],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: contract.isAccepted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
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
            if (contract.budget != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Budget: \$${contract.budget!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // ACTION BUTTONS - CORRECT LOGIC BASED ON DEBUG DATA
            // From your logs: employer_accepted: true, freelancer_accepted: true
            // So this contract is already fully accepted
            if (contract.employerAccepted && !contract.freelancerAccepted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAcceptContractDialog(
                            context, contract.contractId, provider);
                      },
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Accept Contract'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showRejectContractDialog(
                            context, contract.contractId, provider);
                      },
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (contract.isAccepted && contract.freelancerAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Get task ID from the contract
                    final taskId = contract.task['id'] ?? contract.task['task_id'];
                    
                    if (taskId != null) {
                      // Navigate to TaskPage with the task data
                      _navigateToTaskPage(context, contract);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task information not available'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.assignment, size: 20),
                  label: const Text('View Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // NEW METHOD: Navigate to TaskPage with contract data
  void _navigateToTaskPage(BuildContext context, Contract contract) {
    // Get task data from contract
    final taskData = Map<String, dynamic>.from(contract.task);
    
    // Add employer data
    taskData['employer'] = Map<String, dynamic>.from(contract.employer);
    
    // Add task ID (try different possible fields)
    final taskId = contract.task['id'] ?? contract.task['task_id'] ?? 0;
    taskData['task_id'] = taskId;
    taskData['id'] = taskId;
    
    // Mark the task as assigned to current user since it's a contract
    taskData['assigned_user'] = true;
    taskData['status'] = 'in_progress'; // Or 'assigned' based on your logic
    
    // Navigate to TaskPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: taskId,
          task: taskData,
          employer: Map<String, dynamic>.from(contract.employer),
          isTaken: true, // Contract tasks are always taken
          isFromContract: true, // Flag to indicate this is from contract
        ),
      ),
    );
  }

  Widget _buildAcceptanceStatus(String label, bool accepted) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accepted ? Colors.green : Colors.grey[600],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptContractDialog(
      BuildContext context, int contractId, ContractProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          'Accept Contract',
          style: TextStyle(color: Colors.grey[100]),
        ),
        content: Text(
          'By accepting this contract, you agree to complete the task according to the terms and conditions.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.acceptContract(context, contractId);
              } catch (e) {
                // Error is already shown by provider
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectContractDialog(
      BuildContext context, int contractId, ContractProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          'Reject Contract',
          style: TextStyle(color: Colors.grey[100]),
        ),
        content: Text(
          'Are you sure you want to reject this contract? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.rejectContract(context, contractId);
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