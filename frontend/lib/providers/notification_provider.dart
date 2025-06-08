import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:food_bridge/config/api_config.dart';
import 'package:food_bridge/providers/auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthProvider authProvider;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider({required this.authProvider});

  List<Map<String, dynamic>> get notifications => [..._notifications];
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n['isRead']).length;

  Future<void> fetchNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _notifications = List<Map<String, dynamic>>.from(data);
      } else {
        _error = data['message'] ?? 'Failed to fetch notifications';
        throw _error!;
      }
    } catch (e) {
      _error = e.toString();
      throw _error!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          notifyListeners();
        }
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to mark notification as read';
        throw _error!;
      }
    } catch (e) {
      _error = e.toString();
      throw _error!;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      if (response.statusCode == 200) {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
        notifyListeners();
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to mark all notifications as read';
        throw _error!;
      }
    } catch (e) {
      _error = e.toString();
      throw _error!;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer ${authProvider.getToken()}',
        },
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n['_id'] == notificationId);
        notifyListeners();
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to delete notification';
        throw _error!;
      }
    } catch (e) {
      _error = e.toString();
      throw _error!;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 