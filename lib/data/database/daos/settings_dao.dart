import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // 설정값 저장
  Future<void> saveSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 설정값 조회
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  // 여러 설정값 조회
  Future<Map<String, String>> getSettings(List<String> keys) async {
    final results =
    await (select(settings)..where((t) => t.key.isIn(keys))).get();
    return {for (var setting in results) setting.key: setting.value};
  }

  // 모든 설정값 조회
  Future<Map<String, String>> getAllSettings() async {
    final results = await select(settings).get();
    return {for (var setting in results) setting.key: setting.value};
  }

  // 설정값 삭제
  Future<void> deleteSetting(String key) async {
    await (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  // 모든 설정값 삭제
  Future<void> deleteAllSettings() async {
    await delete(settings).go();
  }

  // 설정값 스트림
  Stream<String?> watchSetting(String key) {
    return (select(settings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((setting) => setting?.value);
  }
}
