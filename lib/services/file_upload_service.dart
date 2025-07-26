import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Supported file types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedVideoTypes = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedAudioTypes = ['mp3', 'wav', 'aac', 'm4a'];
  static const List<String> supportedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50MB
  static const int maxDocumentSize = 20 * 1024 * 1024; // 20MB

  // Pick image from camera or gallery
  Future<AttachmentResult> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return AttachmentResult.cancelled();
      }

      final File file = File(image.path);
      final int fileSize = await file.length();

      if (fileSize > maxImageSize) {
        return AttachmentResult.error('Image size exceeds 10MB limit');
      }

      // Compress image if needed
      final compressedFile = await _compressImage(file);

      final attachment = MediaAttachment(
        id: const Uuid().v4(),
        file: compressedFile ?? file,
        fileName: path.basename(image.path),
        fileSize: await (compressedFile ?? file).length(),
        mimeType: 'image/${path.extension(image.path).substring(1)}',
        type: AttachmentType.image,
        uploadStatus: UploadStatus.pending,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick image: $e');
    }
  }

  // Pick video from camera or gallery
  Future<AttachmentResult> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) {
        return AttachmentResult.cancelled();
      }

      final File file = File(video.path);
      final int fileSize = await file.length();

      if (fileSize > maxVideoSize) {
        return AttachmentResult.error('Video size exceeds 100MB limit');
      }

      // Compress video if needed
      final compressedFile = await _compressVideo(file);

      final attachment = MediaAttachment(
        id: const Uuid().v4(),
        file: compressedFile ?? file,
        fileName: path.basename(video.path),
        fileSize: await (compressedFile ?? file).length(),
        mimeType: 'video/${path.extension(video.path).substring(1)}',
        type: AttachmentType.video,
        uploadStatus: UploadStatus.pending,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick video: $e');
    }
  }

  // Pick audio file
  Future<AttachmentResult> pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return AttachmentResult.cancelled();
      }

      final PlatformFile platformFile = result.files.first;
      final File file = File(platformFile.path!);
      final int fileSize = platformFile.size;

      if (fileSize > maxAudioSize) {
        return AttachmentResult.error('Audio size exceeds 50MB limit');
      }

      final attachment = MediaAttachment(
        id: const Uuid().v4(),
        file: file,
        fileName: platformFile.name,
        fileSize: fileSize,
        mimeType: 'audio/${path.extension(platformFile.name).substring(1)}',
        type: AttachmentType.audio,
        uploadStatus: UploadStatus.pending,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick audio: $e');
    }
  }

  // Pick document file
  Future<AttachmentResult> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedDocumentTypes,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return AttachmentResult.cancelled();
      }

      final PlatformFile platformFile = result.files.first;
      final File file = File(platformFile.path!);
      final int fileSize = platformFile.size;

      if (fileSize > maxDocumentSize) {
        return AttachmentResult.error('Document size exceeds 20MB limit');
      }

      final attachment = MediaAttachment(
        id: const Uuid().v4(),
        file: file,
        fileName: platformFile.name,
        fileSize: fileSize,
        mimeType: 'application/${path.extension(platformFile.name).substring(1)}',
        type: AttachmentType.document,
        uploadStatus: UploadStatus.pending,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick document: $e');
    }
  }

  // Upload file to Firebase Storage
  Future<UploadResult> uploadFile(MediaAttachment attachment, String reportId, String userId) async {
    try {
      final String fileName = '${attachment.id}_${attachment.fileName}';
      final Reference storageRef = _storage
          .ref()
          .child('reports')
          .child(userId)
          .child(reportId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        attachment.file,
        SettableMetadata(
          contentType: attachment.mimeType,
          customMetadata: {
            'originalName': attachment.fileName,
            'attachmentId': attachment.id,
            'reportId': reportId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        attachment.uploadProgress = progress;
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult.success(
        downloadUrl: downloadUrl,
        fileName: fileName,
        fileSize: attachment.fileSize,
      );
    } catch (e) {
      return UploadResult.error('Upload failed: $e');
    }
  }

  // Compress image
  Future<File?> _compressImage(File file) async {
    try {
      final String targetPath = '${file.path}_compressed.jpg';
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 600,
      );

      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Image compression failed: $e');
      return null;
    }
  }

  // Compress video
  Future<File?> _compressVideo(File file) async {
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      return info?.file;
    } catch (e) {
      print('Video compression failed: $e');
      return null;
    }
  }

  // Delete file from storage
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Failed to delete file: $e');
      return false;
    }
  }

  // Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata.customMetadata;
    } catch (e) {
      print('Failed to get file metadata: $e');
      return null;
    }
  }
}

// Models and enums
enum AttachmentType { image, video, audio, document }
enum UploadStatus { pending, uploading, completed, failed }

class MediaAttachment {
  final String id;
  final File file;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final AttachmentType type;
  UploadStatus uploadStatus;
  double uploadProgress;
  String? downloadUrl;
  String? errorMessage;

  MediaAttachment({
    required this.id,
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.type,
    this.uploadStatus = UploadStatus.pending,
    this.uploadProgress = 0.0,
    this.downloadUrl,
    this.errorMessage,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'type': type.toString(),
      'downloadUrl': downloadUrl,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
  }
}

class AttachmentResult {
  final bool isSuccess;
  final MediaAttachment? attachment;
  final String? error;
  final bool isCancelled;

  AttachmentResult._({
    required this.isSuccess,
    this.attachment,
    this.error,
    this.isCancelled = false,
  });

  factory AttachmentResult.success(MediaAttachment attachment) {
    return AttachmentResult._(isSuccess: true, attachment: attachment);
  }

  factory AttachmentResult.error(String error) {
    return AttachmentResult._(isSuccess: false, error: error);
  }

  factory AttachmentResult.cancelled() {
    return AttachmentResult._(isSuccess: false, isCancelled: true);
  }
}

class UploadResult {
  final bool isSuccess;
  final String? downloadUrl;
  final String? fileName;
  final int? fileSize;
  final String? error;

  UploadResult._({
    required this.isSuccess,
    this.downloadUrl,
    this.fileName,
    this.fileSize,
    this.error,
  });

  factory UploadResult.success({
    required String downloadUrl,
    required String fileName,
    required int fileSize,
  }) {
    return UploadResult._(
      isSuccess: true,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  factory UploadResult.error(String error) {
    return UploadResult._(isSuccess: false, error: error);
  }
}
