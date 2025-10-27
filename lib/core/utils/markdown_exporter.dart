// lib/core/utils/markdown_exporter.dart

import 'package:flutter/services.dart';
import 'package:vibe_code/data/database/app_database.dart';
import 'package:vibe_code/core/utils/date_formatter.dart';
import 'package:vibe_code/core/utils/logger.dart';
import 'package:intl/intl.dart';

class MarkdownExporter {
  /// 세션 전체를 마크다운으로 변환
  static String exportSessionToMarkdown({
    required ChatSession session,
    required List<Message> messages,
  }) {
    final buffer = StringBuffer();

    // 헤더
    buffer.writeln('# ${session.title}');
    buffer.writeln();
    buffer.writeln('**생성일**: ${DateFormatter.formatChatTime(session.createdAt)}'); // ✅ 수정
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 메시지
    for (final message in messages) {
      _writeMessage(buffer, message);
    }

    // 푸터
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('*Exported from Vibe Code on ${DateFormatter.formatChatTime(DateTime.now())}*'); // ✅ 수정

    return buffer.toString();
  }

  /// 단일 메시지를 마크다운으로 작성
  static void _writeMessage(StringBuffer buffer, Message message) {
    // 역할 헤더
    if (message.role == 'user') {
      buffer.writeln('## 👤 User');
    } else {
      buffer.writeln('## 🤖 Assistant');
    }

    buffer.writeln();

    // 메시지 내용
    buffer.writeln(message.content);
    buffer.writeln();

    // 타임스탬프
    buffer.writeln('*${DateFormatter.formatMessageTime(message.createdAt)}*');

    // 토큰 정보 (AI 메시지만)
    if (message.role == 'assistant') {
      buffer.writeln();
      buffer.writeln('> 📊 Tokens: ${message.inputTokens} → ${message.outputTokens}');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  /// 클립보드에 복사
  static Future<bool> copyToClipboard(String markdown) async {
    try {
      await Clipboard.setData(ClipboardData(text: markdown));
      Logger.info('Markdown copied to clipboard: ${markdown.length} characters');
      return true;
    } catch (e) {
      Logger.error('Failed to copy to clipboard: $e');
      return false;
    }
  }

  /// 파일로 저장 (플랫폼별 처리 필요)
  static String generateFilename(String sessionTitle) {
    final sanitized = sessionTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'chat_${sanitized}_$timestamp.md';
  }
}
