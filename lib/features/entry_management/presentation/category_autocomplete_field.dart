import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class CategoryAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? selectedCategoryName;
  final bool enabled;
  final ValueChanged<String> onCategorySelected;

  const CategoryAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedCategoryName,
    required this.enabled,
    required this.onCategorySelected,
  });

  @override
  ConsumerState<CategoryAutocompleteField> createState() =>
      _CategoryAutocompleteFieldState();
}

class _CategoryAutocompleteFieldState
    extends ConsumerState<CategoryAutocompleteField> {
  bool _isEditingCategorySearch = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) return;
    if (!_isEditingCategorySearch || widget.selectedCategoryName == null) {
      return;
    }
    setState(() {
      _isEditingCategorySearch = false;
      widget.controller.text = CategoryLocalization.displayNameForContext(
        context,
        widget.selectedCategoryName!,
      );
    });
  }

  void beginCategorySearch() {
    if (widget.selectedCategoryName == null || _isEditingCategorySearch) {
      return;
    }

    final displayName = CategoryLocalization.displayNameForContext(
      context,
      widget.selectedCategoryName!,
    );
    if (widget.controller.text == displayName) {
      setState(() {
        _isEditingCategorySearch = true;
        widget.controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(entryRepositoryProvider);

    return TypeAheadField<String>(
      controller: widget.controller,
      focusNode: widget.focusNode,
      suggestionsCallback: repo.searchCategoryNames,
      builder: (context, textController, focusNode) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l10n.category,
            border: const OutlineInputBorder(),
          ),
          onTap: widget.enabled ? beginCategorySearch : null,
          enabled: widget.enabled,
          validator: (value) =>
              value == null || value.isEmpty ? l10n.fieldRequired : null,
        );
      },
      itemBuilder: (context, itemData) {
        return ListTile(
          title: Text(
            CategoryLocalization.displayNameForContext(context, itemData),
          ),
          dense: true,
        );
      },
      onSelected: (selection) {
        widget.controller.text = CategoryLocalization.displayNameForContext(
          context,
          selection,
        );
        setState(() {
          _isEditingCategorySearch = false;
        });
        widget.onCategorySelected(selection);
      },
      debounceDuration: const Duration(milliseconds: 300),
      hideOnEmpty: false,
    );
  }
}
