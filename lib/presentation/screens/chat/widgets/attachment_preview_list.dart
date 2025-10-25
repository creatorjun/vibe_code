// lib/presentation/screens/chat/widgets/attachment_preview_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/ui_constants.dart';
import '../../../../../../data/database/app_database.dart';
import '../../../../../../domain/providers/chat_provider.dart';
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
    // 최적화: 모든 첨부파일을 한 번에 로드
    final attachmentFutures = attachmentIds.map((id) {
      return ref.read(attachmentRepositoryProvider).getAttachment(id);
    }).toList();

    return FutureBuilder<List<Attachment?>>(
      future: Future.wait(attachmentFutures),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final attachments = snapshot.data!
            .where((attachment) => attachment != null)
            .cast<Attachment>()
            .toList();

        if (attachments.isEmpty) {
          return const SizedBox.shrink();
        }

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
                    '${attachments.length}',
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
                  children: attachments
                      .map(
                        (attachment) => Padding(
                      padding: const EdgeInsets.only(
                        right: UIConstants.spacingSm,
                      ),
                      child: AttachmentItem(
                        attachment: attachment,
                        onRemove: () => onRemove(attachment.id),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
