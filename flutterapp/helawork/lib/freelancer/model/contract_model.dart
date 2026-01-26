import 'package:intl/intl.dart';

class Contract {
  final int contractId;
  final Map<String, dynamic> task;
  final Map<String, dynamic> employer;
  final String startDate;
  final String? endDate;
  final bool employerAccepted;
  final bool freelancerAccepted;
  final bool isActive;
  final bool isFullyAccepted;
  final String status;
  final bool isPaid;      
  final bool isCompleted; 

  Contract({
    required this.contractId,
    required this.task,
    required this.employer,
    required this.startDate,
    this.endDate,
    required this.employerAccepted,
    required this.freelancerAccepted,
    required this.isActive,
    required this.isFullyAccepted,
    required this.status,
    required this.isPaid,
    required this.isCompleted,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> employerData = json['employer'] is Map 
        ? Map<String, dynamic>.from(json['employer']) 
        : {};
    
    Map<String, dynamic> taskData = json['task'] is Map 
        ? Map<String, dynamic>.from(json['task']) 
        : {};

    if (json.containsKey('client')) {
      employerData = {
        'id': json['client']?['id'] ?? 0,
        'name': json['client']?['name'] ?? 'Unknown Client',
      };
    }

    return Contract(
      contractId: json['contract_id'] ?? 0,
      task: taskData,
      employer: employerData,
      startDate: json['start_date']?.toString() ?? DateTime.now().toIso8601String(),
      endDate: json['end_date']?.toString(),
      employerAccepted: (json['employer_accepted'] ?? true) == true,
      freelancerAccepted: (json['freelancer_accepted'] ?? false) == true,
      isActive: (json['is_active'] ?? false) == true,
      isFullyAccepted: (json['is_fully_accepted'] ?? false) == true,
      status: (json['status']?.toString() ?? 'pending').toLowerCase().trim(),
      isPaid: (json['is_paid'] ?? taskData['is_paid'] ?? false) == true,
      isCompleted: (json['is_completed'] ?? false) == true,
    );
  }

  // --- LOGIC GATES ---

  bool get isOnSite {
    final type = (task['service_type'] ?? '').toString().toLowerCase();
    return type.contains('on_site') || type.contains('onsite');
  }
  
  bool get canAccept => isPaid && !freelancerAccepted && !isCompleted;

  bool get isAccepted => freelancerAccepted;

  bool get isAwaitingPayment => isAccepted && !isPaid;

  // REMOVED !isCompleted so Micah can still enter OTP after Client marks completed
  bool get needsOtpVerification => isOnSite && isAccepted && isPaid && status != 'paid';

  bool get needsWorkSubmission => !isOnSite && isAccepted && isPaid && !isCompleted;

  bool get isPaidAndCompleted => isPaid && isCompleted && status == 'paid';

  // FIXED: UI needs this getter
  bool get shouldShowInList {
    if (status == 'rejected' || status == 'cancelled') return false;
    return true;
  }

  // --- UI FORMATTING ---

  String get taskTitle => task['title']?.toString() ?? 'Untitled Task';
  
  String get employerName {
    return employer['name'] ?? employer['username'] ?? employer['company_name'] ?? 'Client';
  }
  
  // FIXED: Restored 'budget' getter for your UI
  double get budget {
    final val = task['budget'] ?? task['amount'] ?? 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String get displayStatus {
    // Prioritize OTP input so it doesn't disappear
    if (needsOtpVerification) return 'Action Required: Enter OTP';
    if (isPaidAndCompleted) return 'Completed & Paid';
    if (canAccept) return 'Action Required: Accept Offer';
    if (needsWorkSubmission) return 'Work in Progress';
    if (isAwaitingPayment) return 'Waiting for Escrow Deposit';
    
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String get formattedStartDate {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(startDate));
    } catch (e) {
      return startDate;
    }
  }
}