import 'package:flutter/material.dart';
import 'package:helawork/freelancer/model/user_skill.dart';

class SkillBadge extends StatelessWidget {
  final UserSkill userSkill;

  const SkillBadge({
    super.key,
    required this.userSkill,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color(int.parse(userSkill.badgeColor.replaceFirst('#', '0xFF')));
    final verificationSource = _getVerificationSourceLabel(userSkill.verificationStatus);
    
    return Tooltip(
      message: verificationSource,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userSkill.skill.name,
              style: TextStyle(
                color: badgeColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _getIconForStatus(userSkill.verificationStatus),
              size: 14,
              color: badgeColor,
            ),
          ],
        ),
      ),
    );
  }
  
  String _getVerificationSourceLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified by Portfolio Evidence';
      case 'test_passed':
        return 'Verified by Platform Skill Test';
      default:
        return 'Self-Reported Skill';
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'test_passed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
