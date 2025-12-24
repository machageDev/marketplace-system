import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_proposal_view_screen.dart';
import 'package:helawork/client/models/client_proposal.dart';
import 'package:helawork/client/provider/client_proposal_provider.dart';
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
            // Title + Status
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

            // Freelancer info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Freelancer: ${proposal.freelancerName}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bid and timeline
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

            // Cover Letter Preview
            if (proposal.coverLetter.isNotEmpty)
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
                    const Text(
                      'Cover Letter:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proposal.coverLetter.length > 150
                          ? '${proposal.coverLetter.substring(0, 150)}...'
                          : proposal.coverLetter,
                      style: const TextStyle(color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View Details Button
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
                
                // Accept Button (only for pending proposals)
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
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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
          const Text(
            'No Proposals Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You have not received any proposals yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmation(BuildContext context, ClientProposal proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Proposal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accept proposal from ${proposal.freelancerName}?'),
            const SizedBox(height: 8),
            Text(
              'Bid: Ksh ${proposal.bidAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ClientProposalProvider>().acceptProposal(proposal.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proposal accepted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the list
                context.read<ClientProposalProvider>().loadProposals();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<ClientProposalProvider>().errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _viewProposalDetails(BuildContext context, ClientProposal proposal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProposalViewScreen(proposal: proposal),
      ),
    );
  }
}