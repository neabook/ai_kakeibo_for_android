import 'package:drift/drift.dart';

/// 分析タイプ
enum AnalysisType {
  trend,         // 傾向分析
  savingTips,    // 節約提案
  anomaly,       // 異常検知
  monthlyReport, // 月次レポート
}

/// AI分析結果テーブル - GPT-5-miniによる分析結果をキャッシュ
class AiAnalyses extends Table {
  /// 主キー
  IntColumn get id => integer().autoIncrement()();

  /// 分析タイプ
  TextColumn get analysisType => textEnum<AnalysisType>()();

  /// 分析期間開始（YYYY-MM-DD）
  DateTimeColumn get periodStart => dateTime()();

  /// 分析期間終了（YYYY-MM-DD）
  DateTimeColumn get periodEnd => dateTime()();

  /// 分析結果JSON
  TextColumn get contentJson => text()();

  /// キャッシュ有効期限
  DateTimeColumn get expiresAt => dateTime()();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
