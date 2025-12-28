import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../data/database/tables/expenses.dart';
import '../../data/repositories/expense_repository.dart';
import '../expense_input/expense_input_provider.dart';

/// 支出編集画面
class ExpenseEditScreen extends ConsumerStatefulWidget {
  final int expenseId;

  const ExpenseEditScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseEditScreen> createState() => _ExpenseEditScreenState();
}

class _ExpenseEditScreenState extends ConsumerState<ExpenseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _memoController = TextEditingController();

  ExpenseWithCategory? _originalExpense;
  int? _categoryId;
  DateTime _date = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    final repo = ref.read(expenseRepositoryProvider);
    final expense = await repo.getExpenseById(widget.expenseId);

    if (expense == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '支出が見つかりません';
      });
      return;
    }

    setState(() {
      _originalExpense = expense;
      _categoryId = expense.expense.categoryId;
      _date = expense.expense.date;
      _paymentMethod = expense.expense.paymentMethod;
      _amountController.text =
          NumberFormat('#,###').format(expense.expense.totalAmount);
      _storeNameController.text = expense.expense.storeName ?? '';
      _memoController.text = expense.expense.memo ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _storeNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('支出を編集')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('支出を編集')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出を編集'),
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
            _buildAmountField(),
            const SizedBox(height: 24),

            // カテゴリ選択
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('エラー: $e'),
              data: (categories) => _buildCategorySelector(categories),
            ),
            const SizedBox(height: 24),

            // 日付選択
            _buildDateSelector(),
            const SizedBox(height: 16),

            // 店舗名
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: '店舗名（任意）',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 支払方法
            _buildPaymentMethodSelector(),
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
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _isSaving || _categoryId == null
                  ? null
                  : () => _saveExpense(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? '保存中...' : '変更を保存'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
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
          controller: _amountController,
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
        ),
      ],
    );
  }

  Widget _buildCategorySelector(List<Category> categories) {
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
            final isSelected = category.id == _categoryId;
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
              onSelected: (_) => setState(() => _categoryId = category.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final formatter = DateFormat('yyyy年M月d日 (E)', 'ja_JP');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('日付'),
      subtitle: Text(
        formatter.format(_date),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          locale: const Locale('ja', 'JP'),
        );
        if (picked != null) {
          setState(() => _date = picked);
        }
      },
    );
  }

  Widget _buildPaymentMethodSelector() {
    const methods = [
      (PaymentMethod.cash, '現金', Icons.payments),
      (PaymentMethod.credit, 'クレカ', Icons.credit_card),
      (PaymentMethod.qr, 'QR決済', Icons.qr_code),
      (PaymentMethod.emoney, '電子マネー', Icons.contactless),
      (PaymentMethod.other, 'その他', Icons.more_horiz),
    ];

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
          segments: methods.map((m) {
            return ButtonSegment<PaymentMethod>(
              value: m.$1,
              label: Text(m.$2, style: const TextStyle(fontSize: 12)),
              icon: Icon(m.$3, size: 18),
            );
          }).toList(),
          selected: {_paymentMethod},
          onSelectionChanged: (set) =>
              setState(() => _paymentMethod = set.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }

  Future<void> _saveExpense(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final amount = int.parse(_amountController.text.replaceAll(',', ''));
      final repo = ref.read(expenseRepositoryProvider);

      // 既存のExpenseを更新
      final updatedExpense = _originalExpense!.expense.copyWith(
        categoryId: _categoryId!,
        date: _date,
        storeName: Value(_storeNameController.text.isEmpty
            ? null
            : _storeNameController.text),
        totalAmount: amount,
        paymentMethod: _paymentMethod,
        memo: Value(
            _memoController.text.isEmpty ? null : _memoController.text),
        updatedAt: DateTime.now(),
      );

      await repo.updateExpense(updatedExpense);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('支出を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = '保存に失敗しました: $e';
      });
    }
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
