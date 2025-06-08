import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/providers/donation_provider.dart';
import 'package:food_bridge/providers/notification_provider.dart';
import 'package:food_bridge/screens/splash_screen.dart';
import 'package:food_bridge/screens/notifications_screen.dart';
import 'package:food_bridge/services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  
  // Set up notification action listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
  );
  
  runApp(const MyApp());
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.title}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Get the navigation key to navigate from anywhere
    final context = GlobalKey<NavigatorState>().currentContext;
    if (context == null) return;

    // Handle different notification types
    if (receivedAction.payload?['type'] == 'donation_accepted') {
      // Navigate to the donation details screen
      Navigator.of(context).pushNamed(
        '/donation-details',
        arguments: receivedAction.payload?['donationId'],
      );
    } else if (receivedAction.payload?['type'] == 'donation_expiring') {
      // Navigate to my donations screen
      Navigator.of(context).pushNamed('/my-donations');
    } else {
      // Default navigation to home screen
      Navigator.of(context).pushNamed('/');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DonationProvider>(
          create: (context) => DonationProvider(
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => DonationProvider(
            authProvider: auth,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => NotificationProvider(
            authProvider: auth,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Food Bridge',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            primary: const Color(0xFF4CAF50),
            secondary: const Color(0xFF2196F3),
            background: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
        routes: {
          '/notifications': (context) => const NotificationsScreen(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
