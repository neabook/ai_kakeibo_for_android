import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../database/database.dart';

/// 支出リポジトリプロバイダー
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider));
});

/// 支出リポジトリ
class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  /// 指定月の支出合計を取得
  Future<int> getMonthlyTotal(String yearMonth) async {
    final startDate = DateTime.parse('$yearMonth-01');
    final endDate = DateTime(startDate.year, startDate.month + 1, 0);

    final result = await (_db.select(_db.expenses)
          ..where((e) => e.date.isBetweenValues(startDate, endDate))
          ..where((e) => e.isDeleted.equals(false)))
        .get();

    return result.fold<int>(0, (sum, expense) => sum + expense.totalAmount);
  }

  /// 指定月のカテゴリ別支出を取得
  Future<List<CategoryExpense>> getMonthlyCategoryExpenses(
      String yearMonth) async {
    final startDate = DateTime.parse('$yearMonth-01');
    final endDate = DateTime(startDate.year, startDate.month + 1, 0);

    final query = _db.select(_db.expenses).join([
      innerJoin(_db.categories,
          _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.date.isBetweenValues(startDate, endDate))
      ..where(_db.expenses.isDeleted.equals(false));

    final results = await query.get();

    // カテゴリ別に集計
    final Map<int, CategoryExpense> categoryMap = {};

    for (final row in results) {
      final expense = row.readTable(_db.expenses);
      final category = row.readTable(_db.categories);

      if (categoryMap.containsKey(category.id)) {
        categoryMap[category.id] = CategoryExpense(
          categoryId: category.id,
          categoryName: category.name,
          categoryIcon: category.icon,
          categoryColor: category.color,
          totalAmount:
              categoryMap[category.id]!.totalAmount + expense.totalAmount,
          count: categoryMap[category.id]!.count + 1,
        );
      } else {
        categoryMap[category.id] = CategoryExpense(
          categoryId: category.id,
          categoryName: category.name,
          categoryIcon: category.icon,
          categoryColor: category.color,
          totalAmount: expense.totalAmount,
          count: 1,
        );
      }
    }

    // 金額の降順でソート
    final list = categoryMap.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return list;
  }

  /// 最近の支出を取得
  Future<List<ExpenseWithCategory>> getRecentExpenses({int limit = 5}) async {
    final query = _db.select(_db.expenses).join([
      innerJoin(_db.categories,
          _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(_db.expenses.date)])
      ..limit(limit);

    final results = await query.get();

    return results.map((row) {
      final expense = row.readTable(_db.expenses);
      final category = row.readTable(_db.categories);
      return ExpenseWithCategory(expense: expense, category: category);
    }).toList();
  }

  /// 指定月の支出一覧を取得（日付降順）
  Future<List<ExpenseWithCategory>> getMonthlyExpenses(String yearMonth) async {
    final startDate = DateTime.parse('$yearMonth-01');
    final endDate = DateTime(startDate.year, startDate.month + 1, 0);

    final query = _db.select(_db.expenses).join([
      innerJoin(_db.categories,
          _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.date.isBetweenValues(startDate, endDate))
      ..where(_db.expenses.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(_db.expenses.date)]);

    final results = await query.get();

    return results.map((row) {
      final expense = row.readTable(_db.expenses);
      final category = row.readTable(_db.categories);
      return ExpenseWithCategory(expense: expense, category: category);
    }).toList();
  }

  /// IDで支出を取得
  Future<ExpenseWithCategory?> getExpenseById(int id) async {
    final query = _db.select(_db.expenses).join([
      innerJoin(_db.categories,
          _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.id.equals(id))
      ..where(_db.expenses.isDeleted.equals(false));

    final result = await query.getSingleOrNull();

    if (result == null) return null;

    return ExpenseWithCategory(
      expense: result.readTable(_db.expenses),
      category: result.readTable(_db.categories),
    );
  }

  /// 支出を追加
  Future<int> addExpense(ExpensesCompanion expense) async {
    return await _db.into(_db.expenses).insert(expense);
  }

  /// 支出を更新
  Future<bool> updateExpense(Expense expense) async {
    return await _db.update(_db.expenses).replace(expense);
  }

  /// 支出を削除（ソフトデリート）
  Future<int> deleteExpense(int id) async {
    return await (_db.update(_db.expenses)..where((e) => e.id.equals(id)))
        .write(const ExpensesCompanion(isDeleted: Value(true)));
  }
}

/// カテゴリ別支出
class CategoryExpense {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final int totalAmount;
  final int count;

  CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.totalAmount,
    required this.count,
  });
}

/// カテゴリ付き支出
class ExpenseWithCategory {
  final Expense expense;
  final Category category;

  ExpenseWithCategory({required this.expense, required this.category});
}
