import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/services/analysis_service.dart';
import '../dashboard/dashboard_provider.dart';
import 'analysis_provider.dart';

/// AI分析画面
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // 画面表示時に自動分析
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startAnalysis() {
    final yearMonth = ref.read(analysisYearMonthProvider);
    final dashboardData = ref.read(dashboardDataProvider);

    dashboardData.whenData((data) {
      ref
          .read(analysisProvider.notifier)
          .analyze(yearMonth, data.monthlyBudget);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);
    final yearMonth = ref.watch(analysisYearMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.status == AnalysisStatus.loading
                ? null
                : () => _startAnalysis(),
          ),
        ],
      ),
      body: _buildBody(context, state, yearMonth),
    );
  }

  Widget _buildBody(
      BuildContext context, AnalysisState state, String yearMonth) {
    switch (state.status) {
      case AnalysisStatus.idle:
      case AnalysisStatus.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AIが分析中...'),
              SizedBox(height: 8),
              Text(
                '傾向分析と節約提案を作成しています',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );

      case AnalysisStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'エラーが発生しました',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _startAnalysis(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ),
          ),
        );

      case AnalysisStatus.success:
        return _buildAnalysisResult(context, state, yearMonth);
    }
  }

  Widget _buildAnalysisResult(
      BuildContext context, AnalysisState state, String yearMonth) {
    final trend = state.trendAnalysis!;
    final tips = state.savingTips;

    final date = DateTime.parse('$yearMonth-01');
    final displayMonth = DateFormat('yyyy年M月').format(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 月表示
          Center(
            child: Text(
              '$displayMonth の分析',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // サマリーカード
          _buildSummaryCard(context, trend),
          const SizedBox(height: 16),

          // 気づきポイント
          if (trend.insights.isNotEmpty) ...[
            Text(
              '気づきポイント',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...trend.insights.map((insight) => _buildInsightCard(insight)),
            const SizedBox(height: 16),
          ],

          // カテゴリ別内訳
          if (trend.categoryBreakdown.isNotEmpty) ...[
            Text(
              'カテゴリ別内訳',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCategoryBreakdown(context, trend.categoryBreakdown),
            const SizedBox(height: 16),
          ],

          // 節約提案
          if (tips != null &&
              tips.tips.isNotEmpty &&
              tips.errorMessage == null) ...[
            Row(
              children: [
                Text(
                  '節約提案',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '最大¥${NumberFormat('#,###').format(tips.totalPotentialSaving)}/月節約可能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.tips.map((tip) => _buildSavingTipCard(tip)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TrendAnalysis trend) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'AIサマリー',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              trend.summary,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '合計: ¥${NumberFormat('#,###').format(trend.totalAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            if (trend.comparison != null &&
                trend.comparison!.vsPreviousPeriod != null) ...[
              const SizedBox(height: 4),
              Text(
                '前月比: ${trend.comparison!.vsPreviousPeriod! >= 0 ? '+' : ''}${trend.comparison!.vsPreviousPeriod!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trend.comparison!.vsPreviousPeriod! >= 0
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    IconData icon;
    Color color;

    switch (insight.type) {
      case 'increase':
        icon = Icons.trending_up;
        color = Colors.red;
        break;
      case 'decrease':
        icon = Icons.trending_down;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
      case 'stable':
        icon = Icons.horizontal_rule;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          insight.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(insight.description),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, List<CategoryBreakdown> breakdown) {
    return Card(
      child: Column(
        children: breakdown.map((item) {
          return ListTile(
            title: Text(item.category),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${NumberFormat('#,###').format(item.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            subtitle: item.changeFromPrevious != null
                ? Text(
                    '前月比: ${item.changeFromPrevious! >= 0 ? '+' : ''}${item.changeFromPrevious!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.changeFromPrevious! >= 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSavingTipCard(SavingTip tip) {
    IconData difficultyIcon;
    Color difficultyColor;
    String difficultyText;

    switch (tip.difficulty) {
      case 'easy':
        difficultyIcon = Icons.sentiment_satisfied;
        difficultyColor = Colors.green;
        difficultyText = '簡単';
        break;
      case 'hard':
        difficultyIcon = Icons.sentiment_dissatisfied;
        difficultyColor = Colors.red;
        difficultyText = '難しい';
        break;
      default:
        difficultyIcon = Icons.sentiment_neutral;
        difficultyColor = Colors.orange;
        difficultyText = '普通';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tip.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '¥${NumberFormat('#,###').format(tip.potentialSaving)}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(difficultyIcon, size: 16, color: difficultyColor),
                const SizedBox(width: 4),
                Text(
                  difficultyText,
                  style: TextStyle(
                    fontSize: 12,
                    color: difficultyColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
