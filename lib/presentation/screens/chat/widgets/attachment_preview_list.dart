import 'package:flutter/material.dart';

import '../../../../data/database/app_database.dart';
import '../../../../core/constants/ui_constants.dart';
import 'attachment_item.dart';

class AttachmentPreviewList extends StatelessWidget {
  final List<Attachment> attachments;
  final Function(String)? onRemove;

  const AttachmentPreviewList({
    super.key,
    required this.attachments,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingSm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: UIConstants.iconSm,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: UIConstants.spacingXs),
              Text(
                '첨부파일 ${attachments.length}개',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacingSm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: attachments
                  .map(
                    (attachment) => Padding(
                  padding: const EdgeInsets.only(
                    right: UIConstants.spacingSm,
                  ),
                  child: AttachmentItem(
                    attachment: attachment,
                    onRemove: onRemove != null
                        ? () => onRemove!(attachment.id)
                        : null,
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
