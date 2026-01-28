import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';



enum ClientRatingCategory {
  communication,
  paymentPromptness,
  requirementsClarity,
  professionalism,
  fairness,
  responsiveness,
  wouldWorkAgain,
  scopeDefinition,
  feedbackQuality,
  decisionMaking,
}

extension ClientRatingCategoryExtension on ClientRatingCategory {
  String get displayName {
    switch (this) {
      case ClientRatingCategory.communication:
        return 'Communication';
      case ClientRatingCategory.paymentPromptness:
        return 'Payment Promptness';
      case ClientRatingCategory.requirementsClarity:
        return 'Requirements Clarity';
      case ClientRatingCategory.professionalism:
        return 'Professionalism';
      case ClientRatingCategory.fairness:
        return 'Fairness';
      case ClientRatingCategory.responsiveness:
        return 'Responsiveness';
      case ClientRatingCategory.wouldWorkAgain:
        return 'Would Work Again';
      case ClientRatingCategory.scopeDefinition:
        return 'Scope Definition';
      case ClientRatingCategory.feedbackQuality:
        return 'Feedback Quality';
      case ClientRatingCategory.decisionMaking:
        return 'Decision Making';
    }
  }

  String get description {
    switch (this) {
      case ClientRatingCategory.communication:
        return 'Clarity, frequency, and effectiveness of communication';
      case ClientRatingCategory.paymentPromptness:
        return 'Timeliness of payments and adherence to agreed terms';
      case ClientRatingCategory.requirementsClarity:
        return 'How clearly project requirements were defined';
      case ClientRatingCategory.professionalism:
        return 'Professional conduct and respect throughout';
      case ClientRatingCategory.fairness:
        return 'Fairness in negotiations and scope changes';
      case ClientRatingCategory.responsiveness:
        return 'How quickly they responded to questions/updates';
      case ClientRatingCategory.wouldWorkAgain:
        return 'Likelihood of working with this client again';
      case ClientRatingCategory.scopeDefinition:
        return 'How well project scope was defined upfront';
      case ClientRatingCategory.feedbackQuality:
        return 'Usefulness and clarity of their feedback';
      case ClientRatingCategory.decisionMaking:
        return 'Speed and quality of decision making';
    }
  }
}

enum ClientPerformanceTag {
  excellentCommunication,
  promptPayer,
  clearRequirements,
  professionalConduct,
  fairNegotiator,
  responsiveClient,
  greatCollaborator,
  reasonableExpectations,
  goodFeedback,
  efficientDecisionMaker,
  scopeRespectful,
  appreciative,
  transparent,
  reliable,
  innovativeThinker,
}

extension ClientPerformanceTagExtension on ClientPerformanceTag {
  String get displayName {
    switch (this) {
      case ClientPerformanceTag.excellentCommunication:
        return 'Excellent Communication';
      case ClientPerformanceTag.promptPayer:
        return 'Prompt Payer';
      case ClientPerformanceTag.clearRequirements:
        return 'Clear Requirements';
      case ClientPerformanceTag.professionalConduct:
        return 'Professional Conduct';
      case ClientPerformanceTag.fairNegotiator:
        return 'Fair Negotiator';
      case ClientPerformanceTag.responsiveClient:
        return 'Responsive Client';
      case ClientPerformanceTag.greatCollaborator:
        return 'Great Collaborator';
      case ClientPerformanceTag.reasonableExpectations:
        return 'Reasonable Expectations';
      case ClientPerformanceTag.goodFeedback:
        return 'Good Feedback Provider';
      case ClientPerformanceTag.efficientDecisionMaker:
        return 'Efficient Decision Maker';
      case ClientPerformanceTag.scopeRespectful:
        return 'Respects Scope';
      case ClientPerformanceTag.appreciative:
        return 'Appreciative';
      case ClientPerformanceTag.transparent:
        return 'Transparent';
      case ClientPerformanceTag.reliable:
        return 'Reliable';
      case ClientPerformanceTag.innovativeThinker:
        return 'Innovative Thinker';
    }
  }
}

