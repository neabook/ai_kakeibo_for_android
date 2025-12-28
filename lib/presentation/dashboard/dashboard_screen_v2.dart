import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../providers/budget_providers.dart';

/// 期間選択プロバイダー
final periodProvider = StateProvider<String>((ref) => '月');

/// チャートタイプ選択プロバイダー
final chartTypeProvider = StateProvider<String>((ref) => 'bar');

/// ダッシュボード画面 V2（POCデザイン準拠）
class DashboardScreenV2 extends ConsumerWidget {
  const DashboardScreenV2({super.key});

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
              // サマリーカード
              _SummaryCard(),
              // クイックアクション
              _QuickActions(),
              // 期間タブ
              _PeriodTabs(),
              // チャートセクション
              _ChartSection(),
              // カテゴリ内訳
              _CategoryBreakdown(),
              // 最近の支出
              _RecentExpenses(),
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
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(now),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'こんにちは！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dark,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadow,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.dark,
            ),
          ),
        ],
      ),
    );
  }
}

/// サマリーカード
class _SummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final budget = ref.watch(budgetProvider);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final monthlyTotal = expenses.when(
      data: (list) => list
          .where((e) => e.date.isAfter(monthStart.subtract(const Duration(days: 1))))
          .fold(0, (sum, e) => sum + e.amount),
      loading: () => 0,
      error: (_, __) => 0,
    );

    final budgetAmount = budget.when(
      data: (b) => b?.monthlyBudget ?? 100000,
      loading: () => 100000,
      error: (_, __) => 100000,
    );

    final remaining = budgetAmount - monthlyTotal;
    final progress = (monthlyTotal / budgetAmount).clamp(0.0, 1.0);
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${now.month}月の支出',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.white.withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    remaining >= 0 ? '順調' : '超過',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${formatter.format(monthlyTotal)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 16),
            // 進捗バー
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '予算: ¥${formatter.format(budgetAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '残り: ¥${formatter.format(remaining.abs())}${remaining < 0 ? ' 超過' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
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

/// クイックアクション
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.camera_alt,
              label: 'カメラ入力',
              color: AppTheme.primary,
              onTap: () => Navigator.pushNamed(context, '/receipt-scan', arguments: {'source': 'camera'}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.edit,
              label: '手入力',
              color: AppTheme.accent,
              onTap: () => Navigator.pushNamed(context, '/expense-input'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.shadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 期間タブ
class _PeriodTabs extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(periodProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ['日', '週', '月'].map((period) {
            final isSelected = selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(periodProvider.notifier).state = period,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected ? AppTheme.shadow : null,
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.gray,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// チャートセクション
class _ChartSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartType = ref.watch(chartTypeProvider);
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
          children: [
            // チャートタイプ切り替え
            Row(
              children: [
                const Text(
                  '支出推移',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
                const Spacer(),
                _ChartTypeToggle(
                  icon: Icons.bar_chart,
                  isSelected: chartType == 'bar',
                  onTap: () => ref.read(chartTypeProvider.notifier).state = 'bar',
                ),
                const SizedBox(width: 8),
                _ChartTypeToggle(
                  icon: Icons.show_chart,
                  isSelected: chartType == 'line',
                  onTap: () => ref.read(chartTypeProvider.notifier).state = 'line',
                ),
                const SizedBox(width: 8),
                _ChartTypeToggle(
                  icon: Icons.pie_chart,
                  isSelected: chartType == 'pie',
                  onTap: () => ref.read(chartTypeProvider.notifier).state = 'pie',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // チャート表示
            SizedBox(
              height: 200,
              child: expenses.when(
                data: (list) => _buildChart(chartType, list),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('データ取得エラー')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String type, List<Expense> expenses) {
    switch (type) {
      case 'bar':
        return _buildBarChart(expenses);
      case 'line':
        return _buildLineChart(expenses);
      case 'pie':
        return _buildPieChart(expenses);
      default:
        return _buildBarChart(expenses);
    }
  }

  Widget _buildBarChart(List<Expense> expenses) {
    final dailyData = _getDailyData(expenses);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dailyData.isEmpty ? 10000 : dailyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dailyData.length) return const SizedBox();
                return Text(
                  dailyData[value.toInt()].label,
                  style: const TextStyle(fontSize: 10, color: AppTheme.gray),
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
        barGroups: dailyData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                gradient: AppTheme.primaryGradient,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<Expense> expenses) {
    final dailyData = _getDailyData(expenses);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.lightGray,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dailyData.length) return const SizedBox();
                return Text(
                  dailyData[value.toInt()].label,
                  style: const TextStyle(fontSize: 10, color: AppTheme.gray),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dailyData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            gradient: AppTheme.primaryGradient,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.3),
                  AppTheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Expense> expenses) {
    final categoryData = _getCategoryData(expenses);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: categoryData.asMap().entries.map((entry) {
          return PieChartSectionData(
            color: AppTheme.chartColors[entry.key % AppTheme.chartColors.length],
            value: entry.value.value,
            title: entry.value.label,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_ChartData> _getDailyData(List<Expense> expenses) {
    final now = DateTime.now();
    final List<_ChartData> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
      final total = dayExpenses.fold(0, (sum, e) => sum + e.amount);
      data.add(_ChartData('${date.day}日', total.toDouble()));
    }

    return data;
  }

  List<_ChartData> _getCategoryData(List<Expense> expenses) {
    final Map<String, int> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.categoryName] =
          (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
    }

    return categoryTotals.entries
        .map((e) => _ChartData(e.key, e.value.toDouble()))
        .toList();
  }
}

class _ChartData {
  final String label;
  final double value;

  _ChartData(this.label, this.value);
}

class _ChartTypeToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChartTypeToggle({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppTheme.white : AppTheme.gray,
        ),
      ),
    );
  }
}

/// カテゴリ内訳
class _CategoryBreakdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'カテゴリ別',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 16),
          expenses.when(
            data: (list) => _buildCategoryGrid(list),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('データ取得エラー')),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Expense> expenses) {
    final Map<String, int> categoryTotals = {};
    final formatter = NumberFormat('#,###');

    for (final expense in expenses) {
      categoryTotals[expense.categoryName] =
          (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
    }

    final categories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length > 8 ? 8 : categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryItem(
          name: category.key,
          amount: formatter.format(category.value),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final String amount;

  const _CategoryItem({
    required this.name,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CategoryStyle.getBackgroundColor(name),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            CategoryStyle.getEmoji(name),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.dark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '¥$amount',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.gray,
            ),
          ),
        ],
      ),
    );
  }
}

/// 最近の支出
class _RecentExpenses extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最近の支出',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // 一覧画面へ遷移
                },
                child: const Text(
                  'すべて見る',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          expenses.when(
            data: (list) => _buildExpenseList(list),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('データ取得エラー')),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    final sortedExpenses = expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentExpenses = sortedExpenses.take(5).toList();
    final formatter = NumberFormat('#,###');
    final dateFormat = DateFormat('M/d');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.shadow,
      ),
      child: Column(
        children: recentExpenses.asMap().entries.map((entry) {
          final expense = entry.value;
          final isLast = entry.key == recentExpenses.length - 1;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppTheme.lightGray, width: 1),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CategoryStyle.getBackgroundColor(expense.categoryName),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      CategoryStyle.getEmoji(expense.categoryName),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description ?? expense.categoryName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${expense.categoryName} • ${dateFormat.format(expense.date)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-¥${formatter.format(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
