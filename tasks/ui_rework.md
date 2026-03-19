# InflaBasket UI Rework Assessment

## Current State Summary

The app has a solid foundation with a cohesive dark luxe theme, good component library, and proper architecture. However, there are significant opportunities for improvement in screen complexity, consistency, and UX patterns.

---

## Design System Assessment

### Color Palette
- **Surface Tokens**: bgVoid (#050505), bgVault (#121212), bgElevated (#1E1E1E)
- **Typography**: textPrimary (#FFFFFFFF), textSecondary (#A3A3A3), textTertiary (#525252)
- **Fiat Theme**: accentFiatMain (#10B981 emerald)
- **Bitcoin Theme**: accentBtcMain (#F59E0B gold)
- **Structural**: borderMetallic (8% white)

### Strengths
1. Consistent dark luxe theme with accent color switching
2. Well-organized spacing system (AppSpacing: xs=4, sm=8, md=16, lg=24, xl=32)
3. VaultCard with metallic borders and glow effects
4. Proper Material 3 theming via AppTheme

### Weaknesses
1. ~~**Brittle Luxe mode detection**~~: ✅ Fixed with `LuxeTheme` extension
2. ~~No theme extension for custom properties~~: ✅ Fixed with `LuxeTheme` extension
3. Theme is hardcoded to dark mode only

---

## Screen Inventory

| Screen | Lines | Status |
|--------|-------|--------|
| OverviewTab | ~1367 | **Too large** - needs splitting |
| AddEntryScreen | ~760 | **Too large** - needs splitting |
| SettingsScreen | ~471 | Acceptable but dense |
| DashboardScreen | ~75 | Good |
| HistoryTab | ~400+ | Acceptable |
| CategoriesTab | ~300+ | Acceptable |
| ProductDetailScreen | ~500+ | Acceptable |

---

## Component Library

### Existing Reusable Components
| Component | File | Purpose |
|-----------|------|---------|
| VaultCard | core/widgets/vault_card.dart | Premium dark card with glow |
| CustomBottomNav | core/widgets/custom_bottom_nav.dart | Glassmorphic 4-slot nav |
| FiatBitcoinToggle | core/widgets/fiat_bitcoin_toggle.dart | Mode switcher |
| StateMessageCard | core/widgets/state_message_card.dart | Loading/error/empty states |
| AddEntryBottomSheet | core/widgets/add_entry_bottom_sheet.dart | FAB action selector |
| StoreLogoWidget | core/widgets/store_logo_widget.dart | Store favicon display |
| TabularAmountText | core/widgets/tabular_amount_text.dart | Monospace numbers |
| ChartSkeleton | core/widgets/shimmer/ | Loading placeholders |
| **LuxuryTextField** | core/widgets/luxury_text_field.dart | Luxe form field with keyboard dismissal |
| **LuxuryDropdownField** | core/widgets/luxury_dropdown_field.dart | Luxe dropdown styling |
| **ConfirmDialog** | core/widgets/confirm_dialog.dart | Standardized confirmation dialogs |
| LuxeButton | core/widgets/luxe_button.dart | Luxe styled button |

### Missing Components
1. ~~**LuxuryTextField**~~ - ✅ Implemented
2. ~~**LuxuryDropdownField**~~ - ✅ Implemented  
3. ~~**ConfirmDialog**~~ - ✅ Implemented
4. **SectionHeader** - For grouped settings
5. **ActionRow** - For list tiles with consistent styling

---

## Issues by Priority

### P0 - Critical (Screen Complexity)

#### 1. overview_tab.dart (~1367 lines)
Must split into:
- `SummaryCard` - Yearly inflation display
- `TimeRangeSelector` - Date range dropdown/pills
- `InflationChart` - Line chart with touch handling
- `TopInflatorsList` - Top 5 inflators/deflators
- `OverlayToggle` - M2/CPI comparison toggle

#### 2. add_entry_screen.dart (~760 lines)
Must split into:
- `EntryForm` - Main form container
- `ProductAutocomplete` - Product search field
- `CategoryAutocomplete` - Category search field
- `StoreAutocomplete` - Store search field
- `PriceQuantityRow` - Price + quantity + unit inputs
- `BarcodeSection` - Barcode assignment UI
- `ReceiptScanButton` - AI scanner launch

---

### P1 - High (Consistency)

#### 3. Fix Luxe Mode Detection ✅
```dart
// ✅ Implemented via LuxeTheme extension
extension LuxeTheme on ThemeData {
  bool get isLuxeMode => scaffoldBackgroundColor == AppColors.bgVoid;
  bool get isBitcoinMode => primaryColor == AppColors.accentBtcMain;
}
```

#### 4. Create LuxuryTextField Component ✅
```dart
class LuxuryTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final FocusNode? focusNode;
  // ... full implementation in core/widgets/luxury_text_field.dart
}
```

#### 5. Standardize Dialog Patterns ✅
- ✅ Created `ConfirmDialog` helper in `core/widgets/confirm_dialog.dart`
- Provides `ConfirmDialog.show()` factory method
- Helper methods: `showDelete()`, `showDiscardChanges()`
- Recommendation: Use Material `AlertDialog` via `ConfirmDialog` helper

---

### P2 - Medium (UX Polish)

#### 6. Settings Screen Organization
Current: Long undifferentiated list
Suggested:
- Group into collapsible sections using `ExpansionTile` or `Card` headers
- Sections: Account, Preferences, Data, About

#### 7. Keyboard Dismissal (Known Issue)
Receipt review dialog: iOS keyboard can't be dismissed
Solution options:
- "Done" button overlay in top-right
- Tap outside field to dismiss
- Scroll-to-dismiss gesture
- ✅ Added `LuxuryTextField.dismissKeyboard()` static helper
- ⚠️ Still needs integration into receipt review dialog

#### 8. Empty State Consistency
Screens with empty states should all use `StateMessageCard` with Lottie animations.

---

### P3 - Low (Future)

#### 9. Pull-to-Refresh
Add to History tab for manual data refresh

#### 10. Bottom Sheet Filters
Replace inline dropdown filters with bottom sheet pattern

#### 11. Onboarding Flow
Per roadmap: 3-screen onboarding for new users

---

## Navigation Analysis

### Current Routes (go_router)
```
/home                    → DashboardScreen
  /home/add             → AddEntryScreen (extra: EntryWithDetails/ProductInfo)
  /home/product/:id     → ProductDetailScreen
/scanner                → AIScannerScreen
/barcode                → BarcodeScreen
/settings/categories    → CategoryManagementScreen
/settings/price-alerts   → PriceAlertsScreen
/settings/price-updates  → PriceUpdatesScreen
/paywall                → PaywallScreen
```

### Issues
1. Heavy `state.extra` type casting - fragile
2. No type-safe argument passing
3. Suggestion: Consider `extra` wrapper class for type safety

---

## Implementation Plan

### Phase 1: Component Creation ✅ (v1.27.0)
1. ✅ Create `LuxuryTextField` in `core/widgets/luxury_text_field.dart`
   - Dark luxe InputDecoration styling with focus states
   - Built-in keyboard dismissal support via static `dismissKeyboard()` helper
   - All standard TextFormField props supported
2. ✅ Create `LuxuryDropdownField` in `core/widgets/luxury_dropdown_field.dart`
   - Consistent dark luxe dropdown styling
   - `LuxuryDropdownButton` variant for simpler use cases
3. ✅ Fix Luxe mode detection with theme extension
   - Added `LuxeTheme` extension to `ThemeData` in `app_theme.dart`
   - `isLuxeMode` and `isBitcoinMode` getters
   - Updated `scanner_screen.dart` to use extension
4. ✅ Create `ConfirmDialog` helper in `core/widgets/confirm_dialog.dart`
   - `ConfirmDialog.show()` factory method
   - `ConfirmDialogHelpers` with `showDelete()` and `showDiscardChanges()`

### Phase 2: Screen Splitting
1. Split `overview_tab.dart` into 5 smaller components
2. Split `add_entry_screen.dart` into reusable form components
3. Extract `BarcodeSection` to own widget

### Phase 3: Settings Rework
1. Group settings into collapsible sections
2. Add section headers
3. Standardize all dialogs to Material

### Phase 4: UX Polish
1. Fix iOS keyboard dismissal
2. Add pull-to-refresh to History
3. Review all empty states

---

## Verification Checklist

After each phase:
- [ ] `flutter analyze` passes with no errors
- [ ] `dart run build_runner build -d` if providers modified
- [ ] Test on iOS simulator
- [ ] Test on Android emulator
- [ ] Test dark mode rendering
- [ ] Verify keyboard dismissal works on iOS
- [ ] Check all empty states render correctly
