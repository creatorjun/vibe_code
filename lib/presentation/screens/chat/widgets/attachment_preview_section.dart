// lib/presentation/screens/chat/widgets/attachment_preview_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/providers/chat_provider.dart';
import 'attachment_item.dart';

class AttachmentPreviewSection extends ConsumerWidget {
  final List<String> attachmentIds;
  final Function(String) onRemove;

  const AttachmentPreviewSection({
    super.key,
    required this.attachmentIds,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        UIConstants.spacingMd,
        UIConstants.spacingMd,
        UIConstants.spacingMd,
        UIConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withAlpha(UIConstants.alpha30),
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UIConstants.spacingXs),
              Text(
                '첨부파일 ${attachmentIds.length}개',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacingSm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: attachmentIds
                  .map(
                    (id) => Padding(
                  padding: const EdgeInsets.only(
                    right: UIConstants.spacingSm,
                  ),
                  child: FutureBuilder(
                    future: ref
                        .read(attachmentRepositoryProvider)
                        .getAttachment(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return AttachmentItem(
                          attachment: snapshot.data!,
                          onRemove: () => onRemove(id),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
