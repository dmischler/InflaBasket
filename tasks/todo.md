# Task Plan

- [x] Review current code paths for history, entry editing, routing, and repositories needed for product detail flow.
- [x] Implement backend/data support for product detail view and inline product updates.
- [x] Implement product detail screen, route, history navigation, and localized strings.
- [x] Run generation/verification, update docs/version, and prepare commit.

# Review

- Added a dedicated product detail route with a product-specific chart, inflation facts, and swipeable price-history rows.
- Reused the existing add-entry editor for per-entry updates while locking shared fields when launched from product history.
- Implemented inline product name/category/store editing in the detail screen and propagated shared store updates across linked entries and templates without a schema migration.
- Added history long-press actions to open the detail screen while preserving swipe edit/delete behavior.
- Updated localization, project documentation, and versioning for the new feature; `dart run build_runner build -d`, `flutter gen-l10n`, `flutter analyze`, and `flutter test` all completed successfully.
