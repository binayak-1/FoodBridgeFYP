import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:food_bridge/providers/donation_provider.dart';
import 'package:food_bridge/screens/profile/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:food_bridge/screens/map/location_map_screen.dart';
import 'package:food_bridge/widgets/notification_icon.dart';

class CharityHomeScreen extends StatefulWidget {
  const CharityHomeScreen({super.key});

  @override
  State<CharityHomeScreen> createState() => _CharityHomeScreenState();
}

class _CharityHomeScreenState extends State<CharityHomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonations() async {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    await donationProvider.fetchDonations(
      status: _selectedIndex == 0 ? 'available' : 'accepted',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Food Bridge',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) => Text(
                                      auth.user?['name'] ?? 'Charity',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_outline),
                                color: Colors.white,
                                onPressed: () {
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search donations...',
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
                    const SizedBox(height: 8),
                    TabBar(
                      tabs: const [
                        Tab(text: 'Available'),
                        Tab(text: 'Accepted'),
                      ],
                      onTap: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                        _fetchDonations();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: Consumer<DonationProvider>(
            builder: (context, donationProvider, _) {
              if (donationProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (donationProvider.error != null) {
                return Center(
                  child: Text(
                    donationProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              final donations = donationProvider.donations;
              if (donations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 0
                            ? Icons.search_off
                            : Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedIndex == 0
                            ? 'No available donations found'
                            : 'No accepted donations yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  final donation = donations[index];
                  return _DonationCard(
                    donation: donation,
                    onAccept: () async {
                      try {
                        await donationProvider.acceptDonation(donation['_id']);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Donation accepted successfully'),
                          ),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error.toString()),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final VoidCallback? onAccept;

  const _DonationCard({
    required this.donation,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final donor = donation['donor'] as Map<String, dynamic>;
    final isAvailable = donation['status'] == 'available';
    final expiryDate = DateTime.parse(donation['expiryDate']);
    final isExpiringSoon = expiryDate.difference(DateTime.now()).inDays <= 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isAvailable
                  ? isExpiringSoon
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailable
                      ? isExpiringSoon
                          ? Icons.timer
                          : Icons.check_circle_outline
                      : Icons.history,
                  size: 16,
                  color: isAvailable
                      ? isExpiringSoon
                          ? Colors.orange
                          : Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable
                      ? isExpiringSoon
                          ? 'Expiring Soon'
                          : 'Available'
                      : 'Accepted',
                  style: TextStyle(
                    color: isAvailable
                        ? isExpiringSoon
                            ? Colors.orange
                            : Colors.green
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  donation['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.restaurant,
                      label: donation['foodType'],
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.scale,
                      label: '${donation['quantity']} ${donation['quantityUnit']}',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.event,
                      label: DateFormat('MMM d, y').format(expiryDate),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        donor['name'][0].toUpperCase(),
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
                            donor['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${donation['pickupAddress']['city']}, ${donation['pickupAddress']['state']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAvailable)
                      ElevatedButton(
                        onPressed: onAccept,
                        child: const Text('Accept'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(16),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
} 