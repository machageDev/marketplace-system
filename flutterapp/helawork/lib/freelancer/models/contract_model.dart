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
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      contractId: json['contract_id'] ?? 0,
      task: Map<String, dynamic>.from(json['task'] ?? {}),
      employer: Map<String, dynamic>.from(json['employer'] ?? {}),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      employerAccepted: json['employer_accepted'] ?? false,
      freelancerAccepted: json['freelancer_accepted'] ?? false,
      isActive: json['is_active'] ?? false,
      isFullyAccepted: json['is_fully_accepted'] ?? false,
      status: json['status'] ?? 'pending',
    );
  }

  // Helper getters
  String get taskTitle => task['title'] ?? 'Untitled Task';
  String get employerName => employer['company_name'] ?? employer['name'] ?? 'Client';
  String get formattedStartDate => _formatDate(startDate);
  String? get formattedEndDate => endDate != null ? _formatDate(endDate!) : null;

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  bool get canAccept => employerAccepted && !freelancerAccepted;
  bool get canReject => employerAccepted && !freelancerAccepted;
  bool get isPending => !isFullyAccepted;
  bool get isAccepted => isFullyAccepted;
}