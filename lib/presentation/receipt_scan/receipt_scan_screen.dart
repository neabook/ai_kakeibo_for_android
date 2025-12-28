import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ad_service.dart';
import '../../data/services/subscription_service.dart';
import 'ocr_confirm_screen.dart';
import 'receipt_scan_provider.dart';

/// レシートスキャン画面
class ReceiptScanScreen extends ConsumerWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(receiptScanProvider);
    final scanNotifier = ref.read(receiptScanProvider.notifier);

    // エラー発生時にSnackBarを表示
    ref.listen<ReceiptScanState>(receiptScanProvider, (previous, next) {
      if (next.status == ScanStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '閉じる',
              textColor: Colors.white,
              onPressed: () => scanNotifier.clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('レシート撮影'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(context, ref, scanState, scanNotifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ReceiptScanState scanState,
    ReceiptScanNotifier scanNotifier,
  ) {
    // 処理中
    if (scanState.status == ScanStatus.capturing ||
        scanState.status == ScanStatus.processing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              scanState.status == ScanStatus.capturing
                  ? '画像を読み込んでいます...'
                  : 'AIでレシートを解析中...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // 画像が選択されている場合
    if (scanState.imageBytes != null) {
      return _buildImagePreview(context, ref, scanState, scanNotifier);
    }

    // 初期状態
    return _buildInitialView(context, scanNotifier);
  }

  /// 初期画面（画像選択前）
  Widget _buildInitialView(BuildContext context, ReceiptScanNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // イラスト
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),

          // タイトル
          Text(
            'レシートを撮影',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'AIがレシートを自動で読み取ります',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 48),

          // カメラボタン
          FilledButton.icon(
            onPressed: () => notifier.captureFromCamera(),
            icon: const Icon(Icons.camera_alt),
            label: const Text('カメラで撮影'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: 16),

          // ギャラリーボタン
          OutlinedButton.icon(
            onPressed: () => notifier.pickFromGallery(),
            icon: const Icon(Icons.photo_library),
            label: const Text('ギャラリーから選択'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: 32),

          // ヒント
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '明るい場所でレシート全体が写るように撮影してください',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 画像プレビュー
  Widget _buildImagePreview(
    BuildContext context,
    WidgetRef ref,
    ReceiptScanState scanState,
    ReceiptScanNotifier notifier,
  ) {
    return Column(
      children: [
        // 画像プレビュー
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                scanState.imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // アクションボタン
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 解析ボタン
              FilledButton.icon(
                onPressed: () => _onAnalyzePressed(context, ref, notifier),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AIで解析する'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 12),

              // 再撮影ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.captureFromCamera(),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('再撮影'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.pickFromGallery(),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('別の画像'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 解析ボタン押下処理
  Future<void> _onAnalyzePressed(
    BuildContext context,
    WidgetRef ref,
    ReceiptScanNotifier notifier,
  ) async {
    final isPremium = ref.read(isPremiumProvider);
    final adService = ref.read(adServiceProvider);

    // 非プレミアムユーザーには広告を表示
    if (!isPremium) {
      // 広告表示中のダイアログを表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('広告を読み込んでいます...'),
              ],
            ),
          ),
        );
      }

      // リワード広告を表示
      final adWatched = await adService.showRewardedAd();

      // ダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 広告がスキップされた場合（広告が利用不可の場合は続行を許可）
      if (!adWatched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('広告の視聴が完了しませんでした'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    // OCR解析を実行
    await notifier.analyzeImage();
    final state = ref.read(receiptScanProvider);

    if (state.status == ScanStatus.success &&
        state.ocrResult != null &&
        context.mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => OcrConfirmScreen(
            ocrResult: state.ocrResult!,
            imageBytes: state.imageBytes!,
          ),
        ),
      );

      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
