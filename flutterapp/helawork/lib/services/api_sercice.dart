import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helawork/freelancer/models/contract_model.dart';
import 'package:helawork/freelancer/models/proposal.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
class ApiService{
  static const String baseUrl = 'https://marketplace-system-1.onrender.com';
 
  static const String registerUrl = '$baseUrl/apiregister';
  static const String  loginUrl ='$baseUrl/apilogin';
  static const String paymentsummaryUrl='$baseUrl/apipaymentsummary';
  static const String getuserprofileUrl = '$baseUrl/apigetprofile';
  static const String recentUrl = '$baseUrl/apirecent';
  static const String active_sessionUrl = '$baseUrl/apiactivesession';
  static const String earningUrl = '$baseUrl/apiearing';  
  static const String taskUrl = '$baseUrl/task';
  static const String  withdraw_mpesaUrl = '$baseUrl/mpesa';
  static const String  updateUserProfileUrl = '$baseUrl/apiuserprofile';
  static const String ProposalUrl = '$baseUrl/apiproposal';
  static const String proposalsUrl = '$baseUrl/apiproposal';
  
  static const String apiloginUrl = '$baseUrl/login';
  static const String apiregisterUrl = '$baseUrl/register';
  static const String dashboardUrl = '$baseUrl/dashboard';
  static const String taskStatsUrl = '$baseUrl/employer/task/stats';
  static const String createTaskUrl = '$baseUrl/tasks/create/';  
  static const String employerTasksUrl = '$baseUrl/employer/tasks';
  static const String apiuserprofileUrl = '$baseUrl/apiuserprofile';
  static const String contractUrl = '$baseUrl/contracts';
  static const String fetchtaskUrl = '$baseUrl/api/task_completions/';
  static const String apiforgotpasswordUrl = '$baseUrl/auth/forgot_password/';
  static const String getContractUrl = '$baseUrl/contracts/';
  static const String taskcomplitionUrl = '$baseUrl/api/task_completions/';
  static const String freelancercontractUrl = '$baseUrl/freelancer/contracts/';
  static const String employerIdcontractUrl = '$baseUrl/employer/contracts/';
  static const String acceptproposalUrl = '$baseUrl/proposals/accept/';
  static const String rejectproposalUrl = '$baseUrl/proposals/reject/';
  static const String acceptcontractUrl = '$baseUrl/contracts/accept/';
  static const String rejectcontractUrl = '$baseUrl/contracts/reject/';
  static const String freelancerproposalsUrl = '$baseUrl/client/proposals/';
  static const String withdrawcompleteUrl = '$baseUrl/api/task_completions/'; 
  static const String freelancerrateUrl = '$baseUrl/apifreelancerrates';
  static const String tasktorateUrl ='$baseUrl/apitasks-to-rate';
  static const String employerprofileUrl = '$baseUrl/apiemployerprofile';
  static const String submitRatingUrl = '$baseUrl/employer_ratings/';
  static const String employerratingsUrl ='$baseUrl/apifetchratings';
  static const String taskforratingUrl = '$baseUrl/completetask';
Future<Map<String, dynamic>> register(String name, String email,String phoneNO, String password,  String confirmPassword) async {
  final url = Uri.parse(registerUrl);
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "phone_number": phoneNO,
        "password": password,
        "confirmPassword": confirmPassword,
        
      }),
    );

    if (response.statusCode == 201) {
      return {"success": true};
    } else {
      final responseData = jsonDecode(response.body);
      print("Backend response: $responseData");
      return {"success": false, "message": responseData["error"] ?? responseData.toString()};
    }
  } catch (e) {
    print("Registration error: $e");
    return {"success": false, "message": "Network error, please try again."};
  }
}
 static Future<String> createPaymentIntent(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-payment-intent/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['clientSecret'];
    } else {
      throw Exception('Failed to create PaymentIntent');
    }
  }
static Future<String> getLoggedInUserName() async {
  final response = await http.get(
    Uri.parse("$baseUrl/apiuserlogin"),
    headers: {
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    
    return data["username"] ?? data["name"] ?? "User";
  } else {
    return "User";
  }
}
Future<Map<String, dynamic>> login(String name, String password) async {
  final url = Uri.parse(ApiService.loginUrl);

  print("Logging in with name: $name, password: $password");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "password": password}),
    );

    print("HTTP status: ${response.statusCode}");
    print("Raw response body: ${response.body}");

    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      return {
        "success": false,
        "message": "Invalid response from server",
        "error": response.body,
      };
    }

    if (response.statusCode == 200) {
      
      final String? token = responseData["token"];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', token); 
        print(' TOKEN SAVED TO SHARED PREFERENCES: ${token.substring(0, 10)}...');
      }

      return {
        "success": true,
        "data": {
          "user_id": responseData["user_id"],
          "name": responseData["name"],
          "message": responseData["message"],
          "token": token,
        }
      };
    } else {
      return {
        "success": false,
        "message": responseData["error"] ?? "Invalid credentials",
        "error": responseData,
      };
    }
  } catch (e) {
    print("Login error: $e");
    return {
      "success": false,
      "message": "Network or server error: $e",
    };
  }
}
// Add this helper method to your ApiService class
Future<int> _getCurrentUserId() async {
  try {
    // Method 1: Get from user profile
    final userProfile = await getUserProfile();
    if (userProfile != null && userProfile['user_id'] != null) {
      return userProfile['user_id'] as int;
    }
    
    // Method 2: Get from token or auth system
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      return userId;
    }
    
    // Method 3: If you have user info in token
    final String? token = await _getUserToken();
    if (token != null) {
      // You might need to decode JWT token to get user ID
      // This is a simple example - adjust based on your auth system
      return 1; // Temporary fallback
    }
    
    throw Exception('Could not determine current user ID');
  } catch (e) {
    print('Error getting current user ID: $e');
    throw Exception('Please log in again');
  }
}

