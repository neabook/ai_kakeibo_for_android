import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/expense_repository.dart';

/// カテゴリ別円グラフ
class CategoryChart extends StatelessWidget {
  final List<CategoryExpense> categoryExpenses;
  final int totalAmount;

  const CategoryChart({
    super.key,
    required this.categoryExpenses,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 円グラフ
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 凡例
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categoryExpenses.take(6).map((category) {
                return _LegendItem(
                  color: _parseColor(category.categoryColor),
                  icon: category.categoryIcon,
                  name: category.categoryName,
                  amount: category.totalAmount,
                  percentage: totalAmount > 0
                      ? (category.totalAmount / totalAmount * 100)
                      : 0,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    return categoryExpenses.map((category) {
      final percentage =
          totalAmount > 0 ? category.totalAmount / totalAmount * 100 : 0.0;

      return PieChartSectionData(
        value: category.totalAmount.toDouble(),
        color: _parseColor(category.categoryColor),
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// 凡例アイテム
class _LegendItem extends StatelessWidget {
  final Color color;
  final String icon;
  final String name;
  final int amount;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.name,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            '¥${formatter.format(amount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
