import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat設定
class RevenueCatConfig {
  // TODO: 実際のAPIキーに置き換え
  static const String androidApiKey = 'your_android_api_key';
  static const String iosApiKey = 'your_ios_api_key';

  // 商品ID
  static const String monthlyProductId = 'ai_kakeibo_premium_monthly';
  static const String yearlyProductId = 'ai_kakeibo_premium_yearly';

  // エンタイトルメントID
  static const String premiumEntitlementId = 'premium';
}

/// サブスクリプション状態
enum SubscriptionStatus {
  unknown,
  free,
  premium,
  expired,
}

/// サブスクリプション情報
class SubscriptionInfo {
  final SubscriptionStatus status;
  final DateTime? expirationDate;
  final String? productId;
  final bool isTrialPeriod;
  final String? errorMessage;

  const SubscriptionInfo({
    this.status = SubscriptionStatus.unknown,
    this.expirationDate,
    this.productId,
    this.isTrialPeriod = false,
    this.errorMessage,
  });

  bool get isPremium => status == SubscriptionStatus.premium;

  SubscriptionInfo copyWith({
    SubscriptionStatus? status,
    DateTime? expirationDate,
    String? productId,
    bool? isTrialPeriod,
    String? errorMessage,
  }) {
    return SubscriptionInfo(
      status: status ?? this.status,
      expirationDate: expirationDate ?? this.expirationDate,
      productId: productId ?? this.productId,
      isTrialPeriod: isTrialPeriod ?? this.isTrialPeriod,
      errorMessage: errorMessage,
    );
  }
}

/// 商品情報
class ProductInfo {
  final String id;
  final String title;
  final String description;
  final String priceString;
  final double price;
  final String currencyCode;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
  });
}

/// サブスクリプションサービス
class SubscriptionService {
  bool _isInitialized = false;
  SubscriptionInfo _currentSubscription = const SubscriptionInfo();
  List<ProductInfo> _availableProducts = [];

  bool get isInitialized => _isInitialized;
  SubscriptionInfo get currentSubscription => _currentSubscription;
  List<ProductInfo> get availableProducts => _availableProducts;
  bool get isPremium => _currentSubscription.isPremium;

  /// RevenueCat SDKを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // プラットフォーム別のAPIキーを設定
      final configuration = PurchasesConfiguration(
        Platform.isAndroid
            ? RevenueCatConfig.androidApiKey
            : RevenueCatConfig.iosApiKey,
      );

      await Purchases.configure(configuration);
      _isInitialized = true;

      // 現在のサブスクリプション状態を取得
      await refreshSubscriptionStatus();

      // 利用可能な商品を取得
      await fetchAvailableProducts();

      debugPrint('SubscriptionService initialized');
    } catch (e) {
      debugPrint('SubscriptionService initialization failed: $e');
      // 初期化失敗時はフリープランとして扱う
      _currentSubscription = const SubscriptionInfo(
        status: SubscriptionStatus.free,
        errorMessage: '課金システムの初期化に失敗しました',
      );
    }
  }

  /// サブスクリプション状態を更新
  Future<void> refreshSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('Failed to get customer info: $e');
      _currentSubscription = _currentSubscription.copyWith(
        errorMessage: 'サブスクリプション状態の取得に失敗しました',
      );
    }
  }

  /// 利用可能な商品を取得
  Future<void> fetchAvailableProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null) {
        _availableProducts = current.availablePackages.map((package) {
          final product = package.storeProduct;
          return ProductInfo(
            id: product.identifier,
            title: product.title,
            description: product.description,
            priceString: product.priceString,
            price: product.price,
            currencyCode: product.currencyCode,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch products: $e');
    }
  }

  /// 購入処理
  Future<bool> purchase(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        debugPrint('No offerings available');
        return false;
      }

      // 商品を検索
      Package? targetPackage;
      for (final package in current.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          targetPackage = package;
          break;
        }
      }

      if (targetPackage == null) {
        debugPrint('Product not found: $productId');
        return false;
      }

      // 購入実行
      final customerInfo = await Purchases.purchasePackage(targetPackage);
      _updateSubscriptionFromCustomerInfo(customerInfo);

      return _currentSubscription.isPremium;
    } on PurchasesErrorCode catch (e) {
      debugPrint('Purchase failed: $e');
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        // ユーザーがキャンセルした場合
        return false;
      }
      _currentSubscription = _currentSubscription.copyWith(
        errorMessage: '購入処理に失敗しました',
      );
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      _currentSubscription = _currentSubscription.copyWith(
        errorMessage: '購入処理に失敗しました',
      );
      return false;
    }
  }

  /// 購入を復元
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateSubscriptionFromCustomerInfo(customerInfo);
      return _currentSubscription.isPremium;
    } catch (e) {
      debugPrint('Restore failed: $e');
      _currentSubscription = _currentSubscription.copyWith(
        errorMessage: '購入の復元に失敗しました',
      );
      return false;
    }
  }

  /// CustomerInfoからサブスクリプション情報を更新
  void _updateSubscriptionFromCustomerInfo(CustomerInfo customerInfo) {
    final entitlement =
        customerInfo.entitlements.all[RevenueCatConfig.premiumEntitlementId];

    if (entitlement != null && entitlement.isActive) {
      _currentSubscription = SubscriptionInfo(
        status: SubscriptionStatus.premium,
        expirationDate: entitlement.expirationDate != null
            ? DateTime.parse(entitlement.expirationDate!)
            : null,
        productId: entitlement.productIdentifier,
        isTrialPeriod: entitlement.periodType == PeriodType.trial,
      );
    } else {
      _currentSubscription = const SubscriptionInfo(
        status: SubscriptionStatus.free,
      );
    }
  }
}

/// サブスクリプションサービスプロバイダー
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// サブスクリプション初期化プロバイダー
final subscriptionInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  await service.initialize();
  return service.isInitialized;
});

/// 現在のサブスクリプション状態プロバイダー
final subscriptionStatusProvider = Provider<SubscriptionInfo>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.currentSubscription;
});

/// プレミアム状態プロバイダー
final isPremiumProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionStatusProvider);
  return subscription.isPremium;
});
