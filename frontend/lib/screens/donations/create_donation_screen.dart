import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_bridge/providers/donation_provider.dart';
import 'package:food_bridge/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  String _selectedFoodType = 'Cooked';
  String _selectedQuantityUnit = 'kg';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 1));
  DateTime _pickupTimeFrom = DateTime.now();
  DateTime _pickupTimeTo = DateTime.now().add(const Duration(hours: 2));
  List<String> _imagePaths = [];
  bool _isLoading = false;

  final List<String> _foodTypes = [
    'Cooked',
    'Raw',
    'Packaged',
    'Beverages',
    'Other'
  ];

  final List<String> _quantityUnits = ['kg', 'items', 'packages', 'liters'];

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _loadUserAddress() {
    final user = context.read<AuthProvider>().user;
    if (user != null && user['address'] != null) {
      _streetController.text = user['address']['street'] ?? '';
      _cityController.text = user['address']['city'] ?? '';
      _stateController.text = user['address']['state'] ?? '';
      _zipCodeController.text = user['address']['zipCode'] ?? '';
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imagePaths = pickedFiles.map((file) => file.path).toList();
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _selectPickupTimeRange() async {
    final timeRange = await showTimeRangePicker(context);
    if (timeRange != null) {
      setState(() {
        _pickupTimeFrom = DateTime(
          _pickupTimeFrom.year,
          _pickupTimeFrom.month,
          _pickupTimeFrom.day,
          timeRange.start.hour,
          timeRange.start.minute,
        );
        _pickupTimeTo = DateTime(
          _pickupTimeTo.year,
          _pickupTimeTo.month,
          _pickupTimeTo.day,
          timeRange.end.hour,
          timeRange.end.minute,
        );
      });
    }
  }

  Future<void> _createDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final donationProvider = context.read<DonationProvider>();
      await donationProvider.createDonation({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'foodType': _selectedFoodType,
        'quantity': double.parse(_quantityController.text),
        'quantityUnit': _selectedQuantityUnit,
        'expiryDate': _expiryDate.toIso8601String(),
        'pickupAddress': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
        },
        'pickupTimeSlot': {
          'from': _pickupTimeFrom.toIso8601String(),
          'to': _pickupTimeTo.toIso8601String(),
        },
        'specialInstructions': _specialInstructionsController.text,
        'images': _imagePaths,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donation Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedFoodType,
                decoration: const InputDecoration(
                  labelText: 'Food Type',
                  prefixIcon: Icon(Icons.restaurant),
                  isDense: true,
                ),
                items: _foodTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFoodType = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.scale),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedQuantityUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                      ),
                      items: _quantityUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuantityUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(
                  DateFormat('MMM d, y').format(_expiryDate),
                ),
                leading: const Icon(Icons.event),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectExpiryDate,
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Pickup Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zipCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ZIP code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Pickup Time'),
                subtitle: Text(
                  '${DateFormat('h:mm a').format(_pickupTimeFrom)} - '
                  '${DateFormat('h:mm a').format(_pickupTimeTo)}',
                ),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectPickupTimeRange,
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialInstructionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions (Optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (_imagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_imagePaths.length} photo(s) selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createDonation,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Donation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<TimeRange?> showTimeRangePicker(BuildContext context) async {
  TimeOfDay? startTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (startTime == null) return null;

  TimeOfDay? endTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: startTime.hour + 2,
      minute: startTime.minute,
    ),
  );

  if (endTime == null) return null;

  return TimeRange(startTime, endTime);
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange(this.start, this.end);
} 