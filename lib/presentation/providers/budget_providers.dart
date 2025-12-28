import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/budget_repository.dart';
import '../../domain/entities/expense.dart';

/// 予算プロバイダー
final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, Budget?>(() => BudgetNotifier());

class BudgetNotifier extends AsyncNotifier<Budget?> {
  @override
  Future<Budget?> build() async {
    final repo = ref.watch(budgetRepositoryProvider);
    final yearMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final amount = await repo.getMonthlyBudget(yearMonth);

    return Budget(
      monthlyBudget: amount,
      yearMonth: yearMonth,
    );
  }

  Future<void> updateBudget(int amount) async {
    final repo = ref.watch(budgetRepositoryProvider);
    final yearMonth = DateFormat('yyyy-MM').format(DateTime.now());

    await repo.setBudget(yearMonth, amount);

    state = AsyncValue.data(Budget(
      monthlyBudget: amount,
      yearMonth: yearMonth,
    ));
  }
}
