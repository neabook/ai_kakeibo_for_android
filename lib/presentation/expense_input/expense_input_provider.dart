import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/database/tables/expenses.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/expense_repository.dart';

/// カテゴリ一覧プロバイダー
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getActiveCategories();
});

/// 支出入力フォーム状態
class ExpenseInputState {
  final int? categoryId;
  final DateTime date;
  final String? storeName;
  final int? amount;
  final PaymentMethod paymentMethod;
  final String? memo;
  final bool isSubmitting;
  final String? errorMessage;

  ExpenseInputState({
    this.categoryId,
    DateTime? date,
    this.storeName,
    this.amount,
    this.paymentMethod = PaymentMethod.cash,
    this.memo,
    this.isSubmitting = false,
    this.errorMessage,
  }) : date = date ?? DateTime.now();

  ExpenseInputState copyWith({
    int? categoryId,
    DateTime? date,
    String? storeName,
    int? amount,
    PaymentMethod? paymentMethod,
    String? memo,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ExpenseInputState(
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      storeName: storeName ?? this.storeName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      memo: memo ?? this.memo,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  /// バリデーション
  bool get isValid => categoryId != null && amount != null && amount! > 0;
}

/// 支出入力Notifier
class ExpenseInputNotifier extends StateNotifier<ExpenseInputState> {
  final ExpenseRepository _expenseRepo;

  ExpenseInputNotifier(this._expenseRepo) : super(ExpenseInputState());

  void setCategory(int? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setStoreName(String? storeName) {
    state = state.copyWith(storeName: storeName);
  }

  void setAmount(int? amount) {
    state = state.copyWith(amount: amount);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setMemo(String? memo) {
    state = state.copyWith(memo: memo);
  }

  /// 支出を保存
  Future<bool> saveExpense() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: '必須項目を入力してください');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _expenseRepo.addExpense(
        ExpensesCompanion.insert(
          categoryId: state.categoryId!,
          date: state.date,
          storeName: Value(state.storeName),
          totalAmount: state.amount!,
          paymentMethod: Value(state.paymentMethod),
          memo: Value(state.memo),
          inputMethod: const Value(InputMethod.manual),
        ),
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '保存に失敗しました: $e',
      );
      return false;
    }
  }

  /// フォームをリセット
  void reset() {
    state = ExpenseInputState();
  }
}

/// 支出入力プロバイダー
final expenseInputProvider =
    StateNotifierProvider.autoDispose<ExpenseInputNotifier, ExpenseInputState>(
        (ref) {
  return ExpenseInputNotifier(ref.watch(expenseRepositoryProvider));
});
