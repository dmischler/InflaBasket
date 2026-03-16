import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/features/subscription/presentation/paywall_screen.dart';
import 'package:inflabasket/features/ai_scanner/presentation/scanner_screen.dart';
import 'package:inflabasket/features/barcode/presentation/barcode_screen.dart';
import 'package:inflabasket/features/settings/presentation/category_management_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_alerts_screen.dart';
import 'package:inflabasket/features/settings/presentation/weight_editor_screen.dart';
import 'package:inflabasket/features/settings/presentation/templates_screen.dart';
import 'package:inflabasket/features/settings/presentation/price_updates_screen.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is EntryWithDetails) {
                return AddEntryScreen(entryToEdit: extra);
              }
              if (extra is ProductInfo) {
                return AddEntryScreen(productInfoFromBarcode: extra);
              }
              return const AddEntryScreen();
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
          final extra = state.extra;
          ImageSource? initialSource;
          XFile? initialFile;
          if (extra is XFile) {
            initialFile = extra;
          } else if (extra is ImageSource) {
            initialSource = extra;
          }
          return ScannerScreen(
            initialSource: initialSource,
            initialFile: initialFile,
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
        path: '/settings/weights',
        builder: (context, state) => const WeightEditorScreen(),
      ),
      GoRoute(
        path: '/settings/price-alerts',
        builder: (context, state) => const PriceAlertsScreen(),
      ),
      GoRoute(
        path: '/settings/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/settings/price-updates',
        builder: (context, state) => const PriceUpdatesScreen(),
      ),
    ],
  );
}
