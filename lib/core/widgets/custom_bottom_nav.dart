import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/theme/app_theme.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class CustomBottomNav extends ConsumerStatefulWidget {
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
  ConsumerState<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends ConsumerState<CustomBottomNav> {
  final List<GlobalKey> _navKeys = List.generate(4, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoin = settings.themeType == AppThemeType.luxeDarkBitcoin;
    final accentColor =
        isBitcoin ? AppColors.accentBtcMain : AppColors.accentFiatMain;
    final glowColor =
        isBitcoin ? AppColors.accentBtcGlow : AppColors.accentFiatGlow;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgVault.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderMetallic, width: 1),
            ),
            child: Stack(
              children: [
                _PillIndicator(
                  navKeys: _navKeys,
                  currentIndex: widget.currentIndex,
                  accentColor: accentColor,
                  glowColor: glowColor,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      key: _navKeys[0],
                      isSelected: widget.currentIndex == 0,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      accentColor: accentColor,
                      onTap: () => widget.onTap(0),
                    ),
                    _NavItem(
                      key: _navKeys[1],
                      isSelected: widget.currentIndex == 1,
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      accentColor: accentColor,
                      onTap: () => widget.onTap(1),
                    ),
                    _NavItem(
                      key: _navKeys[2],
                      isSelected: widget.currentIndex == 2,
                      icon: Icons.category_outlined,
                      selectedIcon: Icons.category,
                      accentColor: accentColor,
                      onTap: () => widget.onTap(2),
                    ),
                    _NavItem(
                      key: _navKeys[3],
                      isSelected: widget.currentIndex == 3,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      accentColor: accentColor,
                      onTap: () => widget.onTap(3),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: widget.onFabPressed,
                      backgroundColor: accentColor,
                      mini: true,
                      elevation: 4,
                      child: const Icon(Icons.add, color: AppColors.bgVoid),
                    ),
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
  final List<GlobalKey> navKeys;
  final int currentIndex;
  final Color accentColor;
  final Color glowColor;

  const _PillIndicator({
    required this.navKeys,
    required this.currentIndex,
    required this.accentColor,
    required this.glowColor,
  });

  Offset? _getIconCenter(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetKey = navKeys[currentIndex];
    final iconCenter = _getIconCenter(targetKey);

    if (iconCenter == null) {
      return const SizedBox.shrink();
    }

    final RenderBox? navBox = context.findRenderObject() as RenderBox?;
    if (navBox == null) return const SizedBox.shrink();

    final localPosition = navBox.globalToLocal(iconCenter);
    final pillSize = 48.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: localPosition.dx - pillSize / 2,
      top: (60 - pillSize) / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: pillSize,
        height: pillSize,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(24),
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
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
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
