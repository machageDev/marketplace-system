class PaymentModel {
  final String orderId;  // Add this
  final double amount;
  final String email;
  final String freelancerAccount;
  final String freelancerEmail;
  final String freelancerId;  // Add this
  final String freelancerName;  // Add this
  final String serviceDescription;  // Add this
  final String currency;  // Add this

  PaymentModel({
    required this.orderId,
    required this.amount,
    required this.email,
    required this.freelancerAccount,
    required this.freelancerEmail,
    required this.freelancerId,
    required this.freelancerName,
    required this.serviceDescription,
    this.currency = 'KSH',
  });

  // Helper to create from JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      orderId: json['order_id'] ?? json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      email: json['email'] ?? '',
      freelancerAccount: json['freelancer_paystack_account'] ?? json['paystack_subaccount'] ?? '',
      freelancerEmail: json['freelancer_email']?.toString() ?? '',
      freelancerId: json['freelancer_id'] ?? json['freelancer']?['id'] ?? '',
      freelancerName: json['freelancer_name'] ?? json['freelancer']?['name'] ?? 'Freelancer',
      serviceDescription: json['service_description'] ?? json['task_title'] ?? 'Service',
      currency: json['currency'] ?? 'KSH',
    );
  }

  // Convert to map for API requests
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'amount': amount,
      'email': email,
      'freelancer_paystack_account': freelancerAccount,
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'service_description': serviceDescription,
      'currency': currency,
    };
  }
}