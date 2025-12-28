import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/expense_repository.dart';

/// 現在選択中の年月
final selectedYearMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

/// ダッシュボードデータ
class DashboardData {
  final int monthlyBudget;
  final int monthlyTotal;
  final List<CategoryExpense> categoryExpenses;
  final List<ExpenseWithCategory> recentExpenses;

  DashboardData({
    required this.monthlyBudget,
    required this.monthlyTotal,
    required this.categoryExpenses,
    required this.recentExpenses,
  });

  /// 残り予算
  int get remainingBudget => monthlyBudget - monthlyTotal;

  /// 予算使用率（0.0-1.0、超過時は1.0以上）
  double get budgetUsageRate =>
      monthlyBudget > 0 ? monthlyTotal / monthlyBudget : 0.0;

  /// 予算超過かどうか
  bool get isOverBudget => monthlyTotal > monthlyBudget;
}

/// ダッシュボードデータプロバイダー
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final yearMonth = ref.watch(selectedYearMonthProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);

  // 並列でデータ取得
  final results = await Future.wait([
    budgetRepo.getMonthlyBudget(yearMonth),
    expenseRepo.getMonthlyTotal(yearMonth),
    expenseRepo.getMonthlyCategoryExpenses(yearMonth),
    expenseRepo.getRecentExpenses(limit: 5),
  ]);

  return DashboardData(
    monthlyBudget: results[0] as int,
    monthlyTotal: results[1] as int,
    categoryExpenses: results[2] as List<CategoryExpense>,
    recentExpenses: results[3] as List<ExpenseWithCategory>,
  );
});
