import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../data/database/app_database.dart';

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
    final isImage = isImageFile(attachment.fileName);

    if (isImage) {
      return buildImageThumbnail(context);
    }

    return buildFileItem(context);
  }

  Widget buildImageThumbnail(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
            child: Container(
              width: 120,
              height: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.file(
                File(attachment.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      size: UIConstants.iconLg,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(UIConstants.alpha40),
                    ),
                  );
                },
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(UIConstants.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(UIConstants.spacingXs),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius:
                      BorderRadius.circular(UIConstants.radiusMd),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: UIConstants.iconSm,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildFileItem(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withAlpha(UIConstants.alpha30),
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
                Container(
                  width: UIConstants.iconLg + UIConstants.spacingSm,
                  height: UIConstants.iconLg + UIConstants.spacingSm,
                  padding: const EdgeInsets.all(UIConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: Icon(
                    getFileIcon(attachment.fileName),
                    size: UIConstants.iconMd,
                  ),
                ),
                const SizedBox(width: UIConstants.spacingMd),
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
                        formatFileSize(attachment.fileSize),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(UIConstants.alpha60),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UIConstants.spacingLg),
              ],
            ),
          ),
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
                      borderRadius:
                      BorderRadius.circular(UIConstants.radiusMd),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: UIConstants.iconSm,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  IconData getFileIcon(String fileName) {
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

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
