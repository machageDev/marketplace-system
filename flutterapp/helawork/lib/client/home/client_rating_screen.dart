import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_rating_provider.dart';
import 'package:provider/provider.dart';

// Performance Tags Enum
enum FreelancerPerformanceTag {
  exceededExpectations,     // Delivered beyond scope
  flawlessExecution,        // Zero errors/issues
  exceptionalCommunication, // Proactive, clear updates
  earlyDelivery,           // Completed ahead of schedule
  technicalExpertise,      // Demonstrated advanced skills
  creativeSolutions,       // Innovative problem-solving
  collaborativePartner,    // Team-oriented approach
  autonomousWorker,        // Required minimal oversight
  detailOriented,          // Meticulous attention to specifics
  reliableProfessional,    // Consistent, dependable performance
  quickLearner,           // Rapidly adapted to requirements
  costEffective,          // Exceptional value for investment
  
  // ONSITE-SPECIFIC TAGS
  punctualArrival,         // Arrived on time or early
  professionalAppearance,  // Appropriate attire and grooming
  excellentClientInteraction, // Professional interaction with client/staff
  properEquipment,         // Brought necessary tools/equipment
  siteCleanup,            // Cleaned up work area after completion
  safetyCompliance,        // Followed all safety protocols
  locationFlexibility,     // Adapted well to onsite environment
}

// Rating Categories
enum RatingCategory {
  workQuality,          // Work Quality & Craftsmanship
  communication,        // Communication Proficiency
  deadlineAdherence,    // Deadline Adherence & Time Management
  professionalConduct,  // Professional Conduct
  technicalExpertise,   // Technical Expertise
  problemSolving,       // Problem-Solving Agility
  valueProposition,     // Value Proposition
  
  // ONSITE-SPECIFIC CATEGORIES
  punctuality,          // Onsite: Punctuality & Arrival Time
  onsiteProfessionalism, // Onsite: Professionalism at location
  siteCoordination,     // Onsite: Coordination with onsite requirements
  safetyProtocols,      // Onsite: Safety compliance
}

extension RatingCategoryExtension on RatingCategory {
  String get displayName {
    switch (this) {
      case RatingCategory.workQuality:
        return 'Work Quality';
      case RatingCategory.communication:
        return 'Communication';
      case RatingCategory.deadlineAdherence:
        return 'Deadline Adherence';
      case RatingCategory.professionalConduct:
        return 'Professional Conduct';
      case RatingCategory.technicalExpertise:
        return 'Technical Expertise';
      case RatingCategory.problemSolving:
        return 'Problem-Solving';
      case RatingCategory.valueProposition:
        return 'Value Proposition';
      case RatingCategory.punctuality:
        return 'Punctuality';
      case RatingCategory.onsiteProfessionalism:
        return 'Onsite Professionalism';
      case RatingCategory.siteCoordination:
        return 'Site Coordination';
      case RatingCategory.safetyProtocols:
        return 'Safety Compliance';
    }
  }

  String get description {
    switch (this) {
      case RatingCategory.workQuality:
        return 'Technical excellence, attention to detail';
      case RatingCategory.communication:
        return 'Responsiveness, clarity, proactivity';
      case RatingCategory.deadlineAdherence:
        return 'Punctuality, milestone completion';
      case RatingCategory.professionalConduct:
        return 'Ethics, transparency, business etiquette';
      case RatingCategory.technicalExpertise:
        return 'Skill mastery, tool proficiency, innovation';
      case RatingCategory.problemSolving:
        return 'Solution orientation, adaptability, creativity';
      case RatingCategory.valueProposition:
        return 'Cost-effectiveness, ROI, efficiency';
      case RatingCategory.punctuality:
        return 'Arrival time, schedule adherence';
      case RatingCategory.onsiteProfessionalism:
        return 'Appearance, behavior at location';
      case RatingCategory.siteCoordination:
        return 'Adaptation to onsite environment';
      case RatingCategory.safetyProtocols:
        return 'Following safety rules and protocols';
    }
  }

