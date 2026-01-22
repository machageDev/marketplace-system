import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/freelancer/home/submitting_rating.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
      constraints: const BoxConstraints(
        maxHeight: 500,
      ),
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
    // Add null safety check
    
    debugPrint('📋 Building contract tile with keys: ${contract.keys.toList()}');
    
    // FIXED: Handle different data structures from backend
    final Map<String, dynamic> userToRate;
    
    // Check for 'client' field (from your backend logs)
    if (contract['client'] != null && contract['client'] is Map) {
      userToRate = Map<String, dynamic>.from(contract['client'] as Map);
      debugPrint('✅ Using "client" field for user data');
    } 
    // Check for 'user_to_rate' field (old format)
    else if (contract['user_to_rate'] != null && contract['user_to_rate'] is Map) {
      userToRate = Map<String, dynamic>.from(contract['user_to_rate'] as Map);
      debugPrint('✅ Using "user_to_rate" field for user data');
    } else {
      userToRate = <String, dynamic>{};
      debugPrint('⚠️ No user data found in contract');
    }
    
    final Map<String, dynamic> task;
    if (contract['task'] != null && contract['task'] is Map) {
      task = Map<String, dynamic>.from(contract['task'] as Map);
    } else {
      task = <String, dynamic>{};
    }
    
    // Extract data with defaults
    final daysRemaining = contract['days_remaining'] as int? ?? 30;
    final currentUserRole = contract['current_user_role'] as String? ?? 'freelancer';
    final isFreelancer = currentUserRole == 'freelancer';
    
    // Handle budget - convert to KSH format
    final dynamic budgetData = task['budget'] ?? contract['budget'] ?? 0;
    double budget = 0.0;
    
    if (budgetData is String) {
      // Try to parse string to double
      final cleaned = budgetData.replaceAll(RegExp(r'[^0-9.]'), '');
      budget = double.tryParse(cleaned) ?? 0.0;
    } else if (budgetData is num) {
      budget = budgetData.toDouble();
    }
    
    // Format budget as KSH
    String budgetText = 'KSH ${budget.toStringAsFixed(0)}';
    if (budget >= 1000) {
      budgetText = 'KSH ${(budget / 1000).toStringAsFixed(1)}K';
    }
    
    final taskTitle = (task['title'] as String?) ?? 
                      (contract['task_title'] as String?) ?? 
                      'Task';
    
    // Handle username from different possible fields
    String username = 'User';
    if (userToRate['name'] != null) {
      username = userToRate['name'].toString();
    } else if (userToRate['username'] != null) {
      username = userToRate['username'].toString();
    } else if (contract['client_name'] != null) {
      username = contract['client_name'].toString();
    }
    
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
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
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
                            username,
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
                      taskTitle,
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
                        if (budget > 0)
                          Text(
                            budgetText,
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
    
    try {
      // FIXED: Handle different data structures
      final Map<String, dynamic> userToRate;
      if (contract['client'] != null && contract['client'] is Map) {
        userToRate = Map<String, dynamic>.from(contract['client'] as Map);
      } else if (contract['user_to_rate'] != null && contract['user_to_rate'] is Map) {
        userToRate = Map<String, dynamic>.from(contract['user_to_rate'] as Map);
      } else {
        userToRate = <String, dynamic>{};
      }
      
      final Map<String, dynamic> task;
      if (contract['task'] != null && contract['task'] is Map) {
        task = Map<String, dynamic>.from(contract['task'] as Map);
      } else {
        task = <String, dynamic>{};
      }
      
      final ratedUserId = _parseToInt(userToRate['id']) ?? 0;
      final taskId = _parseToInt(task['id'] ?? contract['task_id']) ?? 0;
      final contractId = _parseToInt(contract['contract_id']) ?? 0;
      
      debugPrint('🎯 Navigate to rating: ratedUserId=$ratedUserId, taskId=$taskId, contractId=$contractId');
      
      if (ratedUserId == 0 || taskId == 0 || contractId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid contract data - missing IDs'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final currentUserRole = contract['current_user_role'] as String? ?? 'freelancer';
      final isFreelancer = currentUserRole == 'freelancer';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmitRatingScreen(
            employerId: isFreelancer ? ratedUserId : currentUserId,
            freelancerId: isFreelancer ? currentUserId : ratedUserId,
            taskId: taskId,
            contractId: contractId,
            clientId: ratedUserId,
            clientName: userToRate['name'] as String? ?? 
                       userToRate['username'] as String? ?? 
                       'Client',
            taskTitle: task['title'] as String? ?? 'Task',
            isFreelancerRating: isFreelancer,
          ),
        ),
      ).then((_) {
        _refreshData();
      });
    } catch (e) {
      debugPrint('❌ Error navigating to submit rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
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

    // Display ratings in a beautiful format
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRatings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rating = filteredRatings[index];
        return _buildRatingCard(rating);
      },
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    // Extract basic data with null safety
    final double overallRating = _extractDouble(rating, ['rating', 'overall', 'value'], 0.0);
    
    String raterName = 'Anonymous';
    if (rating['rater_name'] != null) {
      raterName = rating['rater_name'].toString();
    } else if (rating['client_name'] != null) {
      raterName = rating['client_name'].toString();
    } else if (rating['from_user'] != null && rating['from_user'] is Map) {
      final fromUser = Map<String, dynamic>.from(rating['from_user'] as Map);
      raterName = fromUser['name']?.toString() ?? 'Anonymous';
    }
    
    String taskTitle = 'Task';
    if (rating['task_title'] != null) {
      taskTitle = rating['task_title'].toString();
    } else if (rating['task'] != null && rating['task'] is Map) {
      final task = Map<String, dynamic>.from(rating['task'] as Map);
      taskTitle = task['title']?.toString() ?? 'Task';
    }
    
    final String? comment = rating['comment'] ?? rating['feedback'] ?? rating['review'];
    
    // Parse date
    DateTime? createdAt;
    if (rating['created_at'] != null) {
      if (rating['created_at'] is String) {
        createdAt = DateTime.tryParse(rating['created_at'] as String);
      } else if (rating['created_at'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch((rating['created_at'] as int) * 1000);
      }
    }
    
    // Check for __EXTENDED_DATA__ in comment or extended_data field
    Map<String, dynamic>? extendedData;
    String? cleanComment = comment;
    
    // Check if comment contains __EXTENDED_DATA__
    if (comment != null && comment.contains('__EXTENDED_DATA__')) {
      final jsonStart = comment.indexOf('{');
      if (jsonStart != -1) {
        try {
          final jsonString = comment.substring(jsonStart);
          extendedData = jsonDecode(jsonString);
          // Extract clean comment (part before __EXTENDED_DATA__)
          final cleanCommentEnd = comment.indexOf('__EXTENDED_DATA__');
          if (cleanCommentEnd > 0) {
            cleanComment = comment.substring(0, cleanCommentEnd).trim();
          }
        } catch (e) {
          debugPrint('Error parsing JSON from comment: $e');
        }
      }
    }
    
    // Also check extended_data field
    if (extendedData == null && rating['extended_data'] is String) {
      final extData = rating['extended_data'] as String;
      if (extData.contains('__EXTENDED_DATA__')) {
        final jsonStart = extData.indexOf('{');
        if (jsonStart != -1) {
          try {
            final jsonString = extData.substring(jsonStart);
            extendedData = jsonDecode(jsonString);
          } catch (e) {
            debugPrint('Error parsing extended_data: $e');
          }
        }
      } else {
        // Try parsing as pure JSON
        try {
          extendedData = jsonDecode(extData);
        } catch (e) {
          debugPrint('Error parsing extended_data as JSON: $e');
        }
      }
    } else if (rating['extended_data'] is Map) {
      extendedData = Map<String, dynamic>.from(rating['extended_data'] as Map);
    }
    
    // Extract data from parsed JSON
    Map<String, dynamic>? categoryScores;
    List<String> performanceTags = [];
    bool wouldRecommend = false;
    bool wouldRehire = false;
    
    if (extendedData != null) {
      if (extendedData['category_scores'] is Map) {
        categoryScores = Map<String, dynamic>.from(extendedData['category_scores'] as Map);
      }
      
      if (extendedData['performance_tags'] is List) {
        final tags = extendedData['performance_tags'] as List;
        performanceTags = List<String>.from(tags);
      }
      
      wouldRecommend = extendedData['would_recommend'] as bool? ?? false;
      wouldRehire = extendedData['would_rehire'] as bool? ?? false;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and rating
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      raterName.isNotEmpty ? raterName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Overall rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          overallRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Date
                    if (createdAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Category scores with progress bars (if available)
          if (categoryScores != null && categoryScores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Category Ratings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...categoryScores.entries.map((entry) {
                    final score = _extractDoubleFromDynamic(entry.value);
                    return _buildCategoryProgressBar(
                      _formatCategoryName(entry.key),
                      score,
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          
          // Performance tags as badge chips (if available)
          if (performanceTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: performanceTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCategoryName(tag),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Comment (if available and clean)
          if (cleanComment != null && cleanComment.isNotEmpty && cleanComment != comment)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                cleanComment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          
          // Footer with verification and recommendation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // Verified checkmark if would_recommend is true
                if (wouldRecommend)
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                
                // Recommendation text
                Expanded(
                  child: Text(
                    _getRecommendationText(wouldRecommend, wouldRehire),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build category progress bar
  Widget _buildCategoryProgressBar(String category, double score) {
    final percentage = (score / 5.0) * 100;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/5.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: percentage.toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getProgressBarColor(percentage),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - percentage.toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getProgressBarColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.amber;
    return Colors.orange;
  }

  // Helper methods
  String _getRecommendationText(bool wouldRecommend, bool wouldRehire) {
    if (wouldRecommend && wouldRehire) {
      return 'Highly recommended • Would rehire';
    } else if (wouldRecommend) {
      return 'Recommended for future work';
    } else if (wouldRehire) {
      return 'Would work with again';
    } else {
      return 'Rating submitted';
    }
  }

  double _extractDouble(Map<String, dynamic> data, List<String> keys, double defaultValue) {
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    if (current is num) return current.toDouble();
    if (current is String) return double.tryParse(current) ?? defaultValue;
    return defaultValue;
  }

  double _extractDoubleFromDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatCategoryName(String name) {
    final formatted = name.replaceAll(RegExp(r'([A-Z])'), r' $1').trim();
    if (formatted.isEmpty) return name;
    return formatted[0].toUpperCase() + formatted.substring(1);
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
            label: 'Average Rating',
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
            label: 'Total Ratings',
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