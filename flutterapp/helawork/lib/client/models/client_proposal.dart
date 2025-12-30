// clients/models/client_proposal.dart
class ClientProposal {
  final String id;
  final String proposalId;
  final String taskId;
  final String taskTitle;
  final String taskDescription;
  final double budget;
  final double bidAmount;
  final String coverLetter;
  final String status;
  final String freelancerId;
  final String freelancerName;
  final String freelancerEmail;
  final int estimatedDays;
  final DateTime submittedAt;
  final String? coverLetterFileUrl;

  ClientProposal({
    required this.id,
    required this.proposalId,
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
    required this.budget,
    required this.bidAmount,
    required this.coverLetter,
    required this.status,
    required this.freelancerId,
    required this.freelancerName,
    required this.freelancerEmail,
    required this.estimatedDays,
    required this.submittedAt,
    this.coverLetterFileUrl,
  });

factory ClientProposal.fromJson(Map<String, dynamic> json) {
  return ClientProposal(
    id: json['id']?.toString() ?? json['proposal_id']?.toString() ?? '',
    proposalId: json['proposal_id']?.toString() ?? json['id']?.toString() ?? '',
    taskId: json['task_id']?.toString() ?? json['task']?['task_id']?.toString() ?? '',
    taskTitle: json['task_title'] ?? json['task']?['title'] ?? 'Unknown Task',
    taskDescription: json['task_description'] ?? json['task']?['description'] ?? '',
    
    // FIXED: Parse budget safely
    budget: _parseDouble(json['budget'] ?? json['task']?['budget']),
    
    // FIXED: Parse bidAmount safely
    bidAmount: _parseDouble(json['bid_amount']),
    
    coverLetter: json['cover_letter'] ?? '',
    status: json['status']?.toString().toLowerCase() ?? 'pending',
    freelancerId: json['freelancer_id']?.toString() ?? json['freelancer']?['id']?.toString() ?? '',
    freelancerName: json['freelancer_name'] ?? json['freelancer']?['name'] ?? 'Unknown',
    freelancerEmail: json['freelancer_email'] ?? json['freelancer']?['email'] ?? '',
    
    // FIXED: Parse estimatedDays safely
    estimatedDays: _parseInt(json['estimated_days']),
    
    submittedAt: json['submitted_at'] != null 
        ? DateTime.parse(json['submitted_at']) 
        : DateTime.now(),
    coverLetterFileUrl: json['cover_letter_file_url'],
  );
}

// Helper method to parse double safely
static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

// Helper method to parse int safely
static int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

  ClientProposal copyWith({
    String? status,
    String? coverLetter,
    double? bidAmount,
  }) {
    return ClientProposal(
      id: id,
      proposalId: proposalId,
      taskId: taskId,
      taskTitle: taskTitle,
      taskDescription: taskDescription,
      budget: budget,
      bidAmount: bidAmount ?? this.bidAmount,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      freelancerId: freelancerId,
      freelancerName: freelancerName,
      freelancerEmail: freelancerEmail,
      estimatedDays: estimatedDays,
      submittedAt: submittedAt,
      coverLetterFileUrl: coverLetterFileUrl,
    );
  }
}