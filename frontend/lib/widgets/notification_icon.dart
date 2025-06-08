import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/notification_provider.dart';
import 'package:food_bridge/screens/notifications_screen.dart';

class NotificationIcon extends StatefulWidget {
  final Color? color;

  const NotificationIcon({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when the icon is first shown
    Future.microtask(() =>
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: widget.color,
              ),
              onPressed: () {
                Navigator.pushNamed(context, NotificationsScreen.routeName);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
} 