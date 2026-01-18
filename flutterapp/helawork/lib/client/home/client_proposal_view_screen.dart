import 'package:flutter/material.dart';
import 'package:helawork/client/models/client_proposal.dart';
import 'package:helawork/client/provider/client_proposal_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class ProposalViewScreen extends StatefulWidget {
  final ClientProposal proposal;

  const ProposalViewScreen({super.key, required this.proposal});

  @override
  State<ProposalViewScreen> createState() => _ProposalViewScreenState();
}

class _ProposalViewScreenState extends State<ProposalViewScreen> {
  bool _isProcessing = false;

  void _downloadCoverLetter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download Cover Letter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Copy the cover letter text'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.green),
              title: const Text('Save as Text File'),
              subtitle: const Text('Download as .txt file'),
              onTap: () {
                Navigator.pop(context);
                _saveAsTextFile();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Share'),
              subtitle: const Text('Share via other apps'),
              onTap: () {
                Navigator.pop(context);
                _shareCoverLetter();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.proposal.coverLetter));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover letter copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveAsTextFile() async {
    try {
      final fileContent = '''
PROPOSAL COVER LETTER
=====================

Task: ${widget.proposal.taskTitle}
Freelancer: ${widget.proposal.freelancerName}
Proposed Amount: Ksh ${widget.proposal.bidAmount.toStringAsFixed(2)}
Estimated Days: ${widget.proposal.estimatedDays} days
Submitted: ${_formatDate(widget.proposal.createdAt)}

COVER LETTER:
${widget.proposal.coverLetter}

---
Generated from HelaWork App
''';

      await Clipboard.setData(ClipboardData(text: fileContent));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover letter prepared for download! Copied to clipboard.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareCoverLetter() async {
    final shareText = '''
Check out this proposal from ${widget.proposal.freelancerName}:

Task: ${widget.proposal.taskTitle}
Amount: Ksh ${widget.proposal.bidAmount.toStringAsFixed(2)}
Timeline: ${widget.proposal.estimatedDays} days

Cover Letter:
${widget.proposal.coverLetter.length > 200 ? 
  '${widget.proposal.coverLetter.substring(0, 200)}...' : 
  widget.proposal.coverLetter}
''';

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': 'Proposal from ${widget.proposal.freelancerName} - ${widget.proposal.taskTitle}',
          'body': shareText,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share content copied to clipboard!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Show accept confirmation with payment info
  void _showAcceptConfirmation(BuildContext context) {
    final isOnSite = widget.proposal.taskServiceType == 'on_site';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            Text(
              'Accept proposal from ${widget.proposal.freelancerName}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            
            // Payment Information
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
                        'Ksh ${widget.proposal.bidAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Secure Payment Note
                  const Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Secure Escrow Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    '• Funds go to secure escrow',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    '• Freelancer starts after payment',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    '• Release payment when satisfied',
                    style: TextStyle(fontSize: 13),
                  ),
                  
                  // On-site specific instructions
                  if (isOnSite) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                'On-Site Task',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You will receive an OTP to give to freelancer when work is completed',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _handleAcceptProposal(context);
            },
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Accept & Pay Securely'),
          ),
        ],
      ),
    );
  }

  // UPDATED: Handle accept proposal with payment flow
  Future<void> _handleAcceptProposal(BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final proposalProvider = Provider.of<ClientProposalProvider>(
        context,
        listen: false,
      );

      final success = await proposalProvider.acceptProposal(widget.proposal.id);

      if (success) {
        // Check if payment is required
        final response = proposalProvider.lastResponse;
        
        if (response != null && 
            response.containsKey('requires_payment') &&
            response['requires_payment'] == true &&
            response['checkout_url'] != null) {
          
          // Get payment details
          final checkoutUrl = response['checkout_url'] as String;
          final orderId = response['order_id'] ?? 'N/A';
          
          // Show payment redirect message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Redirecting to secure payment...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Order: $orderId',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          
          // Launch Paystack payment page
          final Uri url = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
            
            // Pop back to proposals screen after launching payment
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot open payment page'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Old flow (payment not required)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proposal accepted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept proposal: ${proposalProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRejectProposal(BuildContext context) async {
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
      final proposalProvider = Provider.of<ClientProposalProvider>(
        context,
        listen: false,
      );

      final success = await proposalProvider.rejectProposal(widget.proposal.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proposal rejected.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject proposal: ${proposalProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Proposal Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadCoverLetter,
            tooltip: 'Download Cover Letter',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title
            Text(
              widget.proposal.taskTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),

            // Service Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.proposal.taskServiceType == 'on_site' 
                    ? Colors.orange.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.proposal.taskServiceType == 'on_site' 
                      ? Colors.orange 
                      : Colors.blue,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.proposal.taskServiceType == 'on_site' 
                        ? Icons.location_on 
                        : Icons.laptop,
                    size: 14,
                    color: widget.proposal.taskServiceType == 'on_site' 
                        ? Colors.orange 
                        : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.proposal.taskServiceType == 'on_site' 
                        ? 'On-Site Work' 
                        : 'Remote Work',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.proposal.taskServiceType == 'on_site' 
                          ? Colors.orange 
                          : Colors.blue,
                    ),
                  ),
                ],
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
                    widget.proposal.freelancerName.isNotEmpty
                        ? widget.proposal.freelancerName[0].toUpperCase()
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
                        widget.proposal.freelancerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Email if available
                      if (widget.proposal.freelancerEmail.isNotEmpty)
                        Text(
                          widget.proposal.freelancerEmail,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
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
              value: _formatDate(widget.proposal.createdAt),
            ),
            _buildDetailsBox(
              label: 'Work Type',
              value: widget.proposal.taskServiceType == 'on_site' 
                  ? 'On-Site (Physical)' 
                  : 'Remote (Digital)',
            ),
            const SizedBox(height: 20),

            // Cover Letter Section
            Row(
              children: [
                const Text(
                  'Cover Letter',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _downloadCoverLetter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Cover Letter Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: _copyToClipboard,
                        tooltip: 'Copy to clipboard',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.share, size: 18),
                        onPressed: _shareCoverLetter,
                        tooltip: 'Share',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  Text(
                    widget.proposal.coverLetter.isNotEmpty
                        ? widget.proposal.coverLetter
                        : "No cover letter provided.",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            if (widget.proposal.status.toLowerCase() == 'pending') ...[
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          label: 'Accept',
                          color: Colors.green,
                          onTap: () => _showAcceptConfirmation(context),
                        ),
                        _buildButton(
                          label: 'Reject',
                          color: Colors.red,
                          onTap: () => _handleRejectProposal(context),
                        ),
                      ],
                    ),
            ],

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}