  String getAnchorDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Significantly below expectations';
      case 2:
        return 'Below Average - Some concerns';
      case 3:
        return 'Average - Met basic requirements';
      case 4:
        return 'Good - Exceeded expectations';
      case 5:
        return 'Exceptional - Far exceeded all expectations';
      default:
        return '';
    }
  }
}

extension PerformanceTagExtension on FreelancerPerformanceTag {
  String get displayName {
    switch (this) {
      case FreelancerPerformanceTag.exceededExpectations:
        return 'Exceeded Expectations';
      case FreelancerPerformanceTag.flawlessExecution:
        return 'Flawless Execution';
      case FreelancerPerformanceTag.exceptionalCommunication:
        return 'Exceptional Communication';
      case FreelancerPerformanceTag.earlyDelivery:
        return 'Early Delivery';
      case FreelancerPerformanceTag.technicalExpertise:
        return 'Technical Expertise';
      case FreelancerPerformanceTag.creativeSolutions:
        return 'Creative Solutions';
      case FreelancerPerformanceTag.collaborativePartner:
        return 'Collaborative Partner';
      case FreelancerPerformanceTag.autonomousWorker:
        return 'Autonomous Worker';
      case FreelancerPerformanceTag.detailOriented:
        return 'Detail Oriented';
      case FreelancerPerformanceTag.reliableProfessional:
        return 'Reliable Professional';
      case FreelancerPerformanceTag.quickLearner:
        return 'Quick Learner';
      case FreelancerPerformanceTag.costEffective:
        return 'Cost Effective';
      case FreelancerPerformanceTag.punctualArrival:
        return 'Punctual Arrival';
      case FreelancerPerformanceTag.professionalAppearance:
        return 'Professional Appearance';
      case FreelancerPerformanceTag.excellentClientInteraction:
        return 'Excellent Client Interaction';
      case FreelancerPerformanceTag.properEquipment:
        return 'Proper Equipment';
      case FreelancerPerformanceTag.siteCleanup:
        return 'Site Cleanup';
      case FreelancerPerformanceTag.safetyCompliance:
        return 'Safety Compliance';
      case FreelancerPerformanceTag.locationFlexibility:
        return 'Location Flexibility';
    }
  }
  
  bool get isOnsiteSpecific {
    return [
      FreelancerPerformanceTag.punctualArrival,
      FreelancerPerformanceTag.professionalAppearance,
      FreelancerPerformanceTag.excellentClientInteraction,
      FreelancerPerformanceTag.properEquipment,
      FreelancerPerformanceTag.siteCleanup,
      FreelancerPerformanceTag.safetyCompliance,
      FreelancerPerformanceTag.locationFlexibility,
    ].contains(this);
  }
}

class ClientRatingScreen extends StatefulWidget {
  final int employerId;
  const ClientRatingScreen({super.key, required this.employerId});

  @override
  State<ClientRatingScreen> createState() => _ClientRatingScreenState();
}