Future<List<dynamic>> getEmployerRateableTasks() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/employer/rateable/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
    );

    print('Employer Rateable Tasks API Response:');
    print('URL: $baseUrl/api/tasks/employer/rateable/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employer rateable tasks: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getEmployerRateableTasks: $e');
    rethrow;
  }
}
// Add this to your ApiService class
Future<List<dynamic>> getEmployerRatings(int employerId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/employers/$employerId/ratings/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
    );

    print('Employer Ratings API Response:');
    print('URL: $baseUrl/api/employers/$employerId/ratings/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employer ratings: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getEmployerRatings: $e');
    rethrow;
  }
}
  Future<Map<String, dynamic>> getActiveSession() async {
    final response = await http.get(Uri.parse(active_sessionUrl));
    return json.decode(response.body);
  }
 Future<Map<String, dynamic>> getEarnings() async {
    final response = await http.get(Uri.parse(earningUrl));
    return json.decode(response.body);
  }

 static Future<List<Map<String, dynamic>>> fetchTasks() async {
  try {
    // Get the token from storage
    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'auth_token');
    
    // Check if token exists
    if (token == null || token.isEmpty) {
      throw Exception("No authentication token found");
    }
    
    print('Using token: ${token.substring(0, 20)}...'); // Log first 20 chars for debugging
    
    // Make the request with Authorization header
    final response = await http.get(
      Uri.parse(taskUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    print('Task API Response Status: ${response.statusCode}');
    print('Task API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      
      if (data is List) {
        if (data.isEmpty) {
          return [
            {
              "task_id": 0, 
              "title": "No tasks available",
              "description": "Check back later for new tasks",
              "employer": {"username": "System"}
            }
          ];
        }
        
        return data.map((task) {
          final mappedTask = Map<String, dynamic>.from(task);
          
          mappedTask['completed'] = mappedTask['completed'] ?? false;
          mappedTask['employer'] = mappedTask['employer'] ?? {
            'username': 'Unknown Client',
            'company_name': 'Unknown Company'
          };
          
          return mappedTask;
        }).toList();
        
      } else if (data is Map && data.containsKey('error')) {
        throw Exception("API Error: ${data['error']}");
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception("Failed to load tasks: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print('Error fetching tasks: $e');
    rethrow;
  }
}

 Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profile, String token, String userId) async {
  try {
    const String url = "$baseUrl/apiuserprofile";

    var request = http.MultipartRequest("PUT", Uri.parse(url));

    
    request.headers.addAll({
      'Authorization': 'Bearer $token', 
      // 'Authorization': 'Token $token', 
      // 'Authorization': 'JWT $token', 
      'Accept': 'application/json',
    });

    
    request.fields['user_id'] = userId;

    
    profile.forEach((key, value) {
      if (value != null && value is! File) {
        request.fields[key] = value.toString();
      }
    });

    
    if (profile['profile_picture'] != null && profile['profile_picture'] is File) {
      File file = profile['profile_picture'];
      request.files.add(
          await http.MultipartFile.fromPath('profile_picture', file.path));
    }

    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

   
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        "success": true,
        "message": "Profile updated successfully",
        "data": json.decode(response.body),
      };
    } else if (response.statusCode == 401) {
      return {"success": false, "message": "Unauthorized. Please log in again."};
    } else {
      return {
        "success": false,
        "message": "Failed: ${response.statusCode} ${response.body}"
      };
    }
  } catch (e) {
    return {"success": false, "message": "Network error: $e"};
  }
}

static Future<String?> _getUserToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    
    final allKeys = prefs.getKeys();
    print(' ALL SHARED PREFERENCES KEYS: $allKeys');
    
    
    String? token = prefs.getString('user_token');
    
    print(' TOKEN FOUND: ${token?.substring(0, 10)}...');
    return token;
  } catch (e) {
    print(' ERROR RETRIEVING TOKEN: $e');
    return null;
  }
}
 
static Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    
    final String? token = await _getUserToken();
    
    if (token == null) {
      print(' No authentication token found - user may not be logged in');
      return null;
    }

    print(' Fetching user profile with token: ${token.substring(0, 10)}...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/apiuserprofile'),
      headers: {
        'Authorization': 'Bearer $token', 
        'Accept': 'application/json',
      },
    );

    print(' Profile API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(' User profile loaded successfully');
      print(' Profile data: $data');
      return Map<String, dynamic>.from(data);
    } else if (response.statusCode == 401) {
      print(' Unauthorized (401) - Token may be invalid or expired');
      print(' Response body: ${response.body}');
      return null;
    } else {
      print(' Failed to load user profile: ${response.statusCode}');
      print(' Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print(' Network error loading user profile: $e');
    return null;
  }
}

   
  static Future<Map<String, dynamic>> getPaymentSummary() async {
    final response = await http.get(Uri.parse(paymentsummaryUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load payment summary");
    }
  }

  // Withdraw payment via M-PESA
  static Future<Map<String, dynamic>> withdrawMpesa() async {
    final response = await http.get(Uri.parse(withdraw_mpesaUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to initiate withdrawal");
    }
  }

   static Future<List<dynamic>> getData(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint/');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching data: $e");
    }
  }

  
  static Future<Map<String, dynamic>> postData(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            "Failed to post data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Error posting data: $e");
    }
  }
  static Future<Map<String, dynamic>> submitRating({
  required int taskId,
  required int freelancerId, 
  required int employerId,    
  required int score,
  String? review,             
}) async {
  final body = {
    "task": taskId,
    "freelancer": freelancerId,  
    "employer": employerId,      
    "score": score,
    "review": review ?? "",      
  };

  return await postData('/employer_ratings/', body);
}

  static Future<Proposal> submitProposal(Proposal proposal, {PlatformFile? pdfFile}) async {
  try {
    // Get authentication token
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception("User not authenticated. Please log in again.");
    }

    
    if (pdfFile == null) {
      throw Exception("Cover letter PDF file is required");
    }

   
    if (pdfFile.bytes == null) {
      throw Exception("PDF file bytes are null - file may be corrupted");
    }

    print(' Starting proposal submission with PDF cover letter...');
    print(' PDF File: ${pdfFile.name} (${pdfFile.size} bytes)');
    print(' Proposal URL: $ProposalUrl');

    
    var request = http.MultipartRequest('POST', Uri.parse(ProposalUrl));
    
   
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
   
    // Add proposal data as fields
    request.fields['task_id'] = proposal.taskId.toString();
    request.fields['freelancer_id'] = proposal.freelancerId.toString();
    request.fields['bid_amount'] = proposal.bidAmount.toString();
    request.fields['status'] = proposal.status;
    
    
    if (proposal.title != null && proposal.title!.isNotEmpty) {
      request.fields['title'] = proposal.title!;
    } else {
      request.fields['title'] = 'Proposal for Task ${proposal.taskId}';
    }

    
    request.files.add(http.MultipartFile.fromBytes(
      'cover_letter_file',
      pdfFile.bytes!, // Now safe because we checked above
      filename: pdfFile.name,
      contentType: MediaType('application', 'pdf'),
    ));

    print(' Request prepared with fields:');
    print('   - task_id: ${proposal.taskId}');
    print('   - freelancer_id: ${proposal.freelancerId}');
    print('   - bid_amount: ${proposal.bidAmount}');
    print('   - status: ${proposal.status}');
    print('   - title: ${proposal.title}');
    print('   - file_field: cover_letter_file');
    print('   - file_name: ${pdfFile.name}');

    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    print(' Proposal API Response:');
    print('   - Status: ${response.statusCode}');
    print('   - Body: $responseBody');

    if (response.statusCode == 201 || response.statusCode == 200) {
      print(' Proposal submitted successfully!');
      final responseData = json.decode(responseBody);
      return Proposal.fromJson(responseData);
    } else if (response.statusCode == 401) {
      throw Exception("Authentication failed. Please log in again.");
    } else if (response.statusCode == 400) {
      throw Exception("Invalid data submitted: $responseBody");
    } else {
      throw Exception("Failed to submit proposal: ${response.statusCode} - $responseBody");
    }

  } catch (e, stackTrace) {
    print('===================================');
    print(' NULL CHECK ERROR DETAILS:');
    print(' Error: $e');
    print(' Stack trace: $stackTrace');
    print('===================================');
    throw Exception("Error submitting proposal: $e");
  }
}
  // In fetchProposals method
static Future<List<Proposal>> fetchProposals() async {
  final String? token = await _getUserToken();
  final url = Uri.parse(proposalsUrl);  
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token', 
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Proposal.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load proposals: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error loading proposals: $e");
  }
}

