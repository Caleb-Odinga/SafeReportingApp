import 'package:flutter/material.dart';
import 'package:safe_reporting/services/location_service.dart';
import 'package:safe_reporting/models/location_data.dart';

class LocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData?) onLocationChanged;
  final bool showPrivacyOptions;
  final bool isRequired;

  const LocationPicker({
    Key? key,
    this.initialLocation,
    required this.onLocationChanged,
    this.showPrivacyOptions = true,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final LocationService _locationService = LocationService();
  final TextEditingController _addressController = TextEditingController();
  
  LocationData? _currentLocation;
  bool _isLoadingLocation = false;
  bool _useCurrentLocation = false;
  bool _shareExactLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
      _addressController.text = _currentLocation?.displayAddress ?? '';
      _useCurrentLocation = _currentLocation?.isCurrentLocation ?? false;
      _shareExactLocation = _currentLocation?.shareExactLocation ?? false;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final locationResult = await _locationService.getCurrentLocation();
      
      if (locationResult.isSuccess) {
        final addressResult = await _locationService.getAddressFromCoordinates(
          locationResult.latitude!,
          locationResult.longitude!,
        );

        if (addressResult.isSuccess) {
          final locationData = LocationData(
            latitude: locationResult.latitude!,
            longitude: locationResult.longitude!,
            accuracy: locationResult.accuracy,
            fullAddress: addressResult.fullAddress!,
            shortAddress: addressResult.shortAddress!,
            displayAddress: _shareExactLocation 
                ? addressResult.fullAddress! 
                : addressResult.shortAddress!,
            isCurrentLocation: true,
            shareExactLocation: _shareExactLocation,
            timestamp: locationResult.timestamp ?? DateTime.now(),
          );

          setState(() {
            _currentLocation = locationData;
            _addressController.text = locationData.displayAddress;
            _useCurrentLocation = true;
          });

          widget.onLocationChanged(_currentLocation);
        } else {
          setState(() {
            _locationError = addressResult.error;
          });
        }
      } else {
        setState(() {
          _locationError = locationResult.error;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final coordinatesResult = await _locationService.getCoordinatesFromAddress(address);
      
      if (coordinatesResult.isSuccess) {
        final locationData = LocationData(
          latitude: coordinatesResult.latitude!,
          longitude: coordinatesResult.longitude!,
          fullAddress: address,
          shortAddress: address,
          displayAddress: address,
          isCurrentLocation: false,
          shareExactLocation: true,
          timestamp: DateTime.now(),
        );

        setState(() {
          _currentLocation = locationData;
          _useCurrentLocation = false;
        });

        widget.onLocationChanged(_currentLocation);
      } else {
        setState(() {
          _locationError = coordinatesResult.error;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to search address: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _currentLocation = null;
      _addressController.clear();
      _useCurrentLocation = false;
      _shareExactLocation = false;
      _locationError = null;
    });
    widget.onLocationChanged(null);
  }

  void _updatePrivacySettings() {
    if (_currentLocation != null && _useCurrentLocation) {
      final updatedLocation = _currentLocation!.copyWith(
        shareExactLocation: _shareExactLocation,
        displayAddress: _shareExactLocation 
            ? _currentLocation!.fullAddress 
            : _currentLocation!.shortAddress,
      );
      
      setState(() {
        _currentLocation = updatedLocation;
        _addressController.text = updatedLocation.displayAddress;
      });
      
      widget.onLocationChanged(_currentLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
            const Spacer(),
            if (_currentLocation != null)
              TextButton.icon(
                onPressed: _clearLocation,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Address input field
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Enter location or use current location',
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingLocation)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _searchAddress(_addressController.text),
                    icon: const Icon(Icons.search),
                    tooltip: 'Search address',
                  ),
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use current location',
                ),
              ],
            ),
          ),
          onFieldSubmitted: _searchAddress,
          validator: widget.isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'Location is required';
            }
            return null;
          } : null,
        ),
        
        // Error message
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_locationError!.contains('permission') || 
                        _locationError!.contains('settings')) {
                      await _locationService.openAppSettings();
                    } else if (_locationError!.contains('disabled')) {
                      await _locationService.openLocationSettings();
                    }
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
          ),
        ],
        
        // Privacy options
        if (widget.showPrivacyOptions && _useCurrentLocation) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Location Privacy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share exact location'),
                  subtitle: Text(
                    _shareExactLocation
                        ? 'Full address will be shared'
                        : 'Only city/area will be shared',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _shareExactLocation,
                  onChanged: (value) {
                    setState(() {
                      _shareExactLocation = value;
                    });
                    _updatePrivacySettings();
                  },
                ),
              ],
            ),
          ),
        ],
        
        // Location info
        if (_currentLocation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _currentLocation!.isCurrentLocation 
                          ? Icons.location_on 
                          : Icons.place,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLocation!.isCurrentLocation
                            ? 'Current Location'
                            : 'Custom Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentLocation!.displayAddress,
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
                if (_currentLocation!.accuracy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Accuracy: ±${_currentLocation!.accuracy!.round()}m',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
