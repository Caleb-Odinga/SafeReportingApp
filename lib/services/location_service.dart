import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get current position with error handling
  Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled. Please enable them in settings.');
      }

      // Check and request permissions
      LocationPermission permission = await checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('Error getting location: $e');
      return LocationResult.error('Failed to get location: ${e.toString()}');
    }
  }

  // Get address from coordinates (reverse geocoding)
  Future<AddressResult> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String fullAddress = _buildFullAddress(place);
        String shortAddress = _buildShortAddress(place);
        
        return AddressResult.success(
          fullAddress: fullAddress,
          shortAddress: shortAddress,
          street: place.street ?? '',
          locality: place.locality ?? '',
          administrativeArea: place.administrativeArea ?? '',
          country: place.country ?? '',
          postalCode: place.postalCode ?? '',
        );
      } else {
        return AddressResult.error('No address found for the given coordinates.');
      }
    } catch (e) {
      print('Error getting address: $e');
      return AddressResult.error('Failed to get address: ${e.toString()}');
    }
  }

  // Get coordinates from address (forward geocoding)
  Future<CoordinatesResult> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return CoordinatesResult.success(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } else {
        return CoordinatesResult.error('No coordinates found for the given address.');
      }
    } catch (e) {
      print('Error getting coordinates: $e');
      return CoordinatesResult.error('Failed to get coordinates: ${e.toString()}');
    }
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Build full address string
  String _buildFullAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
    if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) addressParts.add(place.administrativeArea!);
    if (place.postalCode?.isNotEmpty == true) addressParts.add(place.postalCode!);
    if (place.country?.isNotEmpty == true) addressParts.add(place.country!);
    
    return addressParts.join(', ');
  }

  // Build short address string
  String _buildShortAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) addressParts.add(place.administrativeArea!);
    
    return addressParts.join(', ');
  }
}

// Location result classes
class LocationResult {
  final bool isSuccess;
  final String? error;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? timestamp;

  LocationResult._({
    required this.isSuccess,
    this.error,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.timestamp,
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationResult._(
      isSuccess: true,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }

  factory LocationResult.error(String error) {
    return LocationResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class AddressResult {
  final bool isSuccess;
  final String? error;
  final String? fullAddress;
  final String? shortAddress;
  final String? street;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? postalCode;

  AddressResult._({
    required this.isSuccess,
    this.error,
    this.fullAddress,
    this.shortAddress,
    this.street,
    this.locality,
    this.administrativeArea,
    this.country,
    this.postalCode,
  });

  factory AddressResult.success({
    required String fullAddress,
    required String shortAddress,
    String? street,
    String? locality,
    String? administrativeArea,
    String? country,
    String? postalCode,
  }) {
    return AddressResult._(
      isSuccess: true,
      fullAddress: fullAddress,
      shortAddress: shortAddress,
      street: street,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
      postalCode: postalCode,
    );
  }

  factory AddressResult.error(String error) {
    return AddressResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class CoordinatesResult {
  final bool isSuccess;
  final String? error;
  final double? latitude;
  final double? longitude;

  CoordinatesResult._({
    required this.isSuccess,
    this.error,
    this.latitude,
    this.longitude,
  });

  factory CoordinatesResult.success({
    required double latitude,
    required double longitude,
  }) {
    return CoordinatesResult._(
      isSuccess: true,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory CoordinatesResult.error(String error) {
    return CoordinatesResult._(
      isSuccess: false,
      error: error,
    );
  }
}
