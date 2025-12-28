import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// 傾向分析結果
class TrendAnalysis {
  final String summary;
  final int totalAmount;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<Insight> insights;
  final Comparison? comparison;
  final String? errorMessage;

  TrendAnalysis({
    required this.summary,
    required this.totalAmount,
    required this.categoryBreakdown,
    required this.insights,
    this.comparison,
    this.errorMessage,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) {
    return TrendAnalysis(
      summary: json['summary'] as String? ?? '',
      totalAmount: json['total_amount'] as int? ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>?)
              ?.map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => Insight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparison: json['comparison'] != null
          ? Comparison.fromJson(json['comparison'] as Map<String, dynamic>)
          : null,
    );
  }

  factory TrendAnalysis.error(String message) {
    return TrendAnalysis(
      summary: '',
      totalAmount: 0,
      categoryBreakdown: [],
      insights: [],
      errorMessage: message,
    );
  }
}

/// カテゴリ別内訳
class CategoryBreakdown {
  final String category;
  final int amount;
  final double percentage;
  final double? changeFromPrevious;

  CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
    this.changeFromPrevious,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      changeFromPrevious: (json['change_from_previous'] as num?)?.toDouble(),
    );
  }
}

/// 気づきポイント
class Insight {
  final String type; // increase, decrease, stable, warning, info
  final String title;
  final String description;

