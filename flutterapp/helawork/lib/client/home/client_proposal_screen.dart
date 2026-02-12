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
      if (mounted) {
        context.read<ClientProposalProvider>().loadProposals();
      }
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
            return _buildErrorState(provider);
          }

          final proposals = provider.proposals;
          if (proposals.isEmpty) return _buildEmptyState();

          return RefreshIndicator(
            color: blueColor,
            onRefresh: () => provider.loadProposals(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: proposals.length,
              itemBuilder: (context, index) => _buildProposalCard(proposals[index], context),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                _buildStatusBadge(proposal.status),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _viewFreelancerProfile(context, proposal.freelancerId),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Freelancer: ${proposal.freelancerName}',
                    style: const TextStyle(
                      color: Colors.blue, 
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              proposal.formattedBidAmount, 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewProposalDetails(context, proposal),
                  child: const Text('Details'),
                ),
                const SizedBox(width: 10),
                
                if (proposal.isPending)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _showAcceptConfirmation(context, proposal),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Accept'),
                  ),
                  
                if (proposal.isAccepted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () => _handleDirectPayment(context, proposal),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pay Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptConfirmation(BuildContext context, ClientProposal proposal) {
    final provider = context.read<ClientProposalProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Proposal'),
        content: Text('Accept proposal from ${proposal.freelancerName} for ${proposal.formattedBidAmount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              _showLoading();

              try {
                final success = await provider.acceptProposal(proposal.id);
                
                if (!mounted) return;
                Navigator.pop(context);

                if (success) {
                  final response = provider.lastResponse;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.reload(); 

                  final String? token = prefs.getString('user_token');
                  final String name = prefs.getString('user_name') ?? "Client";
                  final String email = "machagefranklyn@gmail.com";

                  if (token == null || token.isEmpty) {
                    _showErrorSnackBar("Session expired. Please login again.");
                    return;
                  }

                  _navigateToPayment(context, proposal, response, email, name, token);
                } else {
                  _showErrorSnackBar(provider.errorMessage);
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                _showErrorSnackBar('Error: $e');
              }
            },
            child: const Text('Accept & Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDirectPayment(BuildContext context, ClientProposal proposal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); 

    final String? token = prefs.getString('user_token');
    final String name = prefs.getString('user_name') ?? "Client";
    final String email = "machagefranklyn@gmail.com";

    if (token == null || token.isEmpty) {
      _showErrorSnackBar("Session error: Please login again.");
      return;
    }

    _navigateToPayment(context, proposal, null, email, name, token);
  }

  void _navigateToPayment(
    BuildContext context, 
    ClientProposal proposal, 
    Map? response, 
    String email, 
    String name, 
    String token
  ) {
    final String orderUuid = response?['order_id']?.toString() ?? 
                             proposal.orderId ?? 
                             proposal.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: orderUuid, 
          amount: proposal.bidAmount,
          freelancerName: proposal.freelancerName,
          freelancerId: proposal.freelancerId,
          contractId: response?['contract_id']?.toString() ?? proposal.id,
          taskTitle: proposal.taskTitle,
          isValidOrderId: true,
          employerName: name,
          taskId: response?['task_id']?.toString() ?? proposal.taskId,
          email: email,
          authToken: token, 
          currency: "KSH",
        ),
      ),
    ).then((wasSuccessful) {
      if (wasSuccessful == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Verified! Proposal is now PAID."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      if (mounted) {
        context.read<ClientProposalProvider>().loadProposals();
      }
    });
  }

  void _showLoading() {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.red
      )
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPaid = status.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.blue.shade50, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: isPaid ? Colors.green : Colors.blue
        )
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No Proposals Yet", 
        style: TextStyle(fontSize: 18, color: Colors.grey)
      )
    );
  }

  Widget _buildErrorState(ClientProposalProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              provider.errorMessage, 
              textAlign: TextAlign.center
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => provider.loadProposals(), 
            child: const Text("Retry")
          )
        ],
      )
    );
  }

  void _viewProposalDetails(BuildContext context, ClientProposal proposal) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ProposalViewScreen(proposal: proposal)
      )
    );
  }

  void _viewFreelancerProfile(BuildContext context, String freelancerId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => FreelancerProfileScreen(freelancerId: freelancerId)
      )
    );
  }
}