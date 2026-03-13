import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/theme/app_theme.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class CustomBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoin = settings.themeType == AppThemeType.luxeDarkBitcoin;
    final accentColor =
        isBitcoin ? AppColors.accentBtcMain : AppColors.accentFiatMain;
    final glowColor =
        isBitcoin ? AppColors.accentBtcGlow : AppColors.accentFiatGlow;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgVault.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.borderMetallic, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PillIndicator(
                  currentIndex: currentIndex,
                  accentColor: accentColor,
                  glowColor: glowColor,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      accentColor: accentColor,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      accentColor: accentColor,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox(width: 64),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.category_outlined,
                      selectedIcon: Icons.category,
                      accentColor: accentColor,
                      onTap: () => onTap(2),
                    ),
                    _NavItem(
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      accentColor: accentColor,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
                Positioned(
                  child: FloatingActionButton(
                    onPressed: onFabPressed,
                    backgroundColor: accentColor,
                    elevation: 4,
                    child: const Icon(Icons.add, color: AppColors.bgVoid),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillIndicator extends StatelessWidget {
  final int currentIndex;
  final Color accentColor;
  final Color glowColor;

  const _PillIndicator({
    required this.currentIndex,
    required this.accentColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;
    final pillWidth = 48.0;
    final pillHeight = 48.0;
    final leftOffset = (itemWidth - pillWidth) / 2;
    final visualIndex = currentIndex < 2 ? currentIndex : currentIndex + 1;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: itemWidth * visualIndex + leftOffset,
      top: (60 - pillHeight) / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: pillWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 48,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              isSelected ? selectedIcon : icon,
              key: ValueKey(isSelected),
              color: isSelected ? AppColors.bgVoid : AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
