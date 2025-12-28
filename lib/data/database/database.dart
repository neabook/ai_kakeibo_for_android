import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tables.dart';

part 'database.g.dart';

/// アプリケーションデータベース
@DriftDatabase(tables: [
  Categories,
  Expenses,
  ExpenseItems,
  Budgets,
  AiAnalyses,
  Subscriptions,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// テスト用コンストラクタ
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // 初期カテゴリデータ挿入
          await _insertDefaultCategories();
          // 初期設定データ挿入
          await _insertDefaultSettings();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // 将来のマイグレーション用
        },
      );

  /// デフォルトカテゴリを挿入
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        name: '食費',
        icon: '🍽️',
        color: const Value('#FF6B6B'),
        sortOrder: const Value(1),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '日用品',
        icon: '🧴',
        color: const Value('#4ECDC4'),
        sortOrder: const Value(2),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '交通費',
        icon: '🚃',
        color: const Value('#45B7D1'),
        sortOrder: const Value(3),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '娯楽',
        icon: '🎮',
        color: const Value('#96CEB4'),
        sortOrder: const Value(4),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '医療費',
        icon: '💊',
        color: const Value('#DDA0DD'),
        sortOrder: const Value(5),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '衣服',
        icon: '👕',
        color: const Value('#F7DC6F'),
        sortOrder: const Value(6),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '光熱費',
        icon: '💡',
        color: const Value('#F0B27A'),
        sortOrder: const Value(7),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: '通信費',
        icon: '📱',
        color: const Value('#85C1E9'),
        sortOrder: const Value(8),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'その他',
        icon: '📦',
        color: const Value('#AEB6BF'),
        sortOrder: const Value(9),
        isDefault: const Value(true),
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }

  /// デフォルト設定を挿入
  Future<void> _insertDefaultSettings() async {
    final defaultSettings = [
      AppSettingsCompanion.insert(
        key: SettingKeys.userName,
        value: Value(SettingDefaults.userName),
      ),
      AppSettingsCompanion.insert(
        key: SettingKeys.defaultBudget,
        value: Value(SettingDefaults.defaultBudget.toString()),
      ),
      AppSettingsCompanion.insert(
        key: SettingKeys.closingDay,
        value: Value(SettingDefaults.closingDay.toString()),
      ),
      AppSettingsCompanion.insert(
        key: SettingKeys.notificationBudget,
        value: Value(SettingDefaults.notificationBudget.toString()),
      ),
      AppSettingsCompanion.insert(
        key: SettingKeys.notificationWeekly,
        value: Value(SettingDefaults.notificationWeekly.toString()),
      ),
      AppSettingsCompanion.insert(
        key: SettingKeys.themeMode,
        value: Value(SettingDefaults.themeMode),
      ),
    ];

    await batch((batch) {
      batch.insertAll(appSettings, defaultSettings);
    });
  }
}

/// データベース接続を開く
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ai_kakeibo.db'));
    return NativeDatabase.createInBackground(file);
  });
}
