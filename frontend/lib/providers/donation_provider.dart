import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/services/notification_service.dart';
import 'package:food_bridge/config/api_config.dart';

class DonationProvider with ChangeNotifier {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthProvider authProvider;
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = false;
  String? _error;
  int _notificationId = 0;

  DonationProvider({required this.authProvider});

  List<Map<String, dynamic>> get donations => [..._donations];
  bool get isLoading => _isLoading;
  String? get error => _error;

  int _getNextNotificationId() {
    _notificationId++;
    return _notificationId;
  }

  Future<void> createDonation(Map<String, dynamic> donationData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = authProvider.getToken();
      if (token == null) {
        throw 'Not authenticated. Please log in again.';
      }

      // Transform data to match backend schema
      final transformedData = {
        'title': donationData['title'],
        'description': donationData['description'],
        'foodType': donationData['foodType'],
        'quantity': donationData['quantity'],
        'quantityUnit': donationData['quantityUnit'],
        'expiryDate': donationData['expiryDate'],
        'pickupAddress': {
          'street': donationData['pickupAddress']['street'],
          'city': donationData['pickupAddress']['city'],
          'state': donationData['pickupAddress']['state'],
          'zipCode': donationData['pickupAddress']['zipCode'],
        },
        'pickupTimeSlot': {
          'from': donationData['pickupTimeSlot']['from'],
          'to': donationData['pickupTimeSlot']['to'],
        },
        'specialInstructions': donationData['specialInstructions'],
        'images': donationData['images'] ?? [],
      };

      debugPrint('Creating donation with transformed data: ${jsonEncode(transformedData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/donations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(transformedData),
      );

      debugPrint('Donation creation response: ${response.statusCode} - ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await fetchDonations();
        // Show notification to donor
        await _notificationService.showNotification(
          id: _getNextNotificationId(),
          title: 'Donation Created',
          body: 'Your donation "${donationData['title']}" has been created successfully.',
        );
      } else {
        _error = data['message'] ?? 'Failed to create donation';
        notifyListeners();
        throw _error!;
      }
    } catch (error) {
      debugPrint('Error creating donation: $error');
      _error = error.toString();
      notifyListeners();
      throw _error!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDonations({String? status, String? city}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final queryParams = {
        if (status != null) 'status': status,
        if (city != null) 'city': city,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/donations').replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _donations = List<Map<String, dynamic>>.from(data);
        // Check for expiring donations after fetching
        await checkExpiringDonations();
      } else {
        _error = data['message'] ?? 'Failed to fetch donations';
        notifyListeners();
        throw _error!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptDonation(String donationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/donations/$donationId/accept'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await fetchDonations();
        
        // Show notification to both parties
        final donation = _donations.firstWhere((d) => d['_id'] == donationId);
        final donorName = donation['donor']['name'];
        final charityName = authProvider.user!['name'];
        
        // Notify donor
        await _notificationService.showNotification(
          id: _getNextNotificationId(),
          title: 'Donation Accepted',
          body: 'Your donation "${donation['title']}" has been accepted by $charityName.',
        );

        // Schedule reminder notification for pickup
        final pickupTime = DateTime.parse(donation['pickupTimeSlot']['from']);
        if (pickupTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            id: _getNextNotificationId(),
            title: 'Donation Pickup Reminder',
            body: 'Reminder: Your donation "${donation['title']}" is scheduled for pickup today.',
            scheduledDate: pickupTime.subtract(const Duration(hours: 1)),
          );
        }
      } else {
        _error = data['message'] ?? 'Failed to accept donation';
        notifyListeners();
        throw _error!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDonationStatus(String donationId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl/donations/$donationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await fetchDonations();
        
        // Show notification based on status
        final donation = _donations.firstWhere((d) => d['_id'] == donationId);
        final donorName = donation['donor']['name'];
        final charityName = donation['acceptedBy']?['name'] ?? 'the charity';
        
        String notificationTitle;
        String notificationBody;
        
        switch (status) {
          case 'completed':
            notificationTitle = 'Donation Completed';
            notificationBody = 'The donation "${donation['title']}" has been marked as completed.';
            break;
          case 'expired':
            notificationTitle = 'Donation Expired';
            notificationBody = 'Your donation "${donation['title']}" has expired.';
            break;
          default:
            notificationTitle = 'Donation Updated';
            notificationBody = 'The status of donation "${donation['title']}" has been updated to $status.';
        }
        
        await _notificationService.showNotification(
          id: _getNextNotificationId(),
          title: notificationTitle,
          body: notificationBody,
        );
      } else {
        _error = data['message'] ?? 'Failed to update donation status';
        notifyListeners();
        throw _error!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDonorDonations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/donations/donor'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _donations = List<Map<String, dynamic>>.from(data);
      } else {
        _error = data['message'] ?? 'Failed to fetch donor donations';
        notifyListeners();
        throw _error!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCharityDonations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/donations/charity'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _donations = List<Map<String, dynamic>>.from(data);
      } else {
        _error = data['message'] ?? 'Failed to fetch charity donations';
        notifyListeners();
        throw _error!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkExpiringDonations() async {
    try {
      final now = DateTime.now();
      for (var donation in _donations) {
        if (donation['status'] == 'available') {
          final expiryDate = DateTime.parse(donation['expiryDate']);
          final difference = expiryDate.difference(now);
          
          // If donation expires in less than 24 hours
          if (difference.inHours > 0 && difference.inHours <= 24) {
            await _notificationService.showNotification(
              id: _getNextNotificationId(),
              title: 'Donation Expiring Soon',
              body: 'Your donation "${donation['title']}" will expire in ${difference.inHours} hours.',
            );
            
            // Schedule notification for when it expires
            await _notificationService.scheduleNotification(
              id: _getNextNotificationId(),
              title: 'Donation Expired',
              body: 'Your donation "${donation['title']}" has expired.',
              scheduledDate: expiryDate,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking expiring donations: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 