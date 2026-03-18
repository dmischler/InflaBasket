# InflaBasket Project Documentation

Personal inflation tracking app that compares user's custom basket against official CPI metrics and monetary expansion benchmarks.

---

## 1. Tech Stack

- **Framework:** Flutter 3.41+, Dart 3.6+
- **State Management:** `flutter_riverpod` & `riverpod_annotation` (v2.5+)
- **Routing:** `go_router`
- **Database:** `drift` & `sqlite3_flutter_libs` (type-safe SQLite)
- **Charts:** `fl_chart`
- **Loading States:** `shimmer`
- **Illustrations:** `lottie`
- **Icons/Fonts:** `lucide_icons`, `google_fonts`
- **Device Features:** `camera`, `image_picker`, `image_cropper`, `mobile_scanner`
- **Subscriptions:** `purchases_flutter` (RevenueCat)
- **Network:** `dio`, `retrofit`, `openfoodfacts` (official package)
- **Images:** `cached_network_image` (favicon/logo loading with caching)

---

## 2. Database Schema (Drift)

```dart
// categories.dart
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconString => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

// products.dart
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get barcode => text().nullable()();
  TextColumn get brand => text().nullable()();
}

// purchase_entries.dart
class PurchaseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get storeName => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get priceSats => integer().nullable()();
}
```

**Additional Tables (Schema v11):**
- `category_weights` — Custom basket weighting
- `entry_templates` — Recurring purchase templates
- `price_alerts` — Per-product threshold alerts
- `external_series_cache` — CPI/M2 cached data
- `price_histories` — Monthly price history per product (NEW)

---

## 3. Architecture

**Feature-First Clean Architecture:**

```
lib/
├── main.dart
├── core/
│   ├── database/       # Drift configuration
│   ├── theme/          # Material 3 themes
│   ├── router/         # GoRouter setup
│   └── utils/          # Helpers, formatters
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   ├── entry_management/
│   ├── ai_scanner/
│   ├── subscription/
│   └── settings/
```

---

## 4. Screen Structure

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | Splash | Initialize DB, check RevenueCat |
| `/home` | Dashboard | 4 tabs: Overview, History, Categories, Settings |
| `/home/add` | Add Entry | Manual entry form |
| `/home/product/:productId` | Product Detail | Product-level view with inline shared-field edits, chart, and history |
| `/scanner` | Scanner | Camera/Gallery → AI processing → Review |
| `/paywall` | Paywall | Premium upgrade (mobile only) |
| `/settings` | Settings | Subscription, categories, templates, alerts, export |
| `/settings/categories` | Category Management | Add/Delete custom categories |
| `/settings/price-alerts` | Price Alerts | Per-product thresholds |
| `/settings/weights` | Weight Editor | Category weights for basket |

---

## 5. Inflation Calculation

**Current Method: Product-Level Average Yearly Inflation (Unweighted Mean)**

- Inflation summary is the **simple average of yearly product inflation rates**.
- No basket-cost index and no quantity weighting in basket-level inflation math.
- Selected range is shared across overview, categories, and chart logic.
- A product qualifies only if it has:
  - **Baseline**: closest entry BEFORE the selected range start
  - **Current**: latest entry INSIDE the selected range
  - Both entries must have compatible units.

`normalizedUnitPrice = price / (quantity × toBaseMultiplier)`

`productChangePct = ((currentPrice - baselinePrice) / baselinePrice) × 100`

`yearsBetween = (currentDate - baselineDate) / 365.25`

`productYearlyPct = productChangePct / yearsBetween`

`overallYearlyInflationPct = mean(productYearlyPct for all qualifying products)`

### Time Range Filter

- Available presets: **6M, 1Y, 2Y, 3Y, 5Y, 10Y, Custom**.
- Presets are shown only if:
  1. There is at least one purchase older than the range start, AND
  2. At least one product has 2+ entries total (needed for baseline + current calculation).
- Custom range always remains available and uses a start/end month picker.
- Custom end date is normalized to month-end (capped at now) so full selected month is included.

### Chart Semantics

- Baseline point is always forced to **0.0%**.
- Series is generated from **real update dates only** (plus baseline and end date).
- No interpolation and no synthetic monthly points.
- New products only affect inflation from their first available price onward.

