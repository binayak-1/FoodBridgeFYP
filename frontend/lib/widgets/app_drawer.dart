import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/screens/profile/profile_screen.dart';
import 'package:food_bridge/screens/donations/my_donations_screen.dart';
import 'package:food_bridge/screens/map/location_map_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDonor = authProvider.isDonor;
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?['name']?[0]?.toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(user?['name'] ?? 'User'),
            accountEmail: Text(user?['email'] ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(isDonor ? Icons.list_alt : Icons.history),
            title: Text(isDonor ? 'My Donations' : 'Accepted Donations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyDonationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(isDonor ? 'Find Charities' : 'View Map'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationMapScreen(
                    isViewOnly: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 