import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/expense_repository.dart';

/// 最近の支出カード
class RecentExpensesCard extends StatelessWidget {
  final List<ExpenseWithCategory> expenses;
  final VoidCallback? onShowAllPressed;
  final ValueChanged<ExpenseWithCategory>? onExpenseTap;

  const RecentExpensesCard({
    super.key,
    required this.expenses,
    this.onShowAllPressed,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...expenses.map((item) => _ExpenseListItem(
                expenseWithCategory: item,
                onTap: onExpenseTap != null ? () => onExpenseTap!(item) : null,
              )),
          // もっと見るボタン
          InkWell(
            onTap: onShowAllPressed,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'すべて表示',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 支出リストアイテム
class _ExpenseListItem extends StatelessWidget {
  final ExpenseWithCategory expenseWithCategory;
  final VoidCallback? onTap;

  const _ExpenseListItem({
    required this.expenseWithCategory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expense = expenseWithCategory.expense;
    final category = expenseWithCategory.category;
    final formatter = NumberFormat('#,###');
    final dateFormatter = DateFormat('M/d');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // カテゴリアイコン
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _parseColor(category.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 支出情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.storeName ?? category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFormatter.format(expense.date)} · ${category.name}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 金額
            Text(
              '¥${formatter.format(expense.totalAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
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
