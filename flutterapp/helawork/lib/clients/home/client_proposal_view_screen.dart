import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/models/client_proposal.dart';
import 'package:helawork/clients/provider/client_proposal_provider.dart' as client_proposal;

class ProposalViewScreen extends StatefulWidget {
  final Proposal proposal;

  const ProposalViewScreen({super.key, required this.proposal});

  @override
  State<ProposalViewScreen> createState() => _ProposalViewScreenState();
}

class _ProposalViewScreenState extends State<ProposalViewScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Proposal Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title
            Text(
              widget.proposal.task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            // Freelancer info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue,
                  child: Text(
                    widget.proposal.freelancer.name.isNotEmpty
                        ? widget.proposal.freelancer.name[0].toUpperCase()
                        : 'F',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.proposal.freelancer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star_half, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text('(4.5)', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status badge
            _buildStatusBadge(widget.proposal.status),
            const SizedBox(height: 20),

            // Proposal details box
            _buildDetailsBox(
              label: 'Proposed Amount',
              value: 'Ksh ${widget.proposal.bidAmount.toStringAsFixed(2)}',
            ),
            _buildDetailsBox(
              label: 'Estimated Days',
              value: '${widget.proposal.estimatedDays} days',
            ),
            _buildDetailsBox(
              label: 'Submitted On',
              value: widget.proposal.submittedDate,
            ),
            const SizedBox(height: 20),

            // Cover Letter
            const Text(
              'Cover Letter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.proposal.coverLetter.isNotEmpty
                    ? widget.proposal.coverLetter
                    : "No cover letter provided.",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons - Only show if proposal is pending
            if (widget.proposal.status.toLowerCase() == 'pending') ...[
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          label: 'Accept',
                          color: Colors.green,
                          onTap: () => _handleAcceptProposal(context),
                        ),
                        _buildButton(
                          label: 'Reject',
                          color: Colors.red,
                          onTap: () => _handleRejectProposal(context),
                        ),
                      ],
                    ),
            ],

            // Show message if already processed
            if (widget.proposal.status.toLowerCase() != 'pending') ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Proposal already ${widget.proposal.status}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAcceptProposal(BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final proposalProvider = Provider.of<client_proposal.ProposalsProvider>(
        context,
        listen: false,
      );

      final success = await proposalProvider.acceptProposal(widget.proposal.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back or update UI
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept proposal: ${proposalProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleRejectProposal(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: const Text('Are you sure you want to reject this proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final proposalProvider = Provider.of<client_proposal.ProposalsProvider>(
        context,
        listen: false,
      );

      final success = await proposalProvider.rejectProposal(widget.proposal.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject proposal: ${proposalProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status.toLowerCase()) {
      case 'accepted':
        bg = Colors.green[50]!;
        text = Colors.green[800]!;
        break;
      case 'rejected':
        bg = Colors.red[50]!;
        text = Colors.red[800]!;
        break;
      default:
        bg = Colors.orange[50]!;
        text = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailsBox({required String label, required String value}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}