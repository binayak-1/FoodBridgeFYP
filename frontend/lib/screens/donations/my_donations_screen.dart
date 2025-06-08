import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/donation_provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isDonor) {
      await donationProvider.fetchDonorDonations();
    } else {
      await donationProvider.fetchCharityDonations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDonor = authProvider.isDonor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isDonor ? 'My Donations' : 'Accepted Donations'),
          bottom: TabBar(
            tabs: [
              Tab(text: isDonor ? 'Available' : 'Active'),
              const Tab(text: 'Completed'),
              const Tab(text: 'Expired'),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _fetchDonations();
            },
          ),
        ),
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

            final donations = donationProvider.donations.where((donation) {
              switch (_selectedIndex) {
                case 0:
                  return donation['status'] == 'available';
                case 1:
                  return donation['status'] == 'completed';
                case 2:
                  return donation['status'] == 'expired';
                default:
                  return false;
              }
            }).toList();

            if (donations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedIndex == 0
                          ? Icons.volunteer_activism
                          : _selectedIndex == 1
                              ? Icons.check_circle
                              : Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedIndex == 0
                          ? 'No active donations'
                          : _selectedIndex == 1
                              ? 'No completed donations'
                              : 'No expired donations',
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
                  isDonor: isDonor,
                  onStatusUpdate: (String status) async {
                    try {
                      await donationProvider.updateDonationStatus(
                        donation['_id'],
                        status,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status updated successfully'),
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
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final bool isDonor;
  final Function(String) onStatusUpdate;

  const _DonationCard({
    required this.donation,
    required this.isDonor,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final status = donation['status'];
    final expiryDate = DateTime.parse(donation['expiryDate']);
    final isExpiringSoon = expiryDate.difference(DateTime.now()).inDays <= 2;
    final otherParty = isDonor
        ? donation['acceptedBy'] as Map<String, dynamic>?
        : donation['donor'] as Map<String, dynamic>;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'available':
        statusColor = isExpiringSoon ? Colors.orange : Colors.green;
        statusIcon = isExpiringSoon ? Icons.timer : Icons.check_circle_outline;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

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
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
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
                if (otherParty != null) ...[
                  const Divider(height: 32),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          otherParty['name'][0].toUpperCase(),
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
                              otherParty['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              isDonor ? 'Accepted by' : 'Donated by',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'available')
                        TextButton(
                          onPressed: () => onStatusUpdate('completed'),
                          child: const Text('Mark as Completed'),
                        ),
                    ],
                  ),
                ],
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