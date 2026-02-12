import 'dart:math';
import 'package:flutter/src/widgets/framework.dart';
import 'package:helawork/api_config.dart';
import 'package:helawork/freelancer/model/contract_model.dart';
import 'package:helawork/freelancer/model/proposal_model.dart';

import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
class ApiService{
  static const String baseUrl = 'https://marketplace-system-1.onrender.com';
  
  //static const String baseUrl = 'http://192.168.100.188:8000';
 
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
  
  static const String employerratingsUrl ='$baseUrl/apifetchratings';
  static const String taskforratingUrl = '$baseUrl/completetask';
  static const String clientProposalsUrl= '$baseUrl/client/proposals/';

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
// 1. Updated for EMPLOYERS to see tasks they need to rate
Future<dynamic> getEmployerRateableTasks() async { // Changed return type to dynamic
  try {
    final String? token = await _getUserToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/employer/rateable/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", 
      },
    );

    // If successful, decode and return the raw data (List or Map)
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Return a Map with the error so the Provider can catch it gracefully
      return {
        'success': false, 
        'error': "Error ${response.statusCode}: ${response.body}"
      };
    }
  } catch (e) {
    print('❌ Error in getEmployerRateableTasks: $e');
    // Return a Map so the Provider's "response is Map" check works
    return {'success': false, 'error': e.toString()};
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
  

 Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profile, String token) async {  // Remove userId parameter
  try {
    const String url = "$baseUrl/apiuserprofile";

    var request = http.MultipartRequest("PUT", Uri.parse(url));

    // Headers only - NO user_id in fields
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add profile fields (EXCEPT user_id)
    profile.forEach((key, value) {
      if (value != null && value is! File && key != 'user_id') {  // Skip user_id
        request.fields[key] = value.toString();
      }
    });

    // Handle profile picture
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
      var responseData = json.decode(response.body);
      return {
        "success": true,
        "message": responseData["message"] ?? "Profile updated successfully",
        "data": responseData,
      };
    } else if (response.statusCode == 401) {
      return {"success": false, "message": "Unauthorized. Please log in again."};
    } else {
      var errorData = json.decode(response.body);
      return {
        "success": false,
        "message": errorData["errors"] ?? "Failed: ${response.statusCode}"
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
 Future<Map<String, dynamic>?> getUserProfile([String? externalToken]) async {
  try {
    print(' =========== START getUserProfile ===========');
    
    // Use the external token if provided, otherwise get from storage
    String? token;
    if (externalToken != null) {
      token = externalToken;
      print(' Using external token for profile');
      print(' Token preview: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}');
    } else {
      token = await _getUserToken();
      print(' Using stored token for profile');
      print(' Token preview: ${token != null && token.length > 20 ? '${token.substring(0, 20)}...' : token}');
    }
    
    if (token == null || token.isEmpty) {
      print(' No authentication token found');
      print(' =========== END getUserProfile ===========');
      return {
        'success': false,
        'message': 'No authentication token found',
      };
    }

    print(' Making GET request to: $baseUrl/apiuserprofile');
    
    final stopwatch = Stopwatch()..start();
    final response = await http.get(
      Uri.parse('$baseUrl/apiuserprofile'),
      headers: {
        'Authorization': 'Bearer $token', 
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    stopwatch.stop();
    
    print('  Request took: ${stopwatch.elapsedMilliseconds}ms');
    print(' Response Status Code: ${response.statusCode}');
    print(' Response Headers: ${response.headers}');
    
    // Print response body with formatting
    print(' Raw Response Body:');
    print('-' * 50);
    print(response.body);
    print('-' * 50);
    
    // Try to parse the JSON
    try {
      final data = json.decode(response.body);
      print(' JSON parsed successfully');
      print(' Response data type: ${data.runtimeType}');
      
      if (data is Map) {
        print('  Response keys: ${data.keys.toList()}');
        
        // Check for success flag
        if (data.containsKey('success')) {
          print(' Has "success" key: ${data['success']}');
        } else {
          print(' Missing "success" key');
        }
        
        // Check for profile data
        if (data.containsKey('profile')) {
          final profile = data['profile'];
          print(' Has "profile" key');
          print(' Profile type: ${profile.runtimeType}');
          
          if (profile == null) {
            print('  Profile is null');
          } else if (profile is Map) {
            print('  Profile keys: ${profile.keys.toList()}');
            print(' Profile data: $profile');
          } else if (profile is String) {
            print(' Profile is a string: $profile');
          }
        } else {
          print(' Missing "profile" key');
        }
        
        // Check for message
        if (data.containsKey('message')) {
          print(' Message: ${data['message']}');
        }
      } else if (data is List) {
        print(' Response is a List with ${data.length} items');
      }
      
      print(' =========== END getUserProfile ===========');
      return Map<String, dynamic>.from(data);
      
    } catch (e) {
      print(' JSON parsing error: $e');
      print(' Response body that failed to parse: ${response.body}');
      print(' =========== END getUserProfile ===========');
      return {
        'success': false,
        'message': 'Failed to parse response: $e',
        'raw_response': response.body,
      };
    }
    
  } catch (e) {
    print(' Network/HTTP error: $e');
    print(' =========== END getUserProfile ===========');
    return {
      'success': false,
      'message': 'Network error: $e',
    };
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
 static Future<Map<String, dynamic>> rateClientByFreelancer({
    required int taskId,
    required int clientId,
    required int freelancerId,
    required int score,
    String? review,
  }) async {
    final body = {
      "task": taskId,
      "rated_user": clientId,      // Client being rated
      "rater_user": freelancerId,  // Freelancer doing the rating
      "score": score,
      "review": review ?? "",
      "rating_type": "client_rating",
    };

    return await ApiService.postData('/ratings/', body);
  }

  // For employers rating freelancers (if needed)
  static Future<Map<String, dynamic>> rateFreelancerByEmployer({
    required int taskId,
    required int freelancerId,
    required int employerId,
    required int score,
    String? review,
  }) async {
    final body = {
      "task": taskId,
      "rated_user": freelancerId,  
      "rater_user": employerId,    
      "score": score,
      "review": review ?? "",
      "rating_type": "freelancer_rating",
    };

    return await ApiService.postData('/ratings/', body);
  }
// In api_service.dart
static Future<Proposal> submitProposal(Proposal proposal, {required PlatformFile pdfFile}) async {
  try {
    final String? token = await _getUserToken();
    if (token == null) throw Exception("User not authenticated. Please log in again.");

    // Validate File
    if (pdfFile.bytes == null) throw Exception("PDF file is corrupted (no bytes).");

    final request = http.MultipartRequest('POST', Uri.parse(ProposalUrl))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields.addAll({
        'task': proposal.taskId.toString(),
        'bid_amount': proposal.bidAmount.toString(),
        'status': proposal.status,
        'estimated_days': proposal.estimatedDays.toString(),
        'cover_letter': proposal.coverLetter.isEmpty 
            ? 'Proposal for task ${proposal.taskId}' 
            : proposal.coverLetter,
      })
      ..files.add(http.MultipartFile.fromBytes(
        'cover_letter_file',
        pdfFile.bytes!,
        filename: pdfFile.name,
        contentType: MediaType('application', 'pdf'),
      ));

    debugPrint('🚀 Sending Proposal to: $ProposalUrl');

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final decodedData = json.decode(responseBody);

    return _handleProposalResponse(response.statusCode, decodedData, responseBody);
    
  } catch (e, stackTrace) {
    debugPrint('❌ Submission Error: $e\n$stackTrace');
    throw Exception(e.toString().replaceAll("Exception: ", ""));
  }
}

// Add this new method for proposals without PDF
static Future<Proposal> submitProposalWithoutPdf(Proposal proposal) async {
  try {
    final String? token = await _getUserToken();
    if (token == null) throw Exception("User not authenticated. Please log in again.");

    final response = await http.post(
      Uri.parse(ProposalUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'task': proposal.taskId,
        'bid_amount': proposal.bidAmount,
        'status': proposal.status,
        'estimated_days': proposal.estimatedDays,
        'cover_letter': proposal.coverLetter.isEmpty 
            ? 'Proposal for task ${proposal.taskId}' 
            : proposal.coverLetter,
      }),
    );

    debugPrint('🚀 Sending Proposal without PDF to: $ProposalUrl');

    return _handleProposalResponse(response.statusCode, json.decode(response.body), response.body);
    
  } catch (e, stackTrace) {
    debugPrint('❌ Submission Error (no PDF): $e\n$stackTrace');
    throw Exception(e.toString().replaceAll("Exception: ", ""));
  }
}

// Make sure _handleProposalResponse exists
static Proposal _handleProposalResponse(int statusCode, Map<String, dynamic> decodedData, String responseBody) {
  if (statusCode >= 200 && statusCode < 300) {
    debugPrint('✅ Proposal submitted successfully');
    return Proposal.fromJson(decodedData);
  } else {
    debugPrint('❌ Failed to submit proposal: ${decodedData['error'] ?? responseBody}');
    throw Exception(decodedData['error'] ?? 'Failed to submit proposal');
  }
}
static Future<List<Map<String, dynamic>>> fetchTasks(http.Response response, {required BuildContext context}) async {
  try {
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      List<dynamic> tasksList = [];

      if (data is Map && data.containsKey('tasks')) {
        tasksList = data['tasks'];
      } else if (data is List) {
        tasksList = data;
      }

      if (tasksList.isEmpty) {
        return [{"id": 0, "title": "No tasks available", "employer": {"username": "System"}}];
      }

      return tasksList.map((task) {
        final mappedTask = Map<String, dynamic>.from(task);
        
        // standard ID mapping
        mappedTask['id'] = mappedTask['id'] ?? mappedTask['task_id'] ?? 0;
        
        // HYBRID MODEL FIELDS
        mappedTask['service_type'] = mappedTask['service_type'] ?? 'remote';
        mappedTask['payment_type'] = mappedTask['payment_type'] ?? 'fixed';
        mappedTask['location_address'] = mappedTask['location_address'] ?? 'No location provided';
        mappedTask['latitude'] = mappedTask['latitude']; 
        mappedTask['longitude'] = mappedTask['longitude'];
        mappedTask['is_urgent'] = mappedTask['is_urgent'] ?? false;
        
        // Existing status/employer mapping
        mappedTask['overall_status'] = mappedTask['overall_status'] ?? mappedTask['status'] ?? 'open';
        mappedTask['employer'] = mappedTask['employer'] ?? {'username': 'Unknown Client'};
        
        return mappedTask;
      }).toList();
    } else {
      throw Exception("Failed to load tasks: ${response.statusCode}");
    }
  } catch (e) {
    print('Error mapping hybrid task data: $e');
    rethrow;
  }
}
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

// In ApiService class, FIX this method:
Future<List<Contract>> fetchContracts() async {
  try {
    // Use _getUserToken() instead of _getToken()
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception("No authentication token found. Please login.");
    }

    print("Fetching contracts with token: ${token.substring(0, 20)}...");
    
    final response = await http.get(
      Uri.parse(contractUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Contracts API Status: ${response.statusCode}");
    print("Contracts API Body (first 500 chars): ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}");

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      
      // Handle different response formats
      if (data is List) {
        // Format: Direct list [ {...}, {...} ]
        print("Detected format: Direct List");
        return data.map((json) => Contract.fromJson(json)).toList();
        
      } else if (data is Map) {
        if (data.containsKey('contracts') && data['contracts'] is List) {
          // Format: {"contracts": [...], "status": true}
          print("Detected format: Wrapped with 'contracts' key");
          final contractsData = data['contracts'] as List;
          return contractsData.map((json) => Contract.fromJson(json)).toList();
          
        } else if (data.containsKey('data') && data['data'] is List) {
          // Format: {"data": [...], "success": true}
          print("Detected format: Wrapped with 'data' key");
          final contractsData = data['data'] as List;
          return contractsData.map((json) => Contract.fromJson(json)).toList();
          
        } else {
          print("Unexpected Map format. Keys: ${data.keys}");
          throw Exception("Unexpected response format from server");
        }
        
      } else {
        print("Unknown response type: ${data.runtimeType}");
        throw Exception("Unknown response format from server");
      }
      
    } else if (response.statusCode == 401) {
      throw Exception("Authentication expired. Please login again.");
    } else if (response.statusCode == 500) {
      // Try to get error details
      try {
        final errorData = json.decode(response.body);
        throw Exception("Server Error: ${errorData['error'] ?? errorData['detail'] ?? 'Internal server error'}");
      } catch (_) {
        throw Exception("Server Error (500): ${response.body}");
      }
    } else {
      throw Exception("Failed to load contracts: ${response.statusCode}");
    }
    
  } catch (e) {
    print("Error in fetchContracts: $e");
    rethrow;
  }
}
 
 // Get freelancer's contracts
  Future<Map<String, dynamic>> fetchFreelancerContracts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/freelancer/contracts/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Authentication expired");
    } else if (response.statusCode == 404) {
      throw Exception("Endpoint not found");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  // Accept a contract
  Future<Map<String, dynamic>> acceptContract(String token, int contractId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/contracts/$contractId/accept/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception("Not authorized to accept this contract");
    } else {
      throw Exception("Failed to accept contract: ${response.statusCode}");
    }
  }

  // Reject a contract
  Future<Map<String, dynamic>> rejectContract(String token, int contractId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/contracts/$contractId/reject/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception("Not authorized to reject this contract");
    } else {
      throw Exception("Failed to reject contract: ${response.statusCode}");
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
  static Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // 🔥 Add this line! It forces a fresh look at the disk.
  return prefs.getString('user_token');
}
static Future<void> saveUserToken(String token) async {
  if (token.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_token', token);
  await prefs.reload(); // 🔥 Force disk sync
  final saved = prefs.getString('user_token');
  print("🛠 Token saved successfully: ${saved?.substring(0,5)}...");
}

static Future<String?> getUserToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Ensure latest value
  final token = prefs.getString('user_token');
  print("🔑 Token read: ${token?.substring(0,5) ?? 'null'}");
  return token;
}

  // Login API
 Future<Map<String, dynamic>> apilogin(String username, String password) async {
    try {
      print("=== LOGIN API CALL ===");
      final response = await http.post(
        Uri.parse(apiloginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await saveUserToken(data['token']); // Must await!
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'statusCode': response.statusCode, 'error': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Dashboard fetch
 Future<Map<String, dynamic>> fetchDashboardData() async {
  try {
    print("=== DASHBOARD API CALL ===");
    
    // 1. First attempt to get token
    String? token = await getUserToken();

    // 2. 🔥 If null, wait and retry (Race Condition Handler)
    if (token == null || token.isEmpty) {
      print("⏳ Token not found yet. Waiting 1.5 seconds for login to finish...");
      await Future.delayed(Duration(milliseconds: 1500));
      token = await getUserToken(); // Try again
    }

    if (token == null || token.isEmpty) {
      print("❌ Final Attempt: Token still null.");
      throw Exception("Unauthorized: Token not found. Please login.");
    }

    // 3. Proceed with Request
    final response = await http.get(
      Uri.parse(dashboardUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("Status Code: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? data;
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  } catch (e) {
    print("=== DASHBOARD ERROR === $e");
    rethrow;
  }
}
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
  required String serviceType,
  required String paymentType,
  double? budget,
  DateTime? deadline,
  String? skills,
  bool isUrgent = false,
  String? locationAddress,
  double? latitude,
  double? longitude,
}) async {
  try {
    final String? token = await _getUserToken();

    final Map<String, dynamic> requestBody = {
      'title': title,
      'description': description,
      'category': category,
      'service_type': serviceType,
      'payment_type': paymentType,
      'budget': budget,
      'deadline': deadline?.toIso8601String(),
      'required_skills': skills ?? '',
      'is_urgent': isUrgent,
      'location_address': locationAddress ?? '',
      'latitude': latitude,
      'longitude': longitude,
    };

    // Remove nulls except coords
    requestBody.removeWhere(
      (key, value) => value == null && !['latitude', 'longitude'].contains(key),
    );

    final response = await http.post(
      Uri.parse(createTaskUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Task created successfully!',
        'data': data,
      };
    }

    final error = response.body.isNotEmpty ? json.decode(response.body) : {};
    return {
      'success': false,
      'message': error['message'] ?? 'Failed to create task',
      'details': error,
    };

  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: $e',
    };
  }
}
Future<Map<String, dynamic>> fetchEmployerTasks() async {
  try {
    final String? token = await _getUserToken();

    final response = await http.get(
      Uri.parse(employerTasksUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'tasks': data['tasks'] ?? data,
      };
    }

    return {
      'success': false,
      'error': 'Server returned ${response.statusCode}',
    };

  } catch (e) {
    return {
      'success': false,
      'error': 'Connection error: $e',
    };
  }
}
Future<Map<String, dynamic>> deleteTask(int taskId) async {
  try {
    final String? token = await _getUserToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/tasks/$taskId/"),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    // 204 = No Content (Django default)
    if (response.statusCode == 200 || response.statusCode == 204) {
      return {
        'success': true,
        'message': 'Task deleted successfully',
      };
    }

    // Error response with body
    Map<String, dynamic> errorData = {};
    if (response.body.isNotEmpty) {
      try {
        errorData = json.decode(response.body);
      } catch (_) {}
    }

    return {
      'success': false,
      'message': errorData['message'] ??
          errorData['error'] ??
          'Failed to delete task',
    };

  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: $e',
    };
  }
}

// Helper method to get auth headers
Future<Map<String, String>> getAuthHeaders(BuildContext context) async {
  // Implement based on your authentication system
  // Example:
  // final authProvider = Provider.of<AuthProvider>(context, listen: false);
  // final token = authProvider.token;
  
  return {
    'Authorization': 'Bearer your-token-here', // Replace with actual token
    'Content-Type': 'application/json',
  };
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
  

// In ApiService.dart - Add this method
//
 Future<List<dynamic>> getFreelancerProposals() async {
  try {
    // Get token
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No employer token found. Please login as employer.');
    }

    print('Fetching employer proposals from: ${ApiService.baseUrl}/client/proposals/');
    
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/client/proposals/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Employer proposals response: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      
      if (data is List) {
        print('✅ Successfully loaded ${data.length} proposals');
        return data;
      } else if (data is Map && data.containsKey('proposals')) {
        final proposals = data['proposals'];
        print('✅ Found proposals key with ${proposals.length} item(s)');
        return proposals;
      } else if (data is Map && data.containsKey('data')) {
        final proposals = data['data'];
        print('✅ Found data key with ${proposals.length} item(s)');
        return proposals;
      } else if (data is Map && data.containsKey('results')) {
        final proposals = data['results'];
        print('✅ Found results key with ${proposals.length} item(s)');
        return proposals;
      } else if (data is Map) {
        print('⚠️ Map doesn\'t contain expected keys. Full data:');
        print(data);
        return [];
      } else {
        throw Exception('Unexpected response format');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Invalid employer token.');
    } else {
      throw Exception('Failed to load proposals: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error in getFreelancerProposals: $e');
    rethrow;
  }
}

// Get freelancer profile by ID
static Future<Map<String, dynamic>> getFreelancerProfile(String freelancerId) async {
  try {
    // Get token (employer token for clients)
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found. Please login.');
    }

    print('Fetching freelancer profile for ID: $freelancerId');
    print('URL: ${ApiService.baseUrl}/api/freelancers/$freelancerId/');
    
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/freelancers/$freelancerId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Freelancer profile response: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅ Successfully loaded freelancer profile');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 404) {
      throw Exception('Freelancer profile not found');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load profile: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getFreelancerProfile: $e');
    rethrow;
  }
}
// Get freelancer ratings/reviews
static Future<Map<String, dynamic>> getFreelancerRatings(String freelancerId, {int page = 1}) async {
  try {
    // Get token (employer token for clients)
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found. Please login.');
    }

    print('Fetching ratings for freelancer ID: $freelancerId');
    print('URL: ${ApiService.baseUrl}/api/freelancers/$freelancerId/ratings/?page=$page');
    
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/freelancers/$freelancerId/ratings/?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Freelancer ratings response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅ Successfully loaded freelancer ratings');
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load ratings');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 404) {
      // Return empty ratings if endpoint not found (some freelancers may have no ratings)
      return {
        'success': true,
        'ratings': [],
        'average_rating': 0.0,
        'total_ratings': 0
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load ratings: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getFreelancerRatings: $e');
    // Return empty ratings on error
    return {
      'success': false,
      'message': e.toString(),
      'ratings': [],
      'average_rating': 0.0,
      'total_ratings': 0
    };
  }
}
 
Future<Map<String, dynamic>> acceptProposal(String proposalId) async {
  try {
    // 1. Get the token FIRST
    final token = await _getUserToken(); 
    
    // 2. Validate the token
    if (token == null || token.isEmpty) {
      print('❌ ERROR: Token is null or empty!');
      return {
        'success': false,
        'message': 'Authentication required. Please login again.'
      };
    }
    
    print('🔐 Using token for acceptProposal: ${token.substring(0, 10)}...');
    
    // 3. Make the request with the validated token
    final response = await http.post(
      Uri.parse(acceptproposalUrl), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'proposal_id': proposalId, 
      }),
    );

    print('📡 Accept proposal response: ${response.statusCode}');
    print('📡 Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print('✅ Proposal accepted successfully: $result');
      
      // IMPORTANT: Check if we need to redirect to payment
      if (result['success'] == true && result['checkout_url'] != null) {
        // NEW: This means payment is required before work starts
        print('🔄 Redirecting to payment: ${result['checkout_url']}');
        return {
          'success': true,
          'requires_payment': true,  // NEW FLAG
          'checkout_url': result['checkout_url'],
          'order_id': result['order_id'],
          'payment_reference': result['payment_reference'],
          'message': result['message'] ?? 'Please complete payment',
          'data': result,
        };
      }
      
      return result;
    } else if (response.statusCode == 401) {
      print('🔐 Unauthorized - token might be invalid');
      return {
        'success': false,
        'message': 'Session expired. Please login again.'
      };
    } else {
      print('❌ Failed to accept proposal: ${response.statusCode}');
      print('Response body: ${response.body}');
      return {
        'success': false,
        'message': 'Failed to accept proposal: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('❌ Exception in acceptProposal: $e');
    return {
      'success': false,
      'message': 'Failed to accept proposal: $e'
    };
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
// CREATE employer profile - CORRECTED
Future<Map<String, dynamic>> createEmployerProfile(Map<String, dynamic> data) async {
  try {
    final token = await _getToken();
    

    print('Creating employer profile...');
    print('URL: $baseUrl/employers/profile/create/');
    print('Data: $data');
    
    final response = await http.post(
      Uri.parse('$baseUrl/employers/profile/create/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Profile created successfully',
        'data': responseData,
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Invalid or expired token. Please login again.');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      String errorMessage = 'Validation error';
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else {
          final errors = <String>[];
          errorData.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(", ")}');
            } else {
              errors.add('$key: $value');
            }
          });
          errorMessage = errors.join("\n");
        }
      }
      throw Exception(errorMessage);
    } else {
      throw Exception('Failed to create profile. Status: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error creating employer profile: $e');
    rethrow;
  }
}
// GET employer profile - FIXED to match Django response
Future<Map<String, dynamic>> getEmployerProfile() async {
  try {
    final token = await _getToken();
 

    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'data': data,
      };
    } else if (response.statusCode == 404) {
      // Django returns {'error': 'Profile not found. Create one first.'}
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Profile not found');
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting employer profile: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// Check if profile exists - FIXED to match Django view
Future<Map<String, dynamic>> checkProfileExists() async {
  try {
    final token = await _getToken();
    
  
    final response = await http.get(
      Uri.parse('$baseUrl/check_profile_exists/'), // CORRECT ENDPOINT
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'exists': data['exists'] ?? false,
        'profile': data['profile'],
        'success': true,
      };
    } else {
      return {
        'exists': false,
        'success': false,
        'error': 'Failed to check: ${response.statusCode}',
      };
    }
  } catch (e) {
    print('Error checking profile existence: $e');
    return {
      'exists': false,
      'success': false,
      'error': e.toString(),
    };
  }
}

// UPDATE ID number - FIXED to match Django response
Future<Map<String, dynamic>> updateIdNumber(String idNumber) async {
  try {
    final token = await _getToken();
  

    final response = await http.post(
      Uri.parse('$baseUrl/profile/upload-id/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({'id_number': idNumber}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'ID number updated successfully',
        'data': data,
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Validation failed');
    } else {
      throw Exception('Failed to update ID number: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating ID number: $e');
    rethrow;
  }
}

// VERIFY email - FIXED to match Django view
Future<Map<String, dynamic>> verifyEmail(String verificationToken) async {
  try {
    final token = await _getToken();
    
   

    final response = await http.post(
      Uri.parse('$baseUrl/profile/verify-email/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({'token': verificationToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Email verified successfully',
        'data': data['profile'],
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Verification failed');
    } else {
      throw Exception('Failed to verify email: ${response.statusCode}');
    }
  } catch (e) {
    print('Error verifying email: $e');
    rethrow;
  }
}

// VERIFY phone - FIXED to match Django view
Future<Map<String, dynamic>> verifyPhone(String verificationCode) async {
  try {
    final token = await _getToken();
    
   

    final response = await http.post(
      Uri.parse('$baseUrl/profile/verify-phone/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({'code': verificationCode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Phone verified successfully',
        'data': data['profile'],
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Verification failed');
    } else {
      throw Exception('Failed to verify phone: ${response.statusCode}');
    }
  } catch (e) {
    print('Error verifying phone: $e');
    rethrow;
  }
}

// UPLOAD profile picture - CORRECTED (use correct method name)
Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
  try {
    final token = await _getToken();

    print('Uploading profile picture...');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    
    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    final contentType = fileExtension == 'png' 
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
        contentType: contentType,
      ),
    );

    print('Sending upload request...');
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Upload response status: ${response.statusCode}');
    print('Upload response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Profile picture uploaded successfully',
        'data': responseData,
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again.');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception('Upload failed: ${errorData.toString()}');
    } else {
      throw Exception('Failed to upload picture: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error uploading profile picture: $e');
    rethrow;
  }
}

// UPDATE employer profile - CORRECTED (remove duplicate parameter)
Future<Map<String, dynamic>> updateEmployerProfile(Map<String, dynamic> data) async {
  try {
    final token = await _getToken();

    print('Updating employer profile...');
    print('URL: $baseUrl/profile/update/');
    print('Update data: $data');
    
    final response = await http.patch(
      Uri.parse('$baseUrl/profile/update/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    print('Update response status: ${response.statusCode}');
    print('Update response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Profile updated successfully',
        'data': responseData,
      };
    } else if (response.statusCode == 404) {
      throw Exception('Profile not found. Create profile first.');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception('Validation error: ${errorData.toString()}');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Invalid token. Please login again.');
    } else {
      throw Exception('Failed to update profile. Status: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Error updating employer profile: $e');
    rethrow;
  }
}
  // Test connection and get correct endpoints
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      // Test base URL
      final response = await http.get(Uri.parse('$baseUrl/dashboard'));
      
      if (response.statusCode == 200) {
        print('Server is reachable at: $baseUrl');
        
        // Try to discover API endpoints
        final apiResponse = await http.get(
          Uri.parse('$baseUrl/api/'),
          headers: {
            "Authorization": "Bearer ${await _getToken()}",
          },
        );
        
        if (apiResponse.statusCode == 200) {
          final apiData = jsonDecode(apiResponse.body);
          print('Available API endpoints: $apiData');
          return apiData;
        }
      }
      
      return {'status': 'Server reachable but API structure unknown'};
    } catch (e) {
      throw Exception('Cannot connect to server: $e');
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
      Uri.parse('$baseUrl/api/submissions-to-rate/'),
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
// In ApiService.dart - Update these methods:

// Change from: /api/users/$userId/ratings/
// To: /users/ratings/ (with user_id as query parameter)
static Future<List<dynamic>> getUserRatings(int userId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    // ✅ FIXED: Use correct endpoint with query parameter
    final response = await http.get(
      Uri.parse('$baseUrl/users/ratings/?user_id=$userId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('User Ratings API Response:');
    debugPrint('URL: $baseUrl/users/ratings/?user_id=$userId');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user ratings: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error in getUserRatings: $e');
    rethrow;
  }
}

// Change from: /api/contracts/rateable/
// To: /contracts/rateable/ (remove /api/ prefix)
static Future<dynamic> getRateableContracts() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/contracts/rateable/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Rateable Contracts API Response:');
    debugPrint('URL: $baseUrl/contracts/rateable/');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // Return the FULL response data (not just contracts)
      // Based on your logs, backend returns: {"success":true,"count":2,"tasks":[...]}
      return responseData;
    } else {
      throw Exception("Failed to load rateable contracts: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Error in getRateableContracts: $e');
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

Future<Map<String, dynamic>> submitEmployerRating({
  required int taskId,
  required int freelancerId,
  required int score,
  String review = '',
  Map<String, dynamic>? extendedData,
}) async {
  print(' DEBUG submitEmployerRating called with:');
  print('  taskId: $taskId (type: ${taskId.runtimeType})');
  print('  freelancerId: $freelancerId (type: ${freelancerId.runtimeType})');
  print('  score: $score (type: ${score.runtimeType})');
  
  final String? token = await _getUserToken();
  
  final Map<String, dynamic> requestBody = {
    'task': taskId,
    'rated_user': freelancerId,
    'score': score,
    'review': review,
  };

  if (extendedData != null) {
    requestBody['extended_data'] = jsonEncode(extendedData);
  }

  // NOTE: Ensure this URL matches your urls.py path exactly
  final response = await http.post(
    Uri.parse('$baseUrl/ratings/'), 
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Server Error');
  }
}
// 2. For FREELANCERS rating employers/clients (WITH contract field)
static Future<Map<String, dynamic>> createRating({
  required int taskId,
  required int ratedUserId,  // This is EMPLOYER being rated
  required int contractId,   // Freelancer needs contract ID
  required int score,
  String review = '',
  String ratingType = 'freelancer_to_employer',
}) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/ratings/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'task': taskId,
        'contract': contractId,  
        'rated_user': ratedUserId,  
        'score': score,
        'review': review,
        'rating_type': ratingType,
      }),
    );

    debugPrint('💼 Freelancer Create Rating:');
    debugPrint('   Task: $taskId, Employer: $ratedUserId, Contract: $contractId, Score: $score');
    debugPrint('   Response: ${response.statusCode}');
    debugPrint('   Body: ${response.body}');

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
    debugPrint('❌ Error in createRating: $e');
    rethrow;
  }
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
  required String taskId,
  required String title,
  required String description,
  String? url,
  PlatformFile? zipFile,
  PlatformFile? document,
}) async {
  try {
    final String? token = await _getUserToken();
    if (token == null) throw Exception('Please log in first.');

    // Endpoint must match your simplified Django URL
    var uri = Uri.parse("$baseUrl/api/submissions/create/");
    var request = http.MultipartRequest("POST", uri);

    // 1. Text Fields
    request.fields['task_id'] = taskId;
    request.fields['title'] = title;
    request.fields['description'] = description;
    
    if (url != null && url.isNotEmpty) {
      request.fields['url'] = url;
    }

    // 2. The 2 File Fields
    if (zipFile != null && zipFile.path != null) {
      request.files.add(await http.MultipartFile.fromPath('zip_file', zipFile.path!));
    }
    
    if (document != null && document.path != null) {
      request.files.add(await http.MultipartFile.fromPath('document', document.path!));
    }

    // 3. Headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // 4. Send & Handle
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return {'success': true, 'data': data};
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Submission failed');
    }
  } catch (e) {
    throw Exception(e.toString());
  }
}
    
  // In your ApiService class, add this ONE method:
Future<List<Map<String, dynamic>>> getAssignedTasks() async {
  try {
    final token = await _getUserToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/assigned/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('tasks')) {
        return List<Map<String, dynamic>>.from(data['tasks']);
      }
    }
    return [];
  } catch (e) {
    print('Error getting assigned tasks: $e');
    return [];
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

    // ✅ CORRECT: Use the pending orders endpoint
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/pending-payment/'),  // FIXED!
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
      if (data['status'] == true) {
        // Return orders array
        return data['orders'] ?? [];
      } else {
        // API returned status: false
        print('API returned false: ${data['message']}');
        return [];
      }
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      // No orders found or endpoint not found
      return [];
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

    // ✅ CORRECT: Use the correct endpoint
    final response = await http.get(
      Uri.parse('$baseUrl/api/payment/order/$orderId/'),  // FIXED!
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('Order Details API Response:');
    print('URL: $baseUrl/api/payment/order/$orderId/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      return {'status': false, 'message': 'Order not found'};
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

    // ✅ This endpoint might not exist - check your Django URLs
    final response = await http.get(
      Uri.parse('$baseUrl/api/payment/transactions/'),  // Changed to existing endpoint
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('User Orders API Response:');
    print('URL: $baseUrl/api/payment/transactions/');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data['transactions'] ?? [];
      } else {
        return [];
      }
    } else {
      return []; // Return empty if endpoint doesn't exist
    }
  } catch (e) {
    print('Error in getUserOrders: $e');
    return [];
  }
}
// Get current user's orders


  Future<double> getBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/freelancer/wallet/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
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
      print("🔍 Starting fetchRecommendedJobs");
      print("📡 Base URL: $baseUrl");
      print("📡 Endpoint: /freelancer/recommended-jobs/");
      print("🔑 Token length: ${token.length}");
      
      final response = await http.get(
        Uri.parse("$baseUrl/freelancer/recommended-jobs/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(Duration(seconds: 30));

      print("✅ Response status: ${response.statusCode}");
      print("📦 Response body length: ${response.body.length}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📊 Parsed data type: ${data.runtimeType}");
        print("📊 Data keys: ${data.keys.toList()}");
        
        // Debug: Print the structure
        if (data.containsKey("status")) {
          print("📊 Status: ${data["status"]}");
        }
        if (data.containsKey("message")) {
          print("📊 Message: ${data["message"]}");
        }
        if (data.containsKey("freelancer_profile")) {
          print("📊 Freelancer profile exists");
        }
        
        if (data["status"] == true) {
          final recommended = data["recommended"] ?? [];
          print("🎯 Recommended type: ${recommended.runtimeType}");
          print("🎯 Recommended length: ${recommended is List ? recommended.length : 'not a list'}");
          
          // Debug first few items
          if (recommended is List && recommended.isNotEmpty) {
            for (int i = 0; i < min(3, recommended.length); i++) {
              print("🎯 Item $i: ${recommended[i]["title"]}");
              print("🎯   Match Score: ${recommended[i]["match_score"]}");
              print("🎯   Skill Overlap: ${recommended[i]["skill_overlap"]}");
              print("🎯   Common Skills: ${recommended[i]["common_skills"]}");
            }
          }
          
          return recommended;
        } else {
          print("⚠️ API returned false status: ${data['message']}");
          return [];
        }
      } else {
        print("❌ API error ${response.statusCode}: ${response.body}");
        throw Exception('Failed to load recommended jobs: ${response.statusCode}');
      }
    } catch (error) {
      print("💥 Exception: $error");
      rethrow;
    }
  }
  // Add to ApiService.dart

// Get employer pending completions
static Future<List<dynamic>> getEmployerPendingCompletions() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/contracts/employer/pending-completions/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Pending Completions API Response:');
    debugPrint('URL: $baseUrl/contracts/employer/pending-completions/');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return responseData['contracts'] ?? [];
      }
      return [];
    } else {
      throw Exception("Failed to load pending completions: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Error in getEmployerPendingCompletions: $e');
    rethrow;
  }
}

// Mark contract as completed
static Future<Map<String, dynamic>> markContractCompleted(int contractId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/contracts/$contractId/mark-completed/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Mark Contract Completed API Response:');
    debugPrint('URL: $baseUrl/contracts/$contractId/mark-completed/');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to mark contract as completed');
    } else {
      throw Exception('Failed to mark contract as completed: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error in markContractCompleted: $e');
    rethrow;
  }
}

