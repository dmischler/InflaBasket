import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class LuxeButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isSecondary;
  final EdgeInsetsGeometry padding;

  const LuxeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isSecondary = false,
    this.padding = const EdgeInsets.symmetric(
      vertical: AppSpacing.md,
      horizontal: AppSpacing.lg,
    ),
  });

  @override
  State<LuxeButton> createState() => _LuxeButtonState();
}

class _LuxeButtonState extends State<LuxeButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) =>
      setState(() => _isPressed = true);
  void _handleTapUp(TapUpDetails details) => setState(() => _isPressed = false);
  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBitcoinMode = theme.primaryColor == AppColors.accentBtcMain;
    final primaryGlow =
        isBitcoinMode ? AppColors.accentBtcGlow : AppColors.accentFiatGlow;

    final Color bgColor =
        widget.isSecondary ? AppColors.bgElevated : theme.primaryColor;

    final Color textColor =
        widget.isSecondary ? AppColors.textPrimary : AppColors.bgVoid;

    final innerGlowColor = widget.isSecondary
        ? Colors.white.withValues(alpha: 0.05)
        : primaryGlow.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: widget.isSecondary
              ? Border.all(color: AppColors.borderMetallic, width: 1)
              : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: innerGlowColor,
                    blurRadius: 10,
                    spreadRadius: -2,
                  )
                ]
              : [],
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            // Uses standard Inter font defined in Theme.
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
