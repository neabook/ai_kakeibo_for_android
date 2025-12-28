import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/expense_repository.dart';
import '../expense_input/expense_input_screen.dart';
import '../expense_list/expense_list_screen.dart';
import '../expense_list/expense_edit_screen.dart';
import '../analysis/analysis_screen.dart';
import '../premium/premium_screen.dart';
import '../receipt_scan/receipt_scan_screen.dart';
import 'dashboard_provider.dart';
import 'widgets/budget_card.dart';
import 'widgets/category_chart.dart';
import 'widgets/recent_expenses_card.dart';

/// ダッシュボード画面
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYearMonth = ref.watch(selectedYearMonthProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI家計簿'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI分析',
            onPressed: () => _navigateToAnalysis(context),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: 'プレミアム',
            onPressed: () => _navigateToPremium(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 月選択
              _MonthSelector(
                selectedYearMonth: selectedYearMonth,
                onPrevious: () => _changeMonth(ref, -1),
                onNext: () => _changeMonth(ref, 1),
              ),
              const SizedBox(height: 16),

              // ダッシュボードコンテンツ
              dashboardAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('エラーが発生しました\n$error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(dashboardDataProvider),
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) => _DashboardContent(data: data),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseOptions(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('支出を追加'),
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(selectedYearMonthProvider);
    final date = DateTime.parse('$current-01');
    final newDate = DateTime(date.year, date.month + delta, 1);
    ref.read(selectedYearMonthProvider.notifier).state =
        DateFormat('yyyy-MM').format(newDate);
  }

  /// 支出追加オプションを表示
  void _showAddExpenseOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドル
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '支出を追加',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // レシート撮影
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('レシートを撮影'),
                subtitle: const Text('AIが自動で読み取り'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToReceiptScan(context, ref);
                },
              ),
              const Divider(),
              // 手入力
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit, color: Colors.grey),
                ),
                title: const Text('手動で入力'),
                subtitle: const Text('自分で金額を入力'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToAddExpense(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToReceiptScan(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ReceiptScanScreen(),
      ),
    );

    // 保存成功時はダッシュボードを更新
    if (result == true) {
      ref.invalidate(dashboardDataProvider);
    }
  }

  Future<void> _navigateToAddExpense(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ExpenseInputScreen(),
      ),
    );

    // 保存成功時はダッシュボードを更新
    if (result == true) {
      ref.invalidate(dashboardDataProvider);
    }
  }

  void _navigateToAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalysisScreen(),
      ),
    );
  }

  void _navigateToPremium(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }
}

/// 月選択ウィジェット
class _MonthSelector extends StatelessWidget {
  final String selectedYearMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.selectedYearMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('$selectedYearMonth-01');
    final displayText = DateFormat('yyyy年M月').format(date);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Text(
          displayText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// ダッシュボードコンテンツ
class _DashboardContent extends ConsumerWidget {
  final DashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 予算カード
        BudgetCard(
          monthlyBudget: data.monthlyBudget,
          monthlyTotal: data.monthlyTotal,
          remainingBudget: data.remainingBudget,
          usageRate: data.budgetUsageRate,
          isOverBudget: data.isOverBudget,
        ),
        const SizedBox(height: 24),

        // カテゴリ別グラフ
        if (data.categoryExpenses.isNotEmpty) ...[
          Text(
            'カテゴリ別支出',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          CategoryChart(
            categoryExpenses: data.categoryExpenses,
            totalAmount: data.monthlyTotal,
          ),
          const SizedBox(height: 24),
        ],

        // 最近の支出
        Text(
          '最近の支出',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (data.recentExpenses.isEmpty)
          const _EmptyExpenses()
        else
          RecentExpensesCard(
            expenses: data.recentExpenses,
            onShowAllPressed: () => _navigateToExpenseList(context, ref),
            onExpenseTap: (expense) => _navigateToEdit(context, ref, expense),
          ),
      ],
    );
  }

  Future<void> _navigateToExpenseList(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
    );

    if (result == true) {
      ref.invalidate(dashboardDataProvider);
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
      ref.invalidate(dashboardDataProvider);
    }
  }
}

/// 支出がない場合の表示
class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'まだ支出がありません',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                '右下の「支出を追加」ボタンから\n支出を登録してみましょう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
