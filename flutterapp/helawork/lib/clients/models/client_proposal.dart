// models.dart
class Proposal {
  final String id;
  final Task task;
  final Freelancer freelancer;
  final double bidAmount;
  final int estimatedDays;
  final DateTime submittedAt;
  final String status;
  final String coverLetter;

  const Proposal({
    required this.id,
    required this.task,
    required this.freelancer,
    required this.bidAmount,
    required this.estimatedDays,
    required this.submittedAt,
    required this.status,
    required this.coverLetter,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['proposal_id']?.toString() ?? '',
      task: Task.fromJson(json['task']),
      freelancer: Freelancer.fromJson(json['freelancer']),
      bidAmount: (json['bid_amount'] as num?)?.toDouble() ?? 0.0,
      estimatedDays: json['estimated_days'] ?? 0,
      submittedAt: DateTime.parse(json['submitted_at']),
      status: json['status'] ?? 'pending',
      coverLetter: json['cover_letter'] ?? '',
    );
  }

  Proposal copyWith({
    String? status,
  }) {
    return Proposal(
      id: id,
      task: task,
      freelancer: freelancer,
      bidAmount: bidAmount,
      estimatedDays: estimatedDays,
      submittedAt: submittedAt,
      status: status ?? this.status,
      coverLetter: coverLetter,
    );
  }

  String get submittedAgo {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);
    
    if (difference.inDays > 0) return '${difference.inDays} days';
    if (difference.inHours > 0) return '${difference.inHours} hours';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes';
    return 'Just now';
  }

  String get submittedDate {
    return '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';
  }
}

class Task {
  final String title;

  const Task({required this.title});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? '',
    );
  }
}

class Freelancer {
  final String id;
  final String name;

  const Freelancer({required this.id, required this.name});

  factory Freelancer.fromJson(Map<String, dynamic> json) {
    return Freelancer(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['username'] ?? json['name'] ?? 'Unknown',
    );
  }
}