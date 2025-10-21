import 'package:flutter/material.dart';
import 'package:helawork/clients/home/client_rating_screen.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/employer_rating_provider.dart';


class EmployerRatingsScreen extends StatefulWidget {
  final String token;
  final int employerId;

  const EmployerRatingsScreen({
    super.key, 
    required this.token,
    required this.employerId,
  });

  @override
  State<EmployerRatingsScreen> createState() => _EmployerRatingsScreenState();
}

class _EmployerRatingsScreenState extends State<EmployerRatingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployerRatingProvider>(context, listen: false)
          .fetchRatings();
    });
  }

  void _navigateToRateFreelancer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientRatingScreen(employerId: widget.employerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployerRatingProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Employer Ratings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ ADDED: Rate Freelancer Button in AppBar
          IconButton(
            onPressed: _navigateToRateFreelancer,
            icon: const Icon(Icons.star_rate_rounded),
            tooltip: 'Rate Freelancers',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ ADDED: Quick Action Card at the top
          _buildQuickActionsCard(),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  )
                : provider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${provider.errorMessage}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Provider.of<EmployerRatingProvider>(context, listen: false)
                                    .fetchRatings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : provider.ratings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star_outline,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Ratings Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You haven\'t received any ratings yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // ✅ ADDED: Call to action when no ratings
                                ElevatedButton(
                                  onPressed: _navigateToRateFreelancer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Rate Your First Freelancer'),
                                ),
                              ],
                            ),
                          )
                        : _buildRatingsList(provider.ratings),
          ),
        ],
      ),
      // ✅ ADDED: Floating Action Button for quick rating
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRateFreelancer,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.star_rate_rounded),
        tooltip: 'Rate Freelancer',
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.star_rate_rounded,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate Your Freelancers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your experience and help build the community',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _navigateToRateFreelancer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Rate Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList(List<dynamic> ratings) {
    return Column(
      children: [
        // Employer summary card
        _buildEmployerSummary(ratings),
        Expanded(
          child: ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildRatingCard(rating);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployerSummary(List<dynamic> ratings) {
    final totalScore = ratings.fold(0.0, (sum, rating) => sum + (rating['score'] ?? 0));
    final averageScore = ratings.isNotEmpty ? totalScore / ratings.length : 0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  averageScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const Text(
                  'Average Rating',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  ratings.length.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Total Reviews',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // ✅ ADDED: Quick Rate Button in Summary
            Column(
              children: [
                IconButton(
                  onPressed: _navigateToRateFreelancer,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
                const Text(
                  'Add Rating',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            // Star rating visualization
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < (rating['score'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${rating['score'] ?? 0}/5',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (rating['freelancer_name'] != null) ...[
              Text(
                'By: ${rating['freelancer_name']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              rating['review']?.isNotEmpty == true
                  ? rating['review']!
                  : 'No review provided',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (rating['created_at'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Posted on ${_formatDate(rating['created_at'])}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}