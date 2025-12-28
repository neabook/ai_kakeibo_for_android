import 'package:flutter/material.dart';

/// POC v2準拠のアプリテーマ
class AppTheme {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF8B7CF7);

  // Accent Colors
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color danger = Color(0xFFE74C3C);

  // Neutral Colors
  static const Color dark = Color(0xFF2C3E50);
  static const Color gray = Color(0xFF95A5A6);
  static const Color lightGray = Color(0xFFECF0F1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);

  // Category Colors
  static const Color foodColor = Color(0xFFFFE5E5);
  static const Color transportColor = Color(0xFFE5F0FF);
  static const Color dailyColor = Color(0xFFE5FFE9);
  static const Color entertainmentColor = Color(0xFFFFE5F0);
  static const Color medicalColor = Color(0xFFFFF3E5);
  static const Color clothingColor = Color(0xFFE5E5FF);
  static const Color utilityColor = Color(0xFFFFFBE5);
  static const Color otherColor = Color(0xFFF0F0F0);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF96CEB4),
    Color(0xFFDDA0DD),
    Color(0xFFFFB347),
    Color(0xFF87CEEB),
    Color(0xFFDDA0DD),
  ];

  // Shadows
  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radius = 16.0;
  static const double radiusLg = 24.0;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF27AE60)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: white,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: white,
        foregroundColor: dark,
        titleTextStyle: TextStyle(
          color: dark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: gray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: lightGray, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: lightGray, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF16213E),
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF16213E),
        foregroundColor: white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// カテゴリの色とアイコンを取得するヘルパー
class CategoryStyle {
  static Color getBackgroundColor(String categoryName) {
    switch (categoryName) {
      case '食費':
        return AppTheme.foodColor;
      case '交通費':
        return AppTheme.transportColor;
      case '日用品':
        return AppTheme.dailyColor;
      case '娯楽':
        return AppTheme.entertainmentColor;
      case '医療費':
        return AppTheme.medicalColor;
      case '衣服':
        return AppTheme.clothingColor;
      case '光熱費':
        return AppTheme.utilityColor;
      default:
        return AppTheme.otherColor;
    }
  }

  static String getEmoji(String categoryName) {
    switch (categoryName) {
      case '食費':
        return '🍽️';
      case '交通費':
        return '🚃';
      case '日用品':
        return '🧴';
      case '娯楽':
        return '🎮';
      case '医療費':
        return '💊';
      case '衣服':
        return '👕';
      case '光熱費':
        return '💡';
      case '通信費':
        return '📱';
      default:
        return '📦';
    }
  }
}
