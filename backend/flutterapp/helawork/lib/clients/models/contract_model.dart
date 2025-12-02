class ContractModel {
  final int contractId;
  final String taskTitle;
  final String freelancerUsername;
  final String startDate;
  final String? endDate;
  bool employerAccepted;
  final bool freelancerAccepted;
  final bool isActive;

  ContractModel({
    required this.contractId,
    required this.taskTitle,
    required this.freelancerUsername,
    required this.startDate,
    this.endDate,
    required this.employerAccepted,
    required this.freelancerAccepted,
    required this.isActive,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contract_id'],
      taskTitle: json['task']['title'],
      freelancerUsername: json['freelancer']['username'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      employerAccepted: json['employer_accepted'],
      freelancerAccepted: json['freelancer_accepted'],
      isActive: json['is_active'],
    );
  }
}
