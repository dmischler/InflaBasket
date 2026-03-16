import 'package:flutter/material.dart';

/// Design Token System: Premium Dark Luxe
/// All colors used across the application are centralized here.
class AppColors {
  // Surface Tokens
  static const Color bgVoid = Color(0xFF050505);
  static const Color bgVault = Color(0xFF121212);
  static const Color bgElevated = Color(0xFF1E1E1E);

  // Cyberpunk Surface Tokens
  static const Color bgTerminalDeep = Color(0xFF0A110F);
  static const Color bgTerminalSurface = Color(0xFF121A16);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textTertiary = Color(0xFF525252);

  // Fiat Theme Tokens (Default)
  static const Color accentFiatMain = Color(0xFF10B981); // Emerald
  static const Color accentFiatDim = Color(0xFF064E3B);
  static const Color accentFiatGlow = Color(0x2610B981); // 15% opacity Emerald

  // Bitcoin Theme Tokens
  static const Color accentBtcMain = Color(0xFFF59E0B); // True Gold
  static const Color accentBtcDim = Color(0xFF78350F);
  static const Color accentBtcGlow = Color(0x26F59E0B); // 15% opacity Gold

  // Cyberpunk Terminal Tokens
  static const Color accentTerminalPrimary = Color(0xFF00FF41); // Bright Green
  static const Color accentTerminalDim = Color(0xFF008F11); // Dim Green
  static const Color accentTerminalFiatMain =
      Color(0xFFFF003C); // Glitch Magenta
  static const Color accentTerminalFiatDim =
      Color(0xFF00F0FF); // Cyan Wireframe
  static const Color accentTerminalBtcMain = Color(0xFFF28C0F); // Satoshi Neon
  static const Color accentTerminalBtcDim = Color(0xFFFFDF00); // Electric Gold

  // Structural Tokens
  static const Color borderMetallic = Color(0x14FFFFFF); // 8% opacity White
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
