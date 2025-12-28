import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/expense_repository.dart';

/// 支出一覧の選択月（ダッシュボードと独立）
final expenseListYearMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

/// 月別支出一覧プロバイダー
final monthlyExpensesProvider =
    FutureProvider.autoDispose<List<ExpenseWithCategory>>((ref) async {
  final yearMonth = ref.watch(expenseListYearMonthProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getMonthlyExpenses(yearMonth);
});

/// 支出一覧の合計金額プロバイダー
final expenseListTotalProvider = Provider.autoDispose<int>((ref) {
  final expensesAsync = ref.watch(monthlyExpensesProvider);
  return expensesAsync.when(
    data: (expenses) =>
        expenses.fold<int>(0, (sum, e) => sum + e.expense.totalAmount),
    loading: () => 0,
    error: (e, s) => 0,
  );
});
