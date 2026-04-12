import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/router/navigation_extras.dart';
import 'package:inflabasket/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inflabasket/features/dashboard/presentation/product_detail_screen.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';

import 'package:inflabasket/features/ai_scanner/presentation/scanner_screen.dart';
import 'package:inflabasket/features/barcode/presentation/barcode_screen.dart';
import 'package:inflabasket/features/settings/presentation/api_keys_screen.dart';
import 'package:inflabasket/features/settings/presentation/category_management_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_alerts_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_updates_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_update_settings_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
          final tabIndex = (tab != null && tab >= 0 && tab <= 3) ? tab : 0;
          return DashboardScreen(initialIndex: tabIndex);
        },
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
        path: '/settings/api-keys',
        builder: (context, state) => const ApiKeysScreen(),
      ),
    ],
  );
}
