# Task Plan

## Completed Tasks
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

---

# Auto-Save Database Backup Feature

## Overview
Add an auto-save backup feature that automatically saves the database after every entry is added. Users can choose local storage (folder picker) or cloud storage (share sheet to Google Drive/Dropbox/etc.).

## Implementation Status: ✅ COMPLETE

### Phase 1: Data Model & Persistence
- [x] Add auto-save settings to `AppSettings` class in `settings_provider.dart`
- [x] Create `lib/core/models/auto_save_config.dart` with enum
- [x] Add SharedPreferences keys for persistence
- [x] Add methods to `SettingsController`

### Phase 2: Auto-Backup Service
- [x] Create `lib/core/services/auto_backup_service.dart`
- [x] Export the service via Riverpod provider
- [x] Handle platform differences

### Phase 3: Settings UI
- [x] Add localization strings to `app_en.arb` and `app_de.arb`
- [x] Create `lib/features/settings/presentation/auto_save_backup_screen.dart`
- [x] Add route `/settings/auto-save` to `app_router.dart`
- [x] Add navigation item to `settings_screen.dart`

### Phase 4: Integration Hook
- [x] Modify `lib/features/entry_management/application/entry_providers.dart`
- [x] Ensure backup happens asynchronously (don't block entry save)

### Phase 5: Verification & Finalization
- [x] Run `flutter analyze` - passes
- [x] Run `dart run build_runner build -d`
- [x] Run `flutter gen-l10n`
- [x] Update `docs/project_outline.md`
- [x] Bump version to 1.49.0
- [x] Commit changes

---

## Files Created/Modified

| File | Action |
|------|--------|
| `lib/core/models/auto_save_config.dart` | Created |
| `lib/core/services/auto_backup_service.dart` | Created |
| `lib/features/settings/presentation/auto_save_backup_screen.dart` | Created |
| `lib/features/settings/application/settings_provider.dart` | Modified |
| `lib/features/entry_management/application/entry_providers.dart` | Modified |
| `lib/core/router/app_router.dart` | Modified |
| `lib/features/settings/presentation/settings_screen.dart` | Modified |
| `lib/l10n/app_en.arb` | Modified |
| `lib/l10n/app_de.arb` | Modified |
| `pubspec.yaml` | Modified (version bump) |
| `docs/project_outline.md` | Modified |

---

## Commit

```
de51836 feat: add auto-save database backup feature (v1.49.0)

- Add auto-save settings screen with toggle and storage type selector
- Support local folder picker and cloud storage via share sheet
- Auto-save triggers after each entry is added
- Add manual backup button and last backup timestamp display
- Add localization strings for EN and DE
```