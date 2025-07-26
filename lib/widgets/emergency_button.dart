import 'package:flutter/material.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: InkWell(
        onTap: () => _showEmergencyDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Situation?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap here for immediate assistance',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Assistance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create an urgent report that will be prioritized by responders.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Please confirm this is an emergency situation that requires immediate attention.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _createEmergencyReport(context);
            },
            child: Text('Confirm Emergency'),
          ),
        ],
      ),
    );
  }

  void _createEmergencyReport(BuildContext context) {
    // Navigate to emergency report screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewReportScreen(
          initialReportType: 'Emergency',
          isEmergency: true,
        ),
      ),
    );
  }
}

class NewReportScreen extends StatelessWidget {
  final String initialReportType;
  final bool isEmergency;

  const NewReportScreen({
    Key? key,
    this.initialReportType = '',
    this.isEmergency = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEmergency ? 'Emergency Report' : 'New Report'),
        backgroundColor: isEmergency ? Colors.red : null,
      ),
      body: Center(
        child: Text('New Report Screen - Type: $initialReportType, Emergency: $isEmergency'),
      ),
    );
  }
}
