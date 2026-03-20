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

### Phase 2: Wire Up MaterialApp (1 file)

- [ ] **2.1** Update `lib/main.dart` `MaterialApp.router`
  - `theme: AppTheme.getLuxeLightTheme(isBitcoinMode: settings.isBitcoinMode)`
  - `darkTheme: AppTheme.getLuxeDarkTheme(isBitcoinMode: settings.isBitcoinMode)`
  - `themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light`
  - Remove hardcoded `themeMode: ThemeMode.light`

### Phase 3: Refactor Core Widgets (~6 files, highest impact)

These widgets are used everywhere — fixing them fixes most screens.

- [ ] **3.1** Refactor `lib/core/widgets/luxury_dropdown_field.dart` (15 hardcoded refs)
  - Replace `AppColors.bgElevated` → `Theme.of(context).colorScheme.surfaceContainer`
  - Replace `AppColors.textPrimary` → `Theme.of(context).colorScheme.onSurface`
  - Replace `AppColors.borderMetallic` → theme-aware border color

- [ ] **3.2** Refactor `lib/core/widgets/luxury_text_field.dart` (8 hardcoded refs)
  - Same pattern: replace hardcoded AppColors with theme-aware resolution

- [ ] **3.3** Refactor `lib/core/widgets/luxe_button.dart` (5 refs)
  - Background, text, border colors from theme

- [ ] **3.4** Refactor `lib/core/widgets/custom_bottom_nav.dart` (5 refs)
  - Background, border, indicator colors from theme

- [ ] **3.5** Refactor `lib/core/widgets/vault_card.dart` (5 refs)
  - Background, border colors from theme

- [ ] **3.6** Refactor `lib/core/widgets/fiat_bitcoin_toggle.dart` (6 refs)
  - Background, border from theme; accent colors stay as-is

### Phase 4: Refactor Remaining Widgets (~6 files)

- [ ] **4.1** `lib/core/widgets/confirm_dialog.dart` (7 refs)
- [ ] **4.2** `lib/core/widgets/settings_section.dart` (3 refs)
- [ ] **4.3** `lib/core/widgets/store_logo_widget.dart` (4 refs)
- [ ] **4.4** `lib/core/widgets/chart_skeleton.dart` (2 refs)
- [ ] **4.5** `lib/core/widgets/inflation_summary_card.dart` (1 ref)
- [ ] **4.6** Other minor widgets with hardcoded colors

### Phase 5: Refactor Screen-Level Hardcoded Colors (~6 files)

- [ ] **5.1** `lib/features/dashboard/presentation/overview_tab.dart` (~9 AppColors refs, 10 isLuxeMode checks)
- [ ] **5.2** `lib/features/dashboard/presentation/categories_tab.dart` (~13 AppColors refs, 12 isLuxeMode checks)
- [ ] **5.3** `lib/features/dashboard/presentation/history_tab.dart` (1 AppColors ref, 5 isLuxeMode checks)
- [ ] **5.4** `lib/features/dashboard/presentation/product_detail_screen.dart` (3 AppColors refs, 6 isLuxeMode checks)
- [ ] **5.5** Other screens with hardcoded AppColors

### Phase 6: Replace `isLuxeMode` Pattern

- [ ] **6.1** Update `LuxeTheme` extension in `app_theme.dart`
  - Change `isLuxeMode` to check `brightness == Brightness.dark` instead of comparing scaffoldBackgroundColor
  - Or rename to `isDarkMode` for clarity
  - Update all ~69 call sites across ~10 files

### Phase 7: Add Toggle UI + Localization

- [ ] **7.1** Add localization strings to `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`
  - `settingsDarkMode`: "Dark Mode" / "Dunkler Modus"
  - `settingsDarkModeDesc`: "Use dark theme" / "Dunkles Design verwenden"

- [ ] **7.2** Add toggle to `lib/features/settings/presentation/settings_screen.dart`
  - Add `SwitchListTile.adaptive` in Preferences section (after metric toggle)
  - Icon: `Icons.dark_mode`
  - Wire to `settingsControllerProvider.notifier.setDarkMode(val)`

- [ ] **7.3** Run `flutter gen-l10n` to regenerate AppLocalizations

### Phase 8: Verification

- [ ] **8.1** Run `dart run build_runner build -d` (regenerate Riverpod code)
- [ ] **8.2** Run `flutter analyze` (fix any issues)
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
4. **Extend `ColorScheme`** with custom tokens where needed, but prefer standard Material 3 tokens
5. **Color resolution helper** — consider adding an extension on `BuildContext` like `context.colors.bgVault` that returns the right color for the current mode, reducing boilerplate in widgets

## Files Modified (estimated)

| Category | Files | Lines Changed (est.) |
|----------|-------|---------------------|
| Theme foundation | 3 | ~120 |
| MaterialApp | 1 | ~5 |
| Core widgets | ~12 | ~200 |
| Screens | ~6 | ~150 |
| Localization | 3 | ~10 |
| Settings UI | 1 | ~15 |
| **Total** | **~26** | **~500** |

## Review

*To be filled after implementation*
