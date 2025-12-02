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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _hasFetched = false;
  }

  void _navigateToClientSelection() {
    final provider = Provider.of<RatingProvider>(context, listen: false);
    
    if (provider.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clients available to rate. Complete some tasks first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildClientSelectionSheet(provider.clients),
    );
  }

  Widget _buildClientSelectionSheet(List<dynamic> clients) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select a Client to Rate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      (client['username']?[0] ?? 'C').toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(client['username'] ?? 'Unknown Client'),
                  subtitle: Text(client['email'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSubmitRating(client);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSubmitRating(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitRatingScreen(
          taskId: 0, // You'll need to get this from task data
          employerId: client['id'] ?? 0,
          clientName: client['username'] ?? 'Client',
          freelancerId: _getCurrentFreelancerId(),
        ),
      ),
    );
  }

  int _getCurrentFreelancerId() {
    // Replace with your actual user ID retrieval
    // Example: return Provider.of<AuthProvider>(context).user?.id ?? 0;
    return 1; // Temporary
  }

  // Filter ratings based on selected tab
  List<dynamic> _getFilteredRatings(List<dynamic> allRatings) {
    final currentUserId = _getCurrentFreelancerId();
    
    if (_selectedTab == 0) {
      return allRatings.where((rating) => 
          rating['rated_user'] == currentUserId && 
          (rating['rating_type'] == 'client_rating' || rating['rated_user_type'] == 'client')
      ).toList();
    } else {
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
        provider.fetchClientsFromCompletedTasks(); // NEW: Fetch clients
      });
    }

    final filteredRatings = _getFilteredRatings(provider.ratings);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Ratings"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,  
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToClientSelection, // UPDATED: Now opens client selection
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
                      backgroundColor: _selectedTab == 0 ? Colors.grey[900] : Colors.transparent,
                      foregroundColor: _selectedTab == 0 ? Colors.white : Colors.grey[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ratings Received'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    style: TextButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.grey[900] : Colors.transparent,
                      foregroundColor: _selectedTab == 1 ? Colors.white : Colors.grey[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ratings Given'),
                  ),
                ),
              ],
            ),
          ),

          // Client Info (NEW)
          if (_selectedTab == 1 && provider.clients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.clients.length} clients available to rate',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
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
                                onPressed: _navigateToClientSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
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