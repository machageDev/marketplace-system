import 'skill.dart';

class PortfolioItem {
  final int id;
  final String title;
  final String description;
  final String? image;
  final String? videoUrl;
  final String? projectUrl;
  final String? clientQuote;
  final List<Skill> skillsUsed;
  final String completionDate;
  final String? createdAt;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.videoUrl,
    this.projectUrl,
    this.clientQuote,
    required this.skillsUsed,
    required this.completionDate,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      videoUrl: json['video_url'],
      projectUrl: json['project_url'],
      clientQuote: json['client_quote'],
      skillsUsed: (json['skills_used'] as List<dynamic>?)
              ?.map((item) => Skill.fromJson(item))
              .toList() ??
          [],
      completionDate: json['completion_date'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'video_url': videoUrl,
      'project_url': projectUrl,
      'client_quote': clientQuote,
      'skills_used': skillsUsed.map((skill) => skill.toJson()).toList(),
      'completion_date': completionDate,
      'created_at': createdAt,
    };
  }
}
