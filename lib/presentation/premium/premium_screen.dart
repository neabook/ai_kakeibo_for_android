import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/services/subscription_service.dart';

/// プレミアム画面
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionStatusProvider);
    final service = ref.watch(subscriptionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアム'),
      ),
      body: subscription.isPremium
          ? _buildPremiumActiveView(context, subscription)
          : _buildUpgradeView(context, service, subscription),
    );
  }

  /// プレミアム有効時の表示
  Widget _buildPremiumActiveView(
      BuildContext context, SubscriptionInfo subscription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // プレミアムバッジ
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'プレミアム会員',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          if (subscription.isTrialPeriod)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '無料トライアル中',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (subscription.expirationDate != null) ...[
            const SizedBox(height: 16),
            Text(
              '次回更新日: ${DateFormat('yyyy年M月d日').format(subscription.expirationDate!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 32),

          // 特典一覧
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ご利用中の特典',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.block, '広告なし', true),
                  _buildFeatureItem(Icons.all_inclusive, 'OCR無制限', true),
                  _buildFeatureItem(Icons.analytics, 'AI分析無制限', true),
                  _buildFeatureItem(Icons.cloud_upload, 'データバックアップ', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// アップグレード画面
  Widget _buildUpgradeView(
    BuildContext context,
    SubscriptionService service,
    SubscriptionInfo subscription,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ヘッダー
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 56,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'プレミアムにアップグレード',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '広告なしでストレスフリーに',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // 特典一覧
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレミアム特典',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.block, '広告を完全に非表示', false),
                  _buildFeatureItem(Icons.all_inclusive, 'レシートOCR無制限', false),
                  _buildFeatureItem(Icons.analytics, 'AI分析無制限', false),
                  _buildFeatureItem(Icons.cloud_upload, 'データバックアップ', false),
                  _buildFeatureItem(Icons.support_agent, '優先サポート', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // エラーメッセージ
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // 価格プラン
          _buildPricingCard(
            context,
            title: '月額プラン',
            price: '¥500',
            period: '/月',
            productId: RevenueCatConfig.monthlyProductId,
            isPopular: false,
            service: service,
          ),
          const SizedBox(height: 12),

          _buildPricingCard(
            context,
            title: '年額プラン',
            price: '¥4,800',
            period: '/年',
            productId: RevenueCatConfig.yearlyProductId,
            isPopular: true,
            savings: '2ヶ月分お得！',
            service: service,
          ),
          const SizedBox(height: 24),

          // 復元ボタン
          TextButton(
            onPressed: _isLoading ? null : () => _restorePurchases(service),
            child: const Text('購入を復元'),
          ),

          const SizedBox(height: 16),

          // 注意事項
          Text(
            '・購入はApple ID/Googleアカウントに請求されます\n'
            '・期間終了の24時間前までにキャンセルしない限り自動更新されます\n'
            '・購入後の返金はできません',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? Colors.green : Colors.amber.shade700,
          ),
          const SizedBox(width: 12),
          Text(text),
          const Spacer(),
          if (isActive)
            const Icon(Icons.check_circle, size: 20, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required String productId,
    required bool isPopular,
    required SubscriptionService service,
    String? savings,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? BorderSide(color: Colors.amber.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _purchase(productId, service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isPopular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'おすすめ',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (savings != null)
                        Text(
                          savings,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(String productId, SubscriptionService service) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await service.purchase(productId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プレミアムへのアップグレードが完了しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '購入処理に失敗しました';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases(SubscriptionService service) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await service.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '購入を復元しました' : '復元する購入がありません'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '復元に失敗しました';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
