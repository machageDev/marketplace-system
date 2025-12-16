import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    // Debug the incoming JSON
    debugPrint("📄 Parsing contract: ${json['contract_id'] ?? 'Unknown'}");
    
    return Contract(
      contractId: json['contract_id'] ?? 0,
      task: json['task'] is Map ? Map<String, dynamic>.from(json['task']) : {},
      employer: json['employer'] is Map ? Map<String, dynamic>.from(json['employer']) : {},
      startDate: json['start_date']?.toString() ?? DateTime.now().toString(),
      endDate: json['end_date']?.toString(),
      employerAccepted: (json['employer_accepted'] ?? false) == true,
      freelancerAccepted: (json['freelancer_accepted'] ?? false) == true,
      isActive: (json['is_active'] ?? false) == true,
      isFullyAccepted: (json['is_fully_accepted'] ?? false) == true,
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
    );
  }

  // Getter for task title
  String get taskTitle {
    if (task['title'] != null) return task['title'].toString();
    if (task['task_title'] != null) return task['task_title'].toString();
    if (task['name'] != null) return task['name'].toString();
    return 'Untitled Task';
  }

  // Getter for employer name
  String get employerName {
    if (employer['company_name'] != null) return employer['company_name'].toString();
    if (employer['name'] != null) return employer['name'].toString();
    if (employer['username'] != null) return employer['username'].toString();
    if (employer['email'] != null) return employer['email'].toString().split('@').first;
    return 'Client';
  }

  // Format dates
  String get formattedStartDate {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(startDate));
    } catch (e) {
      return startDate;
    }
  }

  String? get formattedEndDate {
    if (endDate == null) return null;
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(endDate!));
    } catch (e) {
      return endDate;
    }
  }

  // CORRECT LOGIC: Show accept button when employer has accepted but freelancer hasn't
  bool get canAccept => employerAccepted && !freelancerAccepted;
  
  //  Show reject button under same conditions
  bool get canReject => employerAccepted && !freelancerAccepted;
  
  //  Contract is fully accepted
  bool get isAccepted => isFullyAccepted;
  
  // Get budget if available
  double? get budget {
    final budgetValue = task['budget'];
    if (budgetValue == null) return null;
    
    if (budgetValue is double) return budgetValue;
    if (budgetValue is int) return budgetValue.toDouble();
    if (budgetValue is String) return double.tryParse(budgetValue);
    
    return null;
  }
  String get taskStatus {
    if (task['status'] != null) return task['status'].toString();
    if (isFullyAccepted) return 'in_progress';
    return 'open';
  }

  // Check if task is taken by anyone
  bool get isTaskTaken {
    final status = taskStatus.toLowerCase();
    return status == 'taken' || 
           status == 'assigned' || 
           status == 'in_progress' || 
           status == 'completed' ||
           status == 'closed';
  }

  // Check if task is assigned to current user (for contracts)
  bool get isAssignedToMe {
    return isFullyAccepted && freelancerAccepted;
  }

}