import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Livewall AI 设计令牌：深色背景 + 紫色渐变主色。
class AppColors {
  AppColors._();

  /// 主渐变起点
  static const Color gradientStart = Color(0xFF6B46FF);

  /// 主渐变终点
  static const Color gradientEnd = Color(0xFFC84CFF);

  /// 页面背景（纯黑偏质感）
  static const Color background = Color(0xFF0A0A0B);

  /// 卡片 / 表面色
  static const Color surface = Color(0xFF1C1C1E);

  /// 次级表面（输入框等）
  static const Color surfaceVariant = Color(0xFF2C2C2E);

  /// 底栏激活色（与设计稿金色点缀一致，可选）
  static const Color navActive = Color(0xFFE8A317);

  /// 底栏未选中
  static const Color navInactive = Color(0xFF8E8E93);

  /// 主文本
  static const Color onSurface = Color(0xFFFFFFFF);

  /// 次级文本
  static const Color onSurfaceMuted = Color(0xFFAEAEB2);
}

/// 全局渐变（按钮、强调块）
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );
}

/// Material 3 深色主题 + Poppins
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.gradientStart,
      secondary: AppColors.gradientEnd,
      onSurface: AppColors.onSurface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF000000),
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navInactive,
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.gradientStart.withValues(alpha: 0.35),
      labelStyle: GoogleFonts.poppins(color: AppColors.onSurface, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: GoogleFonts.poppins(color: AppColors.onSurfaceMuted),
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    ),
  );
}
