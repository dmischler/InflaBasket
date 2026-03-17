# Task Plan

- [x] Replace dashboard time-range model with 6M/1Y/2Y/3Y/5Y/10Y/Custom and make availability depend on purchases in each period.
- [x] Update inflation providers to use only in-range entries and compute average yearly inflation (fiat + sats) from first/last entry inside range.
- [x] Update Overview and Categories tabs for new range labels, dynamic option sets, and Lottie-based insufficient-data state in the summary card.
- [x] Regenerate localization/codegen artifacts, update docs/project_outline.md, bump app version, and run verification commands.

# Review

- Replaced dashboard preset ranges with 6M/1Y/2Y/3Y/5Y/10Y plus Custom, and switched availability checks to "has at least one purchase inside that period".
- Added range-aware entry filtering provider and rewired inflation/list/category/chart providers to only use entries inside the selected window.
- Implemented `YearlyInflationSummary` providers for fiat and sats modes using first/last in-range entries and unweighted yearly-rate averaging across qualifying products.
- Updated Overview/Categories selectors to use resolved valid range selections and updated custom range picker to include full selected end month.
- Switched overview summary card to "Average yearly inflation" and show Lottie empty-state card when insufficient qualifying data exists.
- Regenerated Riverpod and l10n outputs, ran `flutter analyze` (passes with existing generated-file deprecation infos), and bumped app version to `1.20.2`.
- Verified behavior with `flutter test` (all tests passing).