// ============ RATINGS SCREEN ============

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && !_initialized) {
      _initializeData();
    }
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
  List<dynamic> _getFilteredRatings(RatingProvider provider) {
  debugPrint('🎯 ====== GET FILTERED RATINGS CALLED ======');
  debugPrint('🎯 Tab index: $_selectedTab (${_selectedTab == 0 ? 'Received' : 'Given'})');
  
  List<dynamic> result;
  
  if (_selectedTab == 0) {
    // Received tab - ratings from clients to freelancer
    result = provider.getRatingsReceived();
    debugPrint('🎯 Received ratings count: ${result.length}');
  } else {
    // Given tab - use the NEW combined method
    result = provider.getCombinedGivenRatings();
    debugPrint('🎯 Combined given ratings count: ${result.length}');
  }
  
  // Debug log the first few items
  if (result.isNotEmpty) {
    for (int i = 0; i < (result.length < 2 ? result.length : 2); i++) {
      try {
        if (result[i] is Map) {
          final rating = _safeMapConvert(result[i] as Map);
          debugPrint('🎯 Item $i - is_rateable_contract: ${rating['is_rateable_contract'] ?? false}');
          debugPrint('🎯 Item $i - display_score: ${rating['display_score']}');
          debugPrint('🎯 Item $i - display_name: ${rating['display_name']}');
        }
      } catch (e) {
        debugPrint('❌ Error logging item $i: $e');
      }
    }
  } else {
    debugPrint('🎯 Result is empty!');
  }
  
  debugPrint('🎯 ====== END GET FILTERED RATINGS ======\n');
  
  return result;
} 

  double _extractScore(Map<String, dynamic> rating) {
    if (rating.isEmpty) return 0.0;
    
    final dynamic val = rating['display_score'] ??
                       rating['score'] ?? 
                       rating['rating'] ?? 
                       rating['overall'];
    
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) return parsed;
    }
    
    if (val is Map) {
      final dynamic nestedVal = val['overall'] ?? val['value'] ?? val['score'];
      if (nestedVal is num) return nestedVal.toDouble();
      if (nestedVal is String) {
        final parsed = double.tryParse(nestedVal);
        if (parsed != null) return parsed;
      }
    }
    
    return 0.0;
  }

  Map<String, dynamic> _safeMapConvert(Map map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  Future<void> _refreshData() async {
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final currentUserId = _getCurrentUserId();
    await ratingProvider.fetchMyRatings(currentUserId);
    await ratingProvider.fetchRateableContracts(currentUserId);
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
      backgroundColor: Colors.black,
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
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Login Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You need to be logged in to rate.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              // Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
            ),
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
      color: Colors.black,
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
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white),
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
              color: Colors.grey[400],
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
                separatorBuilder: (context, index) => Divider(
                  height: 16,
                  color: Colors.grey[800],
                ),
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
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No contracts to rate',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[300],
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
    final Map<String, dynamic> task;
    if (contract['task'] != null && contract['task'] is Map) {
      task = _safeMapConvert(contract['task'] as Map);
    } else {
      task = <String, dynamic>{};
    }
    
    final Map<String, dynamic> client;
    if (contract['client'] != null && contract['client'] is Map) {
      client = _safeMapConvert(contract['client'] as Map);
    } else {
      client = <String, dynamic>{};
    }
    
    final contractId = contract['contract_id'] ?? 0;
    final status = (contract['status'] ?? '').toString();
    final isCompleted = contract['is_completed'] ?? false;
    
    final dynamic budgetData = task['budget'] ?? '0';
    double budget = 0.0;
    
    if (budgetData is String) {
      final cleaned = budgetData.replaceAll(RegExp(r'[^0-9.]'), '');
      budget = double.tryParse(cleaned) ?? 0.0;
    } else if (budgetData is num) {
      budget = budgetData.toDouble();
    }
    
    String budgetText = 'KSH ${budget.toStringAsFixed(0)}';
    if (budget >= 1000) {
      budgetText = 'KSH ${(budget / 1000).toStringAsFixed(1)}K';
    }
    
    final taskTitle = (task['title'] as String?) ?? 'Task';
    
    String username = 'Client';
    if (client['name'] != null) {
      username = client['name'].toString();
    } else if (client['username'] != null) {
      username = client['username'].toString();
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
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFF2563EB).withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
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
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$contractId',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[300],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.pending,
                                size: 12,
                                color: isCompleted ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCompleted ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                budgetText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
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
      final Map<String, dynamic> task;
      if (contract['task'] != null && contract['task'] is Map) {
        task = _safeMapConvert(contract['task'] as Map);
      } else {
        task = <String, dynamic>{};
      }
      
      final Map<String, dynamic> client;
      if (contract['client'] != null && contract['client'] is Map) {
        client = _safeMapConvert(contract['client'] as Map);
      } else {
        client = <String, dynamic>{};
      }
      
      final contractId = contract['contract_id'] as int? ?? 0;
      final taskId = task['id'] as int? ?? 0;
      final clientId = client['id'] as int? ?? 0;
      
      final clientName = client['name'] as String? ?? 'Client';
      final taskTitle = task['title'] as String? ?? 'Task';
      
      if (clientId == 0 || taskId == 0 || contractId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid contract data - missing IDs'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show detailed rating dialog instead
      _showDetailedClientRatingDialog(
        contractId: contractId,
        taskId: taskId,
        clientId: clientId,
        clientName: clientName,
        taskTitle: taskTitle,
        freelancerId: currentUserId,
      );
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

  // NEW: Detailed Client Rating Dialog Method
  void _showDetailedClientRatingDialog({
    required int contractId,
    required int taskId,
    required int clientId,
    required String clientName,
    required String taskTitle,
    required int freelancerId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DetailedClientRatingDialog(
        contractId: contractId,
        taskId: taskId,
        clientId: clientId,
        clientName: clientName,
        taskTitle: taskTitle,
        freelancerId: freelancerId,
        onRatingSubmitted: () {
          _refreshData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RatingProvider, AuthProvider>(
      builder: (context, ratingProvider, authProvider, child) {
        debugPrint('🔄 CONSUMER BUILDER CALLED - Tab: $_selectedTab');
        final filteredRatings = _getFilteredRatings(ratingProvider);
        final hasRateableContracts = ratingProvider.rateableContracts.isNotEmpty;
        
        if (!authProvider.isLoggedIn) {
          return _buildLoginRequiredView();
        }
        
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              "Ratings & Reviews",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_selectedTab == 1 && hasRateableContracts)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed: () => _showRateableContracts(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Rate Contract',
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            backgroundColor: Colors.black,
            color: Color(0xFF2563EB),
            onRefresh: () async {
              final currentUserId = _getCurrentUserId();
              await ratingProvider.fetchMyRatings(currentUserId);
              if (_selectedTab == 1) {
                await ratingProvider.fetchRateableContracts(currentUserId);
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.black,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            index: 0,
                            icon: Icons.star_rate_rounded,
                            label: 'Received',
                            isSelected: _selectedTab == 0,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey[800],
                        ),
                        Expanded(
                          child: _buildTabButton(
                            index: 1,
                            icon: Icons.rate_review_rounded,
                            label: 'Given',
                            isSelected: _selectedTab == 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // REMOVED the direct display of rateable contracts banner
                // They will now show up in the filteredRatings list

                if (ratingProvider.error != null && filteredRatings.isEmpty && !ratingProvider.isLoading)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.redAccent.withOpacity(0.1),
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
                            icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                            onPressed: () => ratingProvider.clearError(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (filteredRatings.isNotEmpty && _selectedTab == 0) // Only show stats for Received tab
                  SliverToBoxAdapter(
                    child: _buildRatingStats(ratingProvider, filteredRatings),
                  ),

                if (ratingProvider.isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading ratings...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (ratingProvider.error != null && filteredRatings.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                ratingProvider.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                ratingProvider.clearError();
                                _initializeData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (filteredRatings.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(_selectedTab, hasRateableContracts),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final rawRating = filteredRatings[index];
                          
                          Map<String, dynamic> rating;
                          try {
                            if (rawRating is Map) {
                              rating = _safeMapConvert(rawRating);
                            } else {
                              rating = {'display_score': 0.0, 'display_name': 'Unknown'};
                            }
                            
                            final isRateableContract = rating['is_rateable_contract'] == true;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: isRateableContract 
                                  ? _buildRateableContractCard(rating) 
                                  : _buildRatingCard(rating),
                            );
                          } catch (e) {
                            debugPrint('❌ Error converting rating at index $index: $e');
                            return Container(
                              color: Colors.red[900],
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(8),
                              child: Text(
                                'Error loading rating: $e',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                        },
                        childCount: filteredRatings.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // REMOVED: FloatingActionButton (debug button)
        );
      },
    );
  }

  // NEW: Widget for rateable contract cards
  Widget _buildRateableContractCard(Map<String, dynamic> contract) {
    final taskTitle = contract['task_title'] ?? 'Untitled Task';
    final clientName = contract['client_name'] ?? 'Client';
    final budget = contract['budget'] ?? '0.00';
    final status = contract['status'] ?? 'completed';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF60A5FA),
                        ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2563EB).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_outline,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Not Rated',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          Text(
                            taskTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'KES $budget',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // "Rate Now" button for rateable contracts
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _navigateToSubmitRating({
                        'contract_id': contract['contract_id'],
                        'task': {
                          'id': contract['task_id'],
                          'title': contract['task_title'],
                          'budget': contract['budget'],
                        },
                        'client': {
                          'id': contract['client_id'],
                          'name': contract['client_name'],
                        },
                        'status': contract['status'],
                      });
                    },
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('Rate This Client'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildLoginRequiredView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Ratings & Reviews",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Icon(
                  Icons.person_off_outlined,
                  size: 60,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please login to view and manage your ratings & reviews",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  // Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int selectedTab, bool hasRateableContracts) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Icon(
                selectedTab == 0 ? Icons.star_outline : Icons.rate_review_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              selectedTab == 0 
                  ? "No Ratings Received Yet"
                  : "No Ratings Given Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                selectedTab == 0
                    ? "Complete your first contract to receive ratings from clients"
                    : hasRateableContracts
                        ? "You have contracts waiting for your review"
                        : "Complete contracts to rate your experience",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ),
            if (selectedTab == 1 && hasRateableContracts) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _showRateableContracts(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('Start Rating'),
              ),
            ],
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
        splashColor: Color(0xFF2563EB).withOpacity(0.1),
        highlightColor: Color(0xFF2563EB).withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xFF2563EB) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Color(0xFF2563EB) : Colors.grey[500],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Color(0xFF2563EB) : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRatingCard(Map<String, dynamic> rating) {
  final dynamic scoreData = rating['display_score'] ?? rating['score'] ?? 0;
  double score = 0.0;
  if (scoreData is num) {
    score = scoreData.toDouble();
  } else if (scoreData is String) {
    score = double.tryParse(scoreData) ?? 0.0;
  }
  
  final String displayName = (rating['display_name'] ?? 'Unknown').toString();
  final bool isRateableContract = rating['is_rateable_contract'] == true;
  
  String taskTitle = 'Task';
  final dynamic titleData = rating['display_title'] ?? rating['task_title'];
  if (titleData != null) {
    taskTitle = titleData.toString();
  }
  
  final String review = (rating['display_review'] ?? rating['review'] ?? '').toString();
  
  String dateStr = 'Recent';
  final dynamic dateData = rating['date'] ?? rating['created_at'];
  if (dateData != null && dateData.toString().isNotEmpty) {
    try {
      final date = DateTime.parse(dateData.toString());
      dateStr = DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      dateStr = dateData.toString();
    }
  }
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[800]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRateableContract
                            ? [Colors.orange, Colors.amber]
                            : [Color(0xFF2563EB), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isRateableContract ? Icons.person_add : Icons.person,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRateableContract
                                    ? Colors.orange.withOpacity(0.2)
                                    : Color(0xFF2563EB).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isRateableContract 
                                        ? Icons.star_outline 
                                        : Icons.star_rounded,
                                    size: 14,
                                    color: isRateableContract 
                                        ? Colors.orange 
                                        : Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRateableContract 
                                        ? 'Rate Now'
                                        : score.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isRateableContract 
                                          ? Colors.orange 
                                          : Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        Text(
                          taskTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            if (!isRateableContract) ...[
                              Wrap(
                                spacing: 0,
                                runSpacing: 0,
                                children: List.generate(5, (starIndex) {
                                  final isFilled = starIndex < score.floor();
                                  final isHalf = starIndex == score.floor() && (score % 1) >= 0.5;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      isFilled 
                                        ? Icons.star_rounded
                                        : isHalf
                                          ? Icons.star_half_rounded
                                          : Icons.star_border_rounded,
                                      size: 16,
                                      color: Color(0xFFFFB020),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                            ],
                            
                            Expanded(
                              child: Text(
                                isRateableContract 
                                    ? 'Ready to rate • Completed'
                                    : dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRateableContract 
                                      ? Colors.orange 
                                      : Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // For rateable contracts, show a prominent "Rate Now" button
              if (isRateableContract) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _navigateToSubmitRating({
                        'contract_id': rating['contract_id'],
                        'task': {
                          'id': rating['task_id'],
                          'title': rating['task_title'],
                          'budget': rating['budget'],
                        },
                        'client': {
                          'id': rating['client_id'],
                          'name': rating['client_name'],
                        },
                        'status': rating['status'],
                      });
                    },
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('Rate This Client'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              
              // Review text (only for actual ratings)
              if (!isRateableContract && review.isNotEmpty && review != 'null' && review != 'No review provided') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[200],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
} 


  Widget _buildRatingStats(RatingProvider provider, List<dynamic> ratings) {
    double totalScore = 0.0;
    int count = 0;
    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    
    for (final rawRating in ratings) {
      try {
        Map<String, dynamic> rating;
        if (rawRating is Map) {
          rating = _safeMapConvert(rawRating);
        } else {
          continue;
        }
        
        final score = _extractScore(rating);
        totalScore += score;
        count++;
        
        final int starRating = score.round();
        if (starRating >= 1 && starRating <= 5) {
          starCounts[starRating] = (starCounts[starRating] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('❌ Error processing rating in stats: $e');
      }
    }
    
    final double averageRating = count > 0 ? totalScore / count : 0.0;
    final int totalRatings = count;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.grey[900]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2563EB).withOpacity(0.2),
                        Color(0xFF60A5FA).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB020),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Average Rating',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF10B981).withOpacity(0.2),
                        Color(0xFF34D399).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rate_review_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Ratings',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalRatings.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (totalRatings > 0) ...[
            Text(
              'Star Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Column(
              children: List.generate(5, (index) {
                final starRating = 5 - index;
                final count = starCounts[starRating] ?? 0;
                final percentage = totalRatings > 0 ? (count / totalRatings * 100) : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$starRating',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: _getStarColor(starRating),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStarColor(starRating),
                                    _getStarColor(starRating).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[300],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).reversed.toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStarColor(int starRating) {
    switch (starRating) {
      case 5: return Color(0xFF10B981);
      case 4: return Color(0xFF22C55E);
      case 3: return Color(0xFFF59E0B);
      case 2: return Color(0xFFF97316);
      case 1: return Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }
}

// ============ DETAILED CLIENT RATING DIALOG ============

class _DetailedClientRatingDialog extends StatefulWidget {
  final int contractId;
  final int taskId;
  final int clientId;
  final String clientName;
  final String taskTitle;
  final int freelancerId;
  final VoidCallback onRatingSubmitted;

  const _DetailedClientRatingDialog({
    required this.contractId,
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.taskTitle,
    required this.freelancerId,
    required this.onRatingSubmitted,
  });
  
  int get userId => freelancerId; // Fixed: Return freelancerId as userId

  @override
  State<_DetailedClientRatingDialog> createState() => _DetailedClientRatingDialogState();
}

class _DetailedClientRatingDialogState extends State<_DetailedClientRatingDialog> {
  int _currentStep = 0;
  int _overallRating = 3;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  
  final Map<ClientRatingCategory, int> _categoryRatings = {};
  final Set<ClientPerformanceTag> _selectedTags = {};
  bool? _wouldWorkAgain;
  bool _submitAnonymously = false;
  
  final List<String> _stepTitles = [
    "Overall Experience",
    "Detailed Assessment",
    "Strengths & Final Review",
    "Submit Rating"
  ];
  
  @override
  void initState() {
    super.initState();
    for (var category in ClientRatingCategory.values) {
      _categoryRatings[category] = 0;
    }
  }

  List<ClientRatingCategory> get _applicableCategories => ClientRatingCategory.values;

  double get _calculatedCompositeScore {
    final ratedCategories = _categoryRatings.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.value)
        .toList();
    
    if (ratedCategories.isEmpty) return _overallRating.toDouble();
    
    final sum = ratedCategories.fold(0, (a, b) => a + b);
    return sum / ratedCategories.length;
  }

  int get _primaryRating => _calculatedCompositeScore.round();

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF2563EB);
    
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _stepTitles[_currentStep],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rating: ${widget.clientName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Task: ${widget.taskTitle}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_stepTitles.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < _stepTitles.length - 1 ? 4 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= _currentStep 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _currentStep == 0 ? "Cancel" : "Back",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  
                  if (_currentStep == _stepTitles.length - 1)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _submitRating,
                      child: Text(
                        _isSubmitting ? "Submitting..." : "Submit Rating",
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : () {
                        if (_canProceedToNextStep()) {
                          setState(() => _currentStep++);
                        }
                      },
                      child: const Text("Next"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOverallExperienceStep();
      case 1:
        return _buildDetailedAssessmentStep();
      case 2:
        return _buildStrengthsStep();
      case 3:
        return _buildReviewStep();
      default:
        return _buildOverallExperienceStep();
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _overallRating > 0;
      case 1:
        final ratedCount = _categoryRatings.values.where((rating) => rating > 0).length;
        return ratedCount >= 3;
      case 2:
        return _wouldWorkAgain != null;
      default:
        return true;
    }
  }

  Widget _buildOverallExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Experience",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "How was your overall experience working with ${widget.clientName}?",
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                size: 48,
                color: index < _overallRating ? Color(0xFFFFB020) : Colors.grey[600],
              ),
              onPressed: _isSubmitting ? null : () {
                setState(() {
                  _overallRating = index + 1;
                  _categoryRatings[ClientRatingCategory.communication] = _overallRating;
                  _categoryRatings[ClientRatingCategory.professionalism] = _overallRating;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        
        Center(
          child: Text(
            _getRatingDescription(_overallRating),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[300]),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2563EB)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Next, you'll rate specific aspects like communication, payment promptness, and professionalism.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAssessmentStep() {
    final ratedCount = _categoryRatings.values.where((rating) => rating > 0).length;
    final totalCategories = _applicableCategories.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detailed Assessment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "Rate ${widget.clientName} across key performance dimensions",
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        
        ..._applicableCategories.map((category) => _buildCategoryCard(category)),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                ratedCount >= 3 ? Icons.check_circle : Icons.info,
                size: 16,
                color: ratedCount >= 3 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ratedCount >= 3 
                      ? "Great! You've rated $ratedCount out of $totalCategories categories"
                      : "Rate at least 3 categories to continue ($ratedCount/$totalCategories)",
                  style: TextStyle(
                    fontSize: 12,
                    color: ratedCount >= 3 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ClientRatingCategory category) {
    final score = _categoryRatings[category] ?? 0;
    
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 50,
                    child: InkWell(
                      onTap: _isSubmitting ? null : () {
                        setState(() {
                          _categoryRatings[category] = rating;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: score == rating 
                              ? Color(0xFF2563EB).withOpacity(0.2)
                              : Colors.grey[800],
                          border: Border.all(
                            color: score == rating 
                                ? Color(0xFF2563EB) 
                                : Colors.grey[700]!,
                            width: score == rating ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.star,
                              size: 20,
                              color: score == rating 
                                  ? Color(0xFFFFB020) 
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: score == rating 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: score == rating 
                                    ? Color(0xFF2563EB) 
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            if (score > 0) ...[
              const SizedBox(height: 8),
              Text(
                _getCategoryDescription(category, score),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryDescription(ClientRatingCategory category, int score) {
    switch (category) {
      case ClientRatingCategory.communication:
        switch (score) {
          case 1: return "Poor communicator, unclear requirements";
          case 2: return "Occasional communication gaps";
          case 3: return "Adequate communication";
          case 4: return "Good, clear communication";
          case 5: return "Excellent, proactive communicator";
          default: return "";
        }
      case ClientRatingCategory.paymentPromptness:
        switch (score) {
          case 1: return "Late payments, payment issues";
          case 2: return "Sometimes delayed payments";
          case 3: return "Pays on agreed schedule";
          case 4: return "Prompt payments, reliable";
          case 5: return "Exceptional, pays early/bonuses";
          default: return "";
        }
      case ClientRatingCategory.requirementsClarity:
        switch (score) {
          case 1: return "Constantly changing, unclear requirements";
          case 2: return "Some ambiguity in requirements";
          case 3: return "Reasonably clear requirements";
          case 4: return "Well-defined requirements";
          case 5: return "Exceptionally clear and detailed requirements";
          default: return "";
        }
      default:
        return "";
    }
  }

  Widget _buildStrengthsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Strengths & Recommendations",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "Select what ${widget.clientName} did well and provide strategic feedback",
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        
        const Text(
          "Client Strengths",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClientPerformanceTag.values.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              label: Text(
                tag.displayName,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              onSelected: _isSubmitting ? null : (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: Color(0xFF2563EB).withOpacity(0.3),
              checkmarkColor: Color(0xFF2563EB),
              side: BorderSide(
                color: isSelected ? Color(0xFF2563EB) : Colors.grey[700]!,
                width: isSelected ? 1.5 : 1,
              ),
              backgroundColor: Colors.grey[900],
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Would you work with this client again?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () {
                          setState(() => _wouldWorkAgain = true);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _wouldWorkAgain == true 
                                ? Colors.green 
                                : Colors.grey[700]!,
                            width: _wouldWorkAgain == true ? 2 : 1,
                          ),
                          backgroundColor: _wouldWorkAgain == true 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey[900],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _wouldWorkAgain == true 
                                ? Colors.green 
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () {
                          setState(() => _wouldWorkAgain = false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _wouldWorkAgain == false 
                                ? Colors.red 
                                : Colors.grey[700]!,
                            width: _wouldWorkAgain == false ? 2 : 1,
                          ),
                          backgroundColor: _wouldWorkAgain == false 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey[900],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "No",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _wouldWorkAgain == false 
                                ? Colors.red 
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          child: CheckboxListTile(
            title: const Text(
              "Submit feedback anonymously",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            subtitle: Text(
              "Your feedback will be visible but your identity will remain private",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            value: _submitAnonymously,
            onChanged: _isSubmitting ? null : (value) {
              setState(() => _submitAnonymously = value ?? false);
            },
            activeColor: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final ratedCategories = _categoryRatings.entries
        .where((entry) => entry.value > 0)
        .length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Your Feedback",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "Review your assessment before submitting",
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFF2563EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Overall Performance Score",
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                Text(
                  _calculatedCompositeScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 24,
                      color: index < _primaryRating 
                          ? Color(0xFFFFB020) 
                          : Colors.grey[600],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  "Based on $ratedCategories category rating${ratedCategories != 1 ? 's' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (ratedCategories > 0) ...[
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._categoryRatings.entries
              .where((entry) => entry.value > 0)
              .map((entry) => _buildReviewCategoryItem(entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        
        if (_selectedTags.isNotEmpty) ...[
          const Text(
            "Client Strengths",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag.displayName, style: const TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: Color(0xFF2563EB).withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        if (_wouldWorkAgain != null) ...[
          Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recommendation",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildReviewDecisionItem(
                    "Work with again",
                    _wouldWorkAgain == true ? "Yes" : "No",
                    _wouldWorkAgain == true ? Colors.green : Colors.orange,
                  ),
                  if (_submitAnonymously) ...[
                    const SizedBox(height: 8),
                    _buildReviewDecisionItem(
                      "Submission type",
                      "Anonymous",
                      Color(0xFF2563EB),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        const Text(
          "Additional Comments (Optional):",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Add any additional comments about working with ${widget.clientName}...",
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            fillColor: Colors.grey[900],
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
          enabled: !_isSubmitting,
        ),
        
        const SizedBox(height: 16),
        
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.orange),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "This rating helps other freelancers understand what to expect when working with this client.",
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCategoryItem(ClientRatingCategory category, int score) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.displayName,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: index < score 
                        ? Color(0xFFFFB020) 
                        : Colors.grey[600],
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  "$score/5",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewDecisionItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            constraints: const BoxConstraints(minWidth: 60),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Very difficult to work with';
      case 2:
        return 'Below Average - Several issues during collaboration';
      case 3:
        return 'Average - Standard client experience';
      case 4:
        return 'Good - Good to work with, minor improvements needed';
      case 5:
        return 'Excellent - Exceptional client, would gladly work with again';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
      
      // Prepare extended data with categories
      final Map<String, dynamic> extendedData = {};
      extendedData['work_type'] = 'client_rating_from_freelancer';
      
      // Add category scores
      final Map<String, int> categoryScoresMap = {};
      _categoryRatings.forEach((category, score) {
        if (score > 0) {
          categoryScoresMap[category.name] = score;
        }
      });
      if (categoryScoresMap.isNotEmpty) {
        extendedData['category_scores'] = categoryScoresMap;
      }
      
      // Add performance tags
      if (_selectedTags.isNotEmpty) {
        extendedData['performance_tags'] = _selectedTags.map((tag) => tag.name).toList();
      }
      
      // Add recommendations
      if (_wouldWorkAgain != null) {
        extendedData['would_work_again'] = _wouldWorkAgain;
      }
      if (_submitAnonymously) {
        extendedData['anonymous_submission'] = true;
      }
      
      extendedData['calculated_composite'] = _calculatedCompositeScore;
      
      // Build review text
      String reviewText = _reviewController.text.trim();
      if (extendedData.isNotEmpty) {
        final jsonData = jsonEncode(extendedData);
        if (reviewText.isNotEmpty) {
          reviewText = "$reviewText\n\n__EXTENDED_DATA__:$jsonData";
        } else {
          reviewText = "__EXTENDED_DATA__:$jsonData";
        }
      }
      
      // Call the rating provider to submit
      await ratingProvider.submitClientRating(
        userId: widget.freelancerId,
        taskId: widget.taskId,
        clientId: widget.clientId,
        score: _primaryRating,
        review: reviewText,
        freelancerId: widget.freelancerId,
        task: {
          'id': widget.taskId,
          'title': widget.taskTitle,
        },
        extendedData: extendedData,
      );
      
      // Success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating submitted successfully for ${widget.clientName}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onRatingSubmitted();
      }
      
    } catch (e) {
      debugPrint('❌ Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}