import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:helawork/freelancer/provider/rating_provider.dart';

// Performance Tags for Client Rating
enum ClientPerformanceTag {
  clearRequirements,          // Clear project requirements
  responsiveCommunication,    // Quick and responsive communication
  fairPayment,               // Fair and timely payments
  constructiveFeedback,      // Constructive and helpful feedback
  reasonableExpectations,    // Realistic expectations and deadlines
  collaborativeApproach,     // Collaborative problem-solving
  respectfulInteraction,     // Professional and respectful
  goodDecisionMaker,         // Decisive and clear decisions
  flexibleWhenNeeded,        // Reasonable flexibility
  appreciativeOfWork,        // Shows appreciation for work
  transparentAboutBudget,    // Budget transparency
  trustInExpertise,          // Trusts freelancer's expertise
}

// Rating Categories for Client
enum ClientRatingCategory {
  communicationClarity,    // Communication & Clarity
  professionalism,        // Professionalism
  paymentTimeliness,      // Payment Timeliness
  requirementClarity,     // Requirement clarity
  feedbackQuality,        // Quality of feedback
  collaboration,          // Collaboration style
}

extension ClientRatingCategoryExtension on ClientRatingCategory {
  String get displayName {
    switch (this) {
      case ClientRatingCategory.communicationClarity:
        return 'Communication & Clarity';
      case ClientRatingCategory.professionalism:
        return 'Professionalism';
      case ClientRatingCategory.paymentTimeliness:
        return 'Payment Timeliness';
      case ClientRatingCategory.requirementClarity:
        return 'Requirement Clarity';
      case ClientRatingCategory.feedbackQuality:
        return 'Feedback Quality';
      case ClientRatingCategory.collaboration:
        return 'Collaboration';
    }
  }

  String get description {
    switch (this) {
      case ClientRatingCategory.communicationClarity:
        return 'Clear requirements, responsive communication';
      case ClientRatingCategory.professionalism:
        return 'Professional conduct and respect';
      case ClientRatingCategory.paymentTimeliness:
        return 'Prompt payment and fair compensation';
      case ClientRatingCategory.requirementClarity:
        return 'Clear project scope and expectations';
      case ClientRatingCategory.feedbackQuality:
        return 'Constructive and timely feedback';
      case ClientRatingCategory.collaboration:
        return 'Teamwork and problem-solving approach';
    }
  }

  String getAnchorDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Significant issues';
      case 2:
        return 'Below Average - Room for improvement';
      case 3:
        return 'Average - Met basic expectations';
      case 4:
        return 'Good - Exceeded expectations';
      case 5:
        return 'Excellent - Exceptional performance';
      default:
        return '';
    }
  }
}

extension ClientPerformanceTagExtension on ClientPerformanceTag {
  String get displayName {
    switch (this) {
      case ClientPerformanceTag.clearRequirements:
        return 'Clear Requirements';
      case ClientPerformanceTag.responsiveCommunication:
        return 'Responsive Communication';
      case ClientPerformanceTag.fairPayment:
        return 'Fair & Timely Payment';
      case ClientPerformanceTag.constructiveFeedback:
        return 'Constructive Feedback';
      case ClientPerformanceTag.reasonableExpectations:
        return 'Reasonable Expectations';
      case ClientPerformanceTag.collaborativeApproach:
        return 'Collaborative Approach';
      case ClientPerformanceTag.respectfulInteraction:
        return 'Respectful Interaction';
      case ClientPerformanceTag.goodDecisionMaker:
        return 'Good Decision Maker';
      case ClientPerformanceTag.flexibleWhenNeeded:
        return 'Flexible When Needed';
      case ClientPerformanceTag.appreciativeOfWork:
        return 'Appreciative of Work';
      case ClientPerformanceTag.transparentAboutBudget:
        return 'Budget Transparency';
      case ClientPerformanceTag.trustInExpertise:
        return 'Trusts Expertise';
    }
  }
}

class SubmitRatingScreen extends StatefulWidget {
  final dynamic taskId;
  final dynamic clientId;
  final String clientName;
  final String taskTitle;

