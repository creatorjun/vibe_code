// lib/core/utils/clipboard_helper.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:uuid/uuid.dart';
import 'package:vibe_code/core/utils/logger.dart';

class ClipboardHelper {
  static final _uuid = Uuid();

  /// 클립보드에 이미지가 있는지 확인
  static Future<bool> hasImage() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return false;

      final reader = await clipboard.read();
      return reader.canProvide(Formats.png) ||
          reader.canProvide(Formats.jpeg) ||
          reader.canProvide(Formats.gif);
    } catch (e) {
      Logger.error('Failed to check clipboard image: $e');
      return false;
    }
  }

  /// 클립보드에서 이미지 가져오기
  static Future<File?> getImageFromClipboard() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        Logger.debug('[ClipboardHelper] SystemClipboard is null');
        return null;
      }

      final reader = await clipboard.read();

      // 형식 결정
      String extension = 'png';
      SimpleFileFormat format = Formats.png;

      if (reader.canProvide(Formats.png)) {
        extension = 'png';
        format = Formats.png;
      } else if (reader.canProvide(Formats.jpeg)) {
        extension = 'jpg';
        format = Formats.jpeg;
      } else if (reader.canProvide(Formats.gif)) {
        extension = 'gif';
        format = Formats.gif;
      } else {
        Logger.debug('[ClipboardHelper] No supported image format');
        return null;
      }

      Logger.debug('[ClipboardHelper] Reading $extension format');

      // ✅ Completer로 비동기 콜백 처리
      final completer = Completer<File?>();

      // getFile 콜백 사용
      reader.getFile(format, (file) async {
        try {
          Logger.debug('[ClipboardHelper] Reading stream...');
          final stream = file.getStream();
          final chunks = <Uint8List>[];

          await for (final chunk in stream) {
            chunks.add(chunk);
          }

          // 모든 청크 합치기
          final totalLength = chunks.fold(0, (sum, chunk) => sum + chunk.length);
          final imageBytes = Uint8List(totalLength);
          var offset = 0;
          for (final chunk in chunks) {
            imageBytes.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }

          Logger.debug('[ClipboardHelper] Total bytes: $totalLength');

          // 임시 파일로 저장
          final tempDir = await getTemporaryDirectory();
          final fileName = '${_uuid.v4()}.$extension';
          final resultFile = File('${tempDir.path}/$fileName');
          await resultFile.writeAsBytes(imageBytes);

          Logger.info('Image saved from clipboard: ${resultFile.path}');

          // ✅ Completer로 결과 전달
          completer.complete(resultFile);
        } catch (e, stack) {
          Logger.error('[ClipboardHelper] Error reading image', e, stack);
          completer.complete(null);
        }
      });

      // ✅ Completer가 완료될 때까지 대기
      return await completer.future;
    } catch (e, stack) {
      Logger.error('Failed to get image from clipboard', e, stack);
      return null;
    }
  }

  /// 클립보드에 텍스트가 있는지 확인
  static Future<bool> hasText() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return false;

      final reader = await clipboard.read();
      return reader.canProvide(Formats.plainText);
    } catch (e) {
      Logger.error('Failed to check clipboard text: $e');
      return false;
    }
  }

  /// 클립보드에서 텍스트 가져오기
  static Future<String?> getTextFromClipboard() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final reader = await clipboard.read();
        if (reader.canProvide(Formats.plainText)) {
          return await reader.readValue(Formats.plainText);
        }
      }

      // 폴백
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      Logger.error('Failed to get text from clipboard: $e');
      return null;
    }
  }
}
