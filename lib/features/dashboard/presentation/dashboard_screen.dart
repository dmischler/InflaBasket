import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/widgets/add_entry_bottom_sheet.dart';
import 'package:inflabasket/core/widgets/custom_bottom_nav.dart';
import 'package:inflabasket/core/widgets/fiat_bitcoin_toggle.dart';
import 'package:inflabasket/features/dashboard/presentation/overview_tab.dart';
import 'package:inflabasket/features/dashboard/presentation/history_tab.dart';
import 'package:inflabasket/features/dashboard/presentation/categories_tab.dart';
import 'package:inflabasket/features/settings/presentation/settings_screen.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: const [
          FiatBitcoinToggle(),
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          OverviewTab(),
          HistoryTab(),
          CategoriesTab(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onFabPressed: () {
          HapticFeedback.lightImpact();
          AddEntryBottomSheet.show(context);
        },
      ),
    );
  }
}
