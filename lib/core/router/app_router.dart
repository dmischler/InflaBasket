import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/features/subscription/presentation/paywall_screen.dart';
import 'package:inflabasket/features/ai_scanner/presentation/scanner_screen.dart';
import 'package:inflabasket/features/settings/presentation/category_management_screen.dart';

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
            builder: (context, state) => const AddEntryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/settings/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
    ],
  );
}
