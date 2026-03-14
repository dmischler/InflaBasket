import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:inflabasket/core/services/price_history_service.dart';

Future<double?> showPricePromptDialog({
  required BuildContext context,
  required String productName,
  required int productId,
}) {
  final controller = TextEditingController();
  final currentMonth = PriceHistoryService.formatMonthYear(DateTime.now());

  return showCupertinoDialog<double>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Preis für "$productName" eintragen'),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Monat: ${PriceHistoryService.formatGermanMonth(currentMonth)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: controller,
            placeholder: '0.00',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'CHF',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            autofocus: true,
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final price = double.tryParse(controller.text);
            if (price != null && price > 0) {
              Navigator.of(context).pop(price);
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    ),
  );
}
