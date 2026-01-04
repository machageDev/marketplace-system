// client_contracts_screen.dart
import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_contract_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClientContractsScreen extends StatefulWidget {
  const ClientContractsScreen({super.key});

  @override
  State<ClientContractsScreen> createState() => _ClientContractsScreenState();
}

class _ClientContractsScreenState extends State<ClientContractsScreen> {
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _backgroundColor = const Color(0xFFF8FAFD);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _subtitleColor = const Color(0xFF666666);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientContractProvider>(context, listen: false)
          .fetchEmployerContracts();
    });
  }

  void _showCompletionDialog(BuildContext context, int contractId, String taskTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text(
          'Are you sure you want to mark "$taskTitle" as completed?\n\n'
          'Once completed, the freelancer will be able to rate your work.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _completeContract(context, contractId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeContract(BuildContext context, int contractId) async {
    final provider = Provider.of<ClientContractProvider>(context, listen: false);
    
    try {
      await provider.markContractCompleted(contractId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contract marked as completed!'),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Contracts'),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ClientContractProvider>(context, listen: false)
                  .fetchEmployerContracts();
            },
          )
        ],
      ),
      body: Consumer<ClientContractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.contracts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty && provider.contracts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.fetchEmployerContracts();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final contracts = provider.contracts;
          final stats = provider.getContractStats();

          return RefreshIndicator(
            onRefresh: () => provider.fetchEmployerContracts(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Cards
                  _buildStatsCards(stats),
                  const SizedBox(height: 20),
                  
                  // Contracts List
                  if (contracts.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contracts.length,
                      itemBuilder: (context, index) {
                        return _buildContractCard(context, contracts[index], provider);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total', stats['total'] ?? 0, Icons.assignment, _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Ready', stats['ready'] ?? 0, Icons.check_circle, _successColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Pending', stats['pending'] ?? 0, Icons.access_time, _warningColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, Map<String, dynamic> contract, ClientContractProvider provider) {
    final canComplete = contract['can_complete'] == true;
    final contractId = contract['contract_id'] ?? 0;
    final taskTitle = contract['task_title'] ?? 'Task';
    final freelancerName = contract['freelancer_name'] ?? 'Freelancer';
    final paidAmount = contract['paid_amount'];
    final paymentDate = contract['payment_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    taskTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: canComplete 
                      ? _successColor.withOpacity(0.1)
                      : _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    canComplete ? 'Ready' : 'Pending',
                    style: TextStyle(
                      color: canComplete ? _successColor : _warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Freelancer Info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: _subtitleColor),
                const SizedBox(width: 8),
                Text(
                  freelancerName,
                  style: TextStyle(color: _subtitleColor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Payment Info
            if (paidAmount != null)
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: _successColor),
                  const SizedBox(width: 8),
                  Text(
                    '\$$paidAmount',
                    style: TextStyle(
                      color: _successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (paymentDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: _subtitleColor),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d').format(DateTime.parse(paymentDate)),
                      style: TextStyle(color: _subtitleColor),
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 16),

            // Action Button
            if (canComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCompletionDialog(context, contractId, taskTitle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No contracts to complete',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contracts will appear here after freelancers complete work and payment is made',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtitleColor),
          ),
        ],
      ),
    );
  }
}