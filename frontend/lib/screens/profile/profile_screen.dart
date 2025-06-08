import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_bridge/screens/map/location_map_screen.dart';
import 'package:food_bridge/screens/auth/login_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String? _profileImagePath;
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchProfile();
      
      final user = authProvider.user;
      if (user != null) {
        print('Loading user data: $user'); // Debug print
        setState(() {
          _nameController.text = user['name'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          
          // Properly handle nested address data
          final address = user['address'] as Map<String, dynamic>?;
          print('Address data: $address'); // Debug print
          if (address != null) {
            _streetController.text = address['street'] ?? '';
            _cityController.text = address['city'] ?? '';
            _stateController.text = address['state'] ?? '';
            _zipCodeController.text = address['zipCode'] ?? '';
            print('ZIP Code value: ${address['zipCode']}'); // Debug print
          }

          // Handle location data
          if (user['location'] != null) {
            _formData['location'] = Map<String, dynamic>.from(user['location']);
          }

          // Handle profile image
          _profileImagePath = user['profileImage'];
          
          // Store complete user data
          _formData = Map<String, dynamic>.from(user);
        });
      }
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Create complete address object
      final address = {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
      };
      
      print('Updating profile with address: $address'); // Debug print

      // Include location data if it exists
      final location = _formData['location'] as Map<String, dynamic>?;
      
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: address,
        location: location,
        profileImage: _profileImagePath,
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLocationSection() {
    final locationData = _formData['location'] as Map<String, dynamic>?;
    final hasLocation = locationData != null && 
                       locationData['coordinates'] != null &&
                       locationData['coordinates'].length == 2;

    String locationText = 'No location set';
    if (hasLocation) {
      final lat = locationData!['coordinates'][1];
      final lng = locationData['coordinates'][0];
      final address = locationData['address'] as String? ?? '';
      locationText = address.isNotEmpty 
          ? address 
          : '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _isEditing ? () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationMapScreen(
                          isViewOnly: false,
                          initialLocation: hasLocation ? {
                            'latitude': locationData!['coordinates'][1],
                            'longitude': locationData['coordinates'][0],
                            'address': locationData['address'],
                          } : null,
                          onLocationSelected: (location) {
                            setState(() {
                              _formData['location'] = {
                                'type': 'Point',
                                'coordinates': [
                                  location['longitude'],
                                  location['latitude'],
                                ],
                                'address': location['address'],
                              };
                            });
                            Navigator.pop(context, location);
                          },
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _formData['location'] = {
                          'type': 'Point',
                          'coordinates': [
                            result['longitude'],
                            result['latitude'],
                          ],
                          'address': result['address'],
                        };
                      });
                    }
                  } : null,
                  icon: Icon(
                    hasLocation ? Icons.edit_location : Icons.add_location,
                    color: _isEditing ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  label: Text(
                    hasLocation ? 'Change Location' : 'Add Location',
                    style: TextStyle(
                      color: _isEditing ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (hasLocation) ...[
              const SizedBox(height: 16),
              Text(
                locationText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data available'),
        ),
      );
    }

    final isCharity = user['role'] == 'charity';
    final status = user['status'] ?? 'pending';
    final isVerified = status == 'verified';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Reset form data
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: _profileImagePath != null && _profileImagePath!.startsWith('http')
                                  ? NetworkImage(_profileImagePath!)
                                  : _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!)) as ImageProvider
                                      : null,
                              child: _profileImagePath == null
                                  ? Text(
                                      user['name']?[0].toUpperCase() ?? 'U',
                                      style: TextStyle(
                                        fontSize: 36,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    color: Colors.white,
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Badge for Charities
                      if (isCharity)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVerified
                                      ? Icons.verified_user
                                      : Icons.pending,
                                  color: isVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isVerified
                                      ? 'Verified Charity'
                                      : 'Verification Pending',
                                  style: TextStyle(
                                    color: isVerified
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Form Fields
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Address Fields
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Address',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _streetController,
                                decoration: const InputDecoration(
                                  labelText: 'Street',
                                  border: OutlineInputBorder(),
                                ),
                                enabled: _isEditing,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Street is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cityController,
                                      decoration: const InputDecoration(
                                        labelText: 'City',
                                        border: OutlineInputBorder(),
                                      ),
                                      enabled: _isEditing,
                                      validator: (value) => value?.isEmpty ?? true
                                          ? 'City is required'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _stateController,
                                      decoration: const InputDecoration(
                                        labelText: 'State',
                                        border: OutlineInputBorder(),
                                      ),
                                      enabled: _isEditing,
                                      validator: (value) => value?.isEmpty ?? true
                                          ? 'State is required'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _zipCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'ZIP Code',
                                  border: OutlineInputBorder(),
                                ),
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'ZIP Code is required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Map Section
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Save Button
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),

                      // Logout Button
                      if (!_isEditing) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text('Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await context.read<AuthProvider>().logout();
                                        if (!mounted) return;
                                        
                                        // Replace entire navigation stack with login screen
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.logout,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            label: Text(
                              'Logout',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
} 