  const SubmitRatingScreen({
    super.key,
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.taskTitle,
  });

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  int _overallRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  int _currentStep = 0;
  Map<ClientRatingCategory, int> _categoryScores = {};
  Set<ClientPerformanceTag> _selectedTags = {};
  bool? _wouldWorkAgain;
  bool? _wouldRecommend;
  bool _submitAnonymously = false;

  @override
  void initState() {
    super.initState();
    // Initialize all categories with 0
    for (var category in ClientRatingCategory.values) {
      _categoryScores[category] = 0;
    }
  }

  double get _calculatedCompositeScore {
    final ratedScores = _categoryScores.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.value)
        .toList();
    
    if (ratedScores.isEmpty) return _overallRating.toDouble();
    
    final sum = ratedScores.fold(0, (a, b) => a + b);
    return sum / ratedScores.length;
  }

  int get _primaryRating => _calculatedCompositeScore.round();

  void _submitRating() async {
    // Check if all criteria are rated
    final hasCategoryRatings = _categoryScores.values.any((score) => score > 0);
    if (!hasCategoryRatings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all criteria')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ratingProv = Provider.of<RatingProvider>(context, listen: false);

    // FIXED: Null-safety parsing
    final int raterId = auth.getUserIdOrZero();
    final int ratedId = int.tryParse(widget.clientId.toString()) ?? 0;
    final int safeTaskId = int.tryParse(widget.taskId.toString()) ?? 0;

    if (raterId == ratedId) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Logic Error", style: TextStyle(color: Colors.white)),
          content: Text("You cannot rate yourself (ID: $ratedId matches rater).", 
            style: const TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
        ),
      );
      return; 
    }

    setState(() => _isSubmitting = true);

    try {
      // Build extended data
      final extendedData = _buildExtendedDataPayload();
      
      String reviewText = _reviewController.text.trim();
      if (extendedData.isNotEmpty) {
        final jsonData = jsonEncode(extendedData);
        if (reviewText.isNotEmpty) {
          reviewText = "$reviewText\n\n__EXTENDED_DATA__:$jsonData";
        } else {
          reviewText = "__EXTENDED_DATA__:$jsonData";
        }
      }

      await ratingProv.submitClientRating(
        userId: raterId,
        clientId: ratedId,
        taskId: safeTaskId,
        score: _primaryRating,
        review: reviewText,
        freelancerId: raterId,
        task: {},
        extendedData: extendedData,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildExtendedDataPayload() {
    final payload = <String, dynamic>{};
    
    // Category scores
    final categoryScoresMap = <String, int>{};
    _categoryScores.forEach((category, score) {
      if (score > 0) {
        categoryScoresMap[category.name] = score;
      }
    });
    if (categoryScoresMap.isNotEmpty) {
      payload['category_scores'] = categoryScoresMap;
    }
    
    // Performance tags
    if (_selectedTags.isNotEmpty) {
      payload['performance_tags'] = _selectedTags.map((tag) => tag.name).toList();
    }
    
    // Recommendations
    if (_wouldWorkAgain != null) {
      payload['would_work_again'] = _wouldWorkAgain;
    }
    if (_wouldRecommend != null) {
      payload['would_recommend'] = _wouldRecommend;
    }
    if (_submitAnonymously) {
      payload['anonymous_submission'] = true;
    }
    
    payload['calculated_composite'] = _calculatedCompositeScore;
    
    return payload;
  }

  Widget _buildStepContent() {

    switch (_currentStep) {
      case 0:
        return _buildStep1Overall();
      case 1:
        return _buildStep2Detailed();
      case 2:
        return _buildStep3Strengths();
      case 3:
        return _buildStep4Review();
      default:
        return _buildStep1Overall();
    }
  }

  Widget _buildStep1Overall() {
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
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                size: 48,
                color: index < _overallRating ? Colors.amber : Colors.grey[300],
              ),
              onPressed: _isSubmitting ? null : () {
                setState(() {
                  _overallRating = index + 1;
                  // Initialize categories with overall rating
                  if (_categoryScores.values.every((score) => score == 0)) {
                    for (var category in ClientRatingCategory.values) {
                      _categoryScores[category] = _overallRating;
                    }
                  }
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _overallRating > 0 ? "$_overallRating / 5 Stars" : "Select a rating",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _overallRating > 0 ? Colors.amber : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.amber, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Next, you'll rate specific aspects like communication, payment, and professionalism in detail.",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Detailed() {
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
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        ...ClientRatingCategory.values.map((category) => _buildCategoryRatingCard(category)),
      ],
    );
  }

  Widget _buildCategoryRatingCard(ClientRatingCategory category) {
    final score = _categoryScores[category] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
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
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          
          // Rating options
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 45,
                  child: InkWell(
                    onTap: _isSubmitting ? null : () {
                      setState(() {
                        _categoryScores[category] = rating;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: score == rating 
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: score == rating 
                              ? Colors.amber 
                              : Colors.white30,
                          width: score == rating ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18,
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
                                  ? Colors.amber 
                                  : Colors.white70,
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
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Strengths() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Client Strengths",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          "What did ${widget.clientName} do well? Select all that apply.",
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        
        // Tags selection
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClientPerformanceTag.values.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              label: Text(
                tag.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black : Colors.white,
                ),
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
              selectedColor: Colors.amber,
              checkmarkColor: Colors.black,
              side: BorderSide(
                color: isSelected ? Colors.amber : Colors.white30,
                width: isSelected ? 1.5 : 1,
              ),
              backgroundColor: const Color(0xFF1E1E2C),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Recommendation questions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
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
                              : Colors.white30,
                          width: _wouldWorkAgain == true ? 2 : 1,
                        ),
                        backgroundColor: _wouldWorkAgain == true 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Yes",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _wouldWorkAgain == true 
                              ? Colors.green 
                              : Colors.white70,
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
                              : Colors.white30,
                          width: _wouldWorkAgain == false ? 2 : 1,
                        ),
                        backgroundColor: _wouldWorkAgain == false 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "No",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _wouldWorkAgain == false 
                              ? Colors.red 
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Anonymous submission option
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: CheckboxListTile(
            title: const Text(
              "Submit feedback anonymously",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            subtitle: const Text(
              "Your feedback will be visible but your identity will remain private",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            value: _submitAnonymously,
            onChanged: _isSubmitting ? null : (value) {
              setState(() => _submitAnonymously = value ?? false);
            },
            activeColor: Colors.amber,
            checkColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Review() {
    final ratedCategories = _categoryScores.entries
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
          "Review your assessment of ${widget.clientName} before submitting.",
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        
        // Overall score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber),
          ),
          child: Column(
            children: [
              const Text(
                "Overall Client Rating",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _calculatedCompositeScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
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
                        ? Colors.amber 
                        : Colors.grey[300],
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                "Based on $ratedCategories category rating${ratedCategories != 1 ? 's' : ''}",
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category breakdown
        if (ratedCategories > 0) ...[
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._categoryScores.entries
              .where((entry) => entry.value > 0)
              .map((entry) => _buildReviewCategoryItem(entry.key, entry.value)),
          const SizedBox(height: 16),
        ],
        
        // Tags display
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
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  tag.displayName,
                  style: const TextStyle(fontSize: 12, color: Colors.amber),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Recommendations display
        if (_wouldWorkAgain != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.work,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Future Collaboration",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _wouldWorkAgain == true 
                            ? "You would work with this client again"
                            : "You would not work with this client again",
                        style: TextStyle(
                          fontSize: 12,
                          color: _wouldWorkAgain == true ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Additional comments
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
            hintText: "Add any additional comments about working with this client...",
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            fillColor: const Color(0xFF1E1E2C),
            filled: true,
          ),
          enabled: !_isSubmitting,
        ),
      ],
    );
  }

  Widget _buildReviewCategoryItem(ClientRatingCategory category, int score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _overallRating > 0;
      case 1:
        return _categoryScores.values.any((score) => score > 0);
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      "Overall Experience",
      "Detailed Assessment",
      "Client Strengths",
      "Review & Submit"
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('Rate Client', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFF1E1E2C),
            child: Column(
              children: [
                Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(stepTitles.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < stepTitles.length - 1 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentStep 
                              ? Colors.amber 
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.taskTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clientName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.taskTitle,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Step content
                  _buildStepContent(),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white24)),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                
                if (_currentStep == stepTitles.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: Text(
                      _isSubmitting ? "Submitting..." : "Submit Rating",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isSubmitting ? null : () {
                      if (_canProceedToNextStep()) {
                        setState(() => _currentStep++);
                      }
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}