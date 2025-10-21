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
  Future<String> calculateHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate file hash', e, stackTrace);
      throw FileException('파일 해시 계산 실패: $e');
    }
  }

  Future<String> saveToAppDirectory(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(path.join(appDir.path, 'attachments'));

      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(file.path);
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(attachmentsDir.path, newFileName);

      final newFile = await file.copy(newPath);
      Logger.info('File saved to app directory: $newPath');

      return newFile.path;
    } catch (e, stackTrace) {
      Logger.error('Failed to save file', e, stackTrace);
      throw FileException('파일 저장 실패: $e');
    }
  }

  Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('파일이 존재하지 않습니다: $filePath');
      }

      return await file.readAsString();
    } catch (e, stackTrace) {
      Logger.error('Failed to read file', e, stackTrace);
      throw FileException('파일 읽기 실패: $e');
    }
  }

  Future<void> validateFile(File file) async {
    if (!await file.exists()) {
      throw const FileException('파일이 존재하지 않습니다.');
    }

    final fileSize = await file.length();
    if (!Validators.isValidFileSize(fileSize)) {
      throw FileSizeException(
        '파일 크기가 너무 큽니다. 최대 ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB까지 지원됩니다.',
      );
    }

    Logger.info('File validation passed: ${path.basename(file.path)}, ${fileSize ~/ 1024}KB');
  }

  String? getMimeType(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }

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
