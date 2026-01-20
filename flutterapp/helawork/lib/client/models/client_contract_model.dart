class ContractModel {
  final int contractId;
  final String? orderId; // UUID for payments
  final String? orderStatus; // Order status
  final String taskTitle;
  final String taskDescription;
  final String taskCategory;
  final String freelancerName;
  final String freelancerEmail;
  final double amount;
  final String serviceType; // 'remote' or 'on_site'
  final bool isPaid;
  final bool isCompleted;
  final bool isActive;
  final bool employerAccepted;
  final bool freelancerAccepted;
  final String status; // Display status
  final String? startDate;
  final String? endDate;
  final String? paymentDate;
  final String? completedDate;
  final String? verificationCode;
  final String? locationAddress;
  final String? deadline;
  
  // ADD THESE MISSING PROPERTIES:
  final String freelancerPhoto;
  final int freelancerId;
  final String employerName;
  final int taskId;
  final String? completionCode;

  ContractModel({
    required this.contractId,
    this.orderId,
    this.orderStatus,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskCategory,
    required this.freelancerName,
    required this.freelancerEmail,
    required this.amount,
    required this.serviceType,
    required this.isPaid,
    required this.isCompleted,
    required this.isActive,
    required this.employerAccepted,
    required this.freelancerAccepted,
    required this.status,
    this.startDate,
    this.endDate,
    this.paymentDate,
    this.completedDate,
    this.verificationCode,
    this.locationAddress,
    this.deadline,
    
    // ADD THESE TO THE CONSTRUCTOR:
    this.freelancerPhoto = '',
    this.freelancerId = 0,
    this.employerName = '',
    this.taskId = 0,
    this.completionCode,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contract_id'] as int? ?? 0,
      orderId: json['order_id'] as String?,
      orderStatus: json['order_status'] as String?,
      taskTitle: json['task_title'] as String? ?? 'Unknown Task',
      taskDescription: json['task_description'] as String? ?? '',
      taskCategory: json['task_category'] as String? ?? 'other',
      freelancerName: json['freelancer_name'] as String? ?? 'Unknown',
      freelancerEmail: json['freelancer_email'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      serviceType: json['service_type'] as String? ?? 'remote',
      isPaid: (json['is_paid'] as bool?) ?? false,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? false,
      employerAccepted: (json['employer_accepted'] as bool?) ?? false,
      freelancerAccepted: (json['freelancer_accepted'] as bool?) ?? false,
      status: json['status'] as String? ?? 'Unknown',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      paymentDate: json['payment_date'] as String?,
      completedDate: json['completed_date'] as String?,
      verificationCode: json['verification_code'] as String?,
      locationAddress: json['location_address'] as String?,
      deadline: json['deadline'] as String?,
      
      // ADD THESE MAPPINGS:
      freelancerPhoto: json['freelancer_photo'] as String? ?? '',
      freelancerId: json['freelancer_id'] as int? ?? 0,
      employerName: json['employer_name'] as String? ?? '',
      taskId: json['task_id'] as int? ?? 0,
      completionCode: json['completion_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contract_id': contractId,
      'order_id': orderId,
      'order_status': orderStatus,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'task_category': taskCategory,
      'freelancer_name': freelancerName,
      'freelancer_email': freelancerEmail,
      'amount': amount,
      'service_type': serviceType,
      'is_paid': isPaid,
      'is_completed': isCompleted,
      'is_active': isActive,
      'employer_accepted': employerAccepted,
      'freelancer_accepted': freelancerAccepted,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'payment_date': paymentDate,
      'completed_date': completedDate,
      'verification_code': verificationCode,
      'location_address': locationAddress,
      'deadline': deadline,
      // ADD THESE TO JSON:
      'freelancer_photo': freelancerPhoto,
      'freelancer_id': freelancerId,
      'employer_name': employerName,
      'task_id': taskId,
      'completion_code': completionCode,
    };
  }

  // Helper methods
  bool get isOnSite => serviceType == 'on_site';
  bool get isRemote => serviceType == 'remote';
  bool get isFullyAccepted => employerAccepted && freelancerAccepted;
  bool get requiresPayment => !isPaid;
  bool get canBeCompleted => isPaid && !isCompleted;
  bool get isAwaitingPayment => !isPaid;
  bool get isInProgress => isPaid && !isCompleted;
  bool get isFinished => isPaid && isCompleted;
  bool get hasVerificationCode => verificationCode != null && verificationCode!.isNotEmpty;
  bool get hasValidOrderId => orderId != null && orderId!.isNotEmpty && orderId!.contains('-'); // UUID check
  
  // ADD THIS HELPER GETTER:
  String? get verificationOrCompletionCode => verificationCode ?? completionCode;
}