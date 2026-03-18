import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AsyncAutocompleteField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final Future<List<String>> Function(String) suggestionsCallback;
  final String? Function(String?)? validator;
  final int minChars;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onSelected;

  const AsyncAutocompleteField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.suggestionsCallback,
    this.validator,
    this.minChars = 0,
    this.enabled = true,
    this.onFieldSubmitted,
    this.onSelected,
  });

  Future<List<String>> _wrapSuggestions(String search) async {
    if (search.length < minChars) {
      return [];
    }
    return suggestionsCallback(search);
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback: _wrapSuggestions,
      hideOnEmpty: true,
      builder: (context, textController, focusNode) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
        );
      },
      itemBuilder: (context, itemData) {
        return ListTile(
          title: Text(itemData),
          dense: true,
        );
      },
      onSelected: (selection) {
        controller.text = selection;
        controller.selection = TextSelection.collapsed(
          offset: selection.length,
        );
        onSelected?.call(selection);
      },
      debounceDuration: const Duration(milliseconds: 300),
    );
  }
}
