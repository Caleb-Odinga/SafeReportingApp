import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:safe_reporting/models/report.dart';

class ReportService {
  static const String _reportsKey = 'reports';
  static const String _anonymousIdKey = 'anonymous_id';
  
  final Uuid _uuid = const Uuid();

  // Get or create anonymous ID
  Future<String> getAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    String? anonymousId = prefs.getString(_anonymousIdKey);
    
    if (anonymousId == null) {
      anonymousId = _uuid.v4();
      await prefs.setString(_anonymousIdKey, anonymousId);
    }
    
    return anonymousId;
  }

  // Submit a new report
  Future<String> submitReport({
    required String title,
    required String description,
    required String reportType,
    required int urgencyLevel,
    required bool isEmergency,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contactInfo,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final reportId = _uuid.v4();
    final anonymousId = await getAnonymousId();
    final now = DateTime.now();
    
    final report = Report(
      id: reportId,
      title: title,
      description: description,
      reportType: reportType,
      urgencyLevel: urgencyLevel,
      isEmergency: isEmergency,
      createdAt: now,
      updatedAt: now,
      status: 'submitted',
      anonymousId: anonymousId,
      location: location,
      contactInfo: contactInfo,
      attachments: attachments,
    );

    await _saveReport(report);
    return reportId;
  }

  // Save report to local storage
  Future<void> _saveReport(Report report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getAllReports();
    reports.add(report);
    
    final reportsJson = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_reportsKey, jsonEncode(reportsJson));
  }

  // Get all reports
  Future<List<Report>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportsKey);
    
    if (reportsJson == null) {
      return [];
    }
    
    final List<dynamic> reportsList = jsonDecode(reportsJson);
    return reportsList.map((json) => Report.fromJson(json)).toList();
  }

  // Get reports by anonymous ID
  Future<List<Report>> getMyReports() async {
    final anonymousId = await getAnonymousId();
    final allReports = await getAllReports();
    
    return allReports
        .where((report) => report.anonymousId == anonymousId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get report by ID
  Future<Report?> getReportById(String reportId) async {
    final reports = await getAllReports();
    try {
      return reports.firstWhere((report) => report.id == reportId);
    } catch (e) {
      return null;
    }
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status) async {
    final reports = await getAllReports();
    final reportIndex = reports.indexWhere((r) => r.id == reportId);
    
    if (reportIndex != -1) {
      reports[reportIndex] = reports[reportIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));
    }
  }

  // Mark report as having new messages
  Future<void> markReportHasNewMessages(String reportId, bool hasNewMessages) async {
    final reports = await getAllReports();
    final reportIndex = reports.indexWhere((r) => r.id == reportId);
    
    if (reportIndex != -1) {
      reports[reportIndex] = reports[reportIndex].copyWith(
        hasNewMessages: hasNewMessages,
        updatedAt: DateTime.now(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));
    }
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    final reports = await getAllReports();
    reports.removeWhere((report) => report.id == reportId);
    
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_reportsKey, jsonEncode(reportsJson));
  }

  // Get reports count by status
  Future<Map<String, int>> getReportsCountByStatus() async {
    final reports = await getAllReports();
    final Map<String, int> counts = {};
    
    for (final report in reports) {
      counts[report.status] = (counts[report.status] ?? 0) + 1;
    }
    
    return counts;
  }

  // Get emergency reports count
  Future<int> getEmergencyReportsCount() async {
    final reports = await getAllReports();
    return reports.where((report) => report.isEmergency).length;
  }

  // Clear all reports (for testing/development)
  Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
  }
}
