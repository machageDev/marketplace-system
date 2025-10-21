import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/employer_rating_provider.dart';

class EmployerRatingsScreen extends StatefulWidget {
  final String token;

  const EmployerRatingsScreen({super.key, required this.token});

  @override
  State<EmployerRatingsScreen> createState() => _EmployerRatingsScreenState();
}

class _EmployerRatingsScreenState extends State<EmployerRatingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      Provider.of<EmployerRatingProvider>(context, listen: false)
          .fetchRatings(widget.token as int); // Just pass the String token
    });
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
      ),
      body: provider.isLoading
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
                              .fetchRatings(widget.token as int);
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
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.ratings.length,
                      itemBuilder: (context, index) {
                        final rating = provider.ratings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    'Posted on ${rating['created_at']}',
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
                      },
                    ),
    );
  }
}