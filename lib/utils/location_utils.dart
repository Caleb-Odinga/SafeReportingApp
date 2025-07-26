import 'dart:math';
import 'package:safe_reporting/models/location_data.dart';

class LocationUtils {
  // Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  // Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
  
  // Check if location is within a certain radius
  static bool isWithinRadius(LocationData location1, LocationData location2, double radiusInMeters) {
    double distance = calculateDistance(
      location1.latitude,
      location1.longitude,
      location2.latitude,
      location2.longitude,
    );
    return distance <= radiusInMeters;
  }
  
  // Get approximate location by reducing precision
  static LocationData getApproximateLocation(LocationData originalLocation, {double precisionKm = 1.0}) {
    // Reduce coordinate precision to approximate location
    double latPrecision = precisionKm / 111.0; // Roughly 111km per degree of latitude
    double lonPrecision = precisionKm / (111.0 * cos(_degreesToRadians(originalLocation.latitude)));
    
    double approximateLat = (originalLocation.latitude / latPrecision).round() * latPrecision;
    double approximateLon = (originalLocation.longitude / lonPrecision).round() * lonPrecision;
    
    return originalLocation.copyWith(
      latitude: approximateLat,
      longitude: approximateLon,
      shareExactLocation: false,
      displayAddress: originalLocation.shortAddress,
    );
  }
  
  // Validate coordinates
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }
  
  // Get location accuracy description
  static String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return 'Unknown';
    
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 50) return 'Fair';
    if (accuracy <= 100) return 'Poor';
    return 'Very Poor';
  }
  
  // Get location age description
  static String getLocationAge(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
