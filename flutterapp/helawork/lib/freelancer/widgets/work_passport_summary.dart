import 'package:flutter/material.dart';

class WorkPassportSummary extends StatelessWidget {
  final Map<String, dynamic> workPassportData;

  const WorkPassportSummary({
    super.key,
    required this.workPassportData,
  });

  @override
  Widget build(BuildContext context) {
    final totalEarnings = workPassportData['total_earnings']?.toDouble() ?? 0.0;
    final completedTasks = workPassportData['completed_tasks'] ?? 0;
    final avgRating = workPassportData['avg_rating']?.toDouble() ?? 0.0;
    final reviewCount = workPassportData['review_count'] ?? 0;
    final verifiedSkillsCount = workPassportData['verified_skills_count'] ?? 0;
    final platformTenureDays = workPassportData['platform_tenure_days'] ?? 0;
    final satisfactionSummary = workPassportData['client_satisfaction_summary'] ?? 'No ratings yet';

    // Format platform tenure
    String tenureText = 'New member';
    if (platformTenureDays > 0) {
      if (platformTenureDays < 30) {
        tenureText = '$platformTenureDays days';
      } else if (platformTenureDays < 365) {
        final months = (platformTenureDays / 30).floor();
        tenureText = '$months ${months == 1 ? 'month' : 'months'}';
      } else {
        final years = (platformTenureDays / 365).floor();
        tenureText = '$years ${years == 1 ? 'year' : 'years'}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF444444), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Work Passport',
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Top row: Earnings and Completed Tasks
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  label: 'Total Earnings',
                  value: '\$${totalEarnings.toStringAsFixed(2)}',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Completed Jobs',
                  value: completedTasks.toString(),
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Verified Skills and Platform Tenure
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.verified,
                  label: 'Verified Skills',
                  value: verifiedSkillsCount.toString(),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  label: 'Platform Tenure',
                  value: tenureText,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Third row: Average Rating
          _buildStatCard(
            icon: Icons.star,
            label: 'Average Rating',
            value: avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)' : 'No ratings yet',
            color: const Color(0xFFFFD700),
            fullWidth: true,
          ),
          if (satisfactionSummary != 'No ratings yet') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF444444)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sentiment_satisfied,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Client Satisfaction: $satisfactionSummary',
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
