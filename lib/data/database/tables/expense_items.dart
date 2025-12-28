import 'package:drift/drift.dart';
import 'expenses.dart';

/// 支出明細テーブル - レシートの各行を管理
class ExpenseItems extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// 支出ID（外部キー）- CASCADE DELETE
  IntColumn get expenseId => integer().references(Expenses, #id)();

  /// 商品名
  TextColumn get name => text()();

  /// 単価（円）
  IntColumn get price => integer()();

  /// 数量
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// 小計（円）- price * quantity
  IntColumn get subtotal => integer()();

  /// 表示順序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
