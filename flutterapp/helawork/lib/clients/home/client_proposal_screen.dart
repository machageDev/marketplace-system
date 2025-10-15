import 'package:flutter/material.dart';
import 'package:helawork/clients/models/client_proposal.dart';
import 'package:helawork/clients/provider/client_proposal_provider.dart';
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
      context.read<ProposalsProvider>().loadProposals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposals List'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProposalsProvider>(
        builder: (context, proposalsProvider, child) {
          if (proposalsProvider.isLoading && proposalsProvider.proposals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (proposalsProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Proposals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      proposalsProvider.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => proposalsProvider.loadProposals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final proposals = proposalsProvider.proposals;

          if (proposals.isEmpty) {
            return _buildEmptyState();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProposalCount(proposals.length),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => proposalsProvider.loadProposals(),
                    child: ListView.builder(
                      itemCount: proposals.length,
                      itemBuilder: (context, index) {
                        return _buildProposalCard(proposals[index], context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProposalCount(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.blue, width: 4)),
      ),
      child: Text(
        '$count proposal${count == 1 ? '' : 's'} received',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProposalCard(Proposal proposal, BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[50]!, Colors.grey[100]!],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted ${proposal.submittedAgo} ago',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(proposal.status),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Freelancer Info
                _buildFreelancerInfo(proposal.freelancer),
                const SizedBox(height: 20),

                // Proposal Meta
                _buildProposalMeta(proposal),
                const SizedBox(height: 20),

                // Cover Letter
                if (proposal.coverLetter.isNotEmpty) 
                  _buildCoverLetter(proposal.coverLetter),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: _buildActionButtons(proposal, context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        statusText = 'Accepted';
        break;
      case 'rejected':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFreelancerInfo(Freelancer freelancer) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.blueAccent],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Text(
              freelancer.name.isNotEmpty ? freelancer.name[0].toUpperCase() : 'F',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                freelancer.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // Rating
              Row(
                children: [
                  ...List.generate(4, (index) => const Icon(Icons.star, size: 16, color: Colors.amber)),
                  const Icon(Icons.star_half, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  const Text(
                    '(4.5)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProposalMeta(Proposal proposal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetaItem('Proposed Amount', 'Ksh ${proposal.bidAmount.toStringAsFixed(2)}'),
          ),
          Expanded(
            child: _buildMetaItem('Timeline', '${proposal.estimatedDays} days'),
          ),
          Expanded(
            child: _buildMetaItem('Submitted Date', proposal.submittedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverLetter(String coverLetter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Letter:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            coverLetter,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Proposal proposal, BuildContext context) {
    final isPending = proposal.status.toLowerCase() == 'pending';
    final proposalsProvider = context.read<ProposalsProvider>();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Accept/Reject buttons
        if (isPending) ...[
          ElevatedButton.icon(
            onPressed: proposalsProvider.isLoading ? null : () => _showAcceptConfirmation(context, proposal),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: proposalsProvider.isLoading 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Accept Proposal'),
          ),
          ElevatedButton.icon(
            onPressed: proposalsProvider.isLoading ? null : () => _showRejectConfirmation(context, proposal),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close, size: 18),
            label: proposalsProvider.isLoading 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Reject'),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: proposal.status.toLowerCase() == 'accepted' ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(proposal.status.toLowerCase() == 'accepted' ? 'Accepted' : 'Accept Proposal'),
          ),
          ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: proposal.status.toLowerCase() == 'rejected' ? Colors.red : Colors.grey,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close, size: 18),
            label: Text(proposal.status.toLowerCase() == 'rejected' ? 'Rejected' : 'Reject'),
          ),
        ],

        // Message button
        ElevatedButton.icon(
          onPressed: () => _showMessageComingSoon(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.message, size: 18),
          label: const Text('Message'),
        ),

        // View Profile button
        if (proposal.freelancer.id.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => _viewFreelancerProfile(context, proposal.freelancer.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600]!,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Profile'),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.visibility_off, size: 18),
            label: const Text('No Profile'),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No Proposals Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "You haven't received any proposals for your tasks yet.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "When freelancers submit proposals, they'll appear here for your review.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmation(BuildContext context, Proposal proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Proposal'),
        content: const Text('Are you sure you want to accept this proposal? This will reject all other proposals for this task.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ProposalsProvider>().acceptProposal(proposal.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proposal accepted successfully')),
                );
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(BuildContext context, Proposal proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: const Text('Are you sure you want to reject this proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ProposalsProvider>().rejectProposal(proposal.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proposal rejected successfully')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showMessageComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging feature coming soon!')),
    );
  }

  void _viewFreelancerProfile(BuildContext context, String freelancerId) {
    // Navigate to freelancer profile
    // Navigator.push(context, MaterialPageRoute(builder: (_) => FreelancerProfileScreen(freelancerId: freelancerId)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing profile of freelancer $freelancerId')),
    );
  }
}