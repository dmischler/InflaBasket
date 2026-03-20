import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/services/barcode_assignment_service.dart';
import 'package:inflabasket/features/barcode/presentation/barcode_input_dialog.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class BarcodeSection extends ConsumerWidget {
  final Product product;

  const BarcodeSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.barcodeSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        if (product.barcode != null && product.barcode!.isNotEmpty) ...[
          _BarcodeChip(
            barcode: product.barcode!,
            onCopy: () => _copyBarcode(context, product.barcode!, l10n),
            onRemove: () => _removeBarcode(context, ref, product.id, l10n),
            l10n: l10n,
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => _assignBarcode(context, ref, product.id, l10n),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(product.barcode == null
              ? l10n.barcodeAssign
              : l10n.barcodeChange),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }

  void _copyBarcode(
      BuildContext context, String barcode, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.barcodeCopied)),
    );
  }

  Future<void> _assignBarcode(BuildContext context, WidgetRef ref,
      int productId, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final barcode = await showBarcodeInputDialog(context);
    if (barcode == null || !context.mounted) return;

    final service = ref.read(barcodeAssignmentServiceProvider);
    final result =
        await service.assignBarcode(productId: productId, barcode: barcode);

    if (!context.mounted) return;

    switch (result.status) {
      case BarcodeAssignmentStatus.success:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.barcodeAssigned(barcode))),
        );
        router.pop();
        context.push('/home/add');
        break;
      case BarcodeAssignmentStatus.conflict:
        final conflicting = result.conflictingProduct!;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.barcodeConflictTitle),
            content:
                Text(l10n.barcodeConflictMessage(barcode, conflicting.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
        break;
      case BarcodeAssignmentStatus.alreadyAssigned:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.barcodeAlreadyAssigned)),
        );
        break;
    }
  }

  Future<void> _removeBarcode(BuildContext context, WidgetRef ref,
      int productId, AppLocalizations l10n) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.barcodeRemoveConfirmTitle),
        content: Text(l10n.barcodeRemoveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.barcodeRemove),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final service = ref.read(barcodeAssignmentServiceProvider);
    await service.removeBarcode(productId);
    if (!context.mounted) return;

    router.pop();
    context.push('/home/add');
  }
}

class _BarcodeChip extends StatelessWidget {
  final String barcode;
  final VoidCallback onCopy;
  final VoidCallback onRemove;
  final AppLocalizations l10n;

  const _BarcodeChip({
    required this.barcode,
    required this.onCopy,
    required this.onRemove,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(barcode, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          IconButton(
            icon:
                Icon(Icons.copy, size: 18, color: colorScheme.onSurfaceVariant),
            onPressed: onCopy,
            tooltip: l10n.barcodeCopied,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: colorScheme.error),
            onPressed: onRemove,
            tooltip: l10n.barcodeRemove,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
