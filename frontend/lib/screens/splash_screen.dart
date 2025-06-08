import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/screens/auth/login_screen.dart';
import 'package:food_bridge/screens/home/donor_home_screen.dart';
import 'package:food_bridge/screens/home/charity_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();

    // Check authentication status after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuth();
      }
    });
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('Starting auth check...');
    await authProvider.tryAutoLogin();

    if (!mounted) return;

    print('Authentication state: ${authProvider.isAuthenticated}');
    print('User data: ${authProvider.user}');
    print('Is charity: ${authProvider.isCharity}');
    print('Is donor: ${authProvider.isDonor}');

    if (authProvider.isAuthenticated) {
      Widget homeScreen;
      if (authProvider.isCharity) {
        print('Routing to charity home');
        homeScreen = const CharityHomeScreen();
      } else {
        print('Routing to donor home');
        homeScreen = const DonorHomeScreen();
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => homeScreen),
      );
    } else {
      print('Routing to login screen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Food Bridge',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting Donors with Charities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 