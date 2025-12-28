import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../providers/budget_providers.dart';

/// 分析画面 V2（POCデザイン準拠）
class AnalysisScreenV2 extends ConsumerWidget {
  const AnalysisScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー
              _Header(),
              // AIインサイト
              _AIInsightsSection(),
              // 月別比較
              _MonthlyComparisonSection(),
              // カテゴリ分析
              _CategoryAnalysisSection(),
              // 節約ヒント
              _SavingTipsSection(),
              const SizedBox(height: 100), // ボトムナビ用スペース
            ],
          ),
        ),
      ),
    );
  }
}

/// ヘッダー
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '分析',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.premiumGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppTheme.white),
                SizedBox(width: 4),
                Text(
                  'AI分析',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AIインサイトセクション
class _AIInsightsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AIからの提案',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            expenses.when(
              data: (list) => _buildInsight(list),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.white),
              ),
              error: (_, __) => const Text(
                'データを取得できませんでした',
                style: TextStyle(color: AppTheme.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Text(
        '支出データがまだありません。\n記録を始めると、AIが支出パターンを分析して最適なアドバイスを提供します。',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.white.withValues(alpha: 0.9),
          height: 1.5,
        ),
      );
    }

    // カテゴリ別集計
    final Map<String, int> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals[expense.categoryName] =
          (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
    }

    final topCategory = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final formatter = NumberFormat('#,###');
    final topCategoryName = topCategory.isNotEmpty ? topCategory.first.key : '食費';
    final topCategoryAmount = topCategory.isNotEmpty ? topCategory.first.value : 0;

    return Text(
      '今月は「$topCategoryName」への支出が最も多く、¥${formatter.format(topCategoryAmount)}です。\n前月比で見ると、この傾向が続いています。週末の外食を控えることで月¥5,000程度の節約が見込めます。',
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.white.withValues(alpha: 0.9),
        height: 1.5,
      ),
    );
  }
}

/// 月別比較セクション
class _MonthlyComparisonSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '月別推移',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: expenses.when(
                data: (list) => _buildMonthlyChart(list),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('データ取得エラー')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<Expense> expenses) {
    final monthlyData = _getMonthlyData(expenses);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyData.isEmpty
            ? 100000
            : monthlyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '¥${NumberFormat('#,###').format(rod.toY.toInt())}',
                const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    monthlyData[value.toInt()].label,
                    style: const TextStyle(fontSize: 11, color: AppTheme.gray),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: monthlyData.asMap().entries.map((entry) {
          final isCurrentMonth = entry.key == monthlyData.length - 1;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                gradient: isCurrentMonth
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.gray.withValues(alpha: 0.5),
                          AppTheme.gray.withValues(alpha: 0.3),
                        ],
                      ),
                width: 24,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<_ChartData> _getMonthlyData(List<Expense> expenses) {
    final now = DateTime.now();
    final List<_ChartData> data = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final monthExpenses = expenses.where((e) =>
          e.date.isAfter(month.subtract(const Duration(days: 1))) &&
          e.date.isBefore(nextMonth));

      final total = monthExpenses.fold(0, (sum, e) => sum + e.amount);
      data.add(_ChartData('${month.month}月', total.toDouble()));
    }

    return data;
  }
}

class _ChartData {
  final String label;
  final double value;

  _ChartData(this.label, this.value);
}

/// カテゴリ分析セクション
class _CategoryAnalysisSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final budget = ref.watch(budgetProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ別分析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 20),
            expenses.when(
              data: (list) => _buildCategoryAnalysis(list, budget.value),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('データ取得エラー')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis(List<Expense> list, dynamic budget) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final monthExpenses = list.where(
        (e) => e.date.isAfter(monthStart.subtract(const Duration(days: 1))));

    final Map<String, int> categoryTotals = {};
    for (final expense in monthExpenses) {
      categoryTotals[expense.categoryName] =
          (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
    }

    final total = categoryTotals.values.fold(0, (sum, e) => sum + e);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final formatter = NumberFormat('#,###');

    return Column(
      children: sortedCategories.take(5).map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CategoryStyle.getBackgroundColor(entry.key),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    CategoryStyle.getEmoji(entry.key),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dark,
                          ),
                        ),
                        Text(
                          '¥${formatter.format(entry.value)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (percentage / 100).clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.chartColors[
                                  sortedCategories.indexOf(entry) %
                                      AppTheme.chartColors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 節約ヒントセクション
class _SavingTipsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      _SavingTip(
        icon: Icons.restaurant,
        title: '外食を減らす',
        description: '週末の外食を1回減らすと月¥5,000節約',
        color: AppTheme.secondary,
      ),
      _SavingTip(
        icon: Icons.shopping_bag,
        title: 'まとめ買い',
        description: '日用品はまとめ買いで月¥2,000節約',
        color: AppTheme.accent,
      ),
      _SavingTip(
        icon: Icons.local_offer,
        title: 'クーポン活用',
        description: 'アプリクーポンで月¥1,500節約可能',
        color: AppTheme.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '節約のヒント',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    boxShadow: AppTheme.shadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tip.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tip.icon,
                          color: tip.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tip.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.gray.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SavingTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _SavingTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
