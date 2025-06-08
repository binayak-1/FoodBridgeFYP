import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:food_bridge/providers/notification_provider.dart';
import 'package:food_bridge/widgets/app_drawer.dart';
import 'package:food_bridge/widgets/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    Future.microtask(() =>
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<NotificationProvider>(
        builder: (ctx, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationProvider.fetchNotifications(),
            child: ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (ctx, index) {
                final notification = notificationProvider.notifications[index];
                return Dismissible(
                  key: Key(notification['_id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    notificationProvider.deleteNotification(notification['_id']);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: notification['isRead']
                        ? null
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: _getNotificationIcon(notification['type']),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight:
                              notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message']),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(DateTime.parse(notification['createdAt'])),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!notification['isRead']) {
                          notificationProvider
                              .markAsRead(notification['_id']);
                        }
                        // Handle navigation based on notification type if needed
                        _handleNotificationTap(notification);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'donation_accepted':
        return const CircleAvatar(
          child: Icon(Icons.check_circle),
        );
      case 'charity_verified':
        return const CircleAvatar(
          child: Icon(Icons.verified_user),
        );
      case 'donation_reminder':
        return const CircleAvatar(
          child: Icon(Icons.access_time),
        );
      case 'new_donation':
        return const CircleAvatar(
          child: Icon(Icons.card_giftcard),
        );
      case 'donation_created':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check_circle, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          child: Icon(Icons.notifications),
        );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Add navigation logic based on notification type
    if (notification['relatedDonation'] != null) {
      // Navigate to donation details
      Navigator.of(context).pushNamed(
        '/donation-details',
        arguments: notification['relatedDonation'],
      );
    }
  }
} 