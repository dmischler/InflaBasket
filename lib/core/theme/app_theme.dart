import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

enum AppThemeType {
  standardLight,
  standardDark,
  luxeDarkFiat,
  luxeDarkBitcoin,
  neoCyberpunkTerminal,
}

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.luxeDarkFiat:
        return _buildLuxeDarkTheme(isBitcoin: false);
      case AppThemeType.luxeDarkBitcoin:
        return _buildLuxeDarkTheme(isBitcoin: true);
      case AppThemeType.standardLight:
        return _buildStandardLightTheme();
      case AppThemeType.standardDark:
        return _buildStandardDarkTheme();
      case AppThemeType.neoCyberpunkTerminal:
        return _buildNeoCyberpunkTerminalTheme();
    }
  }

  static ThemeData _buildLuxeDarkTheme({required bool isBitcoin}) {
    final accentColor =
        isBitcoin ? AppColors.accentBtcMain : AppColors.accentFiatMain;

    // Use Inter as default for headings and standard text.
    // JetBrains Mono should be applied locally to specific Text widgets.
    const String primaryFontFamily = 'Inter';

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: primaryFontFamily,
      scaffoldBackgroundColor: AppColors.bgVoid,
      primaryColor: accentColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: isBitcoin ? AppColors.accentBtcDim : AppColors.accentFiatDim,
        surface: AppColors.bgVault,
        onPrimary: AppColors.bgVoid,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgVoid,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgVault,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.borderMetallic, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.bgVoid,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: primaryFontFamily,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textTertiary),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _buildNeoCyberpunkTerminalTheme() {
    const primaryFontFamily = 'Rajdhani';

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: primaryFontFamily,
      scaffoldBackgroundColor: AppColors.bgTerminalDeep,
      primaryColor: AppColors.accentTerminalPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTerminalPrimary,
        secondary: AppColors.accentTerminalDim,
        surface: AppColors.bgTerminalSurface,
        onPrimary: AppColors.bgVoid,
        onSurface: AppColors.textPrimary,
        error: AppColors.accentTerminalFiatMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgTerminalDeep,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.accentTerminalPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.accentTerminalPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
          letterSpacing: 2.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgTerminalSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.accentTerminalDim, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgTerminalDeep,
          foregroundColor: AppColors.accentTerminalPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(
                color: AppColors.accentTerminalPrimary, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: primaryFontFamily,
            letterSpacing: 1.5,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(
            color: AppColors.accentTerminalPrimary,
            fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: AppColors.accentTerminalPrimary,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.accentTerminalPrimary,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.accentTerminalDim),
      ),
      useMaterial3: true,
    );
  }

  // Legacy standard themes for easy rollback/A-B testing
  static ThemeData _buildStandardLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }

  static ThemeData _buildStandardDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );
  }
}
