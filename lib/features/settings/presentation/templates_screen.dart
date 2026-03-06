import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

/// Screen that lists saved recurring-purchase templates.
///
/// Each tile shows the product name, category, and store. Tapping "Use"
/// opens [AddEntryScreen] pre-populated with the template's values.
/// Swiping left dismisses (deletes) the template.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Purchases')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No templates yet.\n\nSave a recurring purchase as a template '
                  'to quickly re-enter it later.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return _TemplateTile(
                template: t,
                onDelete: () => ref
                    .read(addTemplateControllerProvider.notifier)
                    .deleteTemplate(t.template.id),
                onUse: () => _useTemplate(context, t),
              );
            },
          );
        },
      ),
    );
  }

  void _useTemplate(BuildContext context, TemplateWithDetails t) {
    // Build a synthetic EntryWithDetails so AddEntryScreen can pre-populate.
    // We supply a fake entry (id = 0) with the template's values.
    final fakeEntry = EntryWithDetails(
      entry: PurchaseEntry(
        id: 0,
        productId: t.product.id,
        storeName: t.template.storeName,
        purchaseDate: DateTime.now(),
        price: 0.0,
        quantity: t.template.quantity,
        unit: t.template.unit,
        location: t.template.location,
        notes: t.template.notes,
      ),
      product: t.product,
      category: t.category,
    );
    context.push('/home/add', extra: fakeEntry);
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onDelete,
    required this.onUse,
  });

  final TemplateWithDetails template;
  final VoidCallback onDelete;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final t = template.template;
    final unitLabel =
        unitTypeFromString(t.unit) == UnitType.count
            ? ''
            : ' · ${unitTypeFromString(t.unit).label}';
    final qtyLabel = t.quantity != 1.0
        ? '${t.quantity.toStringAsFixed(t.quantity % 1 == 0 ? 0 : 1)}$unitLabel'
        : null;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Template'),
            content: Text(
              'Remove "${template.product.name}" from recurring purchases?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: const Icon(Icons.repeat),
        title: Text(template.product.name),
        subtitle: Text(
          [
            template.category.name,
            t.storeName,
            if (qtyLabel != null) qtyLabel,
          ].join(' · '),
        ),
        trailing: FilledButton.tonal(
          onPressed: onUse,
          child: const Text('Use'),
        ),
      ),
    );
  }
}
