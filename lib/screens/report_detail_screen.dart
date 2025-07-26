import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/utils/encryption_util.dart';
import 'package:safe_reporting/models/location_data.dart';
import 'package:safe_reporting/widgets/location_display.dart';
import 'package:safe_reporting/screens/messages_screen.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final encryptionUtil = EncryptionUtil();
      final encryptionKey = await authService.getEncryptionKey();
      encryptionUtil.initializeEncrypter(encryptionKey);

      final doc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .get();

      if (!doc.exists) {
        throw Exception('Report not found');
      }

      final data = doc.data()!;

      // Decrypt sensitive fields
      final decryptedTitle = await encryptionUtil.decrypt(data['title']);
      final decryptedDescription = await encryptionUtil.decrypt(data['description']);

      // Parse location data if available
      LocationData? locationData;
      if (data['location'] != null) {
        final locationMap = data['location'] as Map<String, dynamic>;
        locationData = LocationData(
          latitude: locationMap['latitude']?.toDouble() ?? 0.0,
          longitude: locationMap['longitude']?.toDouble() ?? 0.0,
          accuracy: locationMap['accuracy']?.toDouble(),
          fullAddress: locationMap['displayAddress'] ?? '',
          shortAddress: locationMap['privacySafeAddress'] ?? '',
          displayAddress: locationMap['displayAddress'] ?? '',
          isCurrentLocation: locationMap['isCurrentLocation'] ?? false,
          shareExactLocation: locationMap['shareExactLocation'] ?? false,
          timestamp: DateTime.parse(locationMap['timestamp'] ?? DateTime.now().toIso8601String()),
        );
      }

      if (mounted) {
        setState(() {
          _reportData = {
            ...data,
            'title': decryptedTitle,
            'description': decryptedDescription,
            'locationData': locationData,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading report details: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load report details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (_reportData != null)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(reportId: widget.reportId),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadReportDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildReportDetails(),
    );
  }

  Widget _buildReportDetails() {
    final report = _reportData!;
    final createdAt = report['createdAt'] as Timestamp?;
    final updatedAt = report['updatedAt'] as Timestamp?;
    final locationData = report['locationData'] as LocationData?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and type header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: report['isEmergency'] ? Colors.red : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report['reportType'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: report['isEmergency'] ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusChip(report['status']),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            report['title'],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Urgency level
          if (!report['isEmergency']) ...[
            Row(
              children: [
                const Icon(Icons.priority_high, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Urgency: ${_getUrgencyLabel(report['urgencyLevel'])}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                _buildUrgencyIndicator(report['urgencyLevel']),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(report['description']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Location
          if (locationData != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocationDisplay(
                      locationData: locationData,
                      showCoordinates: locationData.shareExactLocation,
                      showTimestamp: true,
                      showAccuracy: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Attachments
          if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(report['attachments'] as List).length} file(s) attached'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timestamps
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (createdAt != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 16),
                        const SizedBox(width: 8),
                        Text('Created: ${DateFormat('MMM d, yyyy HH:mm').format(createdAt.toDate())}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (updatedAt != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.update, size: 16),
                        const SizedBox(width: 8),
                        Text('Updated: ${DateFormat('MMM d, yyyy HH:mm').format(updatedAt.toDate())}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(reportId: widget.reportId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Messages'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadReportDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'submitted':
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        label = 'Submitted';
        break;
      case 'in_progress':
        color = Colors.orange;
        icon = Icons.sync;
        label = 'In Progress';
        break;
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Resolved';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyIndicator(int urgencyLevel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < urgencyLevel ? _getUrgencyColor(urgencyLevel) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  String _getUrgencyLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  Color _getUrgencyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
