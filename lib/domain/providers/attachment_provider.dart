import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'chat_provider.dart';

final attachmentProvider = FutureProvider.family<Attachment?, String>(
      (ref, String attachmentId) async {
    final repository = ref.watch(attachmentRepositoryProvider);
    return await repository.getAttachment(attachmentId);
  },
);
