import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/core/theme/app_theme.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class FiatBitcoinToggle extends ConsumerWidget {
  const FiatBitcoinToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoin = settings.themeType == AppThemeType.luxeDarkBitcoin;

    // Only show the physical-feeling switch if we are in Luxe mode.
    // Or we can just use it to force Luxe mode.
    if (settings.themeType != AppThemeType.luxeDarkFiat &&
        settings.themeType != AppThemeType.luxeDarkBitcoin) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();

        // Use isBitcoinMode to determine the new theme (not the current theme)
        final newTheme = settings.isBitcoinMode
            ? AppThemeType.luxeDarkFiat
            : AppThemeType.luxeDarkBitcoin;
        ref.read(settingsControllerProvider.notifier).setThemeType(newTheme);

        final newBitcoinMode = !settings.isBitcoinMode;
        ref
            .read(settingsControllerProvider.notifier)
            .setBitcoinMode(newBitcoinMode);

        if (newBitcoinMode) {
          ref.invalidate(btcPriceCacheProvider);
          ref.invalidate(itemInflationListSatsProvider);
          ref.invalidate(basketInflationSatsProvider);
        }
      },
      child: Container(
        width: 60,
        height: 32,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.bgVault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderMetallic,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment:
                  isBitcoin ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBitcoin
                      ? AppColors.accentBtcMain
                      : AppColors.accentFiatMain,
                  boxShadow: [
                    BoxShadow(
                      color: (isBitcoin
                              ? AppColors.accentBtcMain
                              : AppColors.accentFiatMain)
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    isBitcoin ? Icons.currency_bitcoin : Icons.attach_money,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
