import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AsyncAutocompleteField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final Future<List<String>> Function(String) suggestionsCallback;
  final String? Function(String?)? validator;
  final int minChars;

  const AsyncAutocompleteField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.suggestionsCallback,
    this.validator,
    this.minChars = 0,
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
      suggestionsCallback: _wrapSuggestions,
      hideOnEmpty: true,
      builder: (context, textController, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
          validator: validator,
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
      },
      debounceDuration: const Duration(milliseconds: 300),
    );
  }
}
