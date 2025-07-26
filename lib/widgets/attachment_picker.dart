import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_reporting/services/file_upload_service.dart';

class AttachmentPicker extends StatefulWidget {
  final List<MediaAttachment> attachments;
  final Function(List<MediaAttachment>) onAttachmentsChanged;
  final int maxAttachments;
  final bool allowImages;
  final bool allowVideos;
  final bool allowAudio;
  final bool allowDocuments;

  const AttachmentPicker({
    Key? key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.maxAttachments = 5,
    this.allowImages = true,
    this.allowVideos = true,
    this.allowAudio = true,
    this.allowDocuments = true,
  }) : super(key: key);

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  final FileUploadService _fileUploadService = FileUploadService();

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.allowImages) ...[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
            if (widget.allowVideos) ...[
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
            if (widget.allowAudio)
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('Choose Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudio();
                },
              ),
            if (widget.allowDocuments)
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Choose Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final result = await _fileUploadService.pickImage(source: source);
    _handleAttachmentResult(result);
  }

  Future<void> _pickVideo(ImageSource source) async {
    final result = await _fileUploadService.pickVideo(source: source);
    _handleAttachmentResult(result);
  }

  Future<void> _pickAudio() async {
    final result = await _fileUploadService.pickAudio();
    _handleAttachmentResult(result);
  }

  Future<void> _pickDocument() async {
    final result = await _fileUploadService.pickDocument();
    _handleAttachmentResult(result);
  }

  void _handleAttachmentResult(AttachmentResult result) {
    if (result.isSuccess && result.attachment != null) {
      final updatedAttachments = [...widget.attachments, result.attachment!];
      widget.onAttachmentsChanged(updatedAttachments);
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(String attachmentId) {
    final updatedAttachments = widget.attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList();
    widget.onAttachmentsChanged(updatedAttachments);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (widget.attachments.length < widget.maxAttachments)
              TextButton.icon(
                onPressed: _showAttachmentOptions,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (widget.attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.attach_file, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No attachments added',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Add" to attach evidence',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final attachment = widget.attachments[index];
              return _buildAttachmentTile(attachment);
            },
          ),
        
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.attachments.length}/${widget.maxAttachments} attachments',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentTile(MediaAttachment attachment) {
    IconData icon;
    Color color;

    switch (attachment.type) {
      case AttachmentType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case AttachmentType.video:
        icon = Icons.video_file;
        color = Colors.purple;
        break;
      case AttachmentType.audio:
        icon = Icons.audio_file;
        color = Colors.orange;
        break;
      case AttachmentType.document:
        icon = Icons.description;
        color = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attachment.fileSizeFormatted),
            if (attachment.uploadStatus == UploadStatus.uploading)
              LinearProgressIndicator(value: attachment.uploadProgress),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachment.uploadStatus == UploadStatus.completed)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (attachment.uploadStatus == UploadStatus.failed)
              Icon(Icons.error, color: Colors.red, size: 20),
            IconButton(
              onPressed: () => _removeAttachment(attachment.id),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
