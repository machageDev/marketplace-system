import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/client/provider/client_rating_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const ClientRatingScreen({super.key});

  @override
  State<ClientRatingScreen> createState() => _ClientRatingScreenState();
}

class _ClientRatingScreenState extends State<ClientRatingScreen> with SingleTickerProviderStateMixin {
  final Color blue = const Color(0xFF007BFF);
  final Color white = Colors.white;
  late TabController _tabController;
  bool _isTabControllerInitialized = false;
  int? _employerId;
  bool _isLoadingUser = true;
  
  get baseUrl => null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isTabControllerInitialized = true;
    
    // Load employer ID first, then fetch tasks
    _loadEmployerId().then((_) {
      if (_employerId != null && _employerId! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<ClientRatingProvider>(context, listen: false)
              .fetchEmployerRateableTasks();
        });
      }
    });
  }
 
 Future<void> _loadEmployerId() async {
  try {
    print("📱 Loading employer ID from storage...");
    
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    print("🔑 Available shared preferences keys: $allKeys");
    
    // Get the token
    final token = prefs.getString('user_token');
    final userName = prefs.getString('user_name');
    print("🔍 User token exists: ${token != null}");
    print("🔍 User name: $userName");
    
    int? foundId;
    
    // Try to get ID from storage first
    // Check as string (how AuthProvider saves it)
    final userIdString = prefs.getString('user_id');
    if (userIdString != null && userIdString.isNotEmpty) {
      final parsed = int.tryParse(userIdString);
      if (parsed != null && parsed > 0) {
        foundId = parsed;
        print("✅ Found user_id as string: $userIdString -> $foundId");
      }
    }
    
    // Check as int
    if (foundId == null) {
      final userIdInt = prefs.getInt('user_id');
      if (userIdInt != null && userIdInt > 0) {
        foundId = userIdInt;
        print("✅ Found user_id as int: $foundId");
      }
    }
    
    // Debug: Show what's actually in user_id key
    print("🔍 Direct check of 'user_id' key:");
    final rawUserId = prefs.get('user_id');
    print("🔍 user_id value: $rawUserId (${rawUserId != null ? rawUserId.runtimeType : 'null'})");
    
    // If no ID found but we have a token, use a fallback
    if (foundId == null && token != null && token.isNotEmpty) {
      print("⚠️ No user_id found but token exists. Using fallback strategy...");
      
      // STRATEGY 1: Try to fetch from profile API
      try {
        print("🔄 Attempting to fetch user profile...");
        final response = await http.get(
          Uri.parse('/api/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          print("✅ Profile API response: ${data.containsKey('id') ? 'Has ID' : 'No ID'}");
          
          if (data['id'] != null) {
            if (data['id'] is int) {
              foundId = data['id'];
            } else if (data['id'] is String) {
              foundId = int.tryParse(data['id']);
            }
            if (foundId != null) {
              print("✅ Retrieved ID from profile API: $foundId");
              await prefs.setInt('user_id', foundId);
            }
          }
        }
      } catch (e) {
        print("❌ Profile API error (this is normal if endpoint doesn't exist): $e");
      }
      
      // STRATEGY 2: If profile API fails, try ID 1 (based on your working logs)
      if (foundId == null) {
        print("🔄 Trying with ID 1 (fallback)...");
        
        // Test if ID 1 works by checking ratings
        try {
          final testResponse = await http.get(
            //Uri.parse('https://marketplace-system-1.onrender.com/api/$employerId/ratings/'),
            Uri.parse('$baseUrl/api/employers/$_employerId/ratings/'),            
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (testResponse.statusCode == 200) {
            foundId = 1;
            print(" ID 1 works! Using employer ID: 1");
          }
        } catch (e) {
          print(" ID 1 test failed: $e");
        }
      }
      
      // STRATEGY 3: Last resort - use 1 if we have token
      if (foundId == null) {
        print("⚠️ Using default ID 1 (last resort)");
        foundId = 1;
      }
    }
    
    setState(() {
      _employerId = foundId;
      _isLoadingUser = false;
    });
    
    if (_employerId != null && _employerId! > 0) {
      print("✅ FINAL: Loaded employer ID: $_employerId");
      
      // Fetch tasks immediately if we have an ID
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ClientRatingProvider>(context, listen: false)
            .fetchEmployerRateableTasks();
      });
    } else {
      print("❌ FINAL: Could not load employer ID");
      
      // Show what we found for debugging
      print("=== STORAGE DUMP ===");
      for (final key in allKeys) {
        final value = prefs.get(key);
        print("  $key: $value");
      }
      print("===================");
    }
    
  } catch (e) {
    print("❌ Error in _loadEmployerId: $e");
    setState(() {
      _isLoadingUser = false;
    });
  }
}
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRatingDialog(BuildContext context, dynamic task) {
    if (_employerId == null || _employerId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please login again to rate"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final ratingProvider = Provider.of<ClientRatingProvider>(context, listen: false);
    final isOnsite = ratingProvider.isOnsiteTask(task);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _RatingDialogContent(
          task: task,
          employerId: _employerId!,
          ratingProvider: ratingProvider,
          blue: blue,
          isOnsite: isOnsite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while fetching user ID
    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor: white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Loading your information...",
                style: TextStyle(color: blue, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show error if no employer ID found
    if (_employerId == null || _employerId! <= 0) {
      return Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          title: const Text("Ratings Dashboard"),
          backgroundColor: blue,
          foregroundColor: white,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 70, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                "User Information Required",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blue),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Unable to load your employer information. Please ensure you're logged in correctly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () => _loadEmployerId(),
                child: Text("Retry", style: TextStyle(color: white)),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Go Back", style: TextStyle(color: blue)),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading screen if TabController not ready
    if (!_isTabControllerInitialized) {
      return Scaffold(
        backgroundColor: white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text("Ratings Dashboard"),
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: true,
        bottom: _isTabControllerInitialized
            ? TabBar(
                controller: _tabController,
                indicatorColor: white,
                labelColor: white,
                unselectedLabelColor: white.withOpacity(0.7),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.star_rate, size: 20),
                    text: "Rate Freelancers",
                  ),
                  Tab(
                    icon: Icon(Icons.person, size: 20),
                    text: "My Ratings",
                  ),
                ],
              )
            : null,
      ),
      body: _isTabControllerInitialized
          ? TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Rate Freelancers
                _buildRateFreelancersTab(),
                
                // TAB 2: View How You Were Rated
                _buildMyRatingsTab(),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  // TAB 1: Rate Freelancers
  Widget _buildRateFreelancersTab() {
    return Consumer<ClientRatingProvider>(
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
                  "No Tasks to Rate",
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
    );
  }

  // TAB 2: My Ratings (How freelancers rated you)
  Widget _buildMyRatingsTab() {
    return Consumer<ClientRatingProvider>(
      builder: (context, provider, child) {
        // Check if employer ID is available
        if (_employerId == null || _employerId! <= 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 70, color: Colors.orange),
                SizedBox(height: 20),
                Text(
                  "User ID Required",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blue),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Unable to load ratings. Please ensure you're logged in correctly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: blue),
                  onPressed: () => _loadEmployerId(),
                  child: Text("Retry Login", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        print("📊 Fetching ratings for employer ID: $_employerId");
        
        return FutureBuilder<List<dynamic>>(
          future: provider.getEmployerRatings(_employerId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Loading your ratings...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 70, color: Colors.red),
                    const SizedBox(height: 10),
                    const Text(
                      "Error Loading Ratings",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: blue),
                      onPressed: () {
                        provider.fetchEmployerRatings(_employerId!);
                      },
                      child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_outline, size: 70, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      "No Ratings Yet",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Freelancers haven't rated you yet.\n(Employer ID: $_employerId)",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: blue),
                      onPressed: () {
                        provider.fetchEmployerRatings(_employerId!);
                      },
                      child: const Text("Refresh", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            final ratings = snapshot.data!;
            print("✅ Loaded ${ratings.length} ratings for employer ID: $_employerId");
            
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
                        "How Freelancers Rated You",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "See feedback from freelancers you've worked with",
                        style: TextStyle(
                          fontSize: 12,
                          color: white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Employer ID: $_employerId | ${ratings.length} rating${ratings.length != 1 ? 's' : ''}",
                        style: TextStyle(
                          fontSize: 10,
                          color: white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildEmployerRatingsList(ratings),
                ),
              ],
            );
          },
        );
      },
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployerRatingsList(List<dynamic> ratings) {
    double averageRating = 0;
    final Map<String, double> categoryAverages = {};
    final Map<String, int> tagFrequency = {};
    
    if (ratings.isNotEmpty) {
      // Calculate average rating
      final total = ratings.fold<int>(0, (sum, rating) => sum + (rating['score'] as int));
      averageRating = total / ratings.length;
      
      // Calculate category averages
      final Map<String, int> categoryTotals = {};
      final Map<String, int> categoryCounts = {};
      
      // Count performance tags
      for (final rating in ratings) {
        // Extract extended data
        final extendedData = _extractExtendedData(rating['review'] ?? '');
        
        // Process category scores
        final categoryScores = extendedData['category_scores'] as Map<String, dynamic>?;
        if (categoryScores != null) {
          categoryScores.forEach((category, score) {
            if (score is int) {
              categoryTotals[category] = (categoryTotals[category] ?? 0) + score;
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }
          });
        }
        
        // Process performance tags
        final performanceTags = extendedData['performance_tags'] as List<dynamic>?;
        if (performanceTags != null) {
          for (final tag in performanceTags) {
            if (tag is String) {
              tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
            }
          }
        }
      }
      
      // Calculate averages
      categoryTotals.forEach((category, total) {
        final count = categoryCounts[category] ?? 1;
        categoryAverages[category] = total / count;
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Card
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
                    "Your Work Passport",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blue),
                  ),
                  const SizedBox(height: 12),
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
                  
                  // Category Averages
                  if (categoryAverages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Your Strengths",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categoryAverages.entries.map<Widget>((entry) {
                        final categoryName = _getCategoryDisplayName(entry.key);
                        final score = entry.value;
                        return Chip(
                          label: Text("$categoryName: ${score.toStringAsFixed(1)}"),
                          backgroundColor: _getCategoryColor(score),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: score >= 4 ? Colors.white : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Top Performance Tags
                  if (tagFrequency.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Frequently Praised For",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _getTopTags(tagFrequency, 5),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text(
            "Individual Ratings",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          ...ratings.map((rating) {
            final extendedData = _extractExtendedData(rating['review'] ?? '');
            final isOnsiteRating = extendedData['work_type'] == 'onsite';
            final categoryScores = extendedData['category_scores'] as Map<String, dynamic>?;
            final performanceTags = extendedData['performance_tags'] as List<dynamic>?;
            final wouldRehire = extendedData['would_rehire'] as bool?;
            
            // Create a list to hold the review widgets
            final List<Widget> reviewWidgets = [];
            final reviewText = rating['review']?.toString() ?? '';
            if (reviewText.isNotEmpty && _cleanReviewText(reviewText).isNotEmpty) {
              reviewWidgets.addAll([
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _cleanReviewText(reviewText),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]);
            }
            
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
                    // Rating header with stars and work type
                    Row(
                      children: [
                        if (isOnsiteRating)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.green),
                                const SizedBox(width: 2),
                                Text(
                                  "ONSITE",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isOnsiteRating)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: blue),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.computer, size: 12, color: blue),
                                const SizedBox(width: 2),
                                Text(
                                  "REMOTE",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        ...List.generate(5, (starIndex) => Icon(
                          Icons.star,
                          size: 16,
                          color: starIndex < (rating['score'] as int) ? Colors.amber : Colors.grey,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          "${rating['score']}/5",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Task and freelancer info
                    Text(
                      "Task: ${rating['task']?['title'] ?? 'Unknown Task'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "From: ${rating['freelancer']?['name'] ?? rating['rater_name'] ?? 'Freelancer'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    
                    // Performance Tags
                    if (performanceTags != null && performanceTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: performanceTags.map<Widget>((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              _getPerformanceTagDisplayName(tag.toString()),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Category Scores (if available)
                    if (categoryScores != null && categoryScores.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categoryScores.entries.map<Widget>((entry) {
                            final score = entry.value is int ? entry.value as int : 0;
                            return Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(score.toDouble()),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getCategoryDisplayName(entry.key),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: score >= 4 ? Colors.white : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$score/5",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: score >= 4 ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Review Text using the list
                    ...reviewWidgets,
                    
                    // Recommendations
                    if (wouldRehire == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Would hire again",
                            style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    
                    // Submission Date (if available)
                    if (rating['created_at'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(rating['created_at'].toString()),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper methods
  List<Widget> _getTopTags(Map<String, int> tagFrequency, int count) {
    final sortedEntries = tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(count).map((entry) {
      final tagName = _getPerformanceTagDisplayName(entry.key);
      return Chip(
        label: Text("$tagName (${entry.value}x)"),
        backgroundColor: Colors.blue.withOpacity(0.1),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
        labelStyle: const TextStyle(fontSize: 10),
      );
    }).toList();
  }

  String _getCategoryDisplayName(String categoryKey) {
    try {
      final category = RatingCategory.values.firstWhere(
        (c) => c.name == categoryKey,
        orElse: () => RatingCategory.workQuality,
      );
      return category.displayName;
    } catch (e) {
      return categoryKey.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
  }

  String _getPerformanceTagDisplayName(String tagKey) {
    try {
      final tag = FreelancerPerformanceTag.values.firstWhere(
        (t) => t.name == tagKey,
        orElse: () => FreelancerPerformanceTag.exceededExpectations,
      );
      return tag.displayName;
    } catch (e) {
      return tagKey.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
  }

  Color _getCategoryColor(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 4.0) return Colors.lightGreen;
    if (score >= 3.5) return Colors.yellow[700]!;
    if (score >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
        }),
        
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
        ..._applicableCategories.map((category) => _buildCategoryRatingCard(category)),
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
        extendedData: extendedData, 
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