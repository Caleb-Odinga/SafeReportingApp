import 'package:flutter/material.dart';
import 'package:safe_reporting/models/location_data.dart';
import 'package:intl/intl.dart';

class LocationDisplay extends StatelessWidget {
  final LocationData? locationData;
  final bool showCoordinates;
  final bool showTimestamp;
  final bool showAccuracy;
  final VoidCallback? onTap;

  const LocationDisplay({
    Key? key,
    this.locationData,
    this.showCoordinates = false,
    this.showTimestamp = false,
    this.showAccuracy = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (locationData == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'No location provided',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
                Icon(
                  locationData!.isCurrentLocation 
                      ? Icons.my_location 
                      : Icons.place,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationData!.displayAddress,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                if (!locationData!.shareExactLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Approximate',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (showCoordinates) ...[
              const SizedBox(height: 4),
              Text(
                'Coordinates: ${locationData!.coordinatesString}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            
            if (showAccuracy && locationData!.accuracy != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 12,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Accuracy: ±${locationData!.accuracy!.round()}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
            
            if (showTimestamp) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recorded: ${DateFormat('MMM d, yyyy HH:mm').format(locationData!.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
