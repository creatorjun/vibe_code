import 'dart:io';
import 'package:github_analyzer/github_analyzer.dart';
import '../../core/utils/logger.dart';

class GitHubAnalysisService {
  Future<String> analyzeRepository(String repositoryUrl) async {
    try {
      Logger.info('Analyzing GitHub repository: $repositoryUrl');

      final outputPath = await analyzeForLLM(
        repositoryUrl,
        outputDir: Directory.systemTemp.path,
        maxFiles: 200,
      );

      final content = await File(outputPath).readAsString();
      Logger.info('GitHub analysis completed: ${content.length} characters');

      await File(outputPath).delete();

      return content;
    } catch (e, stackTrace) {
      Logger.error('GitHub analysis failed', e, stackTrace);
      throw Exception('GitHub 저장소 분석 실패: $e');
    }
  }

  Future<String> analyzeLocalDirectory(String directoryPath) async {
    try {
      Logger.info('Analyzing local directory: $directoryPath');

      final tempCopyDir = await _createCleanCopy(directoryPath);

      try {
        final outputPath = await analyzeForLLM(
          tempCopyDir.path,
          outputDir: Directory.systemTemp.path,
          maxFiles: 200,
        );

        final content = await File(outputPath).readAsString();
        Logger.info('Local analysis completed: ${content.length} characters');

        await tempCopyDir.delete(recursive: true);
        await File(outputPath).delete();

        return content;
      } catch (e) {
        // 분석 실패 시에도 임시 폴더는 정리
        try {
          await tempCopyDir.delete(recursive: true);
        } catch (_) {}
        rethrow;
      }
    } catch (e, stackTrace) {
      Logger.error('Local analysis failed', e, stackTrace);
      throw Exception('로컬 프로젝트 분석 실패: $e');
    }
  }

  Future<Directory> _createCleanCopy(String sourcePath) async {
    final tempDir = Directory.systemTemp.createTempSync('vibe_analysis_');
    final sourceDir = Directory(sourcePath);

    await _copyDirectory(sourceDir, tempDir);

    return tempDir;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;

      if (_shouldExclude(name)) {
        continue;
      }

      try {
        if (entity is Directory) {
          final newDirectory = Directory('${destination.path}/$name');
          await newDirectory.create();
          await _copyDirectory(entity, newDirectory);
        } else if (entity is File) {
          if (_shouldIncludeFile(name)) {
            await entity.copy('${destination.path}/$name');
          }
        }
      } catch (e) {
        Logger.warning('Failed to copy ${entity.path}: $e');
      }
    }
  }

  bool _shouldExclude(String name) {
    final excludeList = [
      '.git',
      '.github',
      'node_modules',
      'build',
      '.dart_tool',
      '.idea',
      '.vscode',
      'coverage',
      '.flutter-plugins',
      '.flutter-plugins-dependencies',
      '.packages',
      'Pods',
      '.gradle',
      'ephemeral',
      '.symlinks',
      '.symlink',
      'Generated.xcconfig',
      'flutter_export_environment.sh',
    ];

    return excludeList.contains(name) || name.startsWith('.');
  }

  bool _shouldIncludeFile(String name) {
    if (name.endsWith('.g.dart') || name.endsWith('.freezed.dart')) {
      return false;
    }

    if (name == 'pubspec.lock' || name == '.DS_Store') {
      return false;
    }

    final allowedExtensions = [
      '.dart',
      '.yaml',
      '.yml',
      '.json',
      '.md',
      '.txt',
      '.sh',
      '.xml',
      '.gradle',
      '.properties',
    ];

    return allowedExtensions.any((ext) => name.endsWith(ext));
  }
}
