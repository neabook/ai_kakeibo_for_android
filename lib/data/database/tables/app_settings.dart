import 'package:drift/drift.dart';

/// アプリ設定テーブル - キーバリュー形式の設定保存
@DataClassName('AppSetting')
class AppSettings extends Table {
  /// 設定キー（主キー）
  TextColumn get key => text()();

  /// 設定値
  TextColumn get value => text().nullable()();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

/// 設定キー定数
class SettingKeys {
  static const String userName = 'user_name';
  static const String defaultBudget = 'default_budget';
  static const String closingDay = 'closing_day';
  static const String notificationBudget = 'notification_budget';
  static const String notificationWeekly = 'notification_weekly';
  static const String themeMode = 'theme_mode';
  static const String openaiApiKey = 'openai_api_key';
  static const String lastSyncAt = 'last_sync_at';
}

/// デフォルト設定値
class SettingDefaults {
  static const String userName = 'ユーザー';
  static const int defaultBudget = 120000;
  static const int closingDay = 0; // 0=月末
  static const bool notificationBudget = true;
  static const bool notificationWeekly = false;
  static const String themeMode = 'system';
}
