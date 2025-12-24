class PaymentModel {
  final double amount;
  final String email;
  final String freelancerAccount;
  final int jobId;

  PaymentModel({
    required this.amount,
    required this.email,
    required this.freelancerAccount,
    required this.jobId,
  });
}