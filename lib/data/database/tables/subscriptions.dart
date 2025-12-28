import 'package:drift/drift.dart';

/// プランタイプ
enum PlanType {
  free,    // 無料プラン
  monthly, // 月額プラン（500円）
  yearly,  // 年額プラン（4,800円）
}

/// サブスクリプションステータス
enum SubscriptionStatus {
  active,    // 有効
  expired,   // 期限切れ
  cancelled, // キャンセル
  pending,   // 処理中
}

/// プラットフォーム
enum Platform {
  android,
  ios,
}

/// サブスクリプションテーブル - プレミアムプラン管理
class Subscriptions extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// プランタイプ
  TextColumn get planType => textEnum<PlanType>()();

  /// ステータス
  TextColumn get status =>
      textEnum<SubscriptionStatus>().withDefault(Constant(SubscriptionStatus.active.name))();

  /// 開始日時
  DateTimeColumn get startedAt => dateTime()();

  /// 有効期限
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// 購入トークン
  TextColumn get purchaseToken => text().nullable()();

  /// プラットフォーム
  TextColumn get platform =>
      textEnum<Platform>().withDefault(Constant(Platform.android.name))();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
