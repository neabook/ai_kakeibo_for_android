import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// 入力方法選択モーダル
class InputModal extends ConsumerWidget {
  const InputModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          children: [
            // ハンドル
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // タイトル
            const Text(
              '支出を記録',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '入力方法を選択してください',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 24),
            // 入力オプション
            Row(
              children: [
                Expanded(
                  child: _InputOption(
                    icon: Icons.camera_alt,
                    label: 'カメラ',
                    description: 'レシートを撮影',
                    gradient: AppTheme.primaryGradient,
                    onTap: () => _handleCameraInput(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputOption(
                    icon: Icons.photo_library,
                    label: '写真から',
                    description: 'アルバムから選択',
                    gradient: AppTheme.successGradient,
                    onTap: () => _handleGalleryInput(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 手入力ボタン
            _ManualInputButton(
              onTap: () => _handleManualInput(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleCameraInput(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/receipt-scan', arguments: {'source': 'camera'});
  }

  void _handleGalleryInput(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/receipt-scan', arguments: {'source': 'gallery'});
  }

  void _handleManualInput(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/expense-input');
  }
}

/// 入力オプションカード
class _InputOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _InputOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 手入力ボタン
class _ManualInputButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ManualInputButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                color: AppTheme.gray,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '手入力',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  '金額を直接入力',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
