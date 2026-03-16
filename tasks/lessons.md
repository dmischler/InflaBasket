# Lessons

- When using `flutter_typeahead` 5.x, always wire the actual text field to the controller passed into the `builder`; using a separate controller prevents typing from triggering suggestions.
- For searchable defaults in forms, keep the selected value separate from the visible search text so tapping into the field can start a search without losing the current selection.
