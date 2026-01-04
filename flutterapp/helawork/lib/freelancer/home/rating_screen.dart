import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/submitting_rating.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:helawork/freelancer/widgets/rating_card.dart';
import 'package:provider/provider.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  bool _initialized = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_initialized) return;
    
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) return;
    
    final currentUserId = _getCurrentUserId();
    
    try {
      await Future.wait([
        ratingProvider.fetchMyRatings(currentUserId),
        ratingProvider.fetchRateableContracts(currentUserId),
      ]);
    } catch (e) {
      debugPrint('Error initializing ratings: $e');
    }
    
    _initialized = true;
  }

  int _getCurrentUserId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (authProvider.userData != null) {
        final userId = authProvider.userData!['id'] ?? 
                      authProvider.userData!['user_id'] ??
                      authProvider.userData!['userId'];
        
        if (userId is int) return userId;
        if (userId is String) return int.tryParse(userId) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting user ID from auth: $e');
      return 0;
    }
  }

  void _showRateableContracts(BuildContext context) {
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final currentUserId = _getCurrentUserId();
    
    if (currentUserId == 0) {
      _showLoginRequiredDialog(context);
      return;
    }
    
    if (ratingProvider.rateableContracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No contracts available for rating. Complete some tasks and receive payment first.'),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRateableContractsSheet(ratingProvider),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to be logged in to rate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildRateableContractsSheet(RatingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select to Rate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose completed & paid contracts to rate',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          if (provider.rateableContracts.isEmpty)
            _buildEmptyRateableState()
          else
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: provider.rateableContracts.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final contract = provider.rateableContracts[index];
                  return _buildRateableContractTile(contract);
                },
              ),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyRateableState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No contracts to rate',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'To rate someone:\n• Complete a contract together\n• Ensure payment is received\n• Rate within 30 days of completion',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateableContractTile(Map<String, dynamic> contract) {
    final userToRate = contract['user_to_rate'];
    final daysRemaining = contract['days_remaining'] ?? 0;
    final isFreelancer = contract['is_freelancer'] ?? false;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _navigateToSubmitRating(contract);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: daysRemaining > 7 
                    ? Colors.blueAccent.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: daysRemaining > 7
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    (userToRate['username']?[0] ?? 'U').toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: daysRemaining > 7 ? Colors.blueAccent : Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Contract info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userToRate['username'] ?? 'User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (daysRemaining <= 7)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Text(
                              '$daysRemaining days left',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contract['task_title'] ?? 'Task',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isFreelancer ? Icons.person : Icons.business,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFreelancer ? 'Rating a freelancer' : 'Rating an employer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (contract['budget'] > 0)
                          Text(
                            '\$${contract['budget']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubmitRating(Map<String, dynamic> contract) {
    final currentUserId = _getCurrentUserId();
    
    if (currentUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final userToRate = contract['user_to_rate'];
    final ratedUserId = userToRate['id'] ?? 0;
    final taskId = contract['task_id'] ?? 0;
    final contractId = contract['contract_id'] ?? 0;
    
    if (ratedUserId == 0 || taskId == 0 || contractId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid contract data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitRatingScreen(
          employerId: contract['is_employer'] ? currentUserId : ratedUserId,
          freelancerId: contract['is_freelancer'] ? currentUserId : ratedUserId,
          taskId: taskId,
          contractId: contractId,
          clientId: ratedUserId,
          clientName: userToRate['username'] ?? 'User',
          taskTitle: contract['task_title'] ?? 'Task',
          isFreelancerRating: contract['is_freelancer'] ?? false,
        ),
      ),
    ).then((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final currentUserId = _getCurrentUserId();
    await ratingProvider.fetchMyRatings(currentUserId);
    await ratingProvider.fetchRateableContracts(currentUserId);
  }

  List<dynamic> _getFilteredRatings(RatingProvider provider) {
    return _selectedTab == 0 
        ? provider.getRatingsReceived()
        : provider.getClientRatingsGiven();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RatingProvider, AuthProvider>(
      builder: (context, ratingProvider, authProvider, child) {
        final filteredRatings = _getFilteredRatings(ratingProvider);
        final hasRateableContracts = ratingProvider.rateableContracts.isNotEmpty;
        
        if (!authProvider.isLoggedIn) {
          return _buildLoginRequiredView();
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Ratings",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            actions: [
              if (_selectedTab == 1 && hasRateableContracts)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => _showRateableContracts(context),
                  tooltip: 'Rate Someone',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final currentUserId = _getCurrentUserId();
              await ratingProvider.fetchMyRatings(currentUserId);
              if (_selectedTab == 1) {
                await ratingProvider.fetchRateableContracts(currentUserId);
              }
            },
            child: Column(
              children: [
                // Tab Selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          index: 0,
                          icon: Icons.star_border,
                          label: 'Received',
                          isSelected: _selectedTab == 0,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildTabButton(
                          index: 1,
                          icon: Icons.rate_review_outlined,
                          label: 'Given',
                          isSelected: _selectedTab == 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rateable contracts banner
                if (_selectedTab == 1 && hasRateableContracts)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${ratingProvider.rateableContracts.length} contract${ratingProvider.rateableContracts.length == 1 ? '' : 's'} ready for rating',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showRateableContracts(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Rate Now',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error display
                if (ratingProvider.error != null && filteredRatings.isEmpty && !ratingProvider.isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.redAccent.withOpacity(0.05),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ratingProvider.error!,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => ratingProvider.clearError(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Stats (if any ratings)
                if (filteredRatings.isNotEmpty)
                  _buildRatingStats(ratingProvider, filteredRatings),

                // Ratings list
                Expanded(
                  child: _buildRatingsList(ratingProvider, filteredRatings, hasRateableContracts),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequiredView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ratings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              "Login Required",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                "Please login to view and manage your ratings",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.blueAccent : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.blueAccent : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsList(RatingProvider provider, List<dynamic> filteredRatings, bool hasRateableContracts) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && filteredRatings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                _initializeData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (filteredRatings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 0 ? Icons.star_outline : Icons.rate_review_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              _selectedTab == 0 
                  ? "No Ratings Received"
                  : "No Ratings Given",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                _selectedTab == 0
                    ? "Complete contracts to receive ratings"
                    : hasRateableContracts
                        ? "Tap the + button to rate completed contracts"
                        : "Complete contracts and receive payment to rate",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
            if (_selectedTab == 1 && hasRateableContracts)
              const SizedBox(height: 24),
            if (_selectedTab == 1 && hasRateableContracts)
              ElevatedButton(
                onPressed: () => _showRateableContracts(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rate Now'),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRatings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return RatingCard(rating: filteredRatings[index]);
      },
    );
  }

  Widget _buildRatingStats(RatingProvider provider, List<dynamic> ratings) {
    final averageRating = provider.getAverageRating(ratings);
    final totalRatings = ratings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            value: averageRating.toStringAsFixed(1),
            label: 'Average',
            icon: Icons.star,
            color: Colors.blueAccent,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            value: totalRatings.toString(),
            label: 'Total',
            icon: Icons.numbers,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}