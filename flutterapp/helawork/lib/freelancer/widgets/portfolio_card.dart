import 'package:flutter/material.dart';
import 'package:helawork/freelancer/model/portfolio_item.dart';

class PortfolioCard extends StatelessWidget {
  final PortfolioItem portfolioItem;
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.portfolioItem,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF444444)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image if available
              if (portfolioItem.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    portfolioItem.image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: const Color(0xFF252525),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF888888),
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              
              if (portfolioItem.image != null) const SizedBox(height: 16),
              
              // Title
              Text(
                portfolioItem.title,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                portfolioItem.description,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Skills proven by this portfolio item
              if (portfolioItem.skillsUsed.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Skills Demonstrated:',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: portfolioItem.skillsUsed.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10B981),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                skill.name,
                                style: const TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              
              if (portfolioItem.skillsUsed.isNotEmpty) const SizedBox(height: 12),
              
              // Client quote if available
              if (portfolioItem.clientQuote != null && portfolioItem.clientQuote!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF444444)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.format_quote,
                            color: Color(0xFF888888),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Client Feedback',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        portfolioItem.clientQuote!,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (portfolioItem.clientQuote != null && portfolioItem.clientQuote!.isNotEmpty)
                const SizedBox(height: 12),
              
              // Links and date
              Row(
                children: [
                  if (portfolioItem.projectUrl != null)
                    InkWell(
                      onTap: () {
                        // Handle project URL tap
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.link,
                              color: Color(0xFF888888),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Project',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (portfolioItem.videoUrl != null) ...[
                    if (portfolioItem.projectUrl != null) const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        // Handle video URL tap
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.video_library,
                              color: Color(0xFF888888),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Video',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    portfolioItem.completionDate,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
