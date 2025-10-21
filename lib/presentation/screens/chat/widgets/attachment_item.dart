import 'package:flutter/material.dart';
import '../../../../data/database/app_database.dart';
import '../../../../core/constants/ui_constants.dart';

class AttachmentItem extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onRemove;

  const AttachmentItem({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: UIConstants.spacingSm),
      padding: const EdgeInsets.all(UIConstants.spacingSm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.fileName),
            size: UIConstants.iconMd,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UIConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                _formatFileSize(attachment.fileSize),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (onRemove != null) ...[
            const SizedBox(width: UIConstants.spacingSm),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(UIConstants.radiusXs),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'cpp':
      case 'c':
      case 'go':
      case 'rs':
      case 'swift':
      case 'kt':
        return Icons.code;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return Icons.data_object;
      case 'md':
      case 'txt':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
