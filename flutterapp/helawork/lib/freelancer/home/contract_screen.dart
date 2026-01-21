import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/task_detail.dart';
import 'package:helawork/freelancer/model/contract_model.dart';
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

    // Initial fetch logic
    if (!_hasFetched && !provider.isLoading && provider.contracts.isEmpty) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchContracts(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("My Contracts",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => provider.fetchContracts(context),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : provider.contracts.isEmpty
              ? _buildEmptyState(provider)
              : RefreshIndicator(
                  color: Colors.blue,
                  onRefresh: () => provider.fetchContracts(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.contracts.length,
                    itemBuilder: (context, index) {
                      return _buildContractCard(context, provider.contracts[index], provider);
                    },
                  ),
                ),
    );
  }

  Widget _buildContractCard(BuildContext context, Contract contract, ContractProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with task title and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(contract.taskTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              _buildStatusBadge(contract),
            ],
          ),
          const SizedBox(height: 12),
          
          // Contract details
          _buildInfoRow(Icons.person, "Client: ${contract.employerName}"),
          _buildInfoRow(Icons.calendar_today, "Started: ${contract.formattedStartDate}"),
          
          if (contract.budget != null)
            _buildInfoRow(Icons.payments, "Budget: \$${contract.budget!.toStringAsFixed(2)}", color: Colors.green),
          
          _buildInfoRow(
            contract.isOnSite ? Icons.location_on : Icons.computer,
            "Type: ${contract.isOnSite ? 'On-Site' : 'Remote'}",
            color: contract.isOnSite ? Colors.orange : Colors.blue
          ),
          
          const Divider(height: 32, color: Colors.grey),

          // Action buttons based on contract state
          _buildActionButtons(context, contract, provider),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Contract contract, ContractProvider provider) {
    // Check what action is needed
    if (contract.canAccept) {
      return _buildAcceptRejectSection(context, contract, provider);
    } 
    
    else if (contract.needsOtpVerification) {
      return _buildOnSiteOTPButton(context, contract, provider);
    } 
    
    else if (contract.needsWorkSubmission) {
      return _buildRemoteTaskButton(context, contract);
    } 
    
    else if (contract.isAwaitingPayment) {
      return _buildAwaitingPaymentStatus();
    } 
    
    else if (contract.isPaidAndCompleted) {
      return _buildCompletedStatus(contract);
    } 
    
    else if (contract.isAccepted) {
      return _buildInProgressStatus();
    }
    
    else {
      return Center(
        child: Text(
          contract.displayStatus.toUpperCase(),
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildAcceptRejectSection(BuildContext context, Contract contract, ContractProvider provider) {
    return Column(
      children: [
        const Text("Client has sent you this contract",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showAcceptDialog(context, contract.contractId, provider),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Accept Work"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRejectDialog(context, contract.contractId, provider),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                child: const Text("Reject"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnSiteOTPButton(BuildContext context, Contract contract, ContractProvider provider) {
    return Column(
      children: [
        const Text("On-site job - Awaiting completion verification",
            style: TextStyle(color: Colors.orange, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.vpn_key),
            label: const Text("Enter Completion Code"),
            onPressed: () => _showOTPDialog(context, contract, provider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteTaskButton(BuildContext context, Contract contract) {
    return Column(
      children: [
        const Text("Remote work - Payment in escrow",
            style: TextStyle(color: Colors.blue, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("Submit Work Files"),
            onPressed: () => _navigateToTaskPage(context, contract),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAwaitingPaymentStatus() {
    return Column(
      children: [
        const Icon(Icons.hourglass_empty, color: Colors.orange, size: 40),
        const SizedBox(height: 8),
        const Text("⏳ Awaiting Client Payment", 
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        const Text("Client needs to pay into escrow to start",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCompletedStatus(Contract contract) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 40),
        const SizedBox(height: 8),
        const Text("✅ Milestone Completed & Paid", 
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        if (contract.formattedEndDate != null)
          Text("Completed on: ${contract.formattedEndDate}",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInProgressStatus() {
    return Column(
      children: [
        const Icon(Icons.autorenew, color: Colors.blue, size: 40),
        const SizedBox(height: 8),
        const Text("🔄 Work In Progress", 
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const Text("Continue working on the task",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusBadge(Contract contract) {
    Color color;
    String text;
    
    if (contract.isPaidAndCompleted) {
      color = Colors.green;
      text = 'COMPLETED';
    } else if (contract.needsOtpVerification) {
      color = Colors.orange;
      text = 'AWAITING OTP';
    } else if (contract.canAccept) {
      color = Colors.blue;
      text = 'PENDING';
    } else if (contract.needsWorkSubmission) {
      color = Colors.purple;
      text = 'SUBMIT WORK';
    } else if (contract.isAwaitingPayment) {
      color = Colors.yellow;
      text = 'AWAITING PAYMENT';
    } else if (contract.isAccepted) {
      color = Colors.cyan;
      text = 'IN PROGRESS';
    } else {
      color = Colors.grey;
      text = contract.displayStatus.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ]),
    );
  }

  Widget _buildEmptyState(ContractProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text("No contracts found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Contracts awaiting your action will appear here",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  void _showOTPDialog(BuildContext context, Contract contract, ContractProvider provider) {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Verify Completion", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the code from the client to release payment.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blue, fontSize: 32, letterSpacing: 4),
              decoration: const InputDecoration(hintText: "000000", counterText: "", hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length == 6) {
                final success = await provider.verifyContractOTP(
                  context, 
                  contract.contractId, 
                  otpController.text
                );
                if (success && mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Verify & Pay"),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, int id, ContractProvider p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Accept Contract?", style: TextStyle(color: Colors.white)),
        content: const Text("By accepting, you agree to complete this task within the agreed timeline.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              p.acceptContract(context, id);
              Navigator.pop(context);
            }, 
            child: const Text("Confirm Accept")
          ),
        ],
      )
    );
  }

  void _showRejectDialog(BuildContext context, int id, ContractProvider p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Reject Contract?", style: TextStyle(color: Colors.red)),
        content: const Text("This action cannot be undone. The client will be notified.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              p.rejectContract(context, id);
              Navigator.pop(context);
            }, 
            child: const Text("Confirm Reject")
          ),
        ],
      )
    );
  }

  void _navigateToTaskPage(BuildContext context, Contract contract) {
    final rawId = contract.task['task_id'] ?? contract.task['id'];
    final int parsedId = rawId is int 
        ? rawId 
        : int.tryParse(rawId.toString()) ?? 0;

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: parsedId,
          task: contract.task,
          employer: contract.employer,
          isTaken: true,
          isFromContract: true,
        ),
      ),
    );
  }
}