### Bitcoin Mode

- Same unweighted yearly-rate algorithm and same qualifying-product rule.
- Uses sats converted at baseline/current entry dates via cached BTC prices.

---

## 6. AI Receipt Prompt (Gemini 2.5 Flash)

**Key Price Handling Rule:** The `price` field MUST ALWAYS contain the actual amount paid as shown on the receipt — never a normalized per-unit price. The app calculates per-unit prices internally for inflation comparisons.

**Weighted Items Examples:**
- Receipt shows "Bananas 1.2kg €2.39" → `price: 2.39`, `quantity: 1.2`, `total: 2.39`
- Receipt shows "Apples €1.99/kg 500g" → `price: 0.995`, `quantity: 0.5`, `total: 0.995`
- Receipt shows "Milk €1.49" → `price: 1.49`, `quantity: 1`, `total: 1.49`

**JSON Schema:**
```json
{
  "storeName": "string or ''",
  "date": "YYYY-MM-DD or ''",
  "items": [
    {
      "productName": "string",
      "price": number,
      "quantity": number,
      "unit": "count|gram|kilogram|ounce|pound|milliliter|liter|fluidOunce|pack|piece|bottle|can",
      "total": number,
      "suggestedCategory": "exact category from list",
      "confidence": number (0.0-1.0)
    }
  ]
}
```

**Categories:** Default categories (Food & Groceries, Restaurants & Dining Out, etc.) + user-defined custom categories.

---

## 7. Subscription Strategy (RevenueCat)

1. Create entitlement `premium` in RevenueCat
2. Initialize RevenueCat on Android/iOS only
3. Gate premium features via `isPremiumProvider`
4. Desktop/web show graceful mobile-only message

```dart
final isPremiumProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider).valueOrNull;
  return customerInfo?.entitlements.all['premium']?.isActive ?? false;
});
```

---

## 8. Implementation Status

### ✅ Completed

**Core MVP**
- Project setup, Drift schema, Riverpod architecture
- Manual entry UI, History list, SQLite CRUD
- Category seeding (12 default categories auto-created)
- Localized category display (EN/DE)

**Analytics & Dashboard**
- Inflation calculation engine (item, category, basket levels)
- Line chart (basket index history), Bar chart (category comparison)
- Top inflators/deflators list
- Date range & category filtering
- Macro comparison overlay (CPI/M2)
- External series caching for offline fallback

**AI Scanner & Monetization**
- RevenueCat integration (mobile-only)
- Paywall UI with desktop fallback
- Camera/image picker implementation
- Vision API client (OpenAI/GPT-4o)
- Receipt review & edit screen
- Bulk transaction save with rollback

**Settings & Polish**
- Settings tab with premium status
- Category management (add/delete)
- CSV export
- Recurring purchase templates
- Price alerts with notifications
- Dark/Light mode support
- Desktop (Linux) support

**Bug Fixes**
- Category dropdown (DB-sourced)
- SnackBar error feedback on Add Entry
- FocusNode leak fix
- Notes field in entries
- Receipt date parsing
- Per-item receipt review dialog
- Dynamic app version
- Category overview empty state (use all entries, not time-filtered)

**Sprint 4A-4B**
- Desktop drag & drop for receipts
- Debug premium override
- StateMessageCard UX polish
- Macro overlay source notes
- Full UI localization (13 screens)

**Sprint 5**
- AI scanner fallback model handling
- JSON truncation recovery

**Sprint 6 (iOS Launch)**
- Manual entry date restriction (5 years max)
- Premium testing bypass (`FORCE_PREMIUM` flag)
- Barcode scanner crash fix (iOS permissions)
- Dark mode chart legend color fix
- Curve baseline alignment
- Chart tooltip positioning
- X-axis tick layout fix

**v1.4.1 Barcode Scanner**
- Entry/store/category prefill fixes
- Barcode processing state reset

**v1.4.2 Local Caching**
- Product barcode storage
- Local lookup before API call
- Navigation improvement

**v1.5.0 Smart Duplicate Detection**
- Brand column (schema v10)
- Two-stage matching (barcode + fuzzy)
- Fuzzy engine (fuzzywuzzy)
- Confirmation dialog with merge option

