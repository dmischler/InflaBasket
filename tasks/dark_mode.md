# Dark Mode Toggle Plan

## Context

The app currently has a single dark theme (`getLuxeDarkTheme`) with no light mode. ~127 hardcoded `AppColors.*` references across 18 files. The `isLuxeMode` extension check (`scaffoldBackgroundColor == AppColors.bgVoid`) is used in ~69 places for conditional styling. The `isBitcoinMode` controls accent color (emerald vs gold) independently of brightness.

Goal: Add a dark/light mode toggle that persists via SharedPreferences, requiring a proper light ThemeData and refactoring hardcoded colors to be theme-aware.

## Approach

Add `isDarkMode` to `AppSettings`, define light color tokens in `AppColors`, create `getLuxeLightTheme()`, refactor core widgets to use theme-aware color resolution, wire `MaterialApp` to switch `themeMode` and provide both `theme`/`darkTheme`.

The `isBitcoinMode` (accent) and `isDarkMode` (brightness) are orthogonal — 4 combinations: dark-fiat, dark-btc, light-fiat, light-btc.

## Steps

### Phase 1: Foundation (3 files) ✅

- [x] **1.1** Add light color tokens to `lib/core/theme/app_colors.dart`
  - `bgLight` (#FAFAFA), `bgLightVault` (#F5F5F5), `bgLightElevated` (#FFFFFF)
  - `textDarkPrimary` (#171717), `textDarkSecondary` (#525252), `textDarkTertiary` (#A3A3A3)
  - `borderLight` (0x14000000 — 8% opacity black)
  - Keep existing accent colors (they work on both light and dark)

- [x] **1.2** Create `getLuxeLightTheme()` in `lib/core/theme/app_theme.dart`
  - Mirror `getLuxeDarkTheme` but with light colors
  - `brightness: Brightness.light`
  - `scaffoldBackgroundColor: AppColors.bgLight`
  - Update `LuxeTheme` extension: replace `isLuxeMode` with `isDarkMode` check based on `brightness`

- [x] **1.3** Add `isDarkMode` to `AppSettings` in `lib/features/settings/application/settings_provider.dart`
  - Add `isDarkMode` field to `AppSettings` (default `true` — app is currently dark-only)
  - Add `_darkModeKey = 'settings_dark_mode'`
  - Add `setDarkMode(bool)` method on `SettingsController`
  - Load from SharedPreferences in `build()`

### Phase 2: Wire Up MaterialApp (1 file) ✅

- [x] **2.1** Update `lib/main.dart` `MaterialApp.router`
  - `theme: AppTheme.getLuxeLightTheme(isBitcoinMode: settings.isBitcoinMode)`
  - `darkTheme: AppTheme.getLuxeDarkTheme(isBitcoinMode: settings.isBitcoinMode)`
  - `themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light`
  - Remove hardcoded `themeMode: ThemeMode.light`

### Phase 3: Refactor Core Widgets (~6 files, highest impact) ✅

These widgets are used everywhere — fixing them fixes most screens.

- [x] **3.1** Refactor `lib/core/widgets/luxury_dropdown_field.dart` (15 hardcoded refs)
  - `AppColors.bgElevated` → `colorScheme.surfaceContainerHighest`
  - `AppColors.borderMetallic` → `colorScheme.outline`
  - `AppColors.textPrimary` → `colorScheme.onSurface`
  - `AppColors.textSecondary` → `colorScheme.onSurfaceVariant`
  - `AppColors.textTertiary` → `colorScheme.onSurfaceVariant.withValues(alpha: 0.6)`

- [x] **3.2** Refactor `lib/core/widgets/luxury_text_field.dart` (8 hardcoded refs)
  - Same pattern as 3.1

- [x] **3.3** Refactor `lib/core/widgets/luxe_button.dart` (5 refs)
  - Primary: `AppColors.bgVoid` → `colorScheme.onPrimary`
  - Secondary: `AppColors.bgElevated` → `colorScheme.surfaceContainerHighest`
  - Secondary: `AppColors.textPrimary` → `colorScheme.onSurface`
  - Secondary: `AppColors.borderMetallic` → `colorScheme.outline`
  - Inner glow: `Colors.white` → `colorScheme.onSurface` (theme-aware)

- [x] **3.4** Refactor `lib/core/widgets/custom_bottom_nav.dart` (5 refs)
  - Background: `AppColors.bgVault` → `colorScheme.surface` (frosted glass adapts)
  - Border: `AppColors.borderMetallic` → `colorScheme.outline`
  - Selected icon: `AppColors.bgVoid` → `colorScheme.onPrimary`
  - Unselected icon: `AppColors.textSecondary` → `colorScheme.onSurfaceVariant`

- [x] **3.5** Refactor `lib/core/widgets/vault_card.dart` (5 refs)
  - Background: `AppColors.bgVault` → `colorScheme.surface`
  - Border: `AppColors.borderMetallic` → `colorScheme.outline`
  - Shadow: conditional opacity (0.15 light, 0.4 dark)

- [x] **3.6** Refactor `lib/core/widgets/fiat_bitcoin_toggle.dart` (6 refs)
  - Background: `AppColors.bgVault` → `colorScheme.surfaceContainerHighest`
  - Border: `AppColors.borderMetallic` → `colorScheme.outline`
  - Accent colors stay as-is (theme-aware via isBitcoinMode)

### Phase 4: Refactor Remaining Widgets (~6 files) ✅

- [x] **4.1** `lib/core/widgets/confirm_dialog.dart` (7 refs)
  - `bgVault`→`surface`, `borderMetallic`→`outline`, `textPrimary`→`onSurface`, `textSecondary`→`onSurfaceVariant`

- [x] **4.2** `lib/core/widgets/settings_section.dart` (3 refs)
  - `textPrimary`→`onSurface`, `textSecondary`→`onSurfaceVariant`

- [x] **4.3** `lib/core/widgets/store_logo_widget.dart` (4 refs)
  - Removed `isLuxeMode` parameter; use `colorScheme.surfaceContainerHighest` and `colorScheme.onSurface`

- [x] **4.4** `lib/core/widgets/shimmer/chart_skeleton.dart` (2 refs)
  - Replaced `isLuxeMode` with `colorScheme.surfaceContainerHighest`; simplified shadow logic

- [x] **4.5** `lib/core/widgets/inflation_summary_card.dart` (1 ref)
  - Replaced `scaffoldBackgroundColor == AppColors.bgVoid` with `brightness == Brightness.dark`

- [ ] **4.6** Other minor widgets with hardcoded colors

### Phase 5: Refactor Screen-Level Hardcoded Colors (~6 files) ✅

- [x] **5.1** `lib/features/dashboard/presentation/overview_tab.dart` (~9 AppColors refs, 10 isLuxeMode checks)
- [x] **5.2** `lib/features/dashboard/presentation/categories_tab.dart` (~13 AppColors refs, 12 isLuxeMode checks)
- [x] **5.3** `lib/features/dashboard/presentation/history_tab.dart` (1 AppColors ref, 5 isLuxeMode checks)
- [x] **5.4** `lib/features/dashboard/presentation/product_detail_screen.dart` (3 AppColors refs, 6 isLuxeMode checks)
- [x] **5.5** `lib/features/dashboard/presentation/dashboard_screen.dart` (1 AppColors.bgVoid ref)
- [x] **5.6** `lib/features/ai_scanner/presentation/scanner_screen.dart` (isLuxeMode extension, 2 hardcoded Color refs)

### Phase 6: Replace `isLuxeMode` Pattern ✅

- [x] **6.1** Update `LuxeTheme` extension in `app_theme.dart`
  - Changed `isLuxeMode` to check `brightness == Brightness.dark` instead of comparing scaffoldBackgroundColor
  - Added `isDarkMode` as primary getter, `isLuxeMode` as deprecated alias
  - Local `isLuxeMode` variables in screens now use `Theme.of(context).brightness == Brightness.dark`

### Phase 7: Add Toggle UI + Localization

- [x] **7.1** Add localization strings to `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`
  - `settingsDarkMode`: "Dark Mode" / "Dunkler Modus"
  - `settingsDarkModeDesc`: "Use dark theme" / "Dunkles Design verwenden"

- [x] **7.2** Add toggle to `lib/features/settings/presentation/settings_screen.dart`
  - Added `SwitchListTile.adaptive` in Preferences section (after metric toggle)
  - Icon: `Icons.dark_mode`
  - Wired to `settingsControllerProvider.notifier.setDarkMode(val)`

- [x] **7.3** Run `flutter gen-l10n` to regenerate AppLocalizations

### Phase 8: Verification

- [x] **8.1** Run `dart run build_runner build -d` (regenerate Riverpod code) — N/A (no providers modified)
- [x] **8.2** Run `flutter analyze` (fix any issues) — passes with 0 errors
- [ ] **8.3** Run `flutter test`
- [ ] **8.4** Manual test: toggle dark/light mode, verify all screens render correctly in both modes
- [ ] **8.5** Test `isBitcoinMode` × `isDarkMode` combinations (4 modes)
- [ ] **8.6** Verify SharedPreferences persistence (close and reopen app)
- [ ] **8.7** Bump app version
- [ ] **8.8** Update `docs/project_outline.md` if needed

## Key Design Decisions

1. **Default to dark mode** (`isDarkMode: true`) — preserves existing user experience
2. **Orthogonal to Bitcoin mode** — accent color and brightness are independent axes
3. **Use `Theme.of(context).brightness`** instead of scaffoldBackgroundColor comparison for mode detection
4. **Use Material 3 `ColorScheme` tokens directly** — `surface`, `surfaceContainerHighest`, `outline`, `onSurface`, `onSurfaceVariant` handle light/dark automatically
5. **Accent glow colors stay as `AppColors.*`** — they're decorative and vary by isBitcoinMode, not brightness
6. **Conditional shadows** — card shadows use darker opacity in light mode (0.15) vs dark mode (0.4)
7. **Frosted glass (`BackdropFilter`) uses `colorScheme.surface`** — naturally adapts between modes
8. **No custom `BuildContext` extension needed** — Material 3 tokens provide all required mappings

## Files Modified (estimated)

| Category | Files | Lines Changed (est.) |
|----------|-------|---------------------|
| Theme foundation | 3 | ~120 |
| MaterialApp | 1 | ~5 |
| Core widgets (Phase 3) | 6 | ~80 |
| Remaining widgets (Phase 4) | ~6 | ~60 |
| Screens (Phase 5) | ~6 | ~150 |
| Localization | 3 | ~10 |
| Settings UI | 1 | ~15 |
| **Total** | **~26** | **~500** |

## Review

### Phase 3 Refactoring (2026-03-20)
- Replaced ~39 hardcoded `AppColors.*` references with Material 3 `ColorScheme` tokens across 6 core widgets
- All changes use `Theme.of(context).colorScheme` — no custom extension needed
- `flutter analyze` passes with 0 errors (1 benign unused-element warning)
- Key mapping: `bgElevated`→`surfaceContainerHighest`, `borderMetallic`→`outline`, `textPrimary`→`onSurface`, `textSecondary`→`onSurfaceVariant`, `bgVault`→`surface`
- Material 3 tokens automatically resolve correct values for light and dark mode

### Phase 4 Refactoring (2026-03-20)
- Refactored 5 more widgets: confirm_dialog, settings_section, store_logo_widget, chart_skeleton, inflation_summary_card
- Removed `isLuxeMode` parameter from `StoreLogoWidget` (now context-based)
- Replaced `scaffoldBackgroundColor == AppColors.bgVoid` pattern with `brightness == Brightness.dark`
- `flutter analyze` passes with 0 errors across all modified files
- Key change: `isLuxeMode` check replaced with `Theme.of(context).brightness == Brightness.dark`

### Phase 5 Refactoring (2026-03-20)
- Refactored 6 screen-level files: overview_tab, categories_tab, history_tab, product_detail_screen, dashboard_screen, scanner_screen
- Replaced all `scaffoldBackgroundColor == AppColors.bgVoid` checks with `brightness == Brightness.dark`
- Replaced `AppColors.textSecondary` → `colorScheme.onSurfaceVariant`, `AppColors.bgElevated` → `colorScheme.surfaceContainerHighest`
- Replaced `AppColors.bgVoid` → `colorScheme.onPrimary` (FAB icon) / `colorScheme.surface` (gradients)
- Replaced hardcoded `Color(0xFF121212)` / `Color(0x14FFFFFF)` → `colorScheme.surface` / `colorScheme.outline` in scanner modal
- Removed unused `app_colors.dart` imports from history_tab and product_detail_screen
- `flutter analyze` passes with 0 errors
- paywall_screen.dart deferred to separate subscription feature work

### Phase 7: Add Toggle UI + Localization (2026-03-20)
- Added `settingsDarkMode` and `settingsDarkModeDesc` to both `app_en.arb` and `app_de.arb`
- Added `SwitchListTile.adaptive` with `Icons.dark_mode` in Preferences section of settings screen
- Wired toggle to `settingsControllerProvider.notifier.setDarkMode(val)`
- Ran `flutter gen-l10n` to regenerate AppLocalizations
- `flutter analyze` passes with 0 errors across all modified files
