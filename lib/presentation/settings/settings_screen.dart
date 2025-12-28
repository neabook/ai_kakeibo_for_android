import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/budget_providers.dart';

/// 設定画面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー
              _Header(),
              // プレミアムバナー
              _PremiumBanner(),
              // アカウント設定
              _SettingsSection(
                title: 'アカウント',
                items: [
                  _SettingsItem(
                    icon: Icons.person,
                    iconColor: AppTheme.primary,
                    title: 'プロフィール',
                    subtitle: 'ユーザー情報を編集',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: AppTheme.accent,
                    title: '予算設定',
                    subtitle: '月間予算を管理',
                    onTap: () => _showBudgetModal(context, ref),
                  ),
                  _SettingsItem(
                    icon: Icons.category,
                    iconColor: AppTheme.success,
                    title: 'カテゴリ管理',
                    subtitle: 'カテゴリを追加・編集',
                    onTap: () {},
                  ),
                ],
              ),
              // 一般設定
              _SettingsSection(
                title: '一般',
                items: [
                  _SettingsItem(
                    icon: Icons.notifications,
                    iconColor: AppTheme.warning,
                    title: '通知設定',
                    subtitle: 'リマインダーを管理',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.palette,
                    iconColor: AppTheme.primaryLight,
                    title: 'テーマ',
                    subtitle: 'ライト / ダーク',
                    trailing: const Text(
                      'ライト',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray,
                      ),
                    ),
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.language,
                    iconColor: AppTheme.secondary,
                    title: '言語',
                    subtitle: '表示言語を変更',
                    trailing: const Text(
                      '日本語',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              // データ管理
              _SettingsSection(
                title: 'データ',
                items: [
                  _SettingsItem(
                    icon: Icons.cloud_upload,
                    iconColor: AppTheme.primary,
                    title: 'バックアップ',
                    subtitle: 'データをクラウドに保存',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.download,
                    iconColor: AppTheme.accent,
                    title: 'エクスポート',
                    subtitle: 'CSVでダウンロード',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.delete_outline,
                    iconColor: AppTheme.danger,
                    title: 'データ削除',
                    subtitle: 'すべてのデータを削除',
                    onTap: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
              // その他
              _SettingsSection(
                title: 'その他',
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline,
                    iconColor: AppTheme.gray,
                    title: 'ヘルプ',
                    subtitle: '使い方ガイド',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline,
                    iconColor: AppTheme.gray,
                    title: 'アプリについて',
                    subtitle: 'バージョン 1.0.0',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppTheme.gray,
                    title: 'プライバシーポリシー',
                    subtitle: '利用規約',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 100), // ボトムナビ用スペース
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetModal(BuildContext context, WidgetRef ref) {
    final budget = ref.read(budgetProvider);
    final currentBudget = budget.value?.monthlyBudget ?? 100000;
    final controller = TextEditingController(text: currentBudget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                const Text(
                  '月間予算設定',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '今月の予算を設定してください',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    prefixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dark,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          child: const Text(
                            'キャンセル',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final newBudget = int.tryParse(controller.text) ?? currentBudget;
                          ref.read(budgetProvider.notifier).updateBudget(newBudget);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          child: const Text(
                            '保存',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        title: const Text('データ削除'),
        content: const Text(
          'すべての支出データが削除されます。\nこの操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // TODO: データ削除処理
              Navigator.pop(context);
            },
            child: const Text(
              '削除',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// ヘッダー
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            '設定',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
        ],
      ),
    );
  }
}

/// プレミアムバナー
class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/premium'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.premiumGradient,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppTheme.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'プレミアムにアップグレード',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '広告なし & 無制限のAI分析',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 設定セクション
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              boxShadow: AppTheme.shadow,
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == items.length - 1;
                return _buildItem(item, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_SettingsItem item, bool isLast) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray,
                    ),
                  ),
                ],
              ),
            ),
            item.trailing ??
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.gray.withValues(alpha: 0.5),
                ),
          ],
        ),
      ),
    );
  }
}

/// 設定アイテム
class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });
}