  Insight({
    required this.type,
    required this.title,
    required this.description,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// 比較データ
class Comparison {
  final double? vsPreviousPeriod;
  final double? vsAverage;

  Comparison({
    this.vsPreviousPeriod,
    this.vsAverage,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      vsPreviousPeriod: (json['vs_previous_period'] as num?)?.toDouble(),
      vsAverage: (json['vs_average'] as num?)?.toDouble(),
    );
  }
}

/// 節約提案結果
class SavingTips {
  final List<SavingTip> tips;
  final int totalPotentialSaving;
  final String? errorMessage;

  SavingTips({
    required this.tips,
    required this.totalPotentialSaving,
    this.errorMessage,
  });

  factory SavingTips.fromJson(Map<String, dynamic> json) {
    return SavingTips(
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => SavingTip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPotentialSaving: json['total_potential_saving'] as int? ?? 0,
    );
  }

  factory SavingTips.error(String message) {
    return SavingTips(
      tips: [],
      totalPotentialSaving: 0,
      errorMessage: message,
    );
  }
}

/// 節約提案アイテム
class SavingTip {
  final String title;
  final String description;
  final int potentialSaving;
  final String difficulty; // easy, medium, hard
  final String category;

  SavingTip({
    required this.title,
    required this.description,
    required this.potentialSaving,
    required this.difficulty,
    required this.category,
  });

  factory SavingTip.fromJson(Map<String, dynamic> json) {
    return SavingTip(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      potentialSaving: json['potential_saving'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? 'medium',
      category: json['category'] as String? ?? '',
    );
  }
}

/// 支出データ（分析用）
class ExpenseDataForAnalysis {
  final String date;
  final String category;
  final int amount;
  final String? storeName;

  ExpenseDataForAnalysis({
    required this.date,
    required this.category,
    required this.amount,
    this.storeName,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'category': category,
        'amount': amount,
        if (storeName != null) 'store_name': storeName,
      };
}

/// AI分析サービス
class AnalysisService {
  final String _apiKey;

  AnalysisService({required String apiKey}) : _apiKey = apiKey;

  /// 傾向分析を実行
  Future<TrendAnalysis> analyzeTrend({
    required List<ExpenseDataForAnalysis> expenses,
    required int budget,
    required String periodStart,
    required String periodEnd,
    List<ExpenseDataForAnalysis>? previousPeriodExpenses,
  }) async {
    if (_apiKey.isEmpty) {
      return TrendAnalysis.error('APIキーが設定されていません');
    }

    if (expenses.isEmpty) {
      return TrendAnalysis.error('分析するデータがありません');
    }

    try {
      final expenseDataJson = jsonEncode({
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'summary': _calculateSummary(expenses),
      });

      String? previousDataJson;
      if (previousPeriodExpenses != null && previousPeriodExpenses.isNotEmpty) {
        previousDataJson = jsonEncode({
          'expenses': previousPeriodExpenses.map((e) => e.toJson()).toList(),
          'summary': _calculateSummary(previousPeriodExpenses),
        });
      }

      final userPrompt = '''
以下の支出データを分析してください。

## 分析期間
$periodStart ～ $periodEnd

## 支出データ
$expenseDataJson

## 予算情報
月間予算: ¥$budget

${previousDataJson != null ? '''
## 前期間データ（比較用）
$previousDataJson
''' : ''}
''';

      return await _callTrendApi(userPrompt);
    } catch (e) {
      return TrendAnalysis.error('分析に失敗しました: $e');
    }
  }

  /// 節約提案を取得
  Future<SavingTips> getSavingTips({
    required List<ExpenseDataForAnalysis> expenses,
    required int budget,
    required double consumptionRate,
  }) async {
    if (_apiKey.isEmpty) {
      return SavingTips.error('APIキーが設定されていません');
    }

    if (expenses.isEmpty) {
      return SavingTips.error('分析するデータがありません');
    }

    try {
      final summary = _calculateSummary(expenses);
      final topCategory = _getTopCategory(summary);
      final frequentStores = _getFrequentStores(expenses);
      final averageAmount = expenses.isEmpty
          ? 0
          : expenses.fold<int>(0, (sum, e) => sum + e.amount) ~/ expenses.length;

      final expensePatternJson = jsonEncode({
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'summary': summary,
      });

      final userPrompt = '''
以下の支出パターンに対して、実行可能な節約提案をしてください。

## 分析期間の支出
$expensePatternJson

## 頻出パターン
- 最も支出が多いカテゴリ: $topCategory
- よく利用する店舗: ${frequentStores.join(', ')}
- 平均支出単価: ¥$averageAmount

## ユーザー情報
予算: ¥$budget/月
現在の消化率: ${consumptionRate.toStringAsFixed(1)}%
''';

      return await _callSavingApi(userPrompt);
    } catch (e) {
      return SavingTips.error('提案の取得に失敗しました: $e');
    }
  }

  Map<String, int> _calculateSummary(List<ExpenseDataForAnalysis> expenses) {
    final summary = <String, int>{};
    for (final expense in expenses) {
      summary[expense.category] =
          (summary[expense.category] ?? 0) + expense.amount;
    }
    return summary;
  }

  String _getTopCategory(Map<String, int> summary) {
    if (summary.isEmpty) return 'なし';
    final sorted = summary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<String> _getFrequentStores(List<ExpenseDataForAnalysis> expenses) {
    final storeCount = <String, int>{};
    for (final expense in expenses) {
      if (expense.storeName != null && expense.storeName!.isNotEmpty) {
        storeCount[expense.storeName!] =
            (storeCount[expense.storeName!] ?? 0) + 1;
      }
    }
    if (storeCount.isEmpty) return ['記録なし'];
    final sorted = storeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  Future<TrendAnalysis> _callTrendApi(String userPrompt) async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final requestBody = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': _trendSystemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'response_format': {
        'type': 'json_object',
      },
      'max_tokens': 1500,
      'temperature': 0.5,
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseTrendResponse(responseJson);
    } else {
      return TrendAnalysis.error('APIエラー: ${response.statusCode}');
    }
  }

  Future<SavingTips> _callSavingApi(String userPrompt) async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final requestBody = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': _savingSystemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'response_format': {
        'type': 'json_object',
      },
      'max_tokens': 1000,
      'temperature': 0.7,
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseSavingResponse(responseJson);
    } else {
      return SavingTips.error('APIエラー: ${response.statusCode}');
    }
  }

  TrendAnalysis _parseTrendResponse(Map<String, dynamic> responseJson) {
    try {
      final choices = responseJson['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return TrendAnalysis.error('APIからの応答が空です');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) {
        return TrendAnalysis.error('APIからのメッセージが空です');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return TrendAnalysis.error('APIからのコンテンツが空です');
      }

      final resultJson = jsonDecode(content) as Map<String, dynamic>;
      return TrendAnalysis.fromJson(resultJson);
    } catch (e) {
      return TrendAnalysis.error('レスポンスの解析に失敗しました: $e');
    }
  }

  SavingTips _parseSavingResponse(Map<String, dynamic> responseJson) {
    try {
      final choices = responseJson['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return SavingTips.error('APIからの応答が空です');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) {
        return SavingTips.error('APIからのメッセージが空です');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return SavingTips.error('APIからのコンテンツが空です');
      }

      final resultJson = jsonDecode(content) as Map<String, dynamic>;
      return SavingTips.fromJson(resultJson);
    } catch (e) {
      return SavingTips.error('レスポンスの解析に失敗しました: $e');
    }
  }

  static const String _trendSystemPrompt = '''
あなたは家計分析の専門家です。日本の一般的な家計状況に精通しています。

## 役割
ユーザーの支出データを分析し、以下を提供してください：
1. 支出傾向のサマリー（簡潔に）
2. カテゴリ別の内訳と前期比較
3. 気づきポイント（最大5件）
4. 前期間との比較

## 分析の観点
- 支出の増減傾向
- カテゴリ別のバランス
- 異常な支出パターン
- 季節性・イベント性の考慮

## 出力ルール
1. サマリーは100文字以内で簡潔に
2. パーセンテージは小数点第1位まで
3. 金額は円単位の整数
4. 比較がない場合は change_from_previous を省略

## 気づきタイプ
- increase: 増加傾向（注意喚起）
- decrease: 減少傾向（ポジティブ）
- stable: 安定している
- warning: 警告（予算超過など）
- info: 一般情報

## 出力形式
必ず以下のJSON形式で出力してください：
{
  "summary": "分析サマリー（100文字以内）",
  "total_amount": 整数,
  "category_breakdown": [
    {"category": "カテゴリ名", "amount": 整数, "percentage": 小数, "change_from_previous": 小数（任意）}
  ],
  "insights": [
    {"type": "increase/decrease/stable/warning/info", "title": "タイトル", "description": "説明"}
  ],
  "comparison": {"vs_previous_period": 小数, "vs_average": 小数}
}
''';

  static const String _savingSystemPrompt = '''
あなたは節約アドバイザーです。実践的で具体的なアドバイスを提供します。

## 役割
ユーザーの支出パターンを分析し、実行可能な節約提案を行ってください。

## 提案の基準
1. 具体的で実行しやすい内容
2. 節約金額の根拠を明確に
3. 生活の質を大きく下げない範囲
4. 日本の生活環境に適した提案

## 難易度の定義
- easy: すぐに始められる（意識の変化のみ）
- medium: 少しの準備や習慣変更が必要
- hard: 大きな生活スタイルの変更が必要

## 節約金額の算出
- 実際の支出データに基づく
- 月間ベースで算出
- 現実的な削減率を適用（30-50%程度）

## 提案カテゴリ
支出データで多いカテゴリを優先的に提案

## 出力形式
必ず以下のJSON形式で出力してください：
{
  "tips": [
    {
      "title": "提案タイトル",
      "description": "具体的な説明",
      "potential_saving": 整数（月間節約額）,
      "difficulty": "easy/medium/hard",
      "category": "対象カテゴリ"
    }
  ],
  "total_potential_saving": 整数（月間節約可能総額）
}
''';
}

/// APIキー設定
/// 環境変数 OPENAI_API_KEY から取得、または .env ファイルで設定
const String _devApiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

/// 分析サービスプロバイダー
final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return AnalysisService(apiKey: _devApiKey);
});
