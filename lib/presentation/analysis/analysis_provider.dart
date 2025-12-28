import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/expense_repository.dart';
import '../../data/services/analysis_service.dart';
import '../dashboard/dashboard_provider.dart';

/// 分析状態
enum AnalysisStatus {
  idle,
  loading,
  success,
  error,
}

/// 分析画面状態
class AnalysisState {
  final AnalysisStatus status;
  final TrendAnalysis? trendAnalysis;
  final SavingTips? savingTips;
  final String? errorMessage;

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.trendAnalysis,
    this.savingTips,
    this.errorMessage,
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    TrendAnalysis? trendAnalysis,
    SavingTips? savingTips,
    String? errorMessage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      trendAnalysis: trendAnalysis ?? this.trendAnalysis,
      savingTips: savingTips ?? this.savingTips,
      errorMessage: errorMessage,
    );
  }
}

/// 分析Notifier
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final AnalysisService _analysisService;
  final ExpenseRepository _expenseRepo;

  AnalysisNotifier({
    required AnalysisService analysisService,
    required ExpenseRepository expenseRepo,
  })  : _analysisService = analysisService,
        _expenseRepo = expenseRepo,
        super(const AnalysisState());

  /// 分析を実行
  Future<void> analyze(String yearMonth, int budget) async {
    state = state.copyWith(status: AnalysisStatus.loading, errorMessage: null);

    try {
      // 当月の支出データを取得
      final expenses = await _expenseRepo.getMonthlyExpenses(yearMonth);

      if (expenses.isEmpty) {
        state = state.copyWith(
          status: AnalysisStatus.error,
          errorMessage: 'この月の支出データがありません',
        );
        return;
      }

      // 分析用データに変換
      final expenseData = expenses.map((e) {
        return ExpenseDataForAnalysis(
          date: DateFormat('yyyy-MM-dd').format(e.expense.date),
          category: e.category.name,
          amount: e.expense.totalAmount,
          storeName: e.expense.storeName,
        );
      }).toList();

      // 期間を計算
      final startDate = DateTime.parse('$yearMonth-01');
      final endDate = DateTime(startDate.year, startDate.month + 1, 0);
      final periodStart = DateFormat('yyyy-MM-dd').format(startDate);
      final periodEnd = DateFormat('yyyy-MM-dd').format(endDate);

      // 前月データを取得
      final prevMonth = DateTime(startDate.year, startDate.month - 1, 1);
      final prevYearMonth = DateFormat('yyyy-MM').format(prevMonth);
      final prevExpenses = await _expenseRepo.getMonthlyExpenses(prevYearMonth);

      List<ExpenseDataForAnalysis>? prevExpenseData;
      if (prevExpenses.isNotEmpty) {
        prevExpenseData = prevExpenses.map((e) {
          return ExpenseDataForAnalysis(
            date: DateFormat('yyyy-MM-dd').format(e.expense.date),
            category: e.category.name,
            amount: e.expense.totalAmount,
            storeName: e.expense.storeName,
          );
        }).toList();
      }

      // 消費率を計算
      final totalAmount =
          expenses.fold<int>(0, (sum, e) => sum + e.expense.totalAmount);
      final consumptionRate = budget > 0 ? (totalAmount / budget) * 100 : 0.0;

      // 傾向分析と節約提案を並列実行
      final results = await Future.wait([
        _analysisService.analyzeTrend(
          expenses: expenseData,
          budget: budget,
          periodStart: periodStart,
          periodEnd: periodEnd,
          previousPeriodExpenses: prevExpenseData,
        ),
        _analysisService.getSavingTips(
          expenses: expenseData,
          budget: budget,
          consumptionRate: consumptionRate,
        ),
      ]);

      final trendAnalysis = results[0] as TrendAnalysis;
      final savingTips = results[1] as SavingTips;

      // エラーチェック
      if (trendAnalysis.errorMessage != null) {
        state = state.copyWith(
          status: AnalysisStatus.error,
          errorMessage: trendAnalysis.errorMessage,
        );
        return;
      }

      state = state.copyWith(
        status: AnalysisStatus.success,
        trendAnalysis: trendAnalysis,
        savingTips: savingTips,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.error,
        errorMessage: '分析に失敗しました: $e',
      );
    }
  }

  /// 状態をリセット
  void reset() {
    state = const AnalysisState();
  }
}

/// 分析プロバイダー
final analysisProvider =
    StateNotifierProvider.autoDispose<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(
    analysisService: ref.watch(analysisServiceProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
  );
});

/// 選択中の分析月プロバイダー（ダッシュボードと連動）
final analysisYearMonthProvider = Provider<String>((ref) {
  return ref.watch(selectedYearMonthProvider);
});
