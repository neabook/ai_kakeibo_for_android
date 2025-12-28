import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/expense_repository.dart';

/// 支出リストアイテム
class ExpenseListItem extends StatelessWidget {
  final ExpenseWithCategory expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final category = expense.category;
    final expenseData = expense.expense;

    return Dismissible(
      key: Key('expense_${expenseData.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // 削除確認ダイアログで処理するためfalse
      },
      child: ListTile(
        onTap: onTap,
        leading: Container(
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
        title: Text(
          expenseData.storeName?.isNotEmpty == true
              ? expenseData.storeName!
              : category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(category.name),
            if (expenseData.memo?.isNotEmpty == true) ...[
              const Text(' · '),
              Expanded(
                child: Text(
                  expenseData.memo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '¥${formatter.format(expenseData.totalAmount)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
