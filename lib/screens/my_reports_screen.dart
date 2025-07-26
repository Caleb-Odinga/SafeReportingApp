import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/utils/encryption_util.dart';
// import 'package:safe_reporting/screens/report_detail_screen.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Active', 'Resolved', 'Emergency'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final encryptionUtil = EncryptionUtil();
      final encryptionKey = await authService.getEncryptionKey();
      encryptionUtil.initializeEncrypter(encryptionKey);
      
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Query reports for the current user
      QuerySnapshot querySnapshot;
      
      if (_selectedFilter == 'All') {
        querySnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
      } else if (_selectedFilter == 'Emergency') {
        querySnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .where('isEmergency', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: _selectedFilter.toLowerCase())
            .orderBy('createdAt', descending: true)
            .get();
      }
      
      // Process and decrypt report data
      List<Map<String, dynamic>> reports = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Decrypt sensitive fields
        final decryptedTitle = await encryptionUtil.decrypt(data['title']);
        
        reports.add({
          'id': doc.id,
          'title': decryptedTitle,
          'reportType': data['reportType'],
          'urgencyLevel': data['urgencyLevel'],
          'isEmergency': data['isEmergency'] ?? false,
          'status': data['status'],
          'createdAt': data['createdAt'],
          'hasNewMessages': data['hasNewMessages'] ?? false,
        });
      }
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load reports. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : _buildReportsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _loadReports();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'You haven\'t submitted any reports yet'
                : 'No $_selectedFilter reports found',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewReportScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Report'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportsList() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }
  
  Widget _buildReportCard(Map<String, dynamic> report) {
    final createdAt = report['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
        : 'Unknown date';
        
    Color statusColor;
    IconData statusIcon;
    
    switch (report['status']) {
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(reportId: report['id']),
            ),
          ).then((_) => _loadReports());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report['isEmergency'] ? Colors.red : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report['reportType'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: report['isEmergency'] ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _capitalizeFirstLetter(report['status'].replaceAll('_', ' ')),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (report['hasNewMessages'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'New Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: Center(
        child: Text('Report Detail Screen - ID: $reportId'),
      ),
    );
  }
}

class NewReportScreen extends StatelessWidget {
  const NewReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report'),
      ),
      body: const Center(
        child: Text('New Report Screen'),
      ),
    );
  }
}
