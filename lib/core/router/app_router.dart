import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/router/navigation_extras.dart';
import 'package:inflabasket/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inflabasket/features/dashboard/presentation/product_detail_screen.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/features/onboarding/presentation/onboarding_screen.dart';
import 'package:inflabasket/features/onboarding/application/onboarding_provider.dart';
import 'package:inflabasket/features/subscription/presentation/paywall_screen.dart';
import 'package:inflabasket/features/ai_scanner/presentation/scanner_screen.dart';
import 'package:inflabasket/features/barcode/presentation/barcode_screen.dart';
import 'package:inflabasket/features/settings/presentation/category_management_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_alerts_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_updates_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_update_settings_screen.dart';
import 'package:inflabasket/features/settings/presentation/privacy_policy_screen.dart';
import 'package:inflabasket/features/settings/presentation/terms_of_service_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final onboardingCompleted = ref.watch(onboardingControllerProvider);
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!onboardingCompleted && !isOnboardingRoute) {
        return '/onboarding';
      }

      if (onboardingCompleted && isOnboardingRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final extra = state.extra as AddEntryExtras?;
              return AddEntryScreen(
                entryToEdit: extra?.entryToEdit,
                productInfoFromBarcode: extra?.productInfo,
                lockSharedFields: extra?.lockSharedFields ?? false,
              );
            },
          ),
          GoRoute(
            path: 'product/:productId',
            builder: (context, state) {
              final productId =
                  int.parse(state.pathParameters['productId'] ?? '0');
              return ProductDetailScreen(productId: productId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) {
          final extra = state.extra as ScannerExtras?;
          return ScannerScreen(
            initialSource: extra?.source,
            initialFile: extra?.file,
          );
        },
      ),
      GoRoute(
        path: '/barcode',
        builder: (context, state) => const BarcodeScreen(),
      ),
      GoRoute(
        path: '/settings/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/settings/price-alerts',
        builder: (context, state) => const PriceAlertsScreen(),
      ),
      GoRoute(
        path: '/settings/price-updates',
        builder: (context, state) => const PriceUpdatesScreen(),
      ),
      GoRoute(
        path: '/settings/price-updates/settings',
        builder: (context, state) => const PriceUpdateSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );
}
