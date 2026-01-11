import 'skill.dart';

class UserSkill {
  final int id;
  final Skill skill;
  final String verificationStatus;
  final String? verificationEvidence;
  final String? dateVerified;
  final String badgeColor;

  UserSkill({
    required this.id,
    required this.skill,
    required this.verificationStatus,
    this.verificationEvidence,
    this.dateVerified,
    required this.badgeColor,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      id: json['id'] ?? 0,
      skill: Skill.fromJson(json['skill'] ?? {}),
      verificationStatus: json['verification_status'] ?? 'self_reported',
      verificationEvidence: json['verification_evidence'],
      dateVerified: json['date_verified'],
      badgeColor: json['badge_color'] ?? '#6B7280',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill.toJson(),
      'verification_status': verificationStatus,
      'verification_evidence': verificationEvidence,
      'date_verified': dateVerified,
      'badge_color': badgeColor,
    };
  }
}
