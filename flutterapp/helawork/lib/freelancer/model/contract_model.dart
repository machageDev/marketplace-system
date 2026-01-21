
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
  final bool? isPaid;
  final bool? isCompleted;

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
    this.isPaid,
    this.isCompleted,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      contractId: json['contract_id'] ?? 0,
      task: json['task'] is Map ? Map<String, dynamic>.from(json['task']) : {},
      employer: json['employer'] is Map ? Map<String, dynamic>.from(json['employer']) : {},
      startDate: json['start_date']?.toString() ?? DateTime.now().toString(),
      endDate: json['end_date']?.toString(),
      employerAccepted: (json['employer_accepted'] ?? false) == true,
      freelancerAccepted: (json['freelancer_accepted'] ?? false) == true,
      isActive: (json['is_active'] ?? false) == true,
      isFullyAccepted: (json['is_fully_accepted'] ?? false) == true,
      status: (json['status']?.toString() ?? 'pending').toLowerCase().trim(),
      isPaid: (json['is_paid'] ?? json['task']?['is_paid'] ?? false) == true,
      isCompleted: (json['is_completed'] ?? json['task']?['is_completed'] ?? false) == true,
    );
  }

  // --- GETTERS FOR LOGIC ---

  /// Checks if the task is an On-Site service
  bool get isOnSite {
    try {
      final type = task['service_type']?.toString().toLowerCase() ?? 
                  task['serviceType']?.toString().toLowerCase();
      return type == 'on_site' || type == 'onsite' || type == 'on-site';
    } catch (e) {
      return false;
    }
  }

  bool get isRemote => !isOnSite;

  /// Check if contract is fully paid and completed
  bool get isPaidAndCompleted => (isPaid == true) && (isCompleted == true);

  /// Check if freelancer can accept this contract (employer accepted but freelancer hasn't)
  bool get canAccept => employerAccepted && !freelancerAccepted;

  /// Check if contract is accepted by both parties
  bool get isAccepted => isFullyAccepted;

  /// Check if needs OTP verification (for on-site jobs)
  bool get needsOtpVerification {
    // Check if status indicates OTP is needed
    if (status.contains('awaiting') && status.contains('otp')) return true;
    if (status.contains('pending_verification')) return true;
    
    // For on-site jobs that are accepted and paid but not completed
    if (isOnSite && isAccepted && (isPaid == true) && (isCompleted == false)) {
      return true;
    }
    
    return false;
  }

  /// Check if needs work submission (for remote jobs)
  bool get needsWorkSubmission {
    // For remote jobs that are accepted, paid, but not completed
    if (isRemote && isAccepted && (isPaid == true) && (isCompleted == false)) {
      return true;
    }
    return false;
  }

  /// Check if awaiting payment
  bool get isAwaitingPayment {
    // Accepted but not paid yet
    return isAccepted && (isPaid == false);
  }

  /// Check if contract should be shown in the list
  bool get shouldShowInList {
    // ALWAYS SHOW contracts that need freelancer action
    if (canAccept) return true;
    if (needsOtpVerification) return true;
    if (needsWorkSubmission) return true;
    if (isAwaitingPayment) return true;
    
    // For completed contracts, show only if recent (within last 7 days)
    if (isPaidAndCompleted) {
      try {
        final completedDate = endDate != null ? DateTime.parse(endDate!) : null;
        if (completedDate != null) {
          final daysSinceCompletion = DateTime.now().difference(completedDate).inDays;
          return daysSinceCompletion <= 7;
        }
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }

  // --- UI GETTERS ---

  String get taskTitle => task['title']?.toString() ?? 'Untitled Task';

  String get employerName {
    if (employer['company_name']?.toString().isNotEmpty == true) {
      return employer['company_name'].toString();
    }
    if (employer['name']?.toString().isNotEmpty == true) {
      return employer['name'].toString();
    }
    return 'Client';
  }

  String get formattedStartDate {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(startDate));
    } catch (e) {
      return startDate;
    }
  }

  String? get formattedEndDate {
    if (endDate == null) return null;
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(endDate!));
    } catch (e) {
      return endDate;
    }
  }

  double? get budget {
    try {
      final val = task['budget'] ?? task['amount'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    } catch (e) {
      return null;
    }
  }

  String get displayStatus {
    if (isPaidAndCompleted) return 'Completed & Paid';
    if (needsOtpVerification) return 'Awaiting OTP';
    if (canAccept) return 'Pending Acceptance';
    if (needsWorkSubmission) return 'Submit Work';
    if (isAwaitingPayment) return 'Awaiting Payment';
    if (isAccepted) return 'In Progress';
    return status;
  }
}