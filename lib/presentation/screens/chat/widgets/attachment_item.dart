// lib/presentation/screens/chat/widgets/attachment_item.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/database/app_database.dart';

class AttachmentItem extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onRemove;

  const AttachmentItem({super.key, required this.attachment, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha(UIConstants.alpha30),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.spacingMd),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 파일 아이콘
                Container(
                  width: UIConstants.iconLg + UIConstants.spacingSm,
                  height: UIConstants.iconLg + UIConstants.spacingSm,
                  padding: const EdgeInsets.all(UIConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: Icon(
                    _getFileIcon(attachment.fileName),
                    size: UIConstants.iconMd,
                  ),
                ),
                const SizedBox(width: UIConstants.spacingMd),
                // 파일 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(attachment.fileSize),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha(UIConstants.alpha60),
                        ),
                      ),
                    ],
                  ),
                ),
                // 삭제 버튼 공간 확보
                const SizedBox(width: UIConstants.spacingLg),
              ],
            ),
          ),
          // 삭제 버튼 (오른쪽 상단)
          if (onRemove != null)
            Positioned(
              top: UIConstants.spacingXs,
              right: UIConstants.spacingXs,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(UIConstants.spacingXs),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                    ),
                    child: const Icon(Icons.close, size: UIConstants.iconSm),
                  ),
                ),
              ),
            ),
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
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