**v1.6.0 Backup & Restore**
- Database export/import
- JSON export
- Factory reset

**v1.7.0 Smart Re-Scan & Barcode Assignment**
- Assign barcode to existing products (edit screen)
- Exact barcode lookup (<50ms local DB)
- Price prompt dialog (Cupertino style)
- Price history tracking (monthly)
- Barcode conflict detection
- German month names ("März 2026")

**v1.7.1 Export Format Selection**
- Export format dialog (SQLite/CSV/JSON)
- Linux fallback for all export types (FilePicker)
- CSV export Linux support

**FAB Swipe-Up Selection**
- Modal with Manual/Barcode/Scanner options
- Direct scanner actions in main sheet (Camera + Gallery)
- Scanner route performs delayed native picker launch after transition settles (real iOS reliability)
- Haptic feedback

**Smart Category Autocomplete**
- TypeAhead with localization-aware filtering
- Empty field on start

**v1.8.0 Smart Price Update Reminder**
- Price update reminder toggle in Settings
- Duration picker (3/6/9/12/18 months)
- Price Updates screen with collapsible store sections
- Products grouped by store → category
- Price prompt integration (reused from barcode scanner)
- Instant list refresh after saving
- Pull-to-refresh support
- Empty state with themed message

**v1.9.2 OpenFoodFacts Migration**
- Replaced custom Dio HTTP client with official `openfoodfacts` package
- Configured global UserAgent and country settings for bot protection
- Uses v3 API with targeted fields for faster response
- Preserved store parsing and category mapping logic

**v1.9.0 Inflation Engine Refactor**
- Replaced modified Laspeyres basket index with product-level unweighted mean
- Added sparse-data-aware price lookup (`latest price <= date`)
- Chart now uses exact date-based stepped points with forced 0% baseline
- Preserved fiat/bitcoin toggle with simplified shared inflation logic
- Added jump-driver metadata for chart tooltips

**v1.9.x Smart Search & Data Quality**
- Smart search triggers only after 3 characters typed
- Store name extraction with first-letter capitalization (Coop not coop)
- Duplicate detection: same product within 1 month with same price triggers user confirmation, deletes newer entry if confirmed
- Scanned products preserve fiat price in Bitcoin mode (no sat conversion)
- AI-based data curation for product matching

**v1.9.x Price Update Notifications**
- Weekly local reminders for stale product prices (smart date-scheduled)
- Notification fires on the earliest date any product exceeds the threshold
- Re-fires weekly if user dismisses without updating
- In-app popup shows exact count when opened from notification
- Permission requested when enabling setting (iOS/Android)
- Reschedules automatically when updating prices or changing settings

**v1.13.2 Chart Loading Polish**
- Reusable shimmer-based chart skeleton loaders for dashboard chart surfaces
- Time-range pill placeholders and faux line/bar chart canvases
- 8-second timeout fallback to `StateMessageCard`
- Fade transitions into loaded content
- Accessible loading semantics with dark/light shimmer palettes

**v1.13.3 Sats Backfill Reliability**
- App startup repairs entries with missing `priceSats` values automatically
- Editing an entry now recalculates sats instead of dropping the stored value

**v1.13.5 Manual Entry Search Reliability**
- Fixed manual-mode product and store autocomplete so TypeAhead suggestions open again
- Category field now keeps the selected default visible until the user starts searching
- Leaving category search without a new selection restores the current category label

**v1.13.7 Platform Scaffold Repair**
- Removed an accidental nested Flutter project from `ios/` and restored the expected iOS-only project layout
- Regenerated missing root `android/` files and missing iOS `Flutter` xcconfig files required by the Runner target
- Preserved the checked-in iOS `AppIcon.appiconset` and stopped CI from recreating `ios/`, which could strip custom icon assets from iOS builds

**v1.13.8 Android Build Hardening**
- Raised Android minSdk to 24 for `image_picker_android` compatibility and enabled multidex/desugaring for a stable plugin build
- Added scheduled-notification manifest receivers, alarm reboot permissions, and camera hardware declarations for Android Studio builds
- Added release ProGuard rules for `flutter_local_notifications` and requested exact-alarm permission alongside notification permission on Android

