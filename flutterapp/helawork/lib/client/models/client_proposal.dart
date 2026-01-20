// client_proposal.dart

class ClientProposal {
  final String id;
  final String? orderId; // <--- ADDED: Captures the UUID string (e.g., 5ec282ed...)
  final String freelancerId;
  final String freelancerName;
  final String freelancerEmail;
  final String taskId;
  final String taskTitle;
  final double bidAmount;
  final int estimatedDays;
  final String coverLetter;
  final String status;
  final DateTime createdAt;
  final String? taskServiceType;
  final double? budget;
  final DateTime? submittedAt;

  ClientProposal({
    required this.id,
    this.orderId, // Included in constructor
    required this.freelancerId,
    required this.freelancerName,
    required this.freelancerEmail,
    required this.taskId,
    required this.taskTitle,
    required this.bidAmount,
    required this.estimatedDays,
    required this.coverLetter,
    required this.status,
    required this.createdAt,
    this.taskServiceType,
    this.budget,
    this.submittedAt,
  });

  factory ClientProposal.fromJson(Map<String, dynamic> json) {
    return ClientProposal(
      id: json['proposal_id']?.toString() ?? json['id']?.toString() ?? '',
      // Captures the new 'order_id' UUID field from your updated Django Serializer
      orderId: json['order_id']?.toString(), 
      freelancerId: json['freelancer_id']?.toString() ?? '',
      freelancerName: json['freelancer_name']?.toString() ?? 'Unknown',
      freelancerEmail: json['freelancer_email']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      taskTitle: json['task_title']?.toString() ?? 'Untitled Task',
      bidAmount: _parseDouble(json['bid_amount']) ?? 0.0,
      estimatedDays: _parseInt(json['estimated_days']) ?? 0,
      coverLetter: json['cover_letter']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      taskServiceType: json['task_service_type']?.toString() ??
          json['service_type']?.toString() ??
          'remote',
      budget: _parseDouble(json['budget']),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at']!.toString())
          : null,
    );
  }

  // Helper method to parse dynamic values to double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  // Helper method to parse dynamic values to int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  ClientProposal copyWith({
    String? id,
    String? orderId,
    String? freelancerId,
    String? freelancerName,
    String? freelancerEmail,
    String? taskId,
    String? taskTitle,
    double? bidAmount,
    int? estimatedDays,
    String? coverLetter,
    String? status,
    DateTime? createdAt,
    String? taskServiceType,
    double? budget,
    DateTime? submittedAt,
  }) {
    return ClientProposal(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      freelancerId: freelancerId ?? this.freelancerId,
      freelancerName: freelancerName ?? this.freelancerName,
      freelancerEmail: freelancerEmail ?? this.freelancerEmail,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      bidAmount: bidAmount ?? this.bidAmount,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      taskServiceType: taskServiceType ?? this.taskServiceType,
      budget: budget ?? this.budget,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  // Helper getters
  String get formattedBidAmount => 'Ksh ${bidAmount.toStringAsFixed(2)}';

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isOnSite => taskServiceType == 'on_site';
  bool get isRemote => taskServiceType == 'remote' || taskServiceType == null;

  @override
  String toString() {
    return 'ClientProposal(id: $id, orderId: $orderId, freelancer: $freelancerName, task: $taskTitle, bid: $bidAmount, status: $status)';
  }
}