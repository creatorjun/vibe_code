import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../core/utils/logger.dart';
import 'tables/chat_sessions_table.dart';
import 'tables/messages_table.dart';
import 'tables/attachments_table.dart';
import 'tables/message_attachments_table.dart';
import 'tables/settings_table.dart';
import 'daos/chat_dao.dart';
import 'daos/attachment_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ChatSessions,
    Messages,
    Attachments,
    MessageAttachments,
    Settings,
  ],
  daos: [
    ChatDao,
    AttachmentDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ===== 변경: 스키마 버전 2로 증가 =====
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        Logger.debug('[Database] Tables created successfully');

        // 기본 설정 초기화
        await _initializeDefaultSettings();
      },
      // ===== 추가: 마이그레이션 로직 =====
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // 버전 1 → 2: Messages 테이블에 토큰 컬럼 추가
          await m.addColumn(messages, messages.inputTokens);
          await m.addColumn(messages, messages.outputTokens);
          Logger.debug('[Database] Migration 1->2: Added token columns to Messages table');
        }
      },
      // ================================
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        Logger.debug('[Database] Foreign keys enabled');

        if (details.wasCreated) {
          Logger.debug('[Database] New database created');
        } else {
          Logger.debug('[Database] Existing database opened');
        }
      },
    );
  }

  /// 기본 설정 초기화
  Future<void> _initializeDefaultSettings() async {
    try {
      Logger.debug('[Database] Initializing default settings...');

      await into(settings).insert(
        SettingsCompanion.insert(
          key: 'api_key',
          value: '',
        ),
      );

      await into(settings).insert(
        SettingsCompanion.insert(
          key: 'selected_model',
          value: 'anthropic/claude-3.5-sonnet',
        ),
      );

      await into(settings).insert(
        SettingsCompanion.insert(
          key: 'system_prompt',
          value: '''You are a helpful AI assistant specialized in coding and technical discussions.
You provide clear, concise, and accurate responses.
When writing code, always use proper formatting and include comments when necessary.''',
        ),
      );

      await into(settings).insert(
        SettingsCompanion.insert(
          key: 'theme_mode',
          value: 'system',
        ),
      );

      Logger.debug('[Database] Default settings initialized');
    } catch (e) {
      Logger.debug('[Database] Error initializing default settings: $e');
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'vibe_code.db'));
    if (kDebugMode) {
      print('[Database] Database path: ${file.path}');
    }
    return NativeDatabase(file);
  });
}