**v1.13.9 Duplicate Entry Auto-Discard**
- Exact duplicates are now auto-discarded for new entries when product, store, and price match within the last 30 days
- Barcode-based matching is prioritized, then product identity/name matching, before fallback fuzzy matching
- Receipt bulk import now skips exact duplicates and reports how many rows were saved vs skipped

**v1.13.10 Product Detail View**
- Added `/home/product/:productId` with product-specific chart, price-history list, and fiat/bitcoin-aware inflation facts
- History entries now expose a dedicated long-press action sheet with View Details alongside edit/delete
- Product detail supports inline editing for shared product fields (name, category, canonical store) and propagates store edits across linked entries/templates without a schema migration
- Product price-history rows reuse swipe gestures: right to edit entry-specific values, left to delete a single price entry
- Top-level product deletion removes linked entries, templates, alerts, and cached price-history rows after confirmation

**v1.13.11 Startup Duplicate Cleanup**
- On app startup, scans recent entries (last 30 days) for exact duplicates (same normalized product name + store + exact price)
- Auto-deletes newer duplicates, keeping the oldest entry in each group
- Shows localized snackbar notification with count of removed duplicates
- Runs once per app launch alongside sats repair and reminder sync

**v1.15.0 Animated Charts & Touch Highlights**
- Added 600ms chart entrance animations with reduced-motion and single-point fallbacks across dashboard overview, categories, and product detail charts
- Added touch-highlight interactions with dashed guide lines, glow-dot emphasis, debounced haptics, and safer timer-based reset handling
- Category bars now briefly brighten and pop on tap while preserving built-in tooltips and smooth implicit fl_chart transitions

**v1.16.1 Animated Empty States**
- Added bundled Lottie-based empty, loading, and error illustrations with localized accessibility labels and icon fallbacks in `StateMessageCard`
- Rolled the new illustration system across dashboard, scanner, product detail, templates, paywall, alerts, and price-update empty states using a shared asset registry for future theming
- Preserved offline reliability with local animation assets and one-shot error playback while keeping future fiat/bitcoin illustration swapping centralized

**v1.16.2 Responsive Chart Sizing**
- Replaced fixed-height chart containers with responsive sizing based on screen height
- Created shared `chart_sizing.dart` utility for consistent chart heights across app
- Charts now adapt to phone/tablet screen sizes with clamped min/max bounds
- Line chart (overview): 180-240px on phones, 220-320px on tablets
- Bar chart (categories): 200-280px on phones, 220-320px on tablets
- Fixed overflow issues on smaller screens

**v1.16.3 History Tab Scrollbar**
- Added scrollbar to history tab for better navigation through long entry lists

**v1.16.5 History Search Header Fix**
- Fixed bug where clicking search icon in history tab caused the entire header (title + filter icons) to disappear
- Restructured build method to always render the header row at the top
- Empty state now shows below the header instead of replacing it entirely

**v1.16.6 Chart Tooltip Improvements**
- Increased touch detection threshold from 10px to 35px for easier tooltip activation on overview chart
- Added tooltip margin to display tooltip above touch point, preventing finger from blocking the data

**Bitcoin Standard Mode (v1.2.1)**
- CoinGecko BTC price API
- Sats converter utility
- Bitcoin inflation providers
- Sats storage as integers
- Unified Fiat/Bitcoin toggle in Dashboard
- Auto-fetch historical BTC prices
- Provider invalidation on mode switch

**v1.17.0 Theme Simplification**
- Removed theme selection UI (settings dropdown)
- Consolidated to single Luxe Dark theme with Fiat/Bitcoin accent colors
- Theme toggle now controlled by `isBitcoinMode` setting
- Removed unused AppThemeType enum and color tokens

**v1.18.0 Store Logo Display**
- Added store logo display in history tab using favicons from store websites
- Created `StoreLogoCache` service (SharedPreferences-based) for caching store website URLs
- Created `StoreLogoWidget` with fallback chain: DuckDuckGo favicon → Vemetric API → category letter
- Added `storeWebsite` extraction to AI receipt scanner schema
- Added optional website field to entry add/edit screen
- User can manually add store website URL once, applies to all entries with same store name
- Built-in mapping for ~30 common stores (Migros, Coop, Aldi, Lidl, etc.)
- Fallback to category letter when no website available

