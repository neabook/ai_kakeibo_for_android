import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'data/services/ad_service.dart';
import 'data/services/subscription_service.dart';
import 'presentation/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日本語ロケール初期化
  await initializeDateFormatting('ja_JP');

  // モバイルプラットフォームでのみ広告・課金を初期化
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // 広告サービス初期化
      final adService = AdService();
      await adService.initialize();

      // サブスクリプションサービス初期化
      final subscriptionService = SubscriptionService();
      await subscriptionService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize monetization services: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: AiKakeiboApp(),
    ),
  );
}

/// AI家計簿アプリ
class AiKakeiboApp extends StatelessWidget {
  const AiKakeiboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI家計簿',
      debugShowCheckedModeBanner: false,
      // 日本語ローカライゼーション
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainScreen(),
    );
  }
}
