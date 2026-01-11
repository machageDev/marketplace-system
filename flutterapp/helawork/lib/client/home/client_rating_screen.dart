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
  costEffective           // Exceptional value for investment
}

// Rating Categories
enum RatingCategory {
  workQuality,          // Work Quality & Craftsmanship
  communication,        // Communication Proficiency
  deadlineAdherence,    // Deadline Adherence & Time Management
  professionalConduct,  // Professional Conduct
  technicalExpertise,   // Technical Expertise
  problemSolving,       // Problem-Solving Agility
  valueProposition      // Value Proposition
}

extension RatingCategoryExtension on RatingCategory {
  String get displayName {
    switch (this) {
      case RatingCategory.workQuality:
        return 'Work Quality & Craftsmanship';
      case RatingCategory.communication:
        return 'Communication Proficiency';
      case RatingCategory.deadlineAdherence:
        return 'Deadline Adherence & Time Management';
      case RatingCategory.professionalConduct:
        return 'Professional Conduct';
      case RatingCategory.technicalExpertise:
        return 'Technical Expertise';
      case RatingCategory.problemSolving:
        return 'Problem-Solving Agility';
      case RatingCategory.valueProposition:
        return 'Value Proposition';
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
    }
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
    
    showDialog(
      context: context,
      builder: (ctx) {
        return _RatingDialogContent(
          task: task,
          employerId: widget.employerId,
          ratingProvider: ratingProvider,
          blue: blue,
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
      width: 400,
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
                            rating['review'],
                            style: const TextStyle(fontSize: 14),
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
                    
                    return _buildTaskCard(task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final freelancerName = task['freelancer']?['username'] ?? 
                          task['assigned_user']?['username'] ?? 
                          task['contract']?['freelancer']?['username'] ?? 
                          'Unknown Freelancer';
    
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
                  child: const Text(
                    "Rate Work",
                    style: TextStyle(color: Colors.white, fontSize: 12),
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

  const _RatingDialogContent({
    required this.task,
    required this.employerId,
    required this.ratingProvider,
    required this.blue,
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
  
  double get calculatedCompositeScore {
    final ratedScores = categoryScores.values.where((s) => s > 0).toList();
    if (ratedScores.isEmpty) return selectedRating.toDouble();
    final sum = ratedScores.fold(0, (a, b) => a + b);
    return sum / ratedScores.length;
  }

  int get primaryRating {
    final hasCategoryRatings = categoryScores.values.any((s) => s > 0);
    if (hasCategoryRatings) {
      return calculatedCompositeScore.round();
    }
    return selectedRating;
  }

  @override
  void initState() {
    super.initState();
    for (var category in RatingCategory.values) {
      categoryScores[category] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final freelancerName = widget.task['freelancer']?['username'] ?? 
                          widget.task['assigned_user']?['username'] ?? 
                          widget.task['contract']?['freelancer']?['username'] ?? 
                          'the freelancer';
    final freelancerId = widget.task['freelancer']?['id'] ?? 
                        widget.task['assigned_user']?['id'] ?? 
                        widget.task['contract']?['freelancer']?['id'];
    final taskId = widget.task['id'] ?? widget.task['task_id'];
    
    final stepTitles = [
      "Initial Impression",
      "Detailed Assessment",
      "Qualitative Recognition",
      "Strategic Evaluation",
      "Review & Submit"
    ];
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                    children: List.generate(5, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
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
                child: _buildStepContent(freelancerName),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
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
                  
                  if (currentStep == 4)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSubmitting ? null : () => _submitRating(freelancerId, taskId),
                      child: Text(
                        isSubmitting ? "Submitting..." : "Submit Rating",
                      ),
                    )
                  else if (currentStep < 4)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.blue,
                        foregroundColor: Colors.white,
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
    switch (currentStep) {
      case 0:
        return _buildInitialImpressionStep();
      case 1:
        return _buildCategoryRatingsStep();
      case 2:
        return _buildTagSelectionStep();
      case 3:
        return _buildStrategicEvaluationStep();
      case 4:
        return _buildReviewStep();
      default:
        return _buildInitialImpressionStep();
    }
  }
  
  bool _canProceedToNextStep() {
    switch (currentStep) {
      case 0:
        return selectedRating > 0;
      case 1:
        return true; // Categories are optional
      case 2:
        return true; // Tags are optional
      case 3:
        return wouldRecommend != null && wouldRehire != null;
      case 4:
        return true; // Review step - always can submit
      default:
        return false;
    }
  }
  
  Widget _buildInitialImpressionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How would you rate your overall satisfaction?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Provide a quick overall rating. You'll have the opportunity to provide detailed feedback in the next steps.",
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
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: widget.blue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: widget.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Next, you'll be able to provide detailed ratings across 7 performance dimensions.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRatingsStep() {
    final categories = RatingCategory.values;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detailed Performance Assessment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Rate the freelancer across 7 key dimensions. This step is optional - you can skip to continue with the overall rating.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        if (categoryScores.values.any((s) => s > 0))
          _buildImpactProjection(),
        const SizedBox(height: 16),
        ...categories.map((category) => _buildCategoryRatingCard(category)),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: widget.blue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: widget.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${categoryScores.values.where((s) => s > 0).length}/7 categories rated. Detailed ratings help freelancers improve.",
                    style: TextStyle(fontSize: 12, color: widget.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
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
            Row(
              children: [
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
                Tooltip(
                  message: category.description,
                  child: Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return Expanded(
                  child: InkWell(
                    onTap: isSubmitting ? null : () {
                      setState(() {
                        categoryScores[category] = rating;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
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
  
  Widget _buildTagSelectionStep() {
    final allTags = FreelancerPerformanceTag.values;
    final maxTags = 5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Highlight Specific Strengths",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Select up to $maxTags attributes that best describe this freelancer's performance. This helps freelancers understand their strengths.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        if (selectedTags.length >= maxTags)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: widget.blue),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: widget.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Maximum $maxTags tags selected. Deselect a tag to choose another.",
                    style: TextStyle(fontSize: 11, color: widget.blue),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            final canSelect = selectedTags.length < maxTags || isSelected;
            
            return FilterChip(
              selected: isSelected,
              label: Text(tag.displayName),
              onSelected: isSubmitting ? null : (selected) {
                setState(() {
                  if (selected && canSelect) {
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
                width: isSelected ? 2 : 1,
              ),
              disabledColor: Colors.grey[200],
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Selected Strengths (${selectedTags.length}/$maxTags)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedTags.map((tag) {
                      return Chip(
                        label: Text(
                          tag.displayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: widget.blue.withOpacity(0.15),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: isSubmitting ? null : () {
                          setState(() {
                            selectedTags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStrategicEvaluationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Strategic Assessment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Help us understand the long-term value and recommendation potential of this freelancer.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 2,
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
                    Icon(Icons.thumb_up, color: widget.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Would you recommend this freelancer to colleagues?",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "This helps build trust and visibility in our community",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                                ? widget.blue 
                                : Colors.grey[300]!,
                            width: wouldRecommend == true ? 2 : 1,
                          ),
                          backgroundColor: wouldRecommend == true 
                              ? widget.blue.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Yes, I would recommend",
                          style: TextStyle(
                            color: wouldRecommend == true 
                                ? widget.blue 
                                : Colors.grey[700],
                            fontWeight: wouldRecommend == true 
                                ? FontWeight.bold 
                                : FontWeight.normal,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "No, I would not",
                          style: TextStyle(
                            color: wouldRecommend == false 
                                ? Colors.red 
                                : Colors.grey[700],
                            fontWeight: wouldRecommend == false 
                                ? FontWeight.bold 
                                : FontWeight.normal,
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
          elevation: 2,
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
                    Icon(Icons.work_outline, color: widget.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Would you engage this freelancer for future projects?",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "This helps improve future project matching",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                                ? widget.blue 
                                : Colors.grey[300]!,
                            width: wouldRehire == true ? 2 : 1,
                          ),
                          backgroundColor: wouldRehire == true 
                              ? widget.blue.withOpacity(0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Yes, I would rehire",
                          style: TextStyle(
                            color: wouldRehire == true 
                                ? widget.blue 
                                : Colors.grey[700],
                            fontWeight: wouldRehire == true 
                                ? FontWeight.bold 
                                : FontWeight.normal,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "No, I would not",
                          style: TextStyle(
                            color: wouldRehire == false 
                                ? Colors.red 
                                : Colors.grey[700],
                            fontWeight: wouldRehire == false 
                                ? FontWeight.bold 
                                : FontWeight.normal,
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
  
  Widget _buildReviewStep() {
    final categoryCount = categoryScores.values.where((s) => s > 0).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Your Feedback",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Review your assessment before submitting. You can go back to make changes.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
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
                const Text(
                  "Overall Performance Score",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  "Based on $categoryCount category rating${categoryCount != 1 ? 's' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (categoryScores.values.any((s) => s > 0)) ...[
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...RatingCategory.values.where((cat) => (categoryScores[cat] ?? 0) > 0)
              .map((category) {
                final score = categoryScores[category] ?? 0;
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
              }),
          const SizedBox(height: 16),
        ],
        if (selectedTags.isNotEmpty) ...[
          const Text(
            "Selected Strengths",
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
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
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
                _buildReviewItem(
                  "Recommend to colleagues",
                  wouldRecommend == true ? "Yes" : "No",
                  wouldRecommend == true ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildReviewItem(
                  "Rehire for future projects",
                  wouldRehire == true ? "Yes" : "No",
                  wouldRehire == true ? Colors.green : Colors.orange,
                ),
                if (submitAnonymously) ...[
                  const SizedBox(height: 8),
                  _buildReviewItem(
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
        const Text(
          "Additional Feedback (Optional):",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Add any additional comments...",
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            fillColor: Colors.white,
            filled: true,
          ),
          enabled: !isSubmitting,
        ),
      ],
    );
  }
  
  Widget _buildReviewItem(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          ),
        ),
      ],
    );
  }
  
  Widget _buildImpactProjection() {
    final avgScore = calculatedCompositeScore;
    final ratedCount = categoryScores.values.where((s) => s > 0).length;
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.blue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: widget.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Current Performance Projection",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avgScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.blue,
                      ),
                    ),
                    Text(
                      "$ratedCount/7 categories rated",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 20,
                      color: index < avgScore.round() 
                          ? Colors.amber 
                          : Colors.grey[300],
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(int? freelancerId, int? taskId) async {
    if (freelancerId == null || taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not identify freelancer or task"),
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
      
      await widget.ratingProvider.submitEmployerRating(
        taskId: taskId,
        freelancerId: freelancerId,
        score: scoreToSubmit,
        review: reviewText,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              categoryScores.values.any((s) => s > 0)
                  ? "Detailed performance evaluation submitted successfully!"
                  : "Rating submitted successfully!",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
    
    final categoryScoresMap = <String, int>{};
    categoryScores.forEach((category, score) {
      if (score > 0) {
        categoryScoresMap[category.name] = score;
      }
    });
    if (categoryScoresMap.isNotEmpty) {
      payload['category_scores'] = categoryScoresMap;
      payload['calculated_composite'] = calculatedCompositeScore;
    }
    
    if (selectedTags.isNotEmpty) {
      payload['performance_tags'] = selectedTags.map((tag) => tag.name).toList();
    }
    
    if (wouldRecommend != null) {
      payload['would_recommend'] = wouldRecommend;
    }
    if (wouldRehire != null) {
      payload['would_rehire'] = wouldRehire;
    }
    if (submitAnonymously) {
      payload['anonymous_submission'] = true;
    }
    
    return payload;
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}