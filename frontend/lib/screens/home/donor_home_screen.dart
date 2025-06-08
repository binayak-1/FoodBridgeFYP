import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/screens/donations/create_donation_screen.dart';
import 'package:food_bridge/screens/donations/my_donations_screen.dart';
import 'package:food_bridge/screens/profile/profile_screen.dart';
import 'package:food_bridge/screens/map/location_map_screen.dart';
import 'package:food_bridge/widgets/notification_icon.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _charities = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCharities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCharities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implement charity fetching from API
      // This is mock data for now
      await Future.delayed(const Duration(seconds: 1));
      _charities = [
        {
          'name': 'Food Bank Organization',
          'description': 'Helping to feed the hungry in our community',
          'address': {'city': 'New York', 'state': 'NY'},
          'rating': 4.5,
          'totalDonationsReceived': 150,
        },
        {
          'name': 'Homeless Shelter',
          'description': 'Providing meals to homeless individuals',
          'address': {'city': 'Los Angeles', 'state': 'CA'},
          'rating': 4.8,
          'totalDonationsReceived': 200,
        },
        // Add more mock data as needed
      ];
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCharities(String query) {
    // TODO: Implement charity filtering
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            actions: const [
              NotificationIcon(color: Colors.white),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Welcome, ${user?['name'] ?? 'Donor'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Make a difference by donating food',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCharities,
                  decoration: InputDecoration(
                    hintText: 'Search charities...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _ActionCard(
                          icon: Icons.add_circle_outline,
                          title: 'Create\nDonation',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateDonationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionCard(
                          icon: Icons.list_alt,
                          title: 'My\nDonations',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyDonationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionCard(
                          icon: Icons.map_outlined,
                          title: 'Find\nCharities',
                          onTap: () {
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
                        const SizedBox(width: 8),
                        _ActionCard(
                          icon: Icons.person_outline,
                          title: 'My\nProfile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verified Charities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final charity = _charities[index];
                    return _CharityCard(charity: charity);
                  },
                  childCount: _charities.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDonationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Donate Food'),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharityCard extends StatelessWidget {
  final Map<String, dynamic> charity;

  const _CharityCard({required this.charity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    charity['name']?[0]?.toUpperCase() ?? 'C',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        charity['name'] ?? 'Unknown Charity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (charity['address'] != null)
                        Text(
                          '${charity['address']['city'] ?? ''}, ${charity['address']['state'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              charity['organizationDetails']?['description'] ?? 'No description available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: Implement view details
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateDonationScreen(),
                      ),
                    );
                  },
                  child: const Text('Donate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 