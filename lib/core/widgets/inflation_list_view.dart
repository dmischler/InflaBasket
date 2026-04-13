import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class InflationListView extends StatelessWidget {
  const InflationListView({
    super.key,
    required this.items,
    required this.isBitcoinMode,
    required this.settings,
    required this.isInflatorsList,
  });

  final List<InflationListItem> items;
  final bool isBitcoinMode;
  final AppSettings settings;
  final bool isInflatorsList;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return StateMessageCard(
        icon: isInflatorsList ? Icons.trending_up : Icons.trending_down,
        animationAsset: StateIllustrations.emptyGeneral,
        animationHeight: 140,
        title:
            isInflatorsList ? l.overviewTopInflators : l.overviewTopDeflators,
        message: l.overviewNoData,
      );
    }

    final filtered = _filterItems();
    if (filtered.isEmpty) {
      return Text(
        isInflatorsList
            ? l.overviewNoPriceIncreases
            : l.overviewNoPriceDecreases,
      );
    }

    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final unitLabel = item.formattedPriceRange(settings.currency);

        final listTile = _buildListTile(context, item, unitLabel, isLuxeMode);

        if (isLuxeMode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VaultCard(
              padding: EdgeInsets.zero,
              child: listTile,
            ),
          );
        }

        return listTile;
      },
    );
  }

  List<InflationListItem> _filterItems() {
    final filtered = isInflatorsList
        ? items.where((i) => i.inflationPercent > 0).toList()
        : items.where((i) => i.inflationPercent < 0).toList();

    if (!isInflatorsList) {
      filtered.sort((a, b) => a.inflationPercent.compareTo(b.inflationPercent));
    }

    return filtered.take(5).toList();
  }

  Widget _buildListTile(
    BuildContext context,
    InflationListItem item,
    String unitLabel,
    bool isLuxeMode,
  ) {
    final percentColor = isInflatorsList
        ? (isBitcoinMode ? AppColors.accentBtcMain : Colors.red)
        : (isLuxeMode ? AppColors.accentFiatMain : Colors.green);

    final prefix = isInflatorsList ? '+' : '';

    return InkWell(
      onTap: () => context.push('/home/product/${item.product.id}'),
      child: ListTile(
        contentPadding: isLuxeMode
            ? const EdgeInsets.symmetric(horizontal: 16)
            : EdgeInsets.zero,
        title: Text(
          '${item.product.name} (${item.storeName})',
          style:
              isLuxeMode ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
        subtitle: Text(unitLabel),
        trailing: isLuxeMode
            ? TabularAmountText(
                '$prefix${item.inflationPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: percentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : Text(
                '$prefix${item.inflationPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: percentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
