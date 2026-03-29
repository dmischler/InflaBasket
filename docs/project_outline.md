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
- `price_histories` — Monthly price history per product

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
| `/settings/price-updates` | Price Updates | Products needing price refresh |
| `/settings/price-updates/settings` | Price Update Settings | Reminder configuration |
| `/settings/privacy-policy` | Privacy Policy | Legal privacy information |
| `/settings/terms-of-service` | Terms of Service | Legal terms of use |
| `/onboarding` | Onboarding | First-time user intro (3 screens) |

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

- Baseline per product: last entry BEFORE range start, or first entry INSIDE if none before.
- Products without baseline before range.start are **excluded** until first price change.
- Products at baseline contribute **0%** (not skipped).
- Inflation counts only after first price CHANGE (up or down).
- Always starts at **0%** at range.start.
- Aggregate chart: smoothed curves (current display).
- Individual product chart: **staircase** (step function).
- Each price change creates immediate step, stays flat until next change.

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

### ✅ Core Features

**Database & Architecture**
- Drift schema with categories, products, purchase_entries
- Riverpod state management with code generation
- GoRouter navigation with type-safe extras

**Entry Management**
- Manual entry form with category autocomplete
- Barcode scanner (OpenFoodFacts, OpenBeautyFacts, OpenProductsFacts)
- AI receipt scanner (Gemini 2.5 Flash)
- Duplicate detection (exact + fuzzy matching)
- Store logo display with favicon caching

**Dashboard & Analytics**
- Overview tab with inflation summary card
- History tab with search and filtering
- Categories tab with breakdown charts
- Product detail screen with charts
- Bitcoin mode (satoshis) alongside fiat

**Charts & Visualization**
- Line charts with animated entrance
- Bar charts with touch highlights
- Macro overlay (CPI, M2 money supply)
- Smart X-axis tick intervals
- Responsive chart sizing

**Settings & Configuration**
- Dark/light mode toggle
- Language selection (EN/DE)
- Currency selection (CHF, EUR, USD, GBP)
- Metric system toggle
- Category management
- Price alerts
- Price update reminders
- Database export/import (SQLite, CSV, JSON)
- Factory reset

**Legal Screens**
- Privacy policy (v1.45.1)
- Terms of service (v1.46.0)

---

### ✅ Version History

**v1.50.0** — Receipt Review UX Redesign
- Card-based layout for receipt items with visual hierarchy
- Product name as hero element (large, editable)
- Price prominently displayed on right side
- Category/unit/quantity as secondary row with chip-style containers
- Scroll-to-visible for keyboard handling (FocusNode listeners)
- Footer automatically pads when keyboard appears
- Selected items highlighted with background color change
- Improved touch targets for all interactive elements

**v1.49.0** — Auto-Save Backup
- Baseline per product: last entry before range.start, or first inside if none before
- Products without baseline before range excluded until first price change
- Products at baseline contribute 0% (not skipped)
- Inflation counts only after first price CHANGE (up or down)
- Aggregate chart: smoothed curves
- Individual product chart: staircase (step function)
- Always starts at 0% at range.start

**v1.46.0** — Terms of Service
- Added terms of service screen (Settings > About)
- 6 sections: Acceptance, Use of Service, Accounts, IP, Liability, Changes
- EN + DE localization
- Route `/settings/terms-of-service`

**v1.45.1** — Privacy Policy
- Added privacy policy screen (Settings > About)
- 6 sections: Controller, Data Collected, Storage, Sharing, GDPR Rights, Contact
- EN + DE localization
- Route `/settings/privacy-policy`

**v1.45.0** — Onboarding Flow
- 3-screen onboarding (Welcome, Modes, Start Tracking)
- Fiat vs Bitcoin mode selection cards
- SharedPreferences persistence
- GoRouter redirect for first launch

**v1.34.0–v1.36.0** — Settings Reorganization
- Renamed "Preferences" to "Appearance"
- SettingsSection widget (no collapse)
- ActionRow component for consistent list tiles

**v1.26.0–v1.26.1** — Theme System
- Dark/light mode toggle with persistence
- Theme-aware ColorScheme tokens
- 6 core widgets + 6 screens refactored
- Receipt scanner keyboard fix (iOS)

**v1.20.0–v1.20.13** — Chart & Layout Improvements
- FAB redesign (X/Twitter style)
- Time range selector improvements
- Inflation calculation fixes (baseline, range availability)
- Chart X-tick overlap fix
- Overall yearly inflation (independent of range)
- Store website fix
- AI consent dialog (Apple compliance)

