import 'package:flutter/material.dart';

/// Design token system for the app.
/// All colors used across the application are centralized here.
class AppColors {
  // Surface Tokens — Dark
  static const Color bgVoid = Color(0xFF050505);
  static const Color bgVault = Color(0xFF121212);
  static const Color bgElevated = Color(0xFF1E1E1E);

  // Surface Tokens — Light
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bgLightVault = Color(0xFFF5F5F5);
  static const Color bgLightElevated = Color(0xFFFFFFFF);

  // Typography Tokens — Dark
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textTertiary = Color(0xFF525252);

  // Typography Tokens — Light
  static const Color textDarkPrimary = Color(0xFF171717);
  static const Color textDarkSecondary = Color(0xFF525252);
  static const Color textDarkTertiary = Color(0xFFA3A3A3);

  // Fiat Theme Tokens (Default)
  static const Color accentFiatMain = Color(0xFF10B981); // Emerald
  static const Color accentFiatDim = Color(0xFF064E3B);
  static const Color accentFiatGlow = Color(0x2610B981); // 15% opacity Emerald

  // Bitcoin Theme Tokens
  static const Color accentBtcMain = Color(0xFFF59E0B); // True Gold
  static const Color accentBtcDim = Color(0xFF78350F);
  static const Color accentBtcGlow = Color(0x26F59E0B); // 15% opacity Gold

  // Structural Tokens — Dark
  static const Color borderMetallic = Color(0x14FFFFFF); // 8% opacity White

  // Structural Tokens — Light
  static const Color borderLight = Color(0x14000000); // 8% opacity Black
}

/// Helper class for standardized spacing and sizing tokens
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
}
