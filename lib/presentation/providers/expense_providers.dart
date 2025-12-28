import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';

/// 全支出リストプロバイダー
final expenseListProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);

  // 直近3ヶ月分のデータを取得
  final now = DateTime.now();
  final List<Expense> allExpenses = [];

  for (int i = 0; i < 3; i++) {
    final month = DateTime(now.year, now.month - i, 1);
    final yearMonth =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final monthlyExpenses = await repo.getMonthlyExpenses(yearMonth);

    allExpenses.addAll(monthlyExpenses.map((e) => Expense(
          id: e.expense.id,
          amount: e.expense.totalAmount,
          categoryName: e.category.name,
          description: e.expense.memo,
          store: e.expense.storeName,
          date: e.expense.date,
        )));
  }

  return allExpenses;
});

/// 支出を更新するためのNotifier
class ExpenseListNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.watch(expenseListProvider.future);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final expenseListNotifierProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<Expense>>(() {
  return ExpenseListNotifier();
});
