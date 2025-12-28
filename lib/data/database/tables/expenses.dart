import 'package:drift/drift.dart';
import 'categories.dart';

/// 支払方法
enum PaymentMethod {
  cash,    // 現金
  credit,  // クレジットカード
  debit,   // デビットカード
  emoney,  // 電子マネー
  qr,      // QRコード決済
  other,   // その他
}

/// 入力方法
enum InputMethod {
  manual, // 手入力
  ocr,    // AI OCR解析
  api,    // API連携（Phase 2）
}

/// 支出テーブル - 支出データのメインテーブル
class Expenses extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// カテゴリID（外部キー）
  IntColumn get categoryId => integer().references(Categories, #id)();

  /// 支出日（YYYY-MM-DD）
  DateTimeColumn get date => dateTime()();

  /// 支出時刻（HH:MM）- null許容
  TextColumn get time => text().nullable()();

  /// 店舗名
  TextColumn get storeName => text().nullable()();

  /// 合計金額（円）
  IntColumn get totalAmount => integer()();

  /// 支払方法
  TextColumn get paymentMethod =>
      textEnum<PaymentMethod>().withDefault(Constant(PaymentMethod.cash.name))();

  /// メモ
  TextColumn get memo => text().nullable()();

  /// レシート画像パス
  TextColumn get imagePath => text().nullable()();

  /// OCR生テキスト
  TextColumn get ocrRawText => text().nullable()();

  /// OCR信頼度（0.0-1.0）
  RealColumn get ocrConfidence => real().nullable()();

  /// 入力方法
  TextColumn get inputMethod =>
      textEnum<InputMethod>().withDefault(Constant(InputMethod.manual.name))();

  /// 削除フラグ（ソフトデリート）
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
