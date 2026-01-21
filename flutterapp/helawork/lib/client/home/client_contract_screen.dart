import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helawork/client/home/client_payment_screen.dart';
import 'package:helawork/client/models/client_contract_model.dart';
import 'package:helawork/client/provider/client_contract_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientContractsScreen extends StatefulWidget {
  const ClientContractsScreen({super.key});

  @override
  State<ClientContractsScreen> createState() => _ClientContractsScreenState();
}

class _ClientContractsScreenState extends State<ClientContractsScreen> {
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _secondaryBlue = const Color(0xFF2196F3);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _whiteColor = Colors.white;
  final Color _greenBlue = const Color(0xFF4CAF50);
  final Color _warningBlue = const Color(0xFFFF9800);
  final Color _errorBlue = const Color(0xFFF44336);

  String? token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("user_token");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientContractProvider>(context, listen: false)
          .fetchEmployerContracts();
    });
  }

  String _getStatusText(ContractModel contract) {
    // DEBUG
    print('🔄 _getStatusText called for contract ${contract.contractId}');
    print('   Backend status: "${contract.status}"');
    print('   isPaid: ${contract.isPaid}, isCompleted: ${contract.isCompleted}');
    
    // Clean the backend status
    String backendStatus = contract.status.trim();
    
    // FIRST PRIORITY: Show backend status if it's specific
    if (backendStatus.isNotEmpty && 
        backendStatus != 'Unknown' && 
        backendStatus != 'unknown' &&
        backendStatus != 'pending' &&
        backendStatus != 'Pending') {
      
      // These are the statuses that should override our calculations
      if (backendStatus == 'Accepted & Paid' || 
          backendStatus == 'Accepted and Paid' ||
          backendStatus == 'Work in Progress' ||
          backendStatus == 'Work In Progress' ||
          backendStatus == 'Completed & Paid' ||
          backendStatus == 'Completed and Paid' ||
          backendStatus == 'Awaiting OTP Verification' ||
          backendStatus == 'Awaiting Payment' ||
          backendStatus.toLowerCase() == 'rejected' ||
          backendStatus.toLowerCase() == 'cancelled') {
        
        // Special handling for "Accepted & Paid" status
        if (backendStatus == 'Accepted & Paid' || backendStatus == 'Accepted and Paid') {
          return contract.isOnSite ? "Awaiting OTP" : "In Escrow";
        }
        
        print('✅ Using backend status: $backendStatus');
        return backendStatus;
      }
    }
    
    // SECOND: Fallback to calculated status (only if backend status is generic)
    print('📝 Using calculated status');
    if (contract.isPaid && contract.isCompleted) {
      return "Paid & Completed";
    }
    
    if (contract.isPaid && !contract.isCompleted) {
      return contract.isOnSite ? "Awaiting OTP" : "In Escrow";
    }
    
    if (!contract.isPaid) {
      if (!contract.freelancerAccepted) {
        return "Awaiting Freelancer";
      }
      return "Awaiting Payment";
    }
    
    return backendStatus; // Last resort
  }

  Color _getStatusColor(ContractModel contract) {
    String status = contract.status.toLowerCase().trim();
    
    // Handle backend status colors
    if (status.contains('accepted & paid') || status.contains('accepted and paid')) {
      return contract.isOnSite ? _warningBlue : _secondaryBlue;
    }
    
    if (status.contains('work in progress') || status.contains('work_in_progress')) {
      return _greenBlue; // Green for active work
    }
    
    if (status.contains('awaiting otp verification')) {
      return _warningBlue; // Orange for waiting
    }
    
    if (status.contains('completed & paid') || status.contains('completed and paid')) {
      return _greenBlue; // Green for complete
    }
    
    if (status.contains('rejected') || status.contains('cancelled')) {
      return _errorBlue; // Red for rejected/cancelled
    }
    
    // Fallback to calculated status colors
    if (contract.isPaid && contract.isCompleted) return _greenBlue;
    
    if (contract.isPaid && !contract.isCompleted) {
      return contract.isOnSite ? _warningBlue : _secondaryBlue;
    }
    
    if (!contract.isPaid) {
      if (!contract.freelancerAccepted) return _warningBlue;
      return _errorBlue;
    }
    
    return _primaryBlue;
  }

  String _getActionButtonText(ContractModel contract) {
    String status = contract.status.toLowerCase().trim();
    
    // Handle backend status actions
    if (status.contains('accepted & paid') || status.contains('accepted and paid')) {
      return contract.isOnSite
          ? "Show Verification Code"
          : "Release Payment";
    }
    
    if (status.contains('awaiting otp verification')) {
      return "Show Verification Code";
    }
    
    if (status.contains('work in progress') || status.contains('work_in_progress')) {
      return "View Details";
    }
    
    // Fallback to calculated actions
    if (contract.isPaid && contract.isCompleted) {
      return "View Details";
    }
    
    if (contract.isPaid && !contract.isCompleted) {
      return contract.isOnSite
          ? "Show Verification Code"
          : "Release Payment";
    }
    
    if (!contract.isPaid) {
      if (status.contains('rejected') || status.contains('cancelled')) {
        return contract.isPaid ? "Request Refund" : "Find New";
      }
      
      if (contract.freelancerAccepted) {
        return "Pay into Escrow";
      }
    }
    
    return "View Details";
  }

  // ======================================================
  // DIALOGS (Keep your existing dialog code)
  // ======================================================
  void _showOTPDialog(BuildContext context, ContractModel contract) {
    // Keep your existing _showOTPDialog code exactly as is
    final code = contract.verificationOrCompletionCode;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _whiteColor,
        surfaceTintColor: _whiteColor,
        title: Text(
          "On-Site Verification Code",
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Share this code with the worker ONLY when the job is complete.",
              style: TextStyle(fontSize: 14, color: _darkBlue.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primaryBlue, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Verification Code",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    code ?? "Not Generated",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Show this to the worker at the job site",
                    style: TextStyle(fontSize: 12, color: _darkBlue.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (code == null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: _whiteColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  _generateVerificationCode(context, contract.contractId);
                },
                child: const Text(
                  "GENERATE VERIFICATION CODE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (code != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenBlue,
                  foregroundColor: _whiteColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showConfirmCompletionDialog(context, contract);
                },
                child: const Text(
                  "MARK AS COMPLETED",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _primaryBlue,
            ),
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showConfirmCompletionDialog(BuildContext context, ContractModel contract) {
    // Keep your existing _showConfirmCompletionDialog code
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _whiteColor,
        surfaceTintColor: _whiteColor,
        title: Text(
          "Confirm Completion",
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure the work for \"${contract.taskTitle}\" is complete?\n\n"
          "This will release KES ${contract.amount} to ${contract.freelancerName}.",
          style: TextStyle(color: _darkBlue),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _darkBlue.withOpacity(0.6),
            ),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBlue,
              foregroundColor: _whiteColor,
            ),
            child: const Text("Confirm & Release"),
            onPressed: () async {
              Navigator.pop(context);
              await _releasePayment(context, contract.contractId);
            },
          )
        ],
      ),
    );
  }

  void _showReleaseConfirmation(BuildContext context, ContractModel contract) {
    // Keep your existing _showReleaseConfirmation code
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _whiteColor,
        surfaceTintColor: _whiteColor,
        title: Text(
          "Release Payment",
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Release KES ${contract.amount} for \"${contract.taskTitle}\"?\n\n"
          "This will transfer funds to ${contract.freelancerName}.\n\n"
          "⚠️ This action cannot be undone.",
          style: TextStyle(color: _darkBlue),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _darkBlue.withOpacity(0.6),
            ),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBlue,
              foregroundColor: _whiteColor,
            ),
            child: const Text("Release Funds"),
            onPressed: () async {
              Navigator.pop(context);
              await _releasePayment(context, contract.contractId);
            },
          )
        ],
      ),
    );
  }

  void _showRefundRequestDialog(BuildContext context, ContractModel contract) {
    // Keep your existing _showRefundRequestDialog code
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _whiteColor,
        surfaceTintColor: _whiteColor,
        title: Text(
          "Request Refund",
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "The freelancer rejected this task. Would you like to pull your funds back from Escrow into your HelaWork Wallet?",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _darkBlue.withOpacity(0.6),
            ),
            onPressed: () => Navigator.pop(context), 
            child: const Text("Not Now"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBlue,
              foregroundColor: _whiteColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _requestRefund(context, contract.contractId);
            },
            child: const Text(
              "Confirm Refund",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ACTIONS (Keep your existing action code)
  // ======================================================
  Future<void> _releasePayment(BuildContext context, int contractId) async {
    try {
      final provider = Provider.of<ClientContractProvider>(context, listen: false);
      final result = await provider.releasePayment(contractId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["success"] == true 
              ? "✅ ${result["message"]}" 
              : "❌ ${result["message"]}"),
          backgroundColor: result["success"] == true ? _greenBlue : _errorBlue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: _errorBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _generateVerificationCode(BuildContext context, int contractId) async {
    try {
      final provider = Provider.of<ClientContractProvider>(context, listen: false);
      final result = await provider.generateVerificationCode(contractId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["success"] == true 
              ? "✅ Verification code generated" 
              : "❌ ${result["message"]}"),
          backgroundColor: result["success"] == true ? _greenBlue : _errorBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      if (result["success"] == true) {
        final contract = provider.getContractById(contractId);
        if (contract != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOTPDialog(context, contract);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: _errorBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _requestRefund(BuildContext context, int contractId) async {
    try {
      final provider = Provider.of<ClientContractProvider>(context, listen: false);
      final result = await provider.requestRefund(contractId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["success"] == true 
              ? "✅ Refund request submitted" 
              : "❌ ${result["message"]}"),
          backgroundColor: result["success"] == true ? _greenBlue : _errorBlue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: _errorBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // ======================================================
  // PAYMENT NAVIGATION (Keep your existing code)
  // ======================================================
  Future<void> _navigateToPaymentScreen(BuildContext context, ContractModel contract) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email") ?? "";

    if (email.isEmpty) {
      _promptEmailEntry(context);
      return;
    }

    if (!contract.hasValidOrderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("❌ Payment setup in progress. Please wait a moment and try again."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      await Provider.of<ClientContractProvider>(context, listen: false)
          .fetchEmployerContracts();
      return;
    }

    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(contract.orderId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Invalid payment ID. Please contact support. ID: ${contract.orderId}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("💰 INITIALIZING PAYMENT");
    print("   Order: ${contract.orderId}");
    print("   Amount: ${contract.amount}");
    print("   Email: $email");
    print("   Freelancer: ${contract.freelancerName}");
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          orderId: contract.orderId!,
          amount: contract.amount,
          email: email,
          freelancerName: contract.freelancerName,
          serviceDescription: contract.taskTitle,
          freelancerPhotoUrl: contract.freelancerPhoto,
          currency: "KES",
          freelancerId: contract.freelancerId.toString(),
          contractId: contract.contractId.toString(),
          taskTitle: contract.taskTitle,
          isValidOrderId: true,
          employerName: contract.employerName,
          taskId: contract.taskId.toString(),
        ),
      ),
    );
  }

  Future<void> _promptEmailEntry(BuildContext context) async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _whiteColor,
        surfaceTintColor: _whiteColor,
        title: Text(
          "Enter Email",
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter your email for payment receipts",
            border: OutlineInputBorder(
              borderSide: BorderSide(color: _primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _primaryBlue, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _darkBlue.withOpacity(0.6),
            ),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: _whiteColor,
            ),
            child: const Text("Save"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString("user_email", controller.text.trim());
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  // ======================================================
  // CONTRACT CARD WIDGET (Updated with debug info)
  // ======================================================
  Widget _buildContractCard(ContractModel contract) {
    // Debug info in the card (temporary)
    final statusText = _getStatusText(contract);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _lightBlue, width: 1),
      ),
      color: _whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Text(
              contract.taskTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkBlue,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Freelancer Info
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: _primaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    contract.freelancerName,
                    style: TextStyle(fontSize: 14, color: _darkBlue.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Amount
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: _primaryBlue),
                const SizedBox(width: 6),
                Text(
                  "KES ${contract.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
                const Spacer(),
                // Service Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: contract.isOnSite ? _warningBlue.withOpacity(0.1) : _lightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: contract.isOnSite ? _warningBlue : _primaryBlue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        contract.isOnSite ? Icons.location_on : Icons.computer,
                        size: 12,
                        color: contract.isOnSite ? _warningBlue : _primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contract.isOnSite ? "On-Site" : "Remote",
                        style: TextStyle(
                          fontSize: 11,
                          color: contract.isOnSite ? _warningBlue : _primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // DEBUG: Show raw backend status (temporary)
            if (kDebugMode)
              Text(
                "API: ${contract.status}",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(contract),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(contract),
                    size: 14,
                    color: _whiteColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: _whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionButtonColor(contract),
                  foregroundColor: _whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
                onPressed: () => _handleContractAction(context, contract),
                child: Text(
                  _getActionButtonText(contract),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ContractModel contract) {
    String status = contract.status.toLowerCase();
    
    if (status.contains('accepted & paid') || status.contains('accepted and paid')) {
      return contract.isOnSite ? Icons.verified_user : Icons.lock_clock;
    }
    
    if (status.contains('work in progress') || status.contains('work_in_progress')) {
      return Icons.build;
    }
    
    if (status.contains('awaiting otp verification')) {
      return Icons.verified_user;
    }
    
    if (contract.isPaid && contract.isCompleted) return Icons.check_circle;
    if (contract.isPaid && !contract.isCompleted) {
      return contract.isOnSite ? Icons.verified_user : Icons.lock_clock;
    }
    if (!contract.isPaid) return Icons.payment;
    return Icons.info;
  }

  Color _getActionButtonColor(ContractModel contract) {
    String status = contract.status.toLowerCase();
    
    if (status.contains('accepted & paid') || status.contains('accepted and paid')) {
      return _secondaryBlue;
    }
    
    if (contract.isPaid && contract.isCompleted) return _darkBlue;
    if (!contract.isPaid) return _primaryBlue;
    if (contract.isPaid && !contract.isCompleted) return _secondaryBlue;
    return _darkBlue;
  }

  void _handleContractAction(BuildContext context, ContractModel contract) {
    String status = contract.status.toLowerCase();
    
    // Handle backend status "Accepted & Paid" first
    if (status.contains('accepted & paid') || status.contains('accepted and paid')) {
      if (contract.isOnSite) {
        _showOTPDialog(context, contract);
      } else {
        _showReleaseConfirmation(context, contract);
      }
      return;
    }
    
    // Handle "Awaiting OTP Verification"
    if (status.contains('awaiting otp verification')) {
      _showOTPDialog(context, contract);
      return;
    }
    
    // Your existing logic for other cases
    if (contract.isPaid && contract.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Contract is already completed"),
          backgroundColor: _greenBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    
    if (contract.isPaid && !contract.isCompleted) {
      if (contract.isOnSite) {
        _showOTPDialog(context, contract);
      } else {
        _showReleaseConfirmation(context, contract);
      }
      return;
    }
    
    if (!contract.isPaid) {
      if (status.contains('rejected') || status.contains('cancelled')) {
        if (contract.isPaid) {
          _showRefundRequestDialog(context, contract);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Freelancer rejected this contract"),
              backgroundColor: _warningBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return;
      }
      
      if (contract.freelancerAccepted) {
        _navigateToPaymentScreen(context, contract);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Waiting for freelancer to accept"),
            backgroundColor: _warningBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }
  }

  // ======================================================
  // BUILD METHOD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientContractProvider>(context);
    
    return Scaffold(
      backgroundColor: _whiteColor,
      appBar: AppBar(
        title: const Text(
          "My Contracts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<ClientContractProvider>(context, listen: false)
                  .fetchEmployerContracts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primaryBlue,
        backgroundColor: _whiteColor,
        onRefresh: () async {
          await Provider.of<ClientContractProvider>(context, listen: false)
              .fetchEmployerContracts();
        },
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ClientContractProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryBlue),
            const SizedBox(height: 16),
            Text(
              "Loading your contracts...",
              style: TextStyle(color: _darkBlue, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    if (provider.contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: _lightBlue),
            const SizedBox(height: 16),
            Text(
              "No active contracts yet",
              style: TextStyle(
                fontSize: 18,
                color: _darkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Create a task or accept a proposal to get started",
                style: TextStyle(color: _darkBlue.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: _whiteColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // TODO: Navigate to create task screen
              },
              child: const Text("Create New Task"),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.contracts.length,
      itemBuilder: (_, index) => _buildContractCard(provider.contracts[index]),
    );
  }
}