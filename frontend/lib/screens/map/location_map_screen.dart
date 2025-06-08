import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';

class LocationMapScreen extends StatefulWidget {
  final bool isViewOnly;
  final Map<String, dynamic>? initialLocation;
  final Function(Map<String, dynamic>)? onLocationSelected;

  const LocationMapScreen({
    super.key,
    this.isViewOnly = false,
    this.initialLocation,
    this.onLocationSelected,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedAddress;
  List<Map<String, dynamic>> _nearbyUsers = [];
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    debugPrint('LocationMapScreen - initState called');
    if (widget.initialLocation != null) {
      try {
        _selectedLocation = LatLng(
          widget.initialLocation!['latitude'] as double,
          widget.initialLocation!['longitude'] as double,
        );
        _selectedAddress = widget.initialLocation!['address'] as String?;
        _markers = [
          Marker(
            point: _selectedLocation!,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        ];
        debugPrint('LocationMapScreen - Initial location set: $_selectedLocation');
      } catch (e) {
        debugPrint('LocationMapScreen - Error setting initial location: $e');
      }
    }
    _initializeMap();
  }

  @override
  void dispose() {
    debugPrint('LocationMapScreen - dispose called');
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    
    try {
      debugPrint('LocationMapScreen - Starting map initialization');
      setState(() => _isLoading = true);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationMapScreen - Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them in your device settings.';
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('LocationMapScreen - Initial permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('LocationMapScreen - Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in your device settings.';
      }

      // Get current position if no initial location
      if (_selectedLocation == null) {
        debugPrint('LocationMapScreen - Getting current position');
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!mounted) return;

        debugPrint('LocationMapScreen - Current position: ${position.latitude}, ${position.longitude}');
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _markers = [
            Marker(
              point: _selectedLocation!,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ];
        });

        // Get address for current location
        await _updateLocationAddress(_selectedLocation!);
      }

      if (widget.isViewOnly) {
        await _fetchNearbyUsers();
      }

      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isMapReady = true;
      });
      debugPrint('LocationMapScreen - Map initialization completed successfully');
    } catch (error) {
      debugPrint('LocationMapScreen - Error during map initialization: $error');
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationAddress(LatLng point) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String address = [
          if (place.street?.isNotEmpty ?? false) place.street,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.administrativeArea?.isNotEmpty ?? false) place.administrativeArea,
          if (place.country?.isNotEmpty ?? false) place.country,
        ].where((e) => e != null).join(', ');

        setState(() {
          _selectedAddress = address;
        });

        if (widget.onLocationSelected != null) {
          widget.onLocationSelected!({
            'latitude': point.latitude,
            'longitude': point.longitude,
            'address': address,
            'street': place.street,
            'city': place.locality,
            'state': place.administrativeArea,
            'country': place.country,
            'zipCode': place.postalCode,
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location details: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _fetchNearbyUsers() async {
    if (_selectedLocation == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final userRole = authProvider.user?['role'];
      
      // TODO: Replace with actual API call
      _nearbyUsers = [
        {
          'id': '1',
          'name': 'Food Bank A',
          'role': 'charity',
          'location': {'lat': _selectedLocation!.latitude + 0.01, 'lng': _selectedLocation!.longitude + 0.01},
          'address': '123 Main St',
        },
        {
          'id': '2',
          'name': 'Restaurant B',
          'role': 'donor',
          'location': {'lat': _selectedLocation!.latitude - 0.01, 'lng': _selectedLocation!.longitude - 0.01},
          'address': '456 Oak Ave',
        },
      ];

      if (!mounted) return;

      setState(() {
        _nearbyUsers = _nearbyUsers.where((user) => 
          userRole == 'donor' ? user['role'] == 'charity' : user['role'] == 'donor'
        ).toList();

        _markers = [
          ..._markers,
          ..._nearbyUsers.map((user) => Marker(
            point: LatLng(user['location']['lat'], user['location']['lng']),
            width: 40,
            height: 40,
            child: Icon(
              user['role'] == 'charity' ? Icons.business : Icons.person,
              color: user['role'] == 'charity' ? Colors.blue : Colors.green,
              size: 40,
            ),
          )),
        ];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching nearby users: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LocationMapScreen - build called, isLoading: $_isLoading, error: $_error');
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeMap,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isViewOnly ? 'Location' : 'Select Location'),
        actions: [
          if (!widget.isViewOnly && _selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isMapReady) FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(0, 0),
              initialZoom: 15,
              onTap: !widget.isViewOnly ? _handleTap : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodbridge.app',
                maxZoom: 19,
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          if (widget.isViewOnly && _nearbyUsers.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _nearbyUsers.length,
                  itemBuilder: (context, index) {
                    final user = _nearbyUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user['role'] == 'charity'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        child: Icon(
                          user['role'] == 'charity'
                              ? Icons.business
                              : Icons.person,
                          color: user['role'] == 'charity'
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                      title: Text(user['name']),
                      subtitle: Text(user['address']),
                      onTap: () {
                        final location = LatLng(
                          user['location']['lat'],
                          user['location']['lng'],
                        );
                        _mapController.move(location, 15);
                      },
                    );
                  },
                ),
              ),
            ),
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddress!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (widget.isViewOnly) return;

    setState(() {
      _selectedLocation = point;
      _markers = [
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      ];
    });

    _updateLocationAddress(point);
  }
} 