**v1.19.4–v1.19.5** — Chart Overlay Alignment
- M2/inflation overlay baseline alignment
- Offset calculation for proper 0% start

**v1.18.0–v1.18.10** — History Tab & Charts
- Store logo display with favicon caching
- History search layout fixes
- Smooth fiat/bitcoin toggle
- Inflation calculation fix
- Chart X-tick optimization

**v1.16.1–v1.16.6** — UX Polish
- Animated empty states (Lottie)
- Responsive chart sizing
- History tab scrollbar
- Chart tooltip improvements

**v1.15.0** — Animated Charts
- 600ms entrance animations
- Touch highlights with guide lines
- Category bar tap effects

**v1.13.2–v1.13.11** — Stability & Product Detail
- Chart loading skeleton
- Sats backfill reliability
- Platform scaffold repair
- Android build hardening
- Duplicate entry auto-discard
- Product detail view
- Startup duplicate cleanup

**v1.9.0–v1.9.x** — Inflation Engine & Notifications
- Refactored inflation calculation
- Sparse-data-aware price lookup
- Smart search & data quality
- Price update notifications

**v1.8.0** — Price Update Reminders
- Toggle in settings
- Duration picker (3-18 months)
- Price updates screen
- Pull-to-refresh support

**v1.7.0–v1.7.1** — Barcode & Export
- Barcode assignment to existing products
- Price history tracking
- Export format selection (SQLite/CSV/JSON)

**v1.6.0** — Backup & Restore
- Database export/import
- JSON export
- Factory reset

**v1.49.0** — Auto-Save Backup
- Auto-save database after each entry
- Local folder picker for backup storage
- Cloud storage via share sheet (Google Drive, Dropbox, etc.)
- Manual backup button
- Last backup timestamp display

**v1.5.0** — Smart Duplicate Detection
- Brand column (schema v10)
- Two-stage matching (barcode + fuzzy)
- Fuzzy engine (fuzzywuzzy)

**v1.4.x** — Desktop & Barcode
- Barcode scanner fixes (iOS permissions)
- Desktop drag & drop for receipts
- Debug premium override

**v1.2.1** — Bitcoin Mode
- CoinGecko BTC price API
- Sats converter utility
- Unified Fiat/Bitcoin toggle

---

### 🔧 Fit & Finish

**Component Library**
- `LuxuryTextField`, `LuxuryDropdownField`
- `ConfirmDialog`, `CustomDateRangeDialog`
- `InflationSummaryCard`, `TimeRangeSelector`
- `ChartHeader`, `ActionRow`, `BarcodeSection`
- `ReceiptScanButton`, `PriceQuantityRow`
- `InflationLineChart`, `InflationListView`
- `TimeRangeFilterSheet`, `ChartOverlayFilterSheet`
- `StateMessageCard` (empty/loading/error states)

**Localization**
- Full EN + DE support
- 13+ screens localized
- Lottie animations with accessibility labels

**Platform Support**
- iOS, Android, Linux (desktop)
- Mobile: camera, barcode scanner, subscriptions
- Desktop: file drag & drop, graceful feature fallbacks

---

### 🔄 In Progress

**Android Release Signing**
- Android Studio builds configured
- Play Store signing config needs local setup

---

### 🐛 Known Issues

None currently.

---

## 9. Future Roadmap

### Near-Term

| Feature | Description |
|---------|-------------|
| Home-Screen Widgets | iOS/Android widgets for quick inflation view |
| CSV Import | Import entries from CSV files |
| History Search | Advanced filters in history tab |
| Batch Operations | Multi-select edit/delete in history |

### Long-Term

| Feature | Tier |
|---------|------|
| AI Weekly Insights | Premium |
| Price Forecasts (ML) | Premium |
| Family Sharing | Premium |
| Cloud Backup | Free |
| Cross-Device Sync | Premium |
| Voice Entry | Premium |
| Loyalty Card Scanner | Premium |
| Seasonal Insights | Premium |

---

## 10. Production Checklist

- [ ] Replace RevenueCat API key placeholder in `subscription_providers.dart`
- [ ] Replace Vision API key in `vision_client.dart` (move to backend proxy recommended)

---

## 11. Starter Commands

```bash
flutter create --org com.yourdomain inflabasket --platforms ios,android
cd inflabasket
flutter pub add flutter_riverpod riverpod_annotation go_router drift sqlite3_flutter_libs path_provider path fl_chart google_fonts dio purchases_flutter camera image_picker
flutter pub add -d build_runner drift_dev riverpod_generator custom_lint riverpod_lint
dart run build_runner build -d
```