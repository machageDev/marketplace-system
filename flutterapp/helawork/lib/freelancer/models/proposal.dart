class Proposal {
  final int? proposalId;
  final int taskId;
  final int? freelancerId; // Will be set by backend
  final double bidAmount;
  final String status;
  final String? coverLetter; // ✅ ADD THIS
  final int? estimatedDays; 
  final DateTime? submittedAt;
  final String? title; 
  
  Proposal({
    this.proposalId,
    required this.taskId,
    this.freelancerId,
    required this.bidAmount,
    this.status = 'pending',
    this.coverLetter, 
    this.estimatedDays = 7, 
    this.submittedAt,
    this.title,
  });
  
  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      proposalId: json['id'] ?? json['proposal_id'],
      taskId: json['task_id'] ?? json['task']?['task_id'],
      freelancerId: json['freelancer_id'] ?? json['freelancer']?['user_id'],
      bidAmount: (json['bid_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      coverLetter: json['cover_letter'], 
      estimatedDays: json['estimated_days'] ?? 7, 
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : DateTime.now(),
      title: json['task_title'] ?? json['task']?['title'],
    );
  }
}