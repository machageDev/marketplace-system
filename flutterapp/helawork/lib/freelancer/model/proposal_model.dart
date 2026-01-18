// In proposal_model.dart - Add task_id field and ensure proper mapping
class Proposal {
  final int id;
  final int taskId;  // This maps to task_id from Django
  final int freelancerId;
  final String coverLetter;
  final double bidAmount;
  final int estimatedDays;
  final String status;
  final String? title;
  final DateTime? submittedAt;
  final String? pdfUrl;
  final String? pdfName;

  Proposal({
    required this.id,
    required this.taskId,
    required this.freelancerId,
    required this.coverLetter,
    required this.bidAmount,
    required this.estimatedDays,
    required this.status,
    this.title,
    this.submittedAt,
    this.pdfUrl,
    this.pdfName,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    // Handle both 'task_id' from Django and 'taskId' from Flutter
    final taskId = json['task_id'] ?? json['taskId'];
    
    return Proposal(
      id: json['id'],
      taskId: taskId is int ? taskId : int.tryParse(taskId.toString()) ?? 0,
      freelancerId: json['freelancer_id'] ?? json['freelancerId'],
      coverLetter: json['cover_letter'] ?? json['coverLetter'] ?? '',
      // Inside Proposal.fromJson
      bidAmount: double.tryParse(json['bid_amount']?.toString() ?? json['bidAmount']?.toString() ?? '0.0') ?? 0.0,       
      estimatedDays: json['estimated_days'] ?? json['estimatedDays'] ?? 7,
      status: json['status'] ?? 'pending',
      title: json['title'] ?? json['task_title'],
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at'])
          : null,
      pdfUrl: json['pdf_url'],
      pdfName: json['pdf_name'],
    );
  }
}