class _ClientRatingScreenState extends State<ClientRatingScreen> {
  final Color blue = const Color(0xFF007BFF);
  final Color white = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientRatingProvider>(context, listen: false)
          .fetchEmployerRateableTasks();
    });
  }

  void _showRatingDialog(BuildContext context, dynamic task) {
    final ratingProvider = Provider.of<ClientRatingProvider>(context, listen: false);
    final isOnsite = ratingProvider.isOnsiteTask(task);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _RatingDialogContent(
          task: task,
          employerId: widget.employerId,
          ratingProvider: ratingProvider,
          blue: blue,
          isOnsite: isOnsite,
        );
      },
    );
  }

  void _showEmployerRatings(BuildContext context, dynamic task) {
    final employer = task['employer'];
    if (employer == null) return;
    
    final employerId = employer['id'];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        title: Text("How Freelancers Rated Me", style: TextStyle(color: blue)),
        content: FutureBuilder(
          future: Provider.of<ClientRatingProvider>(context, listen: false)
              .getEmployerRatings(employerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("No ratings received yet", style: TextStyle(color: Colors.grey));
            }
            
            final ratings = snapshot.data!;
            return _buildEmployerRatingsList(ratings);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerRatingsList(List<dynamic> ratings) {
    double averageRating = 0;
    if (ratings.isNotEmpty) {
      final total = ratings.fold<int>(0, (sum, rating) => sum + (rating['score'] as int));
      averageRating = total / ratings.length;
    }

    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Card(
            color: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: blue.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Average Rating",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blue),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (starIndex) => Icon(
                        Icons.star,
                        size: 20,
                        color: starIndex < averageRating.round() ? Colors.amber : Colors.grey,
                      )),
                    ],
                  ),
                  Text(
                    "Based on ${ratings.length} rating${ratings.length == 1 ? '' : 's'}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                final rating = ratings[index];
                final extendedData = _extractExtendedData(rating['review'] ?? '');
                final isOnsiteRating = extendedData['work_type'] == 'onsite';
                
                return Card(
                  color: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isOnsiteRating)
                              Icon(Icons.location_on, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            ...List.generate(5, (starIndex) => Icon(
                              Icons.star,
                              size: 16,
                              color: starIndex < (rating['score'] as int) ? Colors.amber : Colors.grey,
                            )),
                            const Spacer(),
                            Text(
                              "${rating['score']}/5",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Task: ${rating['task']?['title'] ?? 'Unknown Task'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "From: ${rating['freelancer']?['name'] ?? 'Freelancer'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (rating['review'] != null && rating['review'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _cleanReviewText(rating['review']),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _cleanReviewText(String review) {
    final extendedDataMatch = RegExp(r'__EXTENDED_DATA__:\{.*\}').firstMatch(review);
    if (extendedDataMatch != null) {
      return review.substring(0, extendedDataMatch.start).trim();
    }
    return review;
  }
  
  Map<String, dynamic> _extractExtendedData(String review) {
    try {
      final match = RegExp(r'__EXTENDED_DATA__:(.*)').firstMatch(review);
      if (match != null) {
        final jsonString = match.group(1);
        return jsonDecode(jsonString!) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error extracting extended data: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text("Rate Completed Work"),
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: true,
      ),
      body: Consumer<ClientRatingProvider>(
        builder: (context, provider, child) {
          final tasks = provider.tasksForRating;
          final taskCount = tasks.length;

          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading completed tasks...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 70, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(
                    "Error Loading Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    onPressed: () {
                      Provider.of<ClientRatingProvider>(context, listen: false)
                          .fetchEmployerRateableTasks();
                    },
                    child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (taskCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_turned_in, size: 70, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Completed Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You don't have any completed tasks ready for rating.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Back to Tasks", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rate Freelancer Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rate freelancers based on their work quality, communication, and professionalism",
                      style: TextStyle(
                        fontSize: 12,
                        color: white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: taskCount,
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= taskCount) {
                      return _buildErrorCard("Invalid task data at index $index");
                    }
                    
                    final task = tasks[index];
                    
                    if (task == null) {
                      return _buildErrorCard("Task data is null at index $index");
                    }
                    
                    return _buildTaskCard(task, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(dynamic task, ClientRatingProvider provider) {
    final freelancerName = task['freelancer']?['username'] ?? 
                          task['assigned_user']?['username'] ?? 
                          task['contract']?['freelancer']?['username'] ?? 
                          'Unknown Freelancer';
    
    final isOnsite = provider.isOnsiteTask(task);
    
    return Card(
      color: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: blue.withOpacity(0.3)),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isOnsite)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "ONSITE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isOnsite)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: blue),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.computer, size: 12, color: blue),
                        const SizedBox(width: 4),
                        Text(
                          "REMOTE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task['title'] ?? 'Untitled Task',
              style: TextStyle(
                color: blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task['description'] ?? 'No description provided',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: blue.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Completed by: $freelancerName",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _showRatingDialog(context, task),
                  child: Text(
                    isOnsite ? "Rate Onsite" : "Rate Work",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: blue),
                    foregroundColor: blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showEmployerRatings(context, task),
                  child: Text(
                    "My Ratings",
                    style: TextStyle(color: blue, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingDialogContent extends StatefulWidget {
  final dynamic task;
  final int employerId;
  final ClientRatingProvider ratingProvider;
  final Color blue;
  final bool isOnsite;

  const _RatingDialogContent({
    required this.task,
    required this.employerId,
    required this.ratingProvider,
    required this.blue,
    required this.isOnsite,
  });

  @override
  State<_RatingDialogContent> createState() => _RatingDialogContentState();
}

class _RatingDialogContentState extends State<_RatingDialogContent> {
  int selectedRating = 3;
  final TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false;
  int currentStep = 0;
  Map<RatingCategory, int> categoryScores = {};
  Set<FreelancerPerformanceTag> selectedTags = {};
  bool? wouldRecommend;
  bool? wouldRehire;
  bool submitAnonymously = false;
  
  // ONSITE-SPECIFIC FIELDS
  int punctualityScore = 3;
  int onSiteProfessionalismScore = 3;
  int safetyComplianceScore = 3;
  int siteCoordinationScore = 3;
  
  @override
  void initState() {
    super.initState();
    // Initialize all categories
    for (var category in RatingCategory.values) {
      categoryScores[category] = 0;
    }
    
    // For remote tasks, initialize with selected rating
    if (!widget.isOnsite) {
      categoryScores[RatingCategory.workQuality] = selectedRating;
      categoryScores[RatingCategory.communication] = selectedRating;
      categoryScores[RatingCategory.deadlineAdherence] = selectedRating;
      categoryScores[RatingCategory.professionalConduct] = selectedRating;
    }
  }

  List<RatingCategory> get _applicableCategories {
    if (widget.isOnsite) {
      return [
        RatingCategory.punctuality,
        RatingCategory.onsiteProfessionalism,
        RatingCategory.safetyProtocols,
        RatingCategory.siteCoordination,
        RatingCategory.workQuality,
        RatingCategory.communication,
        RatingCategory.professionalConduct,
      ];
    } else {
      return RatingCategory.values.where((cat) => ![
        RatingCategory.punctuality,
        RatingCategory.onsiteProfessionalism,
        RatingCategory.safetyProtocols,
        RatingCategory.siteCoordination,
      ].contains(cat)).toList();
    }
  }

  List<FreelancerPerformanceTag> get _applicableTags {
    if (widget.isOnsite) {
      return FreelancerPerformanceTag.values;
    } else {
      return FreelancerPerformanceTag.values
          .where((tag) => !tag.isOnsiteSpecific)
          .toList();
    }
  }

  double get calculatedCompositeScore {
    final applicableCategories = _applicableCategories;
    final ratedScores = categoryScores.entries
        .where((entry) => applicableCategories.contains(entry.key) && entry.value > 0)
        .map((entry) => entry.value)
        .toList();
    
    if (ratedScores.isEmpty) return selectedRating.toDouble();
    
    final sum = ratedScores.fold(0, (a, b) => a + b);
    return sum / ratedScores.length;
  }

  int get primaryRating => calculatedCompositeScore.round();

  @override
  Widget build(BuildContext context) {
    final freelancerName = widget.task['freelancer']?['username'] ?? 
                          widget.task['assigned_user']?['username'] ?? 
                          widget.task['contract']?['freelancer']?['username'] ?? 
                          'the freelancer';
    final freelancerId = widget.task['freelancer']?['id'] ?? 
                        widget.task['assigned_user']?['id'] ?? 
                        widget.task['contract']?['freelancer']?['id'];
    
    final stepTitles = widget.isOnsite
        ? [
            "Onsite Service Rating",
            "Detailed Assessment",
            "Review & Submit"
          ]
        : [
            "Overall Satisfaction",
            "Detailed Performance",
            "Strengths & Recommendations",
            "Review & Submit"
          ];
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isOnsite)
                        Icon(Icons.location_on, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.isOnsite ? "ONSITE SERVICE RATING" : "REMOTE WORK RATING",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepTitles[currentStep],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task['title'] ?? 'Task',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Completed by: $freelancerName",
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(stepTitles.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < stepTitles.length - 1 ? 4 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= currentStep 
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                  ),
                  child: _buildStepContent(freelancerName),
                ),
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
                    onPressed: isSubmitting ? null : () {
                      if (currentStep > 0) {
                        setState(() => currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(currentStep == 0 ? "Cancel" : "Back"),
                  ),
                  
                  if (currentStep == stepTitles.length - 1)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: isSubmitting ? null : () => _submitRating(freelancerId),
                      child: Text(
                        isSubmitting ? "Submitting..." : "Submit Rating",
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: isSubmitting ? null : () {
                        if (_canProceedToNextStep()) {
                          setState(() => currentStep++);
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
  
  Widget _buildStepContent(String freelancerName) {
    if (widget.isOnsite) {
      switch (currentStep) {
        case 0:
          return _buildOnsiteInitialStep();
        case 1:
          return _buildOnsiteDetailedStep();
        case 2:
          return _buildReviewStep();
        default:
          return _buildOnsiteInitialStep();
      }
    } else {
      switch (currentStep) {
        case 0:
          return _buildRemoteInitialStep();
        case 1:
          return _buildRemoteDetailedStep();
        case 2:
          return _buildRemoteTagsStep();
        case 3:
          return _buildReviewStep();
        default:
          return _buildRemoteInitialStep();
      }
    }
  }
  
  bool _canProceedToNextStep() {
    if (widget.isOnsite) {
      switch (currentStep) {
        case 0:
          return selectedRating > 0;
        case 1:
          return true;
        case 2:
          return true;
        default:
          return false;
      }
    } else {
      switch (currentStep) {
        case 0:
          return selectedRating > 0;
        case 1:
          return true;
        case 2:
          return wouldRecommend != null && wouldRehire != null;
        case 3:
          return true;
        default:
          return false;
      }
    }
  }
  
  // ONSITE STEP WIDGETS
  
  Widget _buildOnsiteInitialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rate the Onsite Service",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "How satisfied are you with the freelancer's onsite service?",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                size: 48,
                color: index < selectedRating ? Colors.amber : Colors.grey[300],
              ),
              onPressed: isSubmitting ? null : () {
                setState(() {
                  selectedRating = index + 1;
                  punctualityScore = selectedRating;
                  onSiteProfessionalismScore = selectedRating;
                  categoryScores[RatingCategory.punctuality] = selectedRating;
                  categoryScores[RatingCategory.onsiteProfessionalism] = selectedRating;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "$selectedRating / 5 Stars",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.blue,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.green),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Next, you'll rate specific onsite performance aspects including punctuality, professionalism, and safety compliance.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOnsiteDetailedStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Onsite Performance Details",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Rate specific aspects of the freelancer's onsite service.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        
        // Onsite-specific categories
        ..._applicableCategories.map((category) {
          if (category == RatingCategory.punctuality ||
              category == RatingCategory.onsiteProfessionalism ||
              category == RatingCategory.safetyProtocols ||
              category == RatingCategory.siteCoordination) {
            return _buildOnsiteCategoryCard(category);
          }
          return _buildCategoryRatingCard(category);
        }).toList(),
        
        const SizedBox(height: 16),
        const Text(
          "Performance Highlights",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Select what this freelancer did well during onsite service:",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _applicableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              label: Text(
                tag.displayName,
                style: const TextStyle(fontSize: 12),
              ),
              onSelected: isSubmitting ? null : (selected) {
                setState(() {
                  if (selected) {
                    selectedTags.add(tag);
                  } else {
                    selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: widget.blue.withOpacity(0.2),
              checkmarkColor: widget.blue,
              side: BorderSide(
                color: isSelected ? widget.blue : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildOnsiteCategoryCard(RatingCategory category) {
    final score = categoryScores[category] ?? 3;
    
    String getDescription(int rating) {
      switch (category) {
        case RatingCategory.punctuality:
          switch (rating) {
            case 1: return "Arrived significantly late or not at all";
            case 2: return "Arrived somewhat late";
            case 3: return "Arrived on time as scheduled";
            case 4: return "Arrived slightly early";
            case 5: return "Arrived early and well-prepared";
            default: return "";
          }
        case RatingCategory.onsiteProfessionalism:
          switch (rating) {
            case 1: return "Unprofessional appearance or conduct";
            case 2: return "Some professionalism issues";
            case 3: return "Acceptable professional conduct";
            case 4: return "Professional and courteous throughout";
            case 5: return "Exceptionally professional in all aspects";
            default: return "";
          }
        case RatingCategory.safetyProtocols:
          switch (rating) {
            case 1: return "Ignored safety rules";
            case 2: return "Occasional safety lapses";
            case 3: return "Followed basic safety rules";
            case 4: return "Good safety awareness";
            case 5: return "Excellent safety compliance";
            default: return "";
          }
        case RatingCategory.siteCoordination:
          switch (rating) {
            case 1: return "Poor coordination with site requirements";
            case 2: return "Some coordination issues";
            case 3: return "Adequate site coordination";
            case 4: return "Good adaptation to site";
            case 5: return "Excellent site coordination and adaptation";
            default: return "";
          }
        default:
          return "";
      }
    }
    
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getOnsiteCategoryIcon(category),
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // FIXED: Use horizontal scrolling for rating options
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
                      onTap: isSubmitting ? null : () {
                        setState(() {
                          categoryScores[category] = rating;
                          if (category == RatingCategory.punctuality) {
                            punctualityScore = rating;
                          } else if (category == RatingCategory.onsiteProfessionalism) {
                            onSiteProfessionalismScore = rating;
                          } else if (category == RatingCategory.safetyProtocols) {
                            safetyComplianceScore = rating;
                          } else if (category == RatingCategory.siteCoordination) {
                            siteCoordinationScore = rating;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: score == rating 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.white,
                          border: Border.all(
                            color: score == rating 
                                ? Colors.green 
                                : Colors.grey[300]!,
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
                                  ? Colors.amber 
                                  : Colors.grey[300],
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
                                    ? Colors.green 
                                    : Colors.grey[600],
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
                getDescription(score),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getOnsiteCategoryIcon(RatingCategory category) {
    switch (category) {
      case RatingCategory.punctuality:
        return Icons.access_time;
      case RatingCategory.onsiteProfessionalism:
        return Icons.business_center;
      case RatingCategory.safetyProtocols:
        return Icons.security;
      case RatingCategory.siteCoordination:
        return Icons.handshake;
      default:
        return Icons.star;
    }
  }
  
  // REMOTE STEP WIDGETS
  
  Widget _buildRemoteInitialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Satisfaction",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "How would you rate your overall satisfaction with the remote work?",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                size: 48,
                color: index < selectedRating ? Colors.amber : Colors.grey[300],
              ),
              onPressed: isSubmitting ? null : () {
                setState(() {
                  selectedRating = index + 1;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "$selectedRating / 5 Stars",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.blue,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRemoteDetailedStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detailed Performance Assessment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Rate the freelancer across key performance dimensions.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ..._applicableCategories.map((category) => _buildCategoryRatingCard(category)).toList(),
      ],
    );
  }
  
  Widget _buildRemoteTagsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Strengths & Recommendations",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Select what this freelancer did well and provide strategic feedback.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        
        // Tags selection
        const Text(
          "Performance Highlights",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _applicableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              label: Text(
                tag.displayName,
                style: const TextStyle(fontSize: 12),
              ),
              onSelected: isSubmitting ? null : (selected) {
                setState(() {
                  if (selected) {
                    selectedTags.add(tag);
                  } else {
                    selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: widget.blue.withOpacity(0.2),
              checkmarkColor: widget.blue,
              side: BorderSide(
                color: isSelected ? widget.blue : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Recommendation questions
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Would you recommend this freelancer to others?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () {
                          setState(() => wouldRecommend = true);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: wouldRecommend == true 
                                ? Colors.green 
                                : Colors.grey[300]!,
                            width: wouldRecommend == true ? 2 : 1,
                          ),
                          backgroundColor: wouldRecommend == true 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: wouldRecommend == true 
                                ? Colors.green 
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () {
                          setState(() => wouldRecommend = false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: wouldRecommend == false 
                                ? Colors.red 
                                : Colors.grey[300]!,
                            width: wouldRecommend == false ? 2 : 1,
                          ),
                          backgroundColor: wouldRecommend == false 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "No",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: wouldRecommend == false 
                                ? Colors.red 
                                : Colors.grey[700],
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
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Would you hire this freelancer again?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () {
                          setState(() => wouldRehire = true);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: wouldRehire == true 
                                ? Colors.green 
                                : Colors.grey[300]!,
                            width: wouldRehire == true ? 2 : 1,
                          ),
                          backgroundColor: wouldRehire == true 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: wouldRehire == true 
                                ? Colors.green 
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () {
                          setState(() => wouldRehire = false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: wouldRehire == false 
                                ? Colors.red 
                                : Colors.grey[300]!,
                            width: wouldRehire == false ? 2 : 1,
                          ),
                          backgroundColor: wouldRehire == false 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "No",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: wouldRehire == false 
                                ? Colors.red 
                                : Colors.grey[700],
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
        
        // Anonymous submission option
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: CheckboxListTile(
            title: const Text(
              "Submit feedback anonymously",
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              "Your feedback will be visible but your identity will remain private",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: submitAnonymously,
            onChanged: isSubmitting ? null : (value) {
              setState(() => submitAnonymously = value ?? false);
            },
            activeColor: widget.blue,
          ),
        ),
      ],
    );
  }
  
  // COMMON STEP WIDGETS
  
  Widget _buildCategoryRatingCard(RatingCategory category) {
    final score = categoryScores[category] ?? 0;
    
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
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
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            
            // FIXED: Use horizontal scrolling for rating options
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
                      onTap: isSubmitting ? null : () {
                        setState(() {
                          categoryScores[category] = rating;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: score == rating 
                              ? widget.blue.withOpacity(0.2)
                              : Colors.white,
                          border: Border.all(
                            color: score == rating 
                                ? widget.blue 
                                : Colors.grey[300]!,
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
                                  ? Colors.amber 
                                  : Colors.grey[300],
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
                                    ? widget.blue 
                                    : Colors.grey[600],
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
                category.getAnchorDescription(score),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewStep() {
    final ratedCategories = categoryScores.entries
        .where((entry) => entry.value > 0 && _applicableCategories.contains(entry.key))
        .length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isOnsite ? "Review Onsite Assessment" : "Review Your Feedback",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Review your assessment before submitting.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        
        // Overall score card
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: widget.blue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.isOnsite ? "Onsite Performance Score" : "Overall Performance Score",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  calculatedCompositeScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: widget.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 24,
                      color: index < primaryRating 
                          ? Colors.amber 
                          : Colors.grey[300],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  "Based on $ratedCategories category rating${ratedCategories != 1 ? 's' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category breakdown
        if (ratedCategories > 0) ...[
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...categoryScores.entries
              .where((entry) => entry.value > 0 && _applicableCategories.contains(entry.key))
              .map((entry) => _buildReviewCategoryItem(entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        
        // Tags display
        if (selectedTags.isNotEmpty) ...[
          const Text(
            "Performance Highlights",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag.displayName, style: const TextStyle(fontSize: 12)),
                backgroundColor: widget.blue.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Recommendations display
        if (!widget.isOnsite && (wouldRecommend != null || wouldRehire != null)) ...[
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Strategic Decisions",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (wouldRecommend != null)
                    _buildReviewDecisionItem(
                      "Recommend to colleagues",
                      wouldRecommend == true ? "Yes" : "No",
                      wouldRecommend == true ? Colors.green : Colors.orange,
                    ),
                  if (wouldRehire != null) ...[
                    const SizedBox(height: 8),
                    _buildReviewDecisionItem(
                      "Rehire for future projects",
                      wouldRehire == true ? "Yes" : "No",
                      wouldRehire == true ? Colors.green : Colors.orange,
                    ),
                  ],
                  if (submitAnonymously) ...[
                    const SizedBox(height: 8),
                    _buildReviewDecisionItem(
                      "Submission type",
                      "Anonymous",
                      widget.blue,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Additional comments
        const Text(
          "Additional Comments (Optional):",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: widget.isOnsite 
                ? "Add any additional comments about the onsite service..."
                : "Add any additional comments about the remote work...",
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            fillColor: Colors.white,
            filled: true,
          ),
          enabled: !isSubmitting,
        ),
        
        const SizedBox(height: 16),
        
        // Warning/Info card
        Card(
          color: Colors.white,
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
                    "Submitting this rating will confirm work completion and release payment to the freelancer.",
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
  
  Widget _buildReviewCategoryItem(RatingCategory category, int score) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.displayName,
                style: const TextStyle(fontSize: 13),
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
                        ? Colors.amber 
                        : Colors.grey[300],
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  "$score/5",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
              style: const TextStyle(fontSize: 13),
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

  Future<void> _submitRating(int? freelancerId) async {
    if (freelancerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not identify freelancer"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final extendedData = _buildExtendedDataPayload();
      
      final scoreToSubmit = primaryRating;
      
      String reviewText = reviewController.text.trim();
      if (extendedData.isNotEmpty) {
        final jsonData = jsonEncode(extendedData);
        if (reviewText.isNotEmpty) {
          reviewText = "$reviewText\n\n__EXTENDED_DATA__:$jsonData";
        } else {
          reviewText = "__EXTENDED_DATA__:$jsonData";
        }
      }
      
      final success = await widget.ratingProvider.submitEmployerRating(
        task: widget.task,
        freelancerId: freelancerId,
        score: scoreToSubmit,
        review: reviewText,
        punctuality: widget.isOnsite ? punctualityScore : null,
        quality: !widget.isOnsite ? categoryScores[RatingCategory.workQuality] : null,
        extendedData: extendedData, taskId: 0,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isOnsite
                  ? "Onsite rating submitted successfully! Payment has been released."
                  : "Remote work rating submitted successfully!",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (!success && mounted) {
        setState(() {
          isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit rating: ${widget.ratingProvider.error}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit rating: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  Map<String, dynamic> _buildExtendedDataPayload() {
    final payload = <String, dynamic>{};
    
    payload['work_type'] = widget.isOnsite ? 'onsite' : 'remote';
    
    final categoryScoresMap = <String, int>{};
    categoryScores.forEach((category, score) {
      if (score > 0 && _applicableCategories.contains(category)) {
        categoryScoresMap[category.name] = score;
      }
    });
    if (categoryScoresMap.isNotEmpty) {
      payload['category_scores'] = categoryScoresMap;
    }
    
    if (selectedTags.isNotEmpty) {
      payload['performance_tags'] = selectedTags.map((tag) => tag.name).toList();
    }
    
    if (!widget.isOnsite) {
      if (wouldRecommend != null) {
        payload['would_recommend'] = wouldRecommend;
      }
      if (wouldRehire != null) {
        payload['would_rehire'] = wouldRehire;
      }
      if (submitAnonymously) {
        payload['anonymous_submission'] = true;
      }
    }
    
    payload['calculated_composite'] = calculatedCompositeScore;
    
    return payload;
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}