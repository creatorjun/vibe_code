// lib/domain/providers/project_folder_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// 프로젝트 폴더 상태
class ProjectFolderState {
  final String? folderPath;
  final DateTime? selectedAt;

  const ProjectFolderState({
    this.folderPath,
    this.selectedAt,
  });

  ProjectFolderState copyWith({
    String? folderPath,
    DateTime? selectedAt,
  }) {
    return ProjectFolderState(
      folderPath: folderPath ?? this.folderPath,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  bool get hasFolder => folderPath != null && folderPath!.isNotEmpty;
}

/// 프로젝트 폴더 노티파이어 (Riverpod 3.0)
class ProjectFolderNotifier extends Notifier<ProjectFolderState> {
  @override
  ProjectFolderState build() {
    return const ProjectFolderState();
  }

  /// 프로젝트 폴더 설정
  void setFolder(String path) {
    if (path.isEmpty) {
      Logger.warning('[ProjectFolder] Empty path provided');
      return;
    }

    Logger.info('[ProjectFolder] Setting folder: $path');
    state = ProjectFolderState(
      folderPath: path,
      selectedAt: DateTime.now(),
    );
  }

  /// 프로젝트 폴더 변경
  void changeFolder(String newPath) {
    if (newPath.isEmpty) {
      Logger.warning('[ProjectFolder] Empty path provided for change');
      return;
    }

    Logger.info('[ProjectFolder] Changing folder: ${state.folderPath} → $newPath');
    state = ProjectFolderState(
      folderPath: newPath,
      selectedAt: DateTime.now(),
    );
  }

  /// 프로젝트 폴더 초기화
  void clearFolder() {
    Logger.info('[ProjectFolder] Clearing folder: ${state.folderPath}');
    state = const ProjectFolderState();
  }

  /// 현재 폴더 경로 가져오기
  String? get currentPath => state.folderPath;

  /// 폴더가 설정되어 있는지 확인
  bool get hasFolder => state.hasFolder;
}

/// Provider 정의
final projectFolderProvider = NotifierProvider<ProjectFolderNotifier, ProjectFolderState>(
  ProjectFolderNotifier.new,
);
