import 'package:flutter/material.dart';
import 'package:safe_reporting/screens/simplified_new_report_screen.dart';
import 'package:safe_reporting/screens/simplified_my_reports_screen.dart';
import 'package:safe_reporting/screens/messages_screen.dart';
import 'package:safe_reporting/screens/settings_screen.dart';
import 'package:safe_reporting/services/report_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeContent(),
    const SimplifiedMyReportsScreen(),
    const MessagesScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Simplified initialization without auth service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showInfoDialog();
              },
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplifiedNewReportScreen()),
                );
              },
              label: const Text('New Report'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'SafeReporting';
      case 1:
        return 'My Reports';
      case 2:
        return 'Messages';
      case 3:
        return 'Settings';
      default:
        return 'SafeReporting';
    }
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SafeReporting'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SafeReporting allows you to anonymously report:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Security concerns and threats'),
              Text('• Corruption'),
              Text('• Harassment and abuse'),
              Text('• Mental health concerns'),
              SizedBox(height: 16),
              Text(
                'Your identity is protected through encryption and anonymous reporting.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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
}

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyButton(context),
          const SizedBox(height: 24),
          Text(
            'What would you like to report?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildReportTypeCard(
                context,
                'Security Threat',
                Icons.security,
                Colors.red.shade100,
                () => _navigateToNewReport(context, 'Security Threat'),
              ),
              _buildReportTypeCard(
                context,
                'Corruption',
                Icons.money_off,
                Colors.orange.shade100,
                () => _navigateToNewReport(context, 'Corruption'),
              ),
              _buildReportTypeCard(
                context,
                'Harassment/Abuse',
                Icons.person_off,
                Colors.purple.shade100,
                () => _navigateToNewReport(context, 'Harassment/Abuse'),
              ),
              _buildReportTypeCard(
                context,
                'Mental Health',
                Icons.psychology,
                Colors.blue.shade100,
                () => _navigateToNewReport(context, 'Mental Health'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Privacy',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All reports are encrypted and your identity is protected. You can communicate with responders while remaining anonymous.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.black87,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewReport(BuildContext context, String reportType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimplifiedNewReportScreen(initialReportType: reportType),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SimplifiedNewReportScreen(
                initialReportType: 'Security Threat',
                isEmergency: true,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning, size: 24),
            SizedBox(width: 8),
            Text(
              'EMERGENCY REPORT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
