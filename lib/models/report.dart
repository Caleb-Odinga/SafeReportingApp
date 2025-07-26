class Report {
  final String id;
  final String title;
  final String description;
  final String reportType;
  final int urgencyLevel;
  final bool isEmergency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool hasNewMessages;
  final String? userId;
  final String? anonymousId;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? contactInfo;
  final List<Map<String, dynamic>>? attachments;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.reportType,
    required this.urgencyLevel,
    required this.isEmergency,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.hasNewMessages = false,
    this.userId,
    this.anonymousId,
    this.location,
    this.contactInfo,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reportType': reportType,
      'urgencyLevel': urgencyLevel,
      'isEmergency': isEmergency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'hasNewMessages': hasNewMessages,
      'userId': userId,
      'anonymousId': anonymousId,
      'location': location,
      'contactInfo': contactInfo,
      'attachments': attachments,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      reportType: json['reportType'],
      urgencyLevel: json['urgencyLevel'],
      isEmergency: json['isEmergency'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'],
      hasNewMessages: json['hasNewMessages'] ?? false,
      userId: json['userId'],
      anonymousId: json['anonymousId'],
      location: json['location'],
      contactInfo: json['contactInfo'],
      attachments: json['attachments']?.cast<Map<String, dynamic>>(),
    );
  }

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? reportType,
    int? urgencyLevel,
    bool? isEmergency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? hasNewMessages,
    String? userId,
    String? anonymousId,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contactInfo,
    List<Map<String, dynamic>>? attachments,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reportType: reportType ?? this.reportType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      hasNewMessages: hasNewMessages ?? this.hasNewMessages,
      userId: userId ?? this.userId,
      anonymousId: anonymousId ?? this.anonymousId,
      location: location ?? this.location,
      contactInfo: contactInfo ?? this.contactInfo,
      attachments: attachments ?? this.attachments,
    );
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
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
}
