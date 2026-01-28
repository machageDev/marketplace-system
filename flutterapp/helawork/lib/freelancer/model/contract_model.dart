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
  
  // NEW: Holds the rating details from the employer
  final Map<String, dynamic>? employerRating;

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
    this.employerRating,
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
      // CAPTURE THE RATING OBJECT FROM DJANGO
      employerRating: json['employer_rating'],
    );
  }

  // --- LOGIC GATES ---

  bool get isOnSite {
    final type = (task['service_type'] ?? '').toString().toLowerCase();
    return type.contains('on_site') || type.contains('onsite');
  }

  bool get isRemote => !isOnSite;

  // IMPROVED: Check both the boolean and the string status
  bool get isFinished => isCompleted || status == 'completed';
  
  bool get canAccept => isPaid && !freelancerAccepted && !isFinished;

  bool get isAccepted => freelancerAccepted;

  bool get isAwaitingPayment => isAccepted && !isPaid;

  // OTP is needed if it's on-site, paid, but the handshake hasn't happened yet
  bool get needsOtpVerification => isOnSite && isAccepted && isPaid && !isFinished;

  bool get needsWorkSubmission => isRemote && isAccepted && isPaid && !isFinished;

  // Matches your Django verification logic
  bool get isPaidAndCompleted => isPaid && isFinished;

  bool get shouldShowInList {
    if (status == 'rejected' || status == 'cancelled') return false;
    return true;
  }

  // --- RATING HELPERS ---

  bool get hasRatingFromEmployer => employerRating != null;

  double get ratingScore => (employerRating?['score'] ?? 0).toDouble();

  String get ratingReview => employerRating?['review'] ?? '';

  // This accesses the 'details' field created by your RatingSerializer.get_details
  Map<String, dynamic> get ratingDetails => employerRating?['details'] ?? {};

  int get punctualityScore => ratingDetails['punctuality'] ?? 0;
  
  int get qualityScore => ratingDetails['technical_quality'] ?? ratingDetails['quality'] ?? 0;

  // --- UI FORMATTING ---

  String get taskTitle => task['title']?.toString() ?? 'Untitled Task';
  
  int get taskId => task['id'] ?? task['task_id'] ?? 0;
  
  int get employerId => employer['id'] ?? 0;

  String get employerName {
    return employer['name'] ?? employer['username'] ?? employer['company_name'] ?? 'Client';
  }
  
  double get budget {
    final val = task['budget'] ?? task['amount'] ?? 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String get displayStatus {
    if (isFinished) return 'COMPLETED';
    if (needsOtpVerification) return 'ACTION REQUIRED: ENTER OTP';
    if (canAccept) return 'ACTION REQUIRED: ACCEPT OFFER';
    if (needsWorkSubmission) return 'WORK IN PROGRESS';
    if (isAwaitingPayment) return 'WAITING FOR ESCROW';
    
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