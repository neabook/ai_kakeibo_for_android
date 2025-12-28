import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../data/database/tables/expenses.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/services/ocr_service.dart';
import '../expense_input/expense_input_provider.dart';

/// OCR結果確認・編集画面
class OcrConfirmScreen extends ConsumerStatefulWidget {
  final OcrResult ocrResult;
  final Uint8List imageBytes;

  const OcrConfirmScreen({
    super.key,
    required this.ocrResult,
    required this.imageBytes,
  });

  @override
  ConsumerState<OcrConfirmScreen> createState() => _OcrConfirmScreenState();
}

class _OcrConfirmScreenState extends ConsumerState<OcrConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _memoController = TextEditingController();

  int? _categoryId;
  DateTime _date = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromOcrResult();
  }

  /// OCR結果から初期値を設定
  void _initializeFromOcrResult() {
    final result = widget.ocrResult;

    // 金額
    if (result.totalAmount > 0) {
      _amountController.text = NumberFormat('#,###').format(result.totalAmount);
    }

    // 店舗名
    if (result.storeName != null) {
      _storeNameController.text = result.storeName!;
    }

    // 日付
    if (result.date != null) {
      try {
        _date = DateTime.parse(result.date!);
      } catch (e) {
        _date = DateTime.now();
      }
    }

    // 支払方法
    if (result.paymentMethod != null) {
      _paymentMethod = _parsePaymentMethod(result.paymentMethod!);
    }
  }

  PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'credit':
        return PaymentMethod.credit;
      case 'debit':
        return PaymentMethod.credit; // debitはcreditとして扱う
      case 'emoney':
        return PaymentMethod.emoney;
      case 'qr':
        return PaymentMethod.qr;
      default:
        return PaymentMethod.other;
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('読み取り結果を確認'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 信頼度表示
            _buildConfidenceCard(),
            const SizedBox(height: 16),

            // 金額入力
            _buildAmountField(),
            const SizedBox(height: 24),

            // カテゴリ選択
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('エラー: $e'),
              data: (categories) {
                // 初回のみOCR結果からカテゴリを設定
                _categoryId ??= _findCategoryId(
                  categories,
                  widget.ocrResult.suggestedCategory,
                );
                return _buildCategorySelector(categories);
              },
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
            const SizedBox(height: 16),

            // 商品リスト（読み取り結果参考）
            if (widget.ocrResult.items.isNotEmpty) ...[
              _buildItemsList(),
              const SizedBox(height: 16),
            ],

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
              label: Text(_isSaving ? '保存中...' : '保存する'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 信頼度カード
  Widget _buildConfidenceCard() {
    final confidence = widget.ocrResult.confidence;
    final isHighConfidence = confidence >= 0.7;

    return Card(
      color: isHighConfidence ? Colors.green.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isHighConfidence ? Icons.check_circle : Icons.info_outline,
              color: isHighConfidence
                  ? Colors.green.shade700
                  : Colors.amber.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHighConfidence ? 'AIが正常に読み取りました' : '読み取り結果を確認してください',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHighConfidence
                          ? Colors.green.shade900
                          : Colors.amber.shade900,
                    ),
                  ),
                  Text(
                    '信頼度: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighConfidence
                          ? Colors.green.shade700
                          : Colors.amber.shade700,
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
        if (_categoryId == null)
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

  /// 読み取った商品リスト（参考表示）
  Widget _buildItemsList() {
    final items = widget.ocrResult.items;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  '読み取った商品（参考）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '¥${NumberFormat('#,###').format(item.subtotal)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: item.quantity > 1
                    ? Text('¥${item.price} × ${item.quantity}')
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  /// カテゴリ名からIDを取得
  int? _findCategoryId(List<Category> categories, String categoryName) {
    try {
      return categories.firstWhere((c) => c.name == categoryName).id;
    } catch (e) {
      return categories.isNotEmpty ? categories.first.id : null;
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

  Future<void> _saveExpense(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) return;

    setState(() => _isSaving = true);

    try {
      final amount = int.parse(_amountController.text.replaceAll(',', ''));
      final repo = ref.read(expenseRepositoryProvider);

      await repo.addExpense(
        ExpensesCompanion.insert(
          categoryId: _categoryId!,
          date: _date,
          storeName: Value(_storeNameController.text.isEmpty
              ? null
              : _storeNameController.text),
          totalAmount: amount,
          paymentMethod: Value(_paymentMethod),
          memo: Value(
              _memoController.text.isEmpty ? null : _memoController.text),
          inputMethod: const Value(InputMethod.ocr),
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('支出を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
