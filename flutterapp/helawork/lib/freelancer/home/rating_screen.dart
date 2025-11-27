import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/submitting_rate.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:helawork/freelancer/widgets/rating_card.dart';
import 'package:provider/provider.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  bool _hasFetched = false;
  int _selectedTab = 0; // 0: Received, 1: Given

  @override
  void initState() {
    super.initState();
    _hasFetched = false;
  }

  void _navigateToSubmitRating() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubmitRatingScreen( // Remove 'const' keyword
        taskId: 123, // Change from 'task-123' to actual integer
        employerId: 456, // Change from '' to actual integer
        clientName: 'Client Name', 
        freelancerId: 123,
      ),
    ),
  );
}

  // Filter ratings based on selected tab
  List<dynamic> _getFilteredRatings(List<dynamic> allRatings) {
    final currentUserId = 1; // Replace with actual current user ID
    
    if (_selectedTab == 0) {
      // Ratings received by current user (if they're a client)
      return allRatings.where((rating) => 
          rating['rated_user'] == currentUserId && 
          (rating['rating_type'] == 'client_rating' || rating['rated_user_type'] == 'client')
      ).toList();
    } else {
      // Ratings given by current user (to clients)
      return allRatings.where((rating) => 
          rating['rater_user'] == currentUserId && 
          (rating['rating_type'] == 'client_rating' || rating['rated_user_type'] == 'client')
      ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RatingProvider>(context);

    if (!_hasFetched && !provider.isLoading && provider.ratings.isEmpty) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchMyRatings();
      });
    }

    final filteredRatings = _getFilteredRatings(provider.ratings);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Ratings"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToSubmitRating,
            tooltip: 'Rate a Client',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selection
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _selectedTab = 0),
                    style: TextButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? Colors.blueAccent : Colors.transparent,
                      foregroundColor: _selectedTab == 0 ? Colors.white : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ratings Received'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    style: TextButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.blueAccent : Colors.transparent,
                      foregroundColor: _selectedTab == 1 ? Colors.white : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ratings Given'),
                  ),
                ),
              ],
            ),
          ),

          // Rating Statistics
          if (filteredRatings.isNotEmpty) _buildRatingStats(provider, filteredRatings),

          // Ratings List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRatings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTab == 0 ? Icons.star_outline : Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0 
                                  ? "No ratings received yet"
                                  : "You haven't rated any clients yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 0
                                  ? "Complete tasks to receive ratings from clients"
                                  : "Rate clients after completing tasks",
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (_selectedTab == 1)
                              ElevatedButton(
                                onPressed: _navigateToSubmitRating,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Rate a Client"),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRatings.length,
                        itemBuilder: (context, index) {
                          return RatingCard(rating: filteredRatings[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStats(RatingProvider provider, List<dynamic> ratings) {
    final averageRating = provider.getAverageRating(ratings);
    final totalRatings = ratings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Text(
                _selectedTab == 0 ? 'Avg Received' : 'Avg Given',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                totalRatings.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                _selectedTab == 0 ? 'Total Received' : 'Total Given',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}