**v1.18.4 History Search Layout Fix**
- Fixed RenderFlex error when clicking search icon in history tab
- Wrapped AnimatedCrossFade in Expanded to provide bounded width constraints to inner Row with Expanded widget

**v1.18.3 History Search Layout Fix**
- Fixed RenderFlex error when clicking search icon in history tab
- Added mainAxisSize.min to outer Row to provide bounded constraints for inner Expanded widget

**v1.18.1 History Tab Optimization**
- Removed edit icon button (long press and swipe already provide edit access)
- Store name removed from entry subtitle (now shown via store icon on left)
- Date format changed to d.M.yy (e.g., 13.3.26)
- Store icon now displays in place of category letter using StoreLogoWidget

**v1.18.6 Smooth Fiat/Bitcoin Mode Toggle**
- Removed provider invalidation on mode switch (providers auto-refresh via dependency)
- Removed AnimatedSwitcher from overview tab to prevent content flicker
- Simplified loading logic - only triggers on initial app load, not mode changes
- Content now stays stable while data updates in background
- Fixed RenderFlex overflow in summary card during AnimatedContainer animation by adding mainAxisSize.min to Row

**v1.18.9 Inflation Calculation Fix**
- Fixed inflation calculation to exclude products with only 1 price entry in the selected time range (previously counted as 0%, diluting actual inflation)
- Fixed chart to use selected time range as baseline instead of global earliest entry (chart now correctly starts at 100 for the selected period)
- Chart time frame selector now properly updates the chart view
- Both fiat and bitcoin modes fixed

**v1.18.10 Chart X-Tick Overlap Fix**
- Smart X-axis tick intervals: now never show daily ticks, only months/years based on selected date range
- Added edge handling (minIncluded/maxIncluded: false) to prevent first/last labels from overflowing chart boundaries
- Improved SideTitleFitInsideData configuration to keep labels within visible area
- Overview chart: reduced target labels from 6 to 5, added minInterval calculation for better spacing
- Product detail chart: replaced fixed intervals with dynamic interval calculation based on actual data range

**v1.19.4 Chart Overlay Alignment Fix**
- Fixed M2/inflation overlay chart offset so both curves start at exactly 0% (index 100) at the same baseline date
- Changed comparisonOverlayData to use activeInflationRangeProvider.start as baseline instead of filteredHistory.first.month
- Now finds the exact M2/inflation value at baseline date for proper rebasing

**v1.19.5 Chart Overlay Offset Fix**
- Added offset calculation in chart rendering to ensure first tooltip always starts at exactly 0%
- Offsets comparison curve so first point is always at 0%, regardless of data rebasing

**v1.20.0 FAB Redesign (X/Twitter Style)**
- Removed FAB from inside bottom navigation pill
- Added standalone floating action button positioned at bottom-right (floating above nav bar)
- FAB now has stronger glow effect (blur: 20, spread: 4) compared to selected tab (blur: 12, spread: 2)
- Uses accent color that switches between fiat green and bitcoin orange based on mode
- 56px size vs 46px pill tabs for visual hierarchy
- 4 slots instead of 5 in bottom navigation

**v1.20.2 Simple Yearly Inflation + Dynamic Ranges**
- Replaced overview summary metric with "Average yearly inflation" based on first/last in-range entries per product
- Added sats-mode yearly summary using BTC price cache at entry dates
- Range filtering now works on in-range entries only; products with fewer than two in-range entries are excluded
- Updated dashboard preset ranges to 6M/1Y/2Y/3Y/5Y/10Y + Custom, with dynamic availability by purchase presence
- Overview summary insufficient-data state now uses animated empty-state Lottie via `StateMessageCard`

**v1.20.3 Time Range + Inflation Baseline Fixes**
- Fixed time range availability logic: now shows ranges based on how far back oldest purchase spans (not just if any purchase exists in that period)
- Fixed inflation calculation: products now only count if they have a price PRIOR to the selected time range start (removed partial period fallback)
- Changed time range selector from segmented button to pill + dropdown for cleaner UI
- Changed "overviewTitle" from "Average yearly inflation" / "Durchschnittliche Jahresinflation" to "Ø Jahresinflation"

