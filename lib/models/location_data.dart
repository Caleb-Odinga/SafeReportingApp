class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String fullAddress;
  final String shortAddress;
  final String displayAddress;
  final bool isCurrentLocation;
  final bool shareExactLocation;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.fullAddress,
    required this.shortAddress,
    required this.displayAddress,
    required this.isCurrentLocation,
    required this.shareExactLocation,
    required this.timestamp,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? fullAddress,
    String? shortAddress,
    String? displayAddress,
    bool? isCurrentLocation,
    bool? shareExactLocation,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      fullAddress: fullAddress ?? this.fullAddress,
      shortAddress: shortAddress ?? this.shortAddress,
      displayAddress: displayAddress ?? this.displayAddress,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      shareExactLocation: shareExactLocation ?? this.shareExactLocation,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'fullAddress': fullAddress,
      'shortAddress': shortAddress,
      'displayAddress': displayAddress,
      'isCurrentLocation': isCurrentLocation,
      'shareExactLocation': shareExactLocation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble(),
      fullAddress: json['fullAddress'] ?? '',
      shortAddress: json['shortAddress'] ?? '',
      displayAddress: json['displayAddress'] ?? '',
      isCurrentLocation: json['isCurrentLocation'] ?? false,
      shareExactLocation: json['shareExactLocation'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Get coordinates as a string for display
  String get coordinatesString => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  // Get a privacy-safe address based on sharing preferences
  String get privacySafeAddress => shareExactLocation ? fullAddress : shortAddress;

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $displayAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationData &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.displayAddress == displayAddress;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ displayAddress.hashCode;
  }
}
