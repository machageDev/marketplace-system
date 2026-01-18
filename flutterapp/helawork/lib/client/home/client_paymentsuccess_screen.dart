import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_proposal_screen.dart';
import 'package:helawork/client/home/client_task_scren.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  
  const PaymentSuccessScreen({super.key, required this.paymentData, required String orderId});
  
  @override
  Widget build(BuildContext context) {
    final orderId = paymentData['order_id'] ?? 'N/A';
    final amount = paymentData['amount'] ?? '0';
    final taskTitle = paymentData['task_title'] ?? 'Task';
    final freelancerName = paymentData['freelancer_name'] ?? 'Freelancer';
    final isOnSite = paymentData['is_on_site'] == true;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              
              // Message
              Text(
                'Ksh $amount secured in escrow',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Order ID: $orderId',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Task Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Freelancer: $freelancerName',
                      style: const TextStyle(color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    
                    // On-site specific instructions
                    if (isOnSite)
                      Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'On-site Task',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📱 You will receive an OTP via notification',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '🔐 Give this OTP to the freelancer when work is completed',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '✅ Freelancer will enter OTP to receive payment',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    
                    // Remote task instructions
                    if (!isOnSite)
                      const Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.laptop, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Remote Task',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Freelancer can now start working. You will review and approve deliverables.',
                            style: TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientProposalsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('Back to Proposals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TasksScreen(), // Your tasks screen
                          ),
                        );
                      },
                      icon: const Icon(Icons.task),
                      label: const Text('View My Tasks'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}