**v1.20.4 Layout Consolidation**
- Combined time range selector and M2 toggle into single Row (range left, M2 right)
- Removed "Compare with" / "Vergleichen mit" label from M2 dropdown

**v1.20.5 Layout Alignment**
- Removed "Zeitraum" / "Time Range" label from range selector dropdown to align with M2 toggle

**v1.20.6 Inflation Chart Recovery + Sparse Data Smoothing**
- Fixed flat/empty overview charts by rebuilding tracked product histories from full entry history (not only in-range rows)
- Reworked cumulative inflation line generation to monthly points with per-product forward-fill for sparse, uneven price updates
- Added 65% coverage gating for chart baseline so the first visible point starts at a representative 0% and avoids misleading low-coverage starts
- Applied the same full-history fix to Bitcoin mode chart generation and hardened range start calculations with safe month subtraction

**v1.20.7 Baseline + Range Availability Fixes**
- Fixed yearly inflation calculation to use entries WITHIN selected range only (first = baseline, last = current)
- Fixed time range availability: now checks if any product has entries spanning the range (not just oldest entry date)
- With sample data (products spanning 2 years): only 2Y range now available, 6M/1Y correctly show no inflation when no in-range pairs exist

**v1.20.9 Overall Yearly Inflation**
- Created overallYearlyInflationSummary provider independent of selected time range
- Yearly inflation now always shows average across all products' full data span, regardless of chart range selection
- Same fix applied to Bitcoin mode (overallYearlyInflationSummarySatsProvider)

**v1.20.11 Overall Item Inflation Lists**
- Created overallItemInflationList provider using all entries (not range-filtered)
- Created overallItemInflationListSatsProvider for Bitcoin mode
- Top inflators/deflators now show data from full product history, independent of selected chart range

**v1.20.12 Store Website Fix**
- Fixed store website not being saved to SharedPreferences when manually entered in add entry screen
- Added URL normalization to accept diverse inputs (https://..., www..., or bare domain)
- Added error handling for SharedPreferences operations to prevent iOS crashes

---

### 🔄 In Progress / Partially Complete

**Android Release Signing Setup**
- Android Studio debug/release builds now have the required manifest and Gradle plumbing
- Production Play Store signing config still needs to be added locally before shipping Android releases

---

### 🐛 Known Issues

*(None currently)*

---

## 9. Future Roadmap

### Near-Term (Planned)

**Sprint 4 – UI Design**
- Glassmorphism cards and blur overlays
- Speed dial FAB expansion
- Onboarding flow (3 screens)

**Sprint 5 – Code Refactor**
- Split files >250 lines
- Remove unused code
- Consolidate duplicate logic
- Clean up TODOs and tech debt
- Dependency audit

**Feature: Expand Macro Sources**
- Additional CPI sources (US BLS, UK ONS, BoJ)
- M3 / balance sheet overlays
- Multiple simultaneous overlays

---

### Long-Term (Platform Expansion)

| Feature | Status | Tier |
|---------|--------|------|
| AI Weekly Insights | Planned | Premium |
| Price Forecasts (ML) | Planned | Premium |
| Home-Screen Widgets | Planned | Free |
| Family Sharing | Planned | Premium |
| Cloud Backup (iCloud/GDrive) | Planned | Free |
| User Auth & Cross-Device Sync | Planned | Premium |
| Voice Entry | Planned | Premium |
| Loyalty Card Scanner | Planned | Premium |
| Seasonal/Location Insights | Planned | Premium |
| CSV Import | Planned | Free |
| History Search & Advanced Filters | Planned | Free |
| Batch Operations in History | Planned | Free |

---

## 10. Production Checklist

- [ ] Replace RevenueCat API key placeholder in `subscription_providers.dart`
- [ ] Replace Vision API key in `vision_client.dart` (move to backend proxy recommended)
- [ ] Complete onboarding flow

---

## 11. Starter Commands

```bash
flutter create --org com.yourdomain inflabasket --platforms ios,android
cd inflabasket
flutter pub add flutter_riverpod riverpod_annotation go_router drift sqlite3_flutter_libs path_provider path fl_chart google_fonts dio purchases_flutter camera image_picker
flutter pub add -d build_runner drift_dev riverpod_generator custom_lint riverpod_lint
dart run build_runner build -d
```
