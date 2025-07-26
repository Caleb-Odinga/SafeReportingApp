import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/utils/encryption_util.dart';
import 'package:safe_reporting/models/location_data.dart';
import 'package:safe_reporting/models/contact_info.dart';
import 'package:safe_reporting/widgets/location_display.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  Map<String, int> _statistics = {};
  String _selectedFilter = 'all';

  final List<String> _filterOptions = ['all', 'emergency', 'high_priority', 'pending', 'in_progress'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadReports(),
        _loadStatistics(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReports() async {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);

    // Apply filters
    switch (_selectedFilter) {
      case 'emergency':
        query = query.where('isEmergency', isEqualTo: true);
        break;
      case 'high_priority':
        query = query.where('urgencyLevel', isGreaterThanOrEqualTo: 4);
        break;
      case 'pending':
        query = query.where('status', isEqualTo: 'submitted');
        break;
      case 'in_progress':
        query = query.where('status', isEqualTo: 'in_progress');
        break;
    }

    final querySnapshot = await query.limit(50).get();
    
    List<Map<String, dynamic>> reports = [];
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // For admin dashboard, we'll decrypt the data
      // In a real app, this would require proper admin authentication
      try {
        reports.add({
          'id': doc.id,
          'reportType': data['reportType'],
          'urgencyLevel': data['urgencyLevel'],
          'isEmergency': data['isEmergency'] ?? false,
          'status': data['status'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'hasNewMessages': data['hasNewMessages'] ?? false,
          'location': data['location'],
          'contactInfo': data['contactInfo'],
          'attachments': data['attachments'] ?? [],
          // Note: In production, title and description would be decrypted here
          'title': '[Encrypted]', // Placeholder
          'description': '[Encrypted]', // Placeholder
        });
      } catch (e) {
        print('Error processing report ${doc.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _reports = reports;
      });
    }
  }

  Future<void> _loadStatistics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Get total reports
    final totalReports = await FirebaseFirestore.instance
        .collection('reports')
        .count()
        .get();

    // Get emergency reports
    final emergencyReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('isEmergency', isEqualTo: true)
        .count()
        .get();

    // Get pending reports
    final pendingReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'submitted')
        .count()
        .get();

    // Get this month's reports
    final monthlyReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .count()
        .get();

    if (mounted) {
      setState(() {
        _statistics = {
          'total': totalReports.count ?? 0,
          'emergency': emergencyReports.count ?? 0,
          'pending': pendingReports.count ?? 0,
          'monthly': monthlyReports.count ?? 0,
        };
      });
    }
  }

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add status update message
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .collection('messages')
          .add({
        'message': 'Report status updated to: ${newStatus.replaceAll('_', ' ')}',
        'senderType': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadReports();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'Reports'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildReportsTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Statistics cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard('Total Reports', _statistics['total'] ?? 0, Icons.assignment, Colors.blue),
              _buildStatCard('Emergency', _statistics['emergency'] ?? 0, Icons.warning, Colors.red),
              _buildStatCard('Pending', _statistics['pending'] ?? 0, Icons.hourglass_empty, Colors.orange),
              _buildStatCard('This Month', _statistics['monthly'] ?? 0, Icons.calendar_month, Colors.green),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent emergency reports
          Text(
            'Recent Emergency Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ..._reports
              .where((report) => report['isEmergency'] == true)
              .take(3)
              .map((report) => _buildReportCard(report, isCompact: true)),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
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
        ),
        
        // Reports list
        Expanded(
          child: _reports.isEmpty
              ? const Center(
                  child: Text('No reports found'),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_reports[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Insights',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Report type distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Types Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._getReportTypeStats().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value}'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._getStatusStats().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value}'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Admin Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          subtitle: const Text('Configure alert preferences'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to notification settings
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security Settings'),
          subtitle: const Text('Manage access and permissions'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to security settings
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Data Export'),
          subtitle: const Text('Export reports and analytics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to data export
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help & Support'),
          subtitle: const Text('Admin documentation and support'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to help
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, {bool isCompact = false}) {
    final createdAt = report['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy HH:mm').format(createdAt.toDate())
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                _buildStatusChip(report['status']),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Report ID: ${report['id'].substring(0, 8)}...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(formattedDate, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                if (report['urgencyLevel'] != null)
                  _buildUrgencyIndicator(report['urgencyLevel']),
              ],
            ),
            
            if (!isCompact) ...[
              const SizedBox(height: 12),
              
              // Location info
              if (report['location'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report['location']['displayAddress'] ?? 'Location provided',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Contact info
              if (report['contactInfo'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.contact_phone, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Contact info provided',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ],
              
              // Attachments
              if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      '${(report['attachments'] as List).length} attachment(s)',
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showReportDetails(report),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showStatusUpdateDialog(report['id'], report['status']),
                      child: const Text('Update Status'),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'submitted':
        color = Colors.blue;
        label = 'Submitted';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'In Progress';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUrgencyIndicator(int urgencyLevel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < urgencyLevel ? _getUrgencyColor(urgencyLevel) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
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

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Reports';
      case 'emergency':
        return 'Emergency';
      case 'high_priority':
        return 'High Priority';
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      default:
        return filter;
    }
  }

  Map<String, int> _getReportTypeStats() {
    final Map<String, int> stats = {};
    for (var report in _reports) {
      final type = report['reportType'] as String;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _getStatusStats() {
    final Map<String, int> stats = {};
    for (var report in _reports) {
      final status = report['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${report['id']}'),
              Text('Type: ${report['reportType']}'),
              Text('Status: ${report['status']}'),
              Text('Emergency: ${report['isEmergency'] ? 'Yes' : 'No'}'),
              if (report['urgencyLevel'] != null)
                Text('Urgency: ${report['urgencyLevel']}/5'),
              // Add more details as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(String reportId, String currentStatus) {
    final List<String> statuses = ['submitted', 'in_progress', 'resolved'];
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Report Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return RadioListTile<String>(
              title: Text(status.replaceAll('_', ' ').toUpperCase()),
              value: status,
              groupValue: selectedStatus,
              onChanged: (value) {
                selectedStatus = value!;
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateReportStatus(reportId, selectedStatus);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