// Alternative version using the token from your example
static Future<Map<String, dynamic>> markContractCompleted2(int contractId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/contracts/$contractId/mark-completed/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Mark Contract Completed API Response:');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to mark contract as completed');
    }
  } catch (e) {
    debugPrint('Error in markContractCompleted2: $e');
    rethrow;
  }
}

// Get all employer contracts (not just pending completions)
static Future<List<dynamic>> getEmployerContracts() async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/contracts/employer/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Employer Contracts API Response:');
    debugPrint('URL: $baseUrl/contracts/employer/');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return responseData['contracts'] ?? [];
      }
      return [];
    } else {
      throw Exception("Failed to load employer contracts: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Error in getEmployerContracts: $e');
    rethrow;
  }
}

// Get specific contract details
static Future<Map<String, dynamic>> getContractDetails(int contractId) async {
  try {
    final String? token = await _getUserToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/contracts/$contractId/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint('Contract Details API Response:');
    debugPrint('URL: $baseUrl/contracts/$contractId/');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load contract details: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Error in getContractDetails: $e');
    rethrow;
  }
}
static Future<List<Map<String, dynamic>>> getFreelancerCompletedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null) {
        debugPrint("❌ No token found for freelancer completed tasks");
        return [];
      }
      
      debugPrint("📋 Fetching completed tasks from: ${AppConfig.getBaseUrl()}/api/tasks/freelancer/completed/");
      
      final response = await http.get(
        Uri.parse('${AppConfig.getBaseUrl()}/api/tasks/freelancer/completed/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint("📋 Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("📋 Response success: ${data['success']}");
        debugPrint("📋 Count: ${data['count']}");
        
        if (data['success'] == true) {
          final tasks = (data['completed_tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          debugPrint("✅ Loaded ${tasks.length} completed tasks");
          return tasks;
        } else {
          debugPrint("❌ API returned success: false");
          debugPrint("❌ Error message: ${data['error']}");
          return [];
        }
      } else {
        debugPrint("❌ Failed with status: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
        throw Exception('Failed to load completed tasks: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error fetching completed tasks: $e");
      rethrow;
    }
  }
// In api_service.dart - update getEmployerSubmissions method

static Future<List<dynamic>> getEmployerSubmissions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? prefs.getString('employer_token');
    
    if (token == null || token.isEmpty) {
      debugPrint("❌ No token found for employer submissions");
      return [];
    }
    
    debugPrint("📋 Fetching submissions from: ${AppConfig.getBaseUrl()}/api/submissions/employer/");
    debugPrint("📋 Token: ${token.substring(0, 20)}...");
    
    final response = await http.get(
      Uri.parse('${AppConfig.getBaseUrl()}/api/submissions/employer/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    debugPrint("📋 Response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("📋 Response success: ${data['success']}");
      debugPrint("📋 Count: ${data['count']}");
      
      if (data['success'] == true) {
        final submissions = data['submissions'] ?? [];
        debugPrint("✅ Loaded ${submissions.length} submissions");
        return submissions;
      } else {
        debugPrint("❌ API returned success: false");
        debugPrint("❌ Error message: ${data['error']}");
        return [];
      }
    } else if (response.statusCode == 500) {
      // Server error - try to parse error message
      try {
        final errorData = jsonDecode(response.body);
        debugPrint("❌ Server error: ${errorData['error']}");
        throw Exception(errorData['error'] ?? 'Server error');
      } catch (e) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } else {
      debugPrint("❌ Failed with status: ${response.statusCode}");
      debugPrint("❌ Response body: ${response.body}");
      throw Exception('Failed to load submissions: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("❌ Error fetching submissions: $e");
    rethrow;
  }
}
// Approve submission and mark contract as completed
static Future<Map<String, dynamic>> approveSubmission(int submissionId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? prefs.getString('employer_token');
    
    final response = await http.post(
      Uri.parse('${AppConfig.getBaseUrl()}/api/submissions/$submissionId/approve/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to approve submission');
  } catch (e) {
    print('Error approving submission: $e');
    rethrow;
  }
}

// Request revisions for submission
static Future<Map<String, dynamic>> requestRevision(int submissionId, String notes) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? prefs.getString('employer_token');
    
    final response = await http.post(
      Uri.parse('${AppConfig.getBaseUrl()}/api/submissions/$submissionId/request-revision/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to request revision');
  } catch (e) {
    print('Error requesting revision: $e');
    rethrow;
  }
}

  


}
 
