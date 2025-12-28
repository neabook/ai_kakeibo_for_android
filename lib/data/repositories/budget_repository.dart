import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../database/database.dart';
import '../database/tables/app_settings.dart';

/// 予算リポジトリプロバイダー
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

/// 予算リポジトリ
class BudgetRepository {
  final AppDatabase _db;

  BudgetRepository(this._db);

  /// 指定月の予算を取得（なければデフォルト予算を返す）
  Future<int> getMonthlyBudget(String yearMonth) async {
    final budget = await (_db.select(_db.budgets)
          ..where((b) => b.yearMonth.equals(yearMonth)))
        .getSingleOrNull();

    if (budget != null) {
      return budget.amount;
    }

    // デフォルト予算を取得
    final defaultBudgetSetting = await (_db.select(_db.appSettings)
          ..where((s) => s.key.equals(SettingKeys.defaultBudget)))
        .getSingleOrNull();

    if (defaultBudgetSetting?.value != null) {
      return int.tryParse(defaultBudgetSetting!.value!) ??
          SettingDefaults.defaultBudget;
    }

    return SettingDefaults.defaultBudget;
  }

  /// 予算を設定
  Future<void> setBudget(String yearMonth, int amount) async {
    await _db.into(_db.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(
            yearMonth: yearMonth,
            amount: amount,
          ),
        );
  }
}
