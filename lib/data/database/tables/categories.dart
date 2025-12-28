import 'package:drift/drift.dart';

/// カテゴリテーブル - 支出カテゴリのマスターデータ
class Categories extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// カテゴリ名（例: 食費）
  TextColumn get name => text()();

  /// 絵文字アイコン（例: 🍽️）
  TextColumn get icon => text()();

  /// カラーコード（例: #FF6B6B）
  TextColumn get color => text().withDefault(const Constant('#6C63FF'))();

  /// 表示順序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// デフォルトカテゴリフラグ（0/1）
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// 削除フラグ（0/1）- ソフトデリート
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
