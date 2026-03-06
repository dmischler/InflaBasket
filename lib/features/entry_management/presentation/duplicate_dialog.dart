import 'package:flutter/material.dart';

/// Result returned by [showDuplicateDialog].
enum DuplicateAction {
  /// User wants to link the new entry to the existing product.
  linkToExisting,

  /// User wants to create a brand-new product with the typed name.
  createNew,
}

/// Shows an alert dialog informing the user that a possibly duplicate product
/// name was detected.
///
/// [newName] is the name the user typed.
/// [existingName] is the best-matching name already in the database.
///
/// Returns a [DuplicateAction] or null if the dialog was dismissed.
Future<DuplicateAction?> showDuplicateDialog({
  required BuildContext context,
  required String newName,
  required String existingName,
}) {
  return showDialog<DuplicateAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Possible Duplicate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A similar product already exists in this category. '
            'Would you like to link this entry to the existing product?',
          ),
          const SizedBox(height: 16),
          _NameRow(label: 'You typed', name: newName),
          const SizedBox(height: 8),
          _NameRow(label: 'Existing', name: existingName),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(DuplicateAction.createNew),
          child: const Text('Create New'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(DuplicateAction.linkToExisting),
          child: const Text('Link to Existing'),
        ),
      ],
    ),
  );
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(name)),
      ],
    );
  }
}
