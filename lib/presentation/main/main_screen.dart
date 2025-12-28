import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen_v2.dart';
import '../expense_list/expense_list_screen_v2.dart';
import '../analysis/analysis_screen_v2.dart';
import '../settings/settings_screen.dart';
import 'widgets/input_modal.dart';

/// 選択中のタブインデックス
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// メイン画面（ボトムナビゲーション付き）
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: const [
          DashboardScreenV2(),
          ExpenseListScreenV2(),
          SizedBox(), // Center FABのプレースホルダー
          AnalysisScreenV2(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: selectedTab,
        onTap: (index) {
          if (index == 2) {
            // 中央ボタンはモーダル表示
            _showInputModal(context);
          } else {
            ref.read(selectedTabProvider.notifier).state = index;
          }
        },
      ),
      floatingActionButton: _CenterFAB(
        onPressed: () => _showInputModal(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showInputModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const InputModal(),
    );
  }
}

/// ボトムナビゲーションバー
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home,
              label: 'ホーム',
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.list,
              label: '一覧',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 60), // FAB用スペース
            _NavItem(
              icon: Icons.pie_chart,
              label: '分析',
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.settings,
              label: '設定',
              isSelected: selectedIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// ナビゲーションアイテム
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primary : AppTheme.gray,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中央のFAB
class _CenterFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _CenterFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: AppTheme.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
