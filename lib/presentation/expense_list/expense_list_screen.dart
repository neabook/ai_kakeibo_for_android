import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/expense_repository.dart';
import '../expense_input/expense_input_screen.dart';
import 'expense_list_provider.dart';
import 'widgets/expense_list_item.dart';
import 'expense_edit_screen.dart';

/// 支出一覧画面
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYearMonth = ref.watch(expenseListYearMonthProvider);
    final expensesAsync = ref.watch(monthlyExpensesProvider);
    final total = ref.watch(expenseListTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出一覧'),
      ),
      body: Column(
        children: [
          // 月選択 & 合計
          _MonthHeader(
            selectedYearMonth: selectedYearMonth,
            total: total,
            onPrevious: () => _changeMonth(ref, -1),
            onNext: () => _changeMonth(ref, 1),
          ),

          // 支出リスト
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('エラー: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(monthlyExpensesProvider),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _EmptyState(
                    onAddPressed: () => _navigateToAddExpense(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(monthlyExpensesProvider);
                  },
                  child: _ExpenseListView(
                    expenses: expenses,
                    onTap: (expense) => _navigateToEdit(context, ref, expense),
                    onDelete: (expense) => _showDeleteDialog(context, ref, expense),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(expenseListYearMonthProvider);
    final date = DateTime.parse('$current-01');
    final newDate = DateTime(date.year, date.month + delta, 1);
    ref.read(expenseListYearMonthProvider.notifier).state =
        DateFormat('yyyy-MM').format(newDate);
  }

  Future<void> _navigateToAddExpense(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ExpenseInputScreen()),
    );

    if (result == true) {
      ref.invalidate(monthlyExpensesProvider);
    }
  }

  Future<void> _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    ExpenseWithCategory expense,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExpenseEditScreen(expenseId: expense.expense.id),
      ),
    );

    if (result == true) {
      ref.invalidate(monthlyExpensesProvider);
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ExpenseWithCategory expense,
  ) async {
    final formatter = NumberFormat('#,###');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支出を削除'),
        content: Text(
          '「${expense.expense.storeName ?? expense.category.name}」\n'
          '¥${formatter.format(expense.expense.totalAmount)}\n\n'
          'を削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.deleteExpense(expense.expense.id);
      ref.invalidate(monthlyExpensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('支出を削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// 月選択ヘッダー
class _MonthHeader extends StatelessWidget {
  final String selectedYearMonth;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.selectedYearMonth,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('$selectedYearMonth-01');
    final displayText = DateFormat('yyyy年M月').format(date);
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '合計 ¥${formatter.format(total)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// 空状態
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyState({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'この月の支出はありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('支出を追加'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 支出リストビュー
class _ExpenseListView extends StatelessWidget {
  final List<ExpenseWithCategory> expenses;
  final ValueChanged<ExpenseWithCategory> onTap;
  final ValueChanged<ExpenseWithCategory> onDelete;

  const _ExpenseListView({
    required this.expenses,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 日付でグループ化
    final Map<String, List<ExpenseWithCategory>> grouped = {};
    for (final expense in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.expense.date);
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayExpenses = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final dayTotal = dayExpenses.fold<int>(
          0,
          (sum, e) => sum + e.expense.totalAmount,
        );

        return _DaySection(
          date: date,
          dayTotal: dayTotal,
          expenses: dayExpenses,
          onTap: onTap,
          onDelete: onDelete,
        );
      },
    );
  }
}

/// 日別セクション
class _DaySection extends StatelessWidget {
  final DateTime date;
  final int dayTotal;
  final List<ExpenseWithCategory> expenses;
  final ValueChanged<ExpenseWithCategory> onTap;
  final ValueChanged<ExpenseWithCategory> onDelete;

  const _DaySection({
    required this.date,
    required this.dayTotal,
    required this.expenses,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('M/d (E)', 'ja_JP');
    final amountFormatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付ヘッダー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormatter.format(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '¥${amountFormatter.format(dayTotal)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        // 支出アイテム
        ...expenses.map((expense) => ExpenseListItem(
              expense: expense,
              onTap: () => onTap(expense),
              onDelete: () => onDelete(expense),
            )),
      ],
    );
  }
}
