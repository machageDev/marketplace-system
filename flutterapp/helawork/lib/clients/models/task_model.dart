
class Task {
  final String taskId;
  final String title;
  final String description;
  final String category;
  final double? budget;
  final String status;
  final DateTime? deadline;
  final bool isUrgent;
  final bool isActive;
  final bool isApproved;
  final int proposalCount;
  final String? assignedUser;
  final DateTime createdAt;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    required this.status,
    this.deadline,
    required this.isUrgent,
    required this.isActive,
    required this.isApproved,
    required this.proposalCount,
    this.assignedUser,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      budget: json['budget'] != null ? double.tryParse(json['budget'].toString()) : null,
      status: json['status'] ?? 'open',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isUrgent: json['is_urgent'] ?? false,
      isActive: json['is_active'] ?? true,
      isApproved: json['is_approved'] ?? true,
      proposalCount: json['proposal_count'] ?? json['proposals']?.length ?? 0,
      assignedUser: json['assigned_user'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}