import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_bridge/config/api_config.dart';
import 'dart:math';

class AuthProvider with ChangeNotifier {
  final String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCharity => _user?['role'] == 'charity';
  bool get isDonor => _user?['role'] == 'donor';
  bool get isAdmin => _user?['role'] == 'admin';

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    Map<String, dynamic>? address,
    Map<String, dynamic>? organizationDetails,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'phone': phone,
          if (address != null) 'address': address,
          if (organizationDetails != null) 'organizationDetails': organizationDetails,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _user = data['user'];
        await storage.write(key: 'token', value: _token);
        await storage.write(key: 'user', value: jsonEncode(_user));
      } else {
        throw data['message'] ?? 'Registration failed';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Attempting login for email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        print('Received token: ${_token?.substring(0, min(_token!.length, 10))}...');
        
        _user = Map<String, dynamic>.from(data['user']);
        print('Initial user data: $_user');
        
        await storage.write(key: 'token', value: _token);
        await storage.write(key: 'user', value: jsonEncode(_user));
        
        // Fetch complete profile data after login
        await fetchProfile();
      } else {
        print('Login failed with message: ${data['message']}');
        throw data['message'] ?? 'Login failed';
      }
    } catch (error) {
      print('Login error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    print('Logging out user');
    _token = null;
    _user = null;
    await storage.delete(key: 'token');
    await storage.delete(key: 'user');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      final token = await storage.read(key: 'token');
      final userStr = await storage.read(key: 'user');

      print('Auto login - Token exists: ${token != null}');
      print('Auto login - User data exists: ${userStr != null}');

      if (token != null && userStr != null) {
        _token = token;
        _user = jsonDecode(userStr);
        print('Restored token: ${_token?.substring(0, min(_token!.length, 10))}...');
        print('Restored user data: $_user');
        
        // Fetch fresh profile data
        await fetchProfile();
      }
    } catch (error) {
      print('Auto login error: $error');
      await logout(); // Clear invalid data
    }
  }

  Future<void> fetchProfile() async {
    try {
      if (_token == null) {
        print('No token available for profile fetch');
        throw 'Not authenticated';
      }

      print('Fetching profile with token: ${_token?.substring(0, min(_token!.length, 10))}...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Convert the response data to a Map and update user
        _user = Map<String, dynamic>.from(data);
        print('Updated user data: $_user');
        await storage.write(key: 'user', value: jsonEncode(_user));
        notifyListeners();
      } else {
        print('Profile fetch failed with message: ${data['message']}');
        throw data['message'] ?? 'Failed to fetch profile';
      }
    } catch (error) {
      print('Error fetching profile: $error');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    Map<String, dynamic>? address,
    Map<String, dynamic>? location,
    String? profileImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (location != null) 'location': location,
          if (profileImage != null) 'profileImage': profileImage,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _user = data['user'];
        await storage.write(key: 'user', value: jsonEncode(_user));
        notifyListeners();
      } else {
        throw data['message'] ?? 'Profile update failed';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getToken() {
    return _token;
  }
} 