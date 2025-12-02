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
    // Safe numeric parsing
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Proposal(
      id: json['proposal_id']?.toString() ?? '',
      task: json['task'] is Map<String, dynamic>
          ? Task.fromJson(json['task'])
          : const Task(title: ''),

      freelancer: json['freelancer'] is Map<String, dynamic>
          ? Freelancer.fromJson(json['freelancer'])
          : const Freelancer(id: '', name: 'Unknown'),

      bidAmount: parseDouble(json['bid_amount']),
      estimatedDays: parseInt(json['estimated_days']),
      submittedAt: DateTime.tryParse(json['submitted_at'] ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      coverLetter: json['cover_letter']?.toString() ?? '',
    );
  }

  Proposal copyWith({String? status}) {
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
    final diff = now.difference(submittedAt);

    if (diff.inDays > 0) return '${diff.inDays} days';
    if (diff.inHours > 0) return '${diff.inHours} hours';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes';
    return 'Just now';
  }

  String get submittedDate =>
      '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';
}

class Task {
  final String title;

  const Task({required this.title});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title']?.toString() ?? '',
    );
  }
}

class Freelancer {
  final String id;
  final String name;

  const Freelancer({required this.id, required this.name});

  factory Freelancer.fromJson(Map<String, dynamic> json) {
    return Freelancer(
      id: json['user_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['username']?.toString() ??
          json['name']?.toString() ??
          'Unknown',
    );
  }
}
