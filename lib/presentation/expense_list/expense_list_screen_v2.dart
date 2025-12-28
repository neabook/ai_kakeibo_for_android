import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';

/// 検索クエリプロバイダー
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 選択中カテゴリプロバイダー
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// 日付範囲プロバイダー
final dateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

/// 支出一覧画面 V2（POCデザイン準拠）
class ExpenseListScreenV2 extends ConsumerWidget {
  const ExpenseListScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _Header(),
            // 検索バー
            _SearchBar(),
            // フィルターチップ
            _FilterChips(),
            // 支出リスト
            Expanded(child: _ExpenseList()),
          ],
        ),
      ),
    );
  }
}

/// ヘッダー
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '支出一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterModal(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadow,
              ),
              child: const Icon(
                Icons.filter_list,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FilterModal(),
    );
  }
}

/// 検索バー
class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: AppTheme.shadow,
        ),
        child: TextField(
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: '支出を検索...',
            hintStyle: const TextStyle(color: AppTheme.gray),
            prefixIcon: const Icon(Icons.search, color: AppTheme.gray),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// フィルターチップ
class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);

    final hasFilters = selectedCategory != null || dateRange != null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (hasFilters)
              GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryFilterProvider.notifier).state = null;
                  ref.read(dateRangeFilterProvider.notifier).state = null;
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 16, color: AppTheme.secondary),
                      SizedBox(width: 4),
                      Text(
                        'クリア',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (selectedCategory != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      CategoryStyle.getEmoji(selectedCategory),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedCategory,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (dateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('M/d').format(dateRange.start)} - ${DateFormat('M/d').format(dateRange.end)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 支出リスト
class _ExpenseList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);

    return expenses.when(
      data: (list) {
        var filteredList = list.toList();

        // 検索フィルター
        if (searchQuery.isNotEmpty) {
          filteredList = filteredList.where((e) {
            final description = e.description?.toLowerCase() ?? '';
            final category = e.categoryName.toLowerCase();
            final query = searchQuery.toLowerCase();
            return description.contains(query) || category.contains(query);
          }).toList();
        }

        // カテゴリフィルター
        if (selectedCategory != null) {
          filteredList = filteredList.where((e) => e.categoryName == selectedCategory).toList();
        }

        // 日付フィルター
        if (dateRange != null) {
          filteredList = filteredList.where((e) {
            return e.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                e.date.isBefore(dateRange.end.add(const Duration(days: 1)));
          }).toList();
        }

        // 日付でソート
        filteredList.sort((a, b) => b.date.compareTo(a.date));

        // 日付でグループ化
        final grouped = _groupByDate(filteredList);

        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: AppTheme.gray.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '支出データがありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            return _DateGroup(
              date: entry.key,
              expenses: entry.value,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('データ取得エラー')),
    );
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja');

    for (final expense in expenses) {
      final dateKey = dateFormat.format(expense.date);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(expense);
    }

    return grouped;
  }
}

/// 日付グループ
class _DateGroup extends StatelessWidget {
  final String date;
  final List<Expense> expenses;

  const _DateGroup({
    required this.date,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0, (sum, e) => sum + e.amount);
    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray,
                ),
              ),
              Text(
                '¥${formatter.format(total)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dark,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: AppTheme.shadow,
          ),
          child: Column(
            children: expenses.asMap().entries.map((entry) {
              final expense = entry.value;
              final isLast = entry.key == expenses.length - 1;
              return _ExpenseItem(expense: expense, isLast: isLast);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 支出アイテム
class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final bool isLast;

  const _ExpenseItem({
    required this.expense,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.lightGray, width: 1),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CategoryStyle.getBackgroundColor(expense.categoryName),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                CategoryStyle.getEmoji(expense.categoryName),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ?? expense.categoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.categoryName} • ${timeFormat.format(expense.date)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-¥${formatter.format(expense.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
              if (expense.store != null)
                Text(
                  expense.store!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.gray,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// フィルターモーダル
class _FilterModal extends ConsumerWidget {
  const _FilterModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);

    final categories = [
      '食費',
      '交通費',
      '日用品',
      '娯楽',
      '医療費',
      '衣服',
      '光熱費',
      'その他',
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // タイトル
            const Text(
              'フィルター',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 24),
            // カテゴリ選択
            const Text(
              'カテゴリ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        isSelected ? null : category;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : CategoryStyle.getBackgroundColor(category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CategoryStyle.getEmoji(category),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppTheme.white : AppTheme.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // 期間選択
            const Text(
              '期間',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                );
                if (picked != null) {
                  ref.read(dateRangeFilterProvider.notifier).state = picked;
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.gray, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      dateRange != null
                          ? '${DateFormat('yyyy/M/d').format(dateRange.start)} - ${DateFormat('yyyy/M/d').format(dateRange.end)}'
                          : '期間を選択',
                      style: TextStyle(
                        fontSize: 14,
                        color: dateRange != null ? AppTheme.dark : AppTheme.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 適用ボタン
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: const Text(
                  '適用する',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