// In fetchContracts method  
Future<List<Contract>> fetchContracts() async {
  final String? token = await _getUserToken();
  final url = Uri.parse(contractUrl);
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token', 
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Contract.fromJson(json)).toList();
  } else {
    throw Exception("Failed to load contracts: ${response.body}");
  }
}
  
  Future<void> acceptContract(int contractId) async {
    final url = Uri.parse('contractUrl');
    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to accept contract: ${response.body}");
    }
  }

  
  Future<void> rejectContract(int contractId) async {
    final url = Uri.parse("$baseUrl/contracts/$contractId/reject/");
    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to reject contract: ${response.body}");
    }
  }

   static Future<Map<String, dynamic>> fetchTaskDetails(int taskId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$taskId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'title': data['title'],
          'budget': data['budget'] != null ? double.parse(data['budget'].toString()) : 0.0,
          'deadline': data['deadline'],
          'category_display': data['category_display'],
          'description': data['description'],
          'status': data['status'],
        };
      } else {
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching task details: $e');
      rethrow;
    }
  }

  /// Fetch task completion data for a specific task
  static Future<Map<String, dynamic>?> fetchTaskCompletion(int taskId) async {
  try {
    final token = await _getToken();
    
    
    final response = await http.get(
      Uri.parse('$fetchtaskUrl?task_id=$taskId'), // Option 1: Query parameter
      // OR
      // Uri.parse('$fetchtaskUrl/$taskId/'), // Option 2: URL path parameter
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List && data.isNotEmpty) {
        
        final completion = data.firstWhere(
          (item) => item['task_id'] == taskId || 
                    item['task']?['task_id'] == taskId,
          orElse: () => null,
        );
        
        return completion != null ? _parseCompletionData(completion) : null;
      }
      return null; 
    } else {
      throw Exception('Failed to load completion: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching task completion: $e');
    rethrow;
  }
}
  /// Submit new task completion
  static Future<Map<String, dynamic>> submitTaskCompletion({
    required int taskId,
    required String notes,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(taskcomplitionUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'task_id': taskId,
          'freelancer_submission_notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Completion submitted successfully',
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['non_field_errors']?[0] ?? 
                    errorData['task_id']?[0] ?? 
                    'Submission failed',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Error submitting completion: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  

  /// List all task completions for the current user
  static Future<List<Map<String, dynamic>>> fetchUserCompletions() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(fetchtaskUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => _parseCompletionData(item)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load completions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user completions: $e');
      rethrow;
    }
  }

  /// Withdraw a task completion submission
  static Future<Map<String, dynamic>> withdrawCompletion(int completionId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(withdrawcompleteUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Completion withdrawn successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to withdraw completion',
        };
      }
    } catch (e) {
      print('Error withdrawing completion: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ================= HELPER METHODS =================

  /// Parse completion data from API response
  static Map<String, dynamic> _parseCompletionData(Map<String, dynamic> data) {
    return {
      'completion_id': data['completion_id'],
      'task_id': data['task']?['task_id'] ?? data['task_id'],
      'task_title': data['task_title'] ?? data['task']?['title'],
      'status': data['status'],
      'status_display': data['status_display'] ?? _getStatusDisplay(data['status']),
      'freelancer_submission_notes': data['freelancer_submission_notes'],
      'employer_review_notes': data['employer_review_notes'],
      'completed_at': data['completed_at'],
      'reviewed_at': data['reviewed_at'],
      'paid': data['paid'] ?? false,
      'payment_date': data['payment_date'],
      'amount': data['amount'] != null ? double.parse(data['amount'].toString()) : 0.0,
      'can_update': data['can_update'] ?? (data['status'] == 'submitted' || data['status'] == 'revisions_requested'),
      'can_withdraw': data['can_withdraw'] ?? (data['status'] == 'submitted' || data['status'] == 'under_review' || data['status'] == 'revisions_requested'),
    };
  }

  /// Get display text for status
  static String _getStatusDisplay(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'revisions_requested':
        return 'Revisions Requested';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// Get authentication token (implement based on your auth system)
  static Future<String> _getToken() async {
    // Implement your token retrieval logic
    // This could be from SharedPreferences, secure storage, etc.
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('auth_token') ?? '';
    return 'your-auth-token-here'; // Replace with actual token retrieval
  }
 


Future<void> saveUserToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_token', token);
  print(" Token saved to SharedPreferences: $token");
}



Future<Map<String, dynamic>> apilogin(String username, String password) async {
  try {
    print("=== LOGIN API CALL ===");
    print("URL: $apiloginUrl");
    print("Username: $username");

    final response = await http.post(
      Uri.parse(apiloginUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Check if token exists in the response
      if (responseData['token'] != null && responseData['token'].toString().isNotEmpty) {
        final token = responseData['token'].toString();

        //  Save token locally for future API calls
        await saveUserToken(token);
        print(" Token saved locally: $token");
      } else {
        print(" No token found in response: ${response.body}");
      }

      return {
        'success': true,
        'data': responseData,
      };
    } else {
      print(" Login failed — ${response.statusCode}");
      return {
        'success': false,
        'error': 'Invalid credentials. Please try again.',
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    print("=== LOGIN API ERROR ===");
    print("Error: $e");
    print("Error type: ${e.runtimeType}");

    return {
      'success': false,
      'error': 'Network error. Please check your connection.',
    };
  }
}
Future<Map<String, dynamic>> fetchDashboardData() async {
  try {
    print("=== DASHBOARD API CALL ===");
    print("URL: $dashboardUrl");

    final String? token = await _getUserToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print(" Added Authorization header: Bearer $token");
    } else {
      print(" No token found. You may need to log in again.");
    }

    final response = await http.get(Uri.parse(dashboardUrl), headers: headers);

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("Parsed Response: $responseData");

      // Unified data structure handling
      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == true && responseData.containsKey('data')) {
          return responseData['data'];
        } else {
          return responseData;
        }
      } else {
        throw Exception('Unexpected response format: Expected Map');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Dashboard endpoint not found');
    } else {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
  } catch (e) {
    print("=== DASHBOARD API ERROR ===");
    print("Error: $e");
    print("Error type: ${e.runtimeType}");
    rethrow;
  }
}

  // Add this method to your existing ApiService class
Future<Map<String, dynamic>> apiforgotpassword({
  required String email,
}) async {
  try {
    final response = await http.post(
      Uri.parse(apiforgotpasswordUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Password reset instructions sent to your email.',
      };
    } else {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to process password reset request.',
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Network error. Please check your connection.',
    };
  }
}
  // Add this method to your existing ApiService class
Future<Map<String, dynamic>> apiregister({
  required String username,
  required String email,
  required String password,
  String? phoneNumber,
}) async {
  try {
    final response = await http.post(
      Uri.parse(apiregisterUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'contact_email': email, 
        'password': password,
        'phone_number': phoneNumber,
        'role': 'client',
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(response.body),
        'message': 'Registration successful!',
      };
    } else {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? _getErrorMessage(response.statusCode),
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Network error. Please check your connection.',
    };
  }
}

String _getErrorMessage(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Invalid registration data. Please check your inputs.';
    case 409:
      return 'Username or email already exists.';
    default:
      return 'Registration failed. Please try again.';
  }
}

Future<Map<String, dynamic>> createTask({
  required String title,
  required String description,
  required String category,
  double? budget,
  DateTime? deadline,
  String? skills,
  bool isUrgent = false,
}) async {
  try {
    final String? token = await _getUserToken();
    
    final response = await http.post(
      Uri.parse(createTaskUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'description': description,
        'category': category,
        'budget': budget,
        'deadline': deadline?.toIso8601String().split('T')[0], // Date only for DateField
        'required_skills': skills,
        'is_urgent': isUrgent,
        // No employer field - it will be set automatically from the authenticated user
      }),
    );

    print('Create Task Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return {
        'success': true,
        'message': 'Task created successfully!',
        'data': responseData,
      };
    } else {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 
                errorData['message'] ?? 
                'Failed to create task. Status: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    print('Create Task Error: $e');
    return {
      'success': false,
      'error': 'Network error: $e',
    };
  }
}
// Fetch employer tasks - Updated
Future<Map<String, dynamic>> fetchEmployerTasks() async {
  try {
    final String? token = await _getUserToken();
    
    final response = await http.get(
      Uri.parse(employerTasksUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'tasks': data['tasks'] ?? data['data'] ?? [],
        'stats': data['stats'] ?? data['statistics'] ?? {},
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to load tasks: ${response.statusCode}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Network error: $e',
    };
  }
}

// Get task statistics
Future<Map<String, dynamic>> fetchTaskStats() async {
  try {
    final String? token = await _getUserToken();
    
    final response = await http.get(
      Uri.parse(taskStatsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'stats': data,
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to load task statistics',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Network error: $e',
    };
  }
}

 Future<Map<String, dynamic>> getContract(String contractId) async {
    try {
      final response = await http.get(
        Uri.parse(getContractUrl),
        
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load contract: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load contract: $e');
    }
  }

  // Accept contract
  Future<Map<String, dynamic>> apiacceptContract(String contractId) async {
    try {
      final response = await http.post(
        Uri.parse(acceptcontractUrl),
       
        body: json.encode({'accepted': true}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to accept contract: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to accept contract: $e');
    }
  }
  // Get contracts by employer
  Future<List<dynamic>> getEmployerContracts(String employerId) async {
    try {
      final response = await http.get(
        Uri.parse(employerIdcontractUrl),
        
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load contracts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load contracts: $e');
    }
  }

  // Get contracts by freelancer
  Future<List<dynamic>> getFreelancerContracts(String freelancerId) async {
    try {
      final response = await http.get(
        Uri.parse(freelancercontractUrl),
       
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load contracts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load contracts: $e');
    }
  }
   final String? token;

  ApiService({this.token});

  Map<String, String> get headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

Future<List<dynamic>> getFreelancerProposals() async {
  try {
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

  
    final response = await http.get(
      Uri.parse(freelancerproposalsUrl),
      headers: headers,
    );

  
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load proposals: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load proposals: $e');
  }
}

 
Future<Map<String, dynamic>> acceptProposal(String proposalId) async {
  try {
    final response = await http.post(
      Uri.parse(acceptproposalUrl), 
      headers: headers,
      body: json.encode({
        'proposal_id': proposalId, 
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to accept proposal: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to accept proposal: $e');
  }
}


Future<Map<String, dynamic>> rejectProposal(String proposalId) async {
  try {
    final response = await http.post(
      Uri.parse(rejectproposalUrl), 
      headers: headers,
      body: json.encode({
        'proposal_id': proposalId, 
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reject proposal: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to reject proposal: $e');
  }
}
   Future<Map<String, dynamic>> getEmployerProfile(int employerId) async {
    final response = await http.get(Uri.parse(employerprofileUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load profile");
    }
  }

    Future<Map<String, dynamic>> apigetEmployerProfile(int employerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employers/$employerId/profile/'),
     headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load employer profile');
    }
  }

  Future<bool> updateEmployerProfile(
      int employerId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/employers/$employerId/profile/'), 
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to update employer profile');
    }
  }


Future<bool> apisubmitRating(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse(freelancerrateUrl),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", 
    },
    body: jsonEncode(data),
  );

  return response.statusCode == 201;
}
Future<List<dynamic>> getTasksForRating() async {
  try {

    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse(tasktorateUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
    );

    print('Tasks for Rating API Response:');
    print('URL: $tasktorateUrl');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load tasks: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getTasksForRating: $e');
    rethrow;
  }
}  
Future<bool> apifreelancersubmitRating(Map<String, dynamic> data) async {
  try {

    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse(freelancerrateUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
      body: jsonEncode(data),
    );

    print('Submit Rating API Response:');
    print('URL: $freelancerrateUrl');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    return response.statusCode == 201;
  } catch (e) {
    print('Error in apisubmitRating: $e');
    rethrow;
  }
}
// Add this method to your ApiService class
Future<List<dynamic>> getCompletedTasksForRating(int employerId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse(taskforratingUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('Completed Tasks for Rating API Response:');
    print('URL: $tasktorateUrl');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load completed tasks: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getCompletedTasksForRating: $e');
    rethrow;
  }
}

  //  Employer accepts contract
  Future<void> acceptContractapi() async {
    final response = await http.post(
      Uri.parse(acceptcontractUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to accept contract");
    }
  }


Future<Map<String, dynamic>> createRating({
  required int taskId,
  required int ratedUserId,
  required int score,
  String review = '',
}) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/ratings/create/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'task': taskId,
        'rated_user': ratedUserId,
        'score': score,
        'review': review,
        // 'rater' is automatically set by backend from request.user
      }),
    );

    print('Create Rating API Response:');
    print('URL: $baseUrl/api/ratings/create/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ?? 'Rating created successfully',
        'rating_id': responseData['rating_id'],
        'data': responseData
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create rating');
    } else {
      throw Exception('Failed to create rating: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in createRating: $e');
    rethrow;
  }
}

// Get ratings for a specific user (matches your get_user_ratings endpoint)
Future<List<dynamic>> getUserRatings(int userId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/ratings/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('User Ratings API Response:');
    print('URL: $baseUrl/api/users/$userId/ratings/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user ratings: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getUserRatings: $e');
    rethrow;
  }
}

// Get ratings for a specific task (matches your get_task_ratings endpoint)
Future<List<dynamic>> getTaskRatings(int taskId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/$taskId/ratings/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('Task Ratings API Response:');
    print('URL: $baseUrl/api/tasks/$taskId/ratings/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('You don\'t have permission to view ratings for this task');
    } else {
      throw Exception('Failed to fetch task ratings: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getTaskRatings: $e');
    rethrow;
  }
}

// Get submission stats (matches your submission_stats endpoint)
Future<Map<String, dynamic>> getSubmissionStats() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/submissions/stats/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('Submission Stats API Response:');
    print('URL: $baseUrl/api/submissions/stats/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch submission stats: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getSubmissionStats: $e');
    rethrow;
  }
}



// Employer rates Freelancer
Future<Map<String, dynamic>> submitEmployerRating({
  required int taskId,
  required int freelancerId,
  required int score,
  String review = '',
}) async {
  return await createRating(
    taskId: taskId,
    ratedUserId: freelancerId,
    score: score,
    review: review,
  );
}

// Freelancer rates Employer
Future<Map<String, dynamic>> submitFreelancerRating({
  required int taskId,
  required int employerId,
  required int score,
  String review = '',
}) async {
  return await createRating(
    taskId: taskId,
    ratedUserId: employerId,
    score: score,
    review: review,
  );
}

// Get current user's received ratings
 Future<List<dynamic>> getMyReceivedRatings() async {
  final currentUserId = await _getCurrentUserId();
  return await getUserRatings(currentUserId);
}

// Get employer's received ratings
Future<List<dynamic>> getEmployerReceivedRatings(int employerId) async {
  return await getUserRatings(employerId);
}

// Get freelancer's received ratings
Future<List<dynamic>> getFreelancerReceivedRatings(int freelancerId) async {
  return await getUserRatings(freelancerId);
}
 
  

 Future<String?> initializePayment(double amount) async {
    var url = Uri.parse("$baseUrl/payment/initialize/");
    var response = await http.post(url, body: {
      'amount': amount.toString(),
    });

    if (response.statusCode == 302) {
      // Django redirects directly to checkout link
      return response.headers['location'];
    } else if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data']['link']; // in case you return JSON with link
    } else {
      print("Error: ${response.body}");
      return null;
    }
  }
 Future<Map<String, dynamic>> submitTask({
  required int taskId,
  required String title,
  required String description,
  String? repoUrl,
  String? commitHash,
  String? stagingUrl,
  String? liveDemoUrl,
  String? apkUrl,
  String? testflightLink,
  String? adminUsername,
  String? adminPassword,
  String? accessInstructions,
  String? deploymentInstructions,
  String? testInstructions,
  String? releaseNotes,
  String? revisionNotes,
  required bool checklistTestsPassing,
  required bool checklistDeployedStaging,
  required bool checklistDocumentation,
  required bool checklistNoCriticalBugs,
  PlatformFile? zipFile,
  PlatformFile? screenshots,
  PlatformFile? videoDemo,
}) async {
  try {
    // Get authentication token
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found. Please log in.');
    }

    // CORRECT URL - Must match Django endpoint
    var uri = Uri.parse("$baseUrl/api/submissions/create/");
    
    var request = http.MultipartRequest("POST", uri);

    // ========== FORM FIELDS - CORRECTED ==========
    // NOTE: Django expects 'task' (not 'task_id')
    request.fields['task'] = taskId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    
    // Optional URL fields
    if (repoUrl != null && repoUrl.isNotEmpty) {
      request.fields['repo_url'] = repoUrl;
    }
    if (commitHash != null && commitHash.isNotEmpty) {
      request.fields['commit_hash'] = commitHash;
    }
    if (stagingUrl != null && stagingUrl.isNotEmpty) {
      request.fields['staging_url'] = stagingUrl;
    }
    if (liveDemoUrl != null && liveDemoUrl.isNotEmpty) {
      request.fields['live_demo_url'] = liveDemoUrl;
    }
    if (apkUrl != null && apkUrl.isNotEmpty) {
      request.fields['apk_download_url'] = apkUrl;
    }
    if (testflightLink != null && testflightLink.isNotEmpty) {
      request.fields['testflight_link'] = testflightLink;
    }
    
    // Admin credentials (optional)
    if (adminUsername != null && adminUsername.isNotEmpty) {
      request.fields['admin_username'] = adminUsername;
    }
    if (adminPassword != null && adminPassword.isNotEmpty) {
      request.fields['admin_password'] = adminPassword;
    }
    
    // Instructions (optional)
    if (accessInstructions != null && accessInstructions.isNotEmpty) {
      request.fields['access_instructions'] = accessInstructions;
    }
    if (deploymentInstructions != null && deploymentInstructions.isNotEmpty) {
      request.fields['deployment_instructions'] = deploymentInstructions;
    }
    if (testInstructions != null && testInstructions.isNotEmpty) {
      request.fields['test_instructions'] = testInstructions;
    }
    
    // Notes (optional)
    if (releaseNotes != null && releaseNotes.isNotEmpty) {
      request.fields['release_notes'] = releaseNotes;
    }
    if (revisionNotes != null && revisionNotes.isNotEmpty) {
      request.fields['revision_notes'] = revisionNotes;
    }

    // Checklist fields - must be boolean strings
    request.fields['checklist_tests_passing'] = checklistTestsPassing.toString();
    request.fields['checklist_deployed_staging'] = checklistDeployedStaging.toString();
    request.fields['checklist_documentation'] = checklistDocumentation.toString();
    request.fields['checklist_no_critical_bugs'] = checklistNoCriticalBugs.toString();

    // ========== FILE UPLOADS ==========
    if (zipFile != null && zipFile.path != null && File(zipFile.path!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'zip_file',
        zipFile.path!
      ));
    }
    
    if (screenshots != null && screenshots.path != null && File(screenshots.path!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'screenshots',
        screenshots.path!
      ));
    }
    
    if (videoDemo != null && videoDemo.path != null && File(videoDemo.path!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'video_demo',
        videoDemo.path!
      ));
    }

    // ========== AUTHENTICATION ==========
    // Based on your existing code, you use Bearer token
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    print('=================================');
    print('SUBMITTING TASK TO DJANGO');
    print('=================================');
    print('Endpoint: ${uri.toString()}');
    print('Task ID: $taskId');
    print('Title: $title');
    print('Has files: ${zipFile != null || screenshots != null || videoDemo != null}');
    print('Authorization: Bearer ${token.substring(0, 20)}...');
    
    // Log all fields being sent
    print('\nFields being sent:');
    request.fields.forEach((key, value) {
      print('  $key: $value');
    });
    
    if (request.files.isNotEmpty) {
      print('\nFiles being sent:');
      for (var file in request.files) {
        print('  ${file.field}: ${file.filename}');
      }
    }

    // ========== SEND REQUEST ==========
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('\n=================================');
    print('RESPONSE FROM DJANGO');
    print('=================================');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    // ========== HANDLE RESPONSE ==========
    if (response.statusCode == 201) {
      // Success - submission created
      final responseData = json.decode(response.body);
      print(' Submission successful!');
      print('Submission ID: ${responseData['submission_id']}');
      
      return {
        'success': true,
        'message': 'Submission created successfully',
        'submission_id': responseData['submission_id'],
        'data': responseData
      };
      
    } else if (response.statusCode == 200) {
      // Some APIs return 200 instead of 201
      final responseData = json.decode(response.body);
      print(' Submission successful (200)!');
      
      return {
        'success': true,
        'message': responseData['message'] ?? 'Submission successful',
        'submission_id': responseData['submission_id'],
        'data': responseData
      };
      
    } else if (response.statusCode == 400) {
      // Validation errors
      final errorData = json.decode(response.body);
      print(' Validation failed');
      
      String errorMessage = 'Validation failed';
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('details')) {
          errorMessage = 'Validation errors: ${errorData['details']}';
        } else {
          // Try to extract field-specific errors
          errorMessage = '';
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorMessage += '$key: ${value[0]}\n';
            }
          });
          errorMessage = errorMessage.trim();
        }
      }
      
      throw Exception(errorMessage);
      
    } else if (response.statusCode == 403) {
      // Permission denied
      print(' Permission denied');
      throw Exception('Permission denied. Are you assigned to this task?');
      
    } else if (response.statusCode == 404) {
      // Task not found
      print(' Task not found');
      throw Exception('Task not found or you are not assigned to it');
      
    } else if (response.statusCode == 401) {
      // Unauthorized
      print(' Unauthorized - token may be invalid');
      throw Exception('Session expired. Please log in again.');
      
    } else {
      // Other errors
      print(' Server error: ${response.statusCode}');
      throw Exception('Failed to submit task: ${response.statusCode}');
    }
    
  } catch (e) {
    print('\n=================================');
    print('EXCEPTION IN submitTask()');
    print('=================================');
    print('Error: $e');
    print('Error type: ${e.runtimeType}');
    
    // Rethrow with clearer message
    if (e is http.ClientException) {
      throw Exception('Network error: Please check your internet connection');
    } else if (e is FormatException) {
      throw Exception('Invalid server response');
    } else {
      throw Exception('Submission failed: $e');
    }
  }
}

  Future<List<Map<String, dynamic>>> fetchSubmissions() async {
  try {
    // Get authentication token
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found. Please log in.');
    }

    // CORRECT URL - Must match Django endpoint
    final uri = Uri.parse("$baseUrl/api/submissions/list/");
    
    final response = await http.get(
      uri, 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
    );

    print('=================================');
    print('FETCHING SUBMISSIONS FROM DJANGO');
    print('=================================');
    print('Endpoint: ${uri.toString()}');
    print('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      print(' Submissions fetched successfully');
      
      // Handle different response formats
      if (data is Map && data.containsKey('submissions')) {
        print('Format: Map with "submissions" key');
        return List<Map<String, dynamic>>.from(data['submissions']);
        
      } else if (data is Map && data.containsKey('data')) {
        print('Format: Map with "data" key');
        return List<Map<String, dynamic>>.from(data['data']);
        
      } else if (data is List) {
        print('Format: Direct List');
        return List<Map<String, dynamic>>.from(data);
        
      } else if (data is Map && data.containsKey('results')) {
        print('Format: Paginated results');
        return List<Map<String, dynamic>>.from(data['results']);
        
      } else {
        print('Warning: Unknown response format');
        return [];
      }
      
    } else if (response.statusCode == 401) {
      print(' Unauthorized');
      throw Exception('Session expired. Please log in again.');
      
    } else if (response.statusCode == 403) {
      print(' Permission denied');
      throw Exception('You don\'t have permission to view submissions');
      
    } else {
      print(' Server error: ${response.statusCode}');
      throw Exception('Failed to fetch submissions: ${response.statusCode}');
    }
    
  } catch (e) {
    print('\n=================================');
    print('EXCEPTION IN fetchSubmissions()');
    print('=================================');
    print('Error: $e');
    
    if (e is http.ClientException) {
      throw Exception('Network error: Please check your internet connection');
    } else {
      throw Exception('Failed to load submissions: $e');
    }
  }
}
Future<List<dynamic>> getOrdersForPayment() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/pending-payment/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('Orders for Payment API Response:');
    print('URL: $baseUrl/api/orders/pending-payment/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('orders')) {
        return data['orders'];
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to load orders: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getOrdersForPayment: $e');
    rethrow;
  }
}

// Get order details by ID
Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load order details: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getOrderDetails: $e');
    rethrow;
  }
}

// Get current user's orders
Future<List<dynamic>> getUserOrders() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/user/orders/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('orders')) {
        return data['orders'];
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to load user orders: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in getUserOrders: $e');
    rethrow;
  }
}

  Future<double> getBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/freelancer/wallet/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['balance']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to fetch balance');
    }
  }

  Future<bool> withdraw(double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/freelancer/withdraw/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == true;
    } else {
      return false;
    }
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }
 static Future<List<dynamic>> fetchRecommendedJobs(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/freelancer/recommended-jobs/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Recommended jobs API status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Recommended jobs API response: $data");
        
        if (data["status"] == true) {
          return data["recommended"] ?? [];
        } else {
          print("API returned false status: ${data['message']}");
          return [];
        }
      } else {
        print("API error: ${response.statusCode}");
        throw Exception('Failed to load recommended jobs: ${response.statusCode}');
      }
    } catch (error) {
      print("API exception: $error");
      rethrow;
    }
  }

}  