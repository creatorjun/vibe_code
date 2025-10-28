// lib/data/services/file_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';

class FileService {
  /// 파일 해시 계산 (SHA256)
  Future<String> calculateHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate file hash', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// ✅ 신규: 스트리밍 방식 해시 계산 (대용량 파일용)
  Future<String> calculateHashStream(File file) async {
    try {
      final stream = file.openRead();
      final digest = await sha256.bind(stream).first;
      return digest.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate file hash (stream)', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// 파일을 앱 디렉토리에 저장
  Future<String> saveToAppDirectory(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(path.join(appDir.path, 'attachments'));

      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // 타임스탬프 + 원본 파일명으로 고유한 이름 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(file.path);
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(attachmentsDir.path, newFileName);

      final newFile = await file.copy(newPath);

      Logger.info('File saved to app directory: $newPath');
      return newFile.path;
    } catch (e, stackTrace) {
      Logger.error('Failed to save file', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// 파일 내용 읽기
  Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('파일을 찾을 수 없습니다: $filePath');
      }
      return await file.readAsString();
    } catch (e, stackTrace) {
      Logger.error('Failed to read file', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// ✅ 신규: 스트리밍 방식 파일 읽기 (청크 단위)
  Stream<String> readFileStream(String filePath, {int chunkSize = 1024 * 1024}) async* {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('파일을 찾을 수 없습니다: $filePath');
      }

      final stream = file.openRead();
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        final text = String.fromCharCodes(chunk);
        buffer.write(text);

        // 청크 크기에 도달하면 yield
        if (buffer.length >= chunkSize) {
          yield buffer.toString();
          buffer.clear();
        }
      }

      // 남은 데이터 yield
      if (buffer.isNotEmpty) {
        yield buffer.toString();
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to read file (stream)', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// ✅ 신규: Base64 인코딩 (스트리밍 방식)
  Stream<String> encodeToBase64Stream(File file, {int chunkSize = 1024 * 1024}) async* {
    try {
      if (!await file.exists()) {
        throw FileException('파일이 존재하지 않습니다.');
      }

      final stream = file.openRead();
      final buffer = <int>[];

      await for (final chunk in stream) {
        buffer.addAll(chunk);

        // 청크 크기에 도달하면 인코딩하고 yield
        while (buffer.length >= chunkSize) {
          final toEncode = buffer.sublist(0, chunkSize);
          buffer.removeRange(0, chunkSize);

          // Base64 인코딩은 3바이트 단위로 처리되므로 3의 배수로 맞춤
          final alignedSize = (toEncode.length ~/ 3) * 3;
          if (alignedSize > 0) {
            final aligned = toEncode.sublist(0, alignedSize);
            final remaining = toEncode.sublist(alignedSize);

            yield base64Encode(aligned);

            // 남은 바이트는 버퍼에 다시 추가
            buffer.insertAll(0, remaining);
          }
        }
      }

      // 남은 데이터 인코딩
      if (buffer.isNotEmpty) {
        yield base64Encode(buffer);
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to encode to base64 (stream)', e, stackTrace);
      throw FileException(e.toString());
    }
  }

  /// 파일 유효성 검사
  Future<void> validateFile(File file) async {
    if (!await file.exists()) {
      throw const FileException('파일이 존재하지 않습니다.');
    }

    final fileSize = await file.length();
    if (!Validators.isValidFileSize(fileSize)) {
      throw FileSizeException(
        '파일 크기가 너무 큽니다. (최대 ${AppConstants.maxFileSize ~/ 1024 ~/ 1024}MB).',
      );
    }

    Logger.info(
      'File validation passed: ${path.basename(file.path)}, ${fileSize ~/ 1024}KB',
    );
  }

  /// MIME 타입 가져오기
  String? getMimeType(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }

  /// 파일 삭제
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.info('File deleted: $filePath');
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to delete file', e, stackTrace);
    }
  }

  /// 미사용 파일 정리
  Future<void> cleanupUnusedFiles(List<String> usedFilePaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(path.join(appDir.path, 'attachments'));

      if (!await attachmentsDir.exists()) return;

      final usedPathSet = usedFilePaths.toSet();
      final files = attachmentsDir.listSync();

      for (final file in files) {
        if (file is File && !usedPathSet.contains(file.path)) {
          await deleteFile(file.path);
          Logger.info('Cleaned up unused file: ${file.path}');
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to cleanup unused files', e, stackTrace);
    }
  }
}
