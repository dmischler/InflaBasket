# Lessons

- When using `flutter_typeahead` 5.x, always wire the actual text field to the controller passed into the `builder`; using a separate controller prevents typing from triggering suggestions.
- For searchable defaults in forms, keep the selected value separate from the visible search text so tapping into the field can start a search without losing the current selection.
- For Flutter platform fixes, verify the checked-in platform scaffolds and CI scripts before blaming asset configuration; deleting and recreating `ios/` in CI can silently drop custom app icons and break missing xcconfig references.
- For Android notification scheduling with `flutter_local_notifications` 16+, app manifests must declare the scheduled-notification receivers and reboot permission explicitly; the plugin no longer wires the full setup for the app.
- For `fl_chart` interaction work, confirm the installed package API before finalizing the plan; animation params and `FlDotPainter` requirements differ by version, and tabs that need touch debounce/highlight state may need to become stateful.
- For inflation UX changes, lock the metric definition early (e.g., yearly average vs cumulative), then keep chart semantics explicit so summary metrics and trend lines stay intentionally different instead of accidentally inconsistent.
