import 'package:drift/drift.dart';

/// 予算テーブル - 月間予算を管理
class Budgets extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// 対象年月（YYYY-MM）- ユニーク
  TextColumn get yearMonth => text().unique()();

  /// 予算額（円）
  IntColumn get amount => integer()();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
