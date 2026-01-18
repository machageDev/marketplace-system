import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_paymentsuccess_screen.dart';
import 'package:helawork/client/home/client_proposal_view_screen.dart';
import 'package:helawork/client/home/freelancer_profile_screen.dart';
import 'package:helawork/client/models/client_proposal.dart';
import 'package:helawork/client/provider/client_proposal_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // ADD THIS IMPORT

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

            // Freelancer info (clickable)
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

            // Service Type Indicator
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

  // UPDATED: Complete _showAcceptConfirmation function
  void _showAcceptConfirmation(BuildContext context, ClientProposal proposal) {
    final isOnSite = proposal.taskServiceType == 'on_site';
    
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
              'Accept proposal from ${proposal.freelancerName}?',
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
                        'Ksh ${proposal.bidAmount.toStringAsFixed(2)}',
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
                  Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
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
              
              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final provider = context.read<ClientProposalProvider>();
                final success = await provider.acceptProposal(proposal.id);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                }
                
                if (success && context.mounted) {
                  // Check if payment URL is returned
                  final response = provider.lastResponse;
                  
                  if (response != null && 
                      response.containsKey('requires_payment') &&
                      response['requires_payment'] == true &&
                      response['checkout_url'] != null) {
                    
                    // Get payment details
                    final checkoutUrl = response['checkout_url'] as String;
                    final orderId = response['order_id'] ?? 'N/A';
                    final taskTitle = proposal.taskTitle;
                    
                    // Show payment redirect message
                    if (context.mounted) {
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
                      
                      // Note: After payment, user will be redirected back to your app
                      // You should handle this in your main.dart or navigation handler
                      // For now, show a success screen
                      if (context.mounted) {
                        // Navigate to payment success screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentSuccessScreen(
                              paymentData: {
                                'order_id': orderId,
                                'amount': proposal.bidAmount.toStringAsFixed(2),
                                'task_title': taskTitle,
                                'service_type': proposal.taskServiceType,
                                'freelancer_name': proposal.freelancerName,
                                'is_on_site': isOnSite,
                              }, orderId: '',
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Proposal accepted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      provider.loadProposals();
                    }
                  }
                } else if (context.mounted) {
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProposalViewScreen(proposal: proposal),
      ),
    );
  }

  void _viewFreelancerProfile(BuildContext context, String freelancerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FreelancerProfileScreen(freelancerId: freelancerId),
      ),
    );
  }
}