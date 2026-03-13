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

  static const _barHeight = 60.0;
  static const _outerMargin = 12.0;
  static const _pillSize = 46.0;
  static const _fabSize = 46.0;
  static const _slotCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoin = settings.themeType == AppThemeType.luxeDarkBitcoin;
    final accentColor =
        isBitcoin ? AppColors.accentBtcMain : AppColors.accentFiatMain;
    final glowColor =
        isBitcoin ? AppColors.accentBtcGlow : AppColors.accentFiatGlow;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _outerMargin,
          0,
          _outerMargin,
          4,
        ),
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / _slotCount;
              final pillLeft = _slotLeftForIndex(currentIndex, slotWidth) +
                  (slotWidth - _pillSize) / 2;

              return ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgVault.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.borderMetallic,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: pillLeft,
                          top: (_barHeight - _pillSize) / 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(23),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              width: _pillSize,
                              height: _pillSize,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _NavSlot(
                              width: slotWidth,
                              child: _NavItem(
                                isSelected: currentIndex == 0,
                                icon: Icons.dashboard_outlined,
                                selectedIcon: Icons.dashboard,
                                onTap: () => onTap(0),
                              ),
                            ),
                            _NavSlot(
                              width: slotWidth,
                              child: _NavItem(
                                isSelected: currentIndex == 1,
                                icon: Icons.history_outlined,
                                selectedIcon: Icons.history,
                                onTap: () => onTap(1),
                              ),
                            ),
                            SizedBox(
                              width: slotWidth,
                              child: Center(
                                child: SizedBox(
                                  width: _fabSize,
                                  height: _fabSize,
                                  child: FloatingActionButton(
                                    heroTag: 'custom_bottom_nav_fab',
                                    onPressed: onFabPressed,
                                    backgroundColor: accentColor,
                                    elevation: 4,
                                    shape: const CircleBorder(),
                                    child: const Icon(
                                      Icons.add,
                                      color: AppColors.bgVoid,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _NavSlot(
                              width: slotWidth,
                              child: _NavItem(
                                isSelected: currentIndex == 2,
                                icon: Icons.category_outlined,
                                selectedIcon: Icons.category,
                                onTap: () => onTap(2),
                              ),
                            ),
                            _NavSlot(
                              width: slotWidth,
                              child: _NavItem(
                                isSelected: currentIndex == 3,
                                icon: Icons.settings_outlined,
                                selectedIcon: Icons.settings,
                                onTap: () => onTap(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _slotLeftForIndex(int index, double slotWidth) {
    final visualIndex = index >= 2 ? index + 1 : index;
    return visualIndex * slotWidth;
  }
}

class _NavSlot extends StatelessWidget {
  final double width;
  final Widget child;

  const _NavSlot({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _NavItem({
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
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
                key: ValueKey('${isSelected}_$icon'),
                color: isSelected ? AppColors.bgVoid : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
