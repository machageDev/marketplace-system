import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helawork/api_service.dart';

class UserProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic> _profile = {};
  bool _isLoading = false;
  String _errorMessage = '';
  bool _profileExists = false;

  Map<String, dynamic> get profile => _profile;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get profileExists => _profileExists;

  // Load profile from API
  Future<void> loadProfile() async {
    print('\n =========== START loadProfile ===========');
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print(' Reading token from secure storage...');
      final token = await _secureStorage.read(key: "auth_token");
      
      if (token == null || token.isEmpty) {
        print(' No auth token found in secure storage');
        _errorMessage = 'Please log in to view profile';
        _profileExists = false;
      } else {
        print(' Token found, length: ${token.length}');
        print(' Calling ApiService.getUserProfile()...');
        
        final response = await ApiService.getUserProfile(token);
        print(' Response received from ApiService');
        
        if (response != null) {
          print(' Response analysis:');
          print('   Type: ${response.runtimeType}');
          print('   Keys: ${response.keys.toList()}');
          
          if (response['success'] == true) {
            print(' API returned success');
            
            if (response.containsKey('profile')) {
              final profileData = response['profile'];
              print(' Profile data found in response');
              print('   Profile data type: ${profileData.runtimeType}');
              
              if (profileData == null) {
                print('  Profile data is null');
                _profile = {};
                _profileExists = false;
                _errorMessage = 'Profile data is empty';
              } else if (profileData is Map<String, dynamic>) {
                print(' Profile data is a Map');
                _profile = profileData;
                
                // Check if profile has actual data
                if (_profile.isNotEmpty) {
                  print(' Profile has ${_profile.length} fields');
                  print('   Profile fields: ${_profile.keys.toList()}');
                  _profileExists = true;
                  
                  // Print each field
                  _profile.forEach((key, value) {
                    print('   - $key: ${value ?? "null"} (${value.runtimeType})');
                  });
                } else {
                  print('  Profile Map is empty');
                  _profileExists = false;
                  _errorMessage = 'Profile exists but has no data';
                }
              } else if (profileData is String) {
                print('  Profile data is a String: $profileData');
                _profile = {'raw_data': profileData};
                _profileExists = false;
                _errorMessage = 'Unexpected profile format';
              } else {
                print('  Profile data is unexpected type: ${profileData.runtimeType}');
                print('   Data: $profileData');
                _profile = {};
                _profileExists = false;
                _errorMessage = 'Unexpected profile format';
              }
            } else {
              print(' No "profile" key in response');
              print('   Available keys: ${response.keys.toList()}');
              _profile = {};
              _profileExists = false;
              _errorMessage = response['message'] ?? 'No profile data in response';
            }
          } else {
            print(' API returned failure');
            _profile = {};
            _profileExists = false;
            _errorMessage = response['message'] ?? 'Failed to load profile';
            print('   Error message: $_errorMessage');
          }
        } else {
          print(' Response from ApiService is null');
          _profile = {};
          _profileExists = false;
          _errorMessage = 'No response from server';
        }
      }
    } catch (e) {
      print(' Exception in loadProfile: $e');
      print('Stack trace: ${e.toString()}');
      _errorMessage = 'Error loading profile: $e';
      _profile = {};
      _profileExists = false;
    }

    print('\n Final state after loadProfile:');
    print('   isLoading: $_isLoading');
    print('   profileExists: $_profileExists');
    print('   errorMessage: $_errorMessage');
    print('   profile isEmpty: ${_profile.isEmpty}');
    if (_profile.isNotEmpty) {
      print('   profile keys: ${_profile.keys.toList()}');
    }
    print(' =========== END loadProfile ===========\n');
    
    _isLoading = false;
    notifyListeners();
  }

  // Set profile field (for editing)
  void setProfileField(String key, dynamic value) {
    print(' Setting profile field: $key = $value');
    _profile[key] = value;
    notifyListeners();
  }

  // Save/Update profile
  Future<bool> saveProfile(BuildContext context) async {
    print(' Starting saveProfile');
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: "auth_token");
      if (token == null) {
        _errorMessage = 'Please log in to save profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print(' Sending profile data: $_profile');
      final response = await _apiService.updateUserProfile(_profile, token);
      
      if (response['success'] == true) {
        // Update local profile with server response
        if (response['data']?['profile'] != null) {
          _profile = response['data']['profile'];
          _profileExists = true;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to save profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save profile'),
            backgroundColor: Colors.red,
          ),
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error saving profile: $e';
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear profile data
  void clearProfile() {
    print(' Clearing profile data');
    _profile = {};
    _profileExists = false;
    notifyListeners();
  }
}