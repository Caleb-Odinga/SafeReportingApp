import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/services/file_upload_service.dart';
import 'package:safe_reporting/utils/encryption_util.dart';
import 'package:safe_reporting/widgets/location_picker.dart';
import 'package:safe_reporting/widgets/attachment_picker.dart';
import 'package:safe_reporting/widgets/contact_info_form.dart';
import 'package:safe_reporting/models/location_data.dart';
import 'package:safe_reporting/models/contact_info.dart';

class NewReportScreen extends StatefulWidget {
  final String initialReportType;
  final bool isEmergency;

  const NewReportScreen({
    Key? key,
    this.initialReportType = '',
    this.isEmergency = false,
  }) : super(key: key);

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedReportType = '';
  int _urgencyLevel = 3; // Default medium urgency
  List<MediaAttachment> _attachments = [];
  bool _isSubmitting = false;
  
  final List<String> _reportTypes = [
    'Security Threat',
    'Corruption',
    'Harassment/Abuse',
    'Mental Health',
    'Other',
  ];

  LocationData? _selectedLocation;
  ContactInfo? _contactInfo;
  final FileUploadService _fileUploadService = FileUploadService();

  @override
  void initState() {
    super.initState();
    _selectedReportType = widget.initialReportType.isNotEmpty
        ? widget.initialReportType
        : _reportTypes[0];
    
    if (widget.isEmergency) {
      _urgencyLevel = 5; // Highest urgency for emergency reports
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final encryptionUtil = EncryptionUtil();
      final encryptionKey = await authService.getEncryptionKey();
      encryptionUtil.initializeEncrypter(encryptionKey);
      
      // Generate a unique report ID
      final reportId = const Uuid().v4();
      
      // Upload attachments
      List<Map<String, dynamic>> uploadedAttachments = [];
      for (var attachment in _attachments) {
        setState(() {
          attachment.uploadStatus = UploadStatus.uploading;
        });
        
        final uploadResult = await _fileUploadService.uploadFile(
          attachment,
          reportId,
          authService.anonymousId!,
        );
        
        if (uploadResult.isSuccess) {
          attachment.uploadStatus = UploadStatus.completed;
          attachment.downloadUrl = uploadResult.downloadUrl;
          uploadedAttachments.add(attachment.toJson());
        } else {
          attachment.uploadStatus = UploadStatus.failed;
          attachment.errorMessage = uploadResult.error;
        }
      }
      
      // Encrypt sensitive data
      final encryptedTitle = await encryptionUtil.encrypt(_titleController.text);
      final encryptedDescription = await encryptionUtil.encrypt(_descriptionController.text);
      
      // Prepare contact info (encrypt if provided)
      Map<String, dynamic>? encryptedContactInfo;
      if (_contactInfo != null && _contactInfo!.hasContactInfo) {
        final contactJson = _contactInfo!.toJson();
        encryptedContactInfo = {};
        for (var entry in contactJson.entries) {
          if (entry.value != null && entry.value is String && entry.value.isNotEmpty) {
            encryptedContactInfo[entry.key] = await encryptionUtil.encrypt(entry.value);
          } else {
            encryptedContactInfo[entry.key] = entry.value;
          }
        }
      }
      
      // Handle location data
      Map<String, dynamic>? locationData;
      if (_selectedLocation != null) {
        locationData = {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'accuracy': _selectedLocation!.accuracy,
          'displayAddress': _selectedLocation!.displayAddress,
          'privacySafeAddress': _selectedLocation!.privacySafeAddress,
          'isCurrentLocation': _selectedLocation!.isCurrentLocation,
          'shareExactLocation': _selectedLocation!.shareExactLocation,
          'timestamp': _selectedLocation!.timestamp.toIso8601String(),
        };
      }
      
      // Create the report document
      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'userId': authService.currentUser?.uid,
        'anonymousId': authService.anonymousId,
        'reportType': _selectedReportType,
        'urgencyLevel': _urgencyLevel,
        'isEmergency': widget.isEmergency,
        'title': encryptedTitle,
        'description': encryptedDescription,
        'location': locationData,
        'contactInfo': encryptedContactInfo,
        'attachments': uploadedAttachments,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'hasNewMessages': false,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEmergency ? 'Emergency Report' : 'New Report'),
        backgroundColor: widget.isEmergency ? Colors.red : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isEmergency)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This report will be marked as an emergency and prioritized by responders.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Text(
                'Report Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a report type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              Text(
                'Title',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Brief title for your report',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Provide details about the incident',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              LocationPicker(
                initialLocation: _selectedLocation,
                onLocationChanged: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                showPrivacyOptions: true,
                isRequired: false,
              ),
              
              const SizedBox(height: 16),
              AttachmentPicker(
                attachments: _attachments,
                onAttachmentsChanged: (attachments) {
                  setState(() {
                    _attachments = attachments;
                  });
                },
                maxAttachments: 5,
              ),
              
              const SizedBox(height: 16),
              ContactInfoForm(
                initialContactInfo: _contactInfo,
                onContactInfoChanged: (contactInfo) {
                  setState(() {
                    _contactInfo = contactInfo;
                  });
                },
                showPrivacyWarning: true,
              ),
              
              const SizedBox(height: 16),
              if (!widget.isEmergency) ...[
                Text(
                  'Urgency Level',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _urgencyLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _getUrgencyLabel(_urgencyLevel),
                  onChanged: (value) {
                    setState(() {
                      _urgencyLevel = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(color: Colors.grey)),
                    Text('High', style: TextStyle(color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.isEmergency ? Colors.red : null,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(widget.isEmergency ? 'Submit Emergency Report' : 'Submit Report'),
                ),
              ),
              
              const SizedBox(height: 16),
              const Text(
                'Your report will be submitted anonymously and securely encrypted.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
}
