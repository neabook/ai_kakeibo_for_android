import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../data/database/tables/expenses.dart';
import 'expense_input_provider.dart';

/// 手入力画面
class ExpenseInputScreen extends ConsumerStatefulWidget {
  const ExpenseInputScreen({super.key});

  @override
  ConsumerState<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends ConsumerState<ExpenseInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _storeNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseInputProvider);
    final notifier = ref.read(expenseInputProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出を追加'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 金額入力
            _AmountField(
              controller: _amountController,
              onChanged: (value) {
                final amount = int.tryParse(value.replaceAll(',', ''));
                notifier.setAmount(amount);
              },
            ),
            const SizedBox(height: 24),

            // カテゴリ選択
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('エラー: $e'),
              data: (categories) => _CategorySelector(
                categories: categories,
                selectedId: state.categoryId,
                onSelected: notifier.setCategory,
              ),
            ),
            const SizedBox(height: 24),

            // 日付選択
            _DateSelector(
              selectedDate: state.date,
              onDateSelected: notifier.setDate,
            ),
            const SizedBox(height: 16),

            // 店舗名
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: '店舗名（任意）',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setStoreName,
            ),
            const SizedBox(height: 16),

            // 支払方法
            _PaymentMethodSelector(
              selected: state.paymentMethod,
              onSelected: notifier.setPaymentMethod,
            ),
            const SizedBox(height: 16),

            // メモ
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: notifier.setMemo,
            ),
            const SizedBox(height: 24),

            // エラーメッセージ
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // 保存ボタン
            FilledButton.icon(
              onPressed: state.isSubmitting || !state.isValid
                  ? null
                  : () => _saveExpense(context, notifier),
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(state.isSubmitting ? '保存中...' : '保存する'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense(
      BuildContext context, ExpenseInputNotifier notifier) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await notifier.saveExpense();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('支出を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 保存成功を返す
      }
    }
  }
}

/// 金額入力フィールド
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '金額',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorFormatter(),
          ],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          decoration: InputDecoration(
            prefixText: '¥ ',
            prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            hintText: '0',
            border: const OutlineInputBorder(),
            filled: true,
          ),
          textAlign: TextAlign.end,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '金額を入力してください';
            }
            final amount = int.tryParse(value.replaceAll(',', ''));
            if (amount == null || amount <= 0) {
              return '正しい金額を入力してください';
            }
            return null;
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// 3桁区切りフォーマッター
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// カテゴリ選択
class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = category.id == selectedId;
            final color = _parseColor(category.color);

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon),
                  const SizedBox(width: 4),
                  Text(category.name),
                ],
              ),
              selectedColor: color.withValues(alpha: 0.3),
              checkmarkColor: color,
              onSelected: (_) => onSelected(category.id),
            );
          }).toList(),
        ),
        if (selectedId == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'カテゴリを選択してください',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// 日付選択
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy年M月d日 (E)', 'ja_JP');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('日付'),
      subtitle: Text(
        formatter.format(selectedDate),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          locale: const Locale('ja', 'JP'),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
    );
  }
}

/// 支払方法選択
class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onSelected,
  });

  static const _methods = [
    (PaymentMethod.cash, '現金', Icons.payments),
    (PaymentMethod.credit, 'クレカ', Icons.credit_card),
    (PaymentMethod.qr, 'QR決済', Icons.qr_code),
    (PaymentMethod.emoney, '電子マネー', Icons.contactless),
    (PaymentMethod.other, 'その他', Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '支払方法',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<PaymentMethod>(
          segments: _methods.map((m) {
            return ButtonSegment<PaymentMethod>(
              value: m.$1,
              label: Text(m.$2, style: const TextStyle(fontSize: 12)),
              icon: Icon(m.$3, size: 18),
            );
          }).toList(),
          selected: {selected},
          onSelectionChanged: (set) => onSelected(set.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}
