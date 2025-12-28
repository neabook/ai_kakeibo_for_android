import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 予算カード
class BudgetCard extends StatelessWidget {
  final int monthlyBudget;
  final int monthlyTotal;
  final int remainingBudget;
  final double usageRate;
  final bool isOverBudget;

  const BudgetCard({
    super.key,
    required this.monthlyBudget,
    required this.monthlyTotal,
    required this.remainingBudget,
    required this.usageRate,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final progressColor = _getProgressColor();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今月の予算',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '¥${formatter.format(monthlyBudget)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 支出額
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${formatter.format(monthlyTotal)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : null,
                      ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '使用済み',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usageRate.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),

            // 残り予算
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget ? '予算超過' : '残り',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.grey[600],
                    fontWeight:
                        isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  isOverBudget
                      ? '-¥${formatter.format(remainingBudget.abs())}'
                      : '¥${formatter.format(remainingBudget)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : Colors.green[700],
                  ),
                ),
              ],
            ),

            // 使用率表示
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${(usageRate * 100).toStringAsFixed(1)}% 使用',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (usageRate >= 1.0) return Colors.red;
    if (usageRate >= 0.8) return Colors.orange;
    if (usageRate >= 0.5) return Colors.amber;
    return Colors.green;
  }
}
