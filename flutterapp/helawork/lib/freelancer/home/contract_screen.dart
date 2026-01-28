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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContractProvider>(context, listen: false).fetchContracts(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);

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
        border: Border.all(
          // Visual cue: Green border if Peter has paid but you haven't accepted
          color: contract.canAccept ? Colors.green : Colors.grey[800]!,
          width: contract.canAccept ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          _buildInfoRow(Icons.person, "Client: ${contract.employerName}"),
          _buildInfoRow(Icons.calendar_today, "Started: ${contract.formattedStartDate}"),
          
          _buildInfoRow(Icons.payments, "Budget: KES ${contract.budget.toStringAsFixed(2)}", color: Colors.green),
          
          _buildInfoRow(
            contract.isOnSite ? Icons.location_on : Icons.computer,
            "Type: ${contract.isOnSite ? 'On-Site' : 'Remote'}",
            color: contract.isOnSite ? Colors.orange : Colors.blue
          ),

          // --- DEBUG LINE: REMOVE THIS AFTER TESTING ---
          // Padding(
          //   padding: const EdgeInsets.only(top: 8.0),
          //   child: Text("Paid: ${contract.isPaid}, Accepted: ${contract.isAccepted}", 
          //   style: TextStyle(color: Colors.white38, fontSize: 10)),
          // ),
          
          const Divider(height: 32, color: Colors.grey),

          _buildActionButtons(context, contract, provider),
        ],
      ),
    );
  }
  Widget _buildActionButtons(BuildContext context, Contract contract, ContractProvider provider) {
  // 1. HIGH PRIORITY: If it's done, show the completed status immediately
  // This is where the "Mark Completed" visual happens
  if (contract.isCompleted || contract.status.toLowerCase() == 'completed') {
    return _buildCompletedStatus(contract);
  }

  // 2. Check Acceptance
  if (contract.canAccept) {
    return _buildAcceptRejectSection(context, contract, provider);
  } 
  
  // 3. If already accepted and NOT completed, show active workflow
  if (contract.isAccepted) {
    // Only show OTP button if NOT completed
    if (contract.isOnSite && !contract.isCompleted) {
       return _buildOnSiteOTPButton(context, contract, provider);
    }
    
    if (contract.isRemote && !contract.isCompleted) {
       return _buildRemoteTaskButton(context, contract);
    }

    if (contract.isAwaitingPayment) return _buildAwaitingPaymentStatus();
    
    return _buildInProgressStatus();
  }

  // 4. Fallback
  return Center(
    child: Text(
      contract.displayStatus.toUpperCase(),
      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
    ),
  );


}
Widget _buildStatusBadge(Contract contract) {
  Color color;
  String text;

  // 1. Check for completion first to override "In Progress"
  if (contract.isCompleted || contract.status == 'completed') {
    color = Colors.grey; // Or blueGrey
    text = 'COMPLETED';
  } else if (contract.canAccept) {
    color = Colors.green;
    text = 'PAID & READY';
  } else if (contract.isAccepted) {
    color = Colors.cyan;
    text = 'IN PROGRESS';
  } else {
    color = Colors.grey;
    text = contract.status.toUpperCase();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

  Widget _buildAcceptRejectSection(BuildContext context, Contract contract, ContractProvider provider) {
    return Column(
      children: [
        const Text("✅ Peter has paid for this task. Accept to start.",
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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

  // --- Utility Widgets ---
  Widget _buildOnSiteOTPButton(BuildContext context, Contract contract, ContractProvider provider) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(
      icon: const Icon(Icons.vpn_key),
      label: const Text("Enter Completion Code"),
      onPressed: () => _showOTPDialog(context, contract, provider),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
    ));
  }

  Widget _buildRemoteTaskButton(BuildContext context, Contract contract) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text("Submit Work Files"),
      onPressed: () => _navigateToTaskPage(context, contract),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
    ));
  }

  Widget _buildAwaitingPaymentStatus() => const Center(child: Text("Awaiting Payment...", style: TextStyle(color: Colors.orange)));
  Widget _buildCompletedStatus(Contract contract) => const Center(child: Text("✅ Task Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
  Widget _buildInProgressStatus() => const Center(child: Text("🔄 Work in Progress", style: TextStyle(color: Colors.cyan)));

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

  Widget _buildEmptyState(ContractProvider provider) => const Center(child: Text("No contracts found.", style: TextStyle(color: Colors.grey)));

  // --- Dialogs ---
  void _showAcceptDialog(BuildContext context, int id, ContractProvider p) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Accept Offer?", style: TextStyle(color: Colors.white)),
      content: const Text("This confirms you are starting the work."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () { p.acceptContract(context, id); Navigator.pop(context); }, child: const Text("Confirm")),
      ],
    ));
  }

  void _showRejectDialog(BuildContext context, int id, ContractProvider p) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Reject?", style: TextStyle(color: Colors.red)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () { p.rejectContract(context, id); Navigator.pop(context); }, child: const Text("Reject")),
      ],
    ));
  }

  void _showOTPDialog(BuildContext context, Contract contract, ContractProvider provider) {
    final TextEditingController otpController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Enter Code"),
      content: TextField(controller: otpController, keyboardType: TextInputType.number, maxLength: 6, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if (otpController.text.length == 6) {
            await provider.verifyContractOTP(context, contract.contractId, otpController.text);
            Navigator.pop(context);
          }
        }, child: const Text("Verify")),
      ],
    ));
  }

  void _navigateToTaskPage(BuildContext context, Contract contract) {
    final rawId = contract.task['task_id'] ?? contract.task['id'];
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(
      taskId: parsedId, task: contract.task, employer: contract.employer, isTaken: true, isFromContract: true,
    )));
  }
}