import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_payment_screen.dart';
import 'package:helawork/client/home/client_proposal_view_screen.dart';
import 'package:helawork/client/home/freelancer_profile_screen.dart';
import 'package:helawork/client/models/client_proposal.dart';
import 'package:helawork/client/provider/client_proposal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ClientProposalsScreen extends StatefulWidget {
  const ClientProposalsScreen({super.key});

  @override
  State<ClientProposalsScreen> createState() => _ClientProposalsScreenState();
}

class _ClientProposalsScreenState extends State<ClientProposalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProposalProvider>().loadProposals();
    });
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Colors.blue;
    const whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        title: const Text('Proposals List'),
        backgroundColor: blueColor,
        foregroundColor: whiteColor,
        centerTitle: true,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ClientProposalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.proposals.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: blueColor));
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Proposals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: whiteColor,
                    ),
                    onPressed: () => provider.loadProposals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final proposals = provider.proposals;

          if (proposals.isEmpty) {
            return _buildEmptyState();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RefreshIndicator(
              color: blueColor,
              onRefresh: () => provider.loadProposals(),
              child: ListView.builder(
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  return _buildProposalCard(proposals[index], context);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProposalCard(ClientProposal proposal, BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    proposal.taskTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ),
                _buildStatusBadge(proposal.status),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _viewFreelancerProfile(context, proposal.freelancerId),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Freelancer: ${proposal.freelancerName}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Bid: Ksh ${proposal.bidAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${proposal.estimatedDays} days',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: proposal.taskServiceType == 'on_site' 
                    ? Colors.orange.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: proposal.taskServiceType == 'on_site' 
                      ? Colors.orange.withOpacity(0.3) 
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    proposal.taskServiceType == 'on_site' ? Icons.location_on : Icons.laptop,
                    size: 14,
                    color: proposal.taskServiceType == 'on_site' ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    proposal.taskServiceType == 'on_site' ? 'On-Site Work' : 'Remote Work',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: proposal.taskServiceType == 'on_site' ? Colors.orange : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _viewProposalDetails(context, proposal),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 10),
                if (proposal.status.toLowerCase() == 'pending')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _showAcceptConfirmation(context, proposal),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Accept'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'accepted':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 100, color: Colors.blue[100]),
          const SizedBox(height: 20),
          const Text('No Proposals Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue)),
          const Text('You have not received any proposals yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAcceptConfirmation(BuildContext context, ClientProposal proposal) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Accept Proposal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accept proposal from ${proposal.freelancerName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Ksh ${proposal.bidAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Funds go to secure escrow', style: TextStyle(fontSize: 13)),
                  const Text('• Freelancer starts after payment', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final provider = context.read<ClientProposalProvider>();
                final success = await provider.acceptProposal(proposal.id);
                
                if (context.mounted) Navigator.pop(context);

                if (success) {
                  final response = provider.lastResponse;
                  final prefs = await SharedPreferences.getInstance();

                  // FIX: Prioritize response email to avoid "Glen" email issue
                  final String userEmail = response?['employer_email']?.toString() ?? 
                                         prefs.getString("user_email") ?? "";
                  
                  final String userName = response?['employer_name']?.toString() ?? 
                                        prefs.getString("user_name") ?? "Client";
                  
                  final String orderId = response?['order_id']?.toString() ?? proposal.id.toString();
                  final String taskId = response?['task_id']?.toString() ?? proposal.taskId;

                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        orderId: orderId,
                        amount: proposal.bidAmount,
                        freelancerName: proposal.freelancerName,
                        freelancerId: proposal.freelancerId,
                        contractId: response?['contract_id']?.toString() ?? orderId,
                        taskTitle: response?['task_title']?.toString() ?? proposal.taskTitle,
                        isValidOrderId: true,
                        employerName: userName,
                        taskId: taskId,
                        serviceDescription: proposal.taskTitle,
                        email: userEmail,
                        currency: "KSH",
                      ),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(provider.errorMessage), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context); 
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Accept & Pay Securely'),
          ),
        ],
      ),
    );
  }

  void _viewProposalDetails(BuildContext context, ClientProposal proposal) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProposalViewScreen(proposal: proposal)));
  }

  void _viewFreelancerProfile(BuildContext context, String freelancerId) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FreelancerProfileScreen(freelancerId: freelancerId)));
  }
}