/// 支出エンティティ（画面表示用）
class Expense {
  final int id;
  final int amount;
  final String categoryName;
  final String? description;
  final String? store;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryName,
    this.description,
    this.store,
    required this.date,
  });
}

/// 予算エンティティ
class Budget {
  final int monthlyBudget;
  final String yearMonth;

  Budget({
    required this.monthlyBudget,
    required this.yearMonth,
  });
}
