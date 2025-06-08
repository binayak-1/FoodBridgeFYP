import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_bridge/config/api_config.dart';
import 'package:food_bridge/providers/auth_provider.dart';

class AdminService {
  static const String baseUrl = ApiConfig.baseUrl;
  static const String adminEndpoint = ApiConfig.adminEndpoint;
  final AuthProvider _authProvider;

  AdminService(this._authProvider);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_authProvider.getToken()}',
  };

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminEndpoint/stats'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load dashboard statistics');
    } catch (e) {
      throw Exception('Error fetching dashboard statistics: $e');
    }
  }

  // User Management
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$adminEndpoint/users'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load users');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> verifyCharity(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$adminEndpoint/users/$userId/verify'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify charity');
      }
    } catch (e) {
      throw Exception('Error verifying charity: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$adminEndpoint/users/$userId'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Donation Management
  Future<List<Map<String, dynamic>>> getDonations() async {
    try {
      print('Fetching donations from: $baseUrl$adminEndpoint/donations');
      final response = await http.get(
        Uri.parse('$baseUrl$adminEndpoint/donations'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to load donations');
    } catch (e) {
      print('Error in getDonations: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDonationsByStatus(String status) async {
    try {
      print('Fetching donations by status from: $baseUrl$adminEndpoint/donations?status=$status');
      final response = await http.get(
        Uri.parse('$baseUrl$adminEndpoint/donations?status=$status'),
        headers: _headers,
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to load donations by status');
    } catch (e) {
      print('Error in getDonationsByStatus: $e');
      rethrow;
    }
  }
} 