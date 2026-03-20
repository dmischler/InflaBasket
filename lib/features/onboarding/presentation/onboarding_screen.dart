import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/features/onboarding/application/onboarding_provider.dart';
import 'package:inflabasket/features/onboarding/presentation/onboarding_modes_cards.dart';
import 'package:inflabasket/features/onboarding/presentation/onboarding_page.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home/add');
    }
  }

  Future<void> _skipOnboarding() async {
    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == 2;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgVoid : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = page);
                },
                children: [
                  OnboardingPage(
                    animationAsset: StateIllustrations.emptyGeneral,
                    title: l10n.onboardingWelcomeTitle,
                    subtitle: l10n.onboardingWelcomeSubtitle,
                    icon: Icons.shopping_basket_outlined,
                  ),
                  OnboardingPage(
                    icon: Icons.swap_horiz_rounded,
                    title: l10n.onboardingModesTitle,
                    subtitle: l10n.onboardingModesSubtitle,
                    content: const ModesComparisonCards(),
                  ),
                  OnboardingPage(
                    animationAsset: StateIllustrations.loadingMinimal,
                    icon: Icons.add_shopping_cart_rounded,
                    title: l10n.onboardingStartTitle,
                    subtitle: l10n.onboardingStartSubtitle,
                  ),
                ],
              ),
            ),
            _buildPageIndicators(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: isLastPage ? _completeOnboarding : _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor:
                            isDark ? AppColors.bgVoid : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: isDark ? 0 : 2,
                      ),
                      child: Text(
                        isLastPage
                            ? l10n.onboardingStartTracking
                            : l10n.onboardingNext,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      l10n.onboardingSkip,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
