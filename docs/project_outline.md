# InflaBasket Flutter Cross-Platform Development Plan – Ready to Build

Here is the complete, production-grade development roadmap for **InflaBasket**, designed to deliver a high-performance, beautiful, and highly functional mobile application using the latest Flutter and Dart advancements.

---

## 1. App Overview & Prioritized User Stories

**Overview:** InflaBasket empowers users to track their personal inflation rate by logging everyday purchases. By comparing their custom "basket" against official CPI metrics and monetary expansion benchmarks such as M2 money supply, users gain actionable insights into their spending power and category-level price trends.

**Prioritized User Stories (Agile Epics):**
- **Epic 1: Core Tracking (Free)**
  - *As a user, I want to manually log a purchase (product, price, store, date) so I can track it.*
  - *As a user, I want to categorize my items so I can see which areas of my life are getting more expensive.*
- **Epic 2: Analytics & Dashboard (Free)**
  - *As a user, I want to see a line chart of my overall basket inflation over the last 3, 6, and 12 months.*
  - *As a user, I want to see a side-by-side comparison of inflation by category.*
- **Epic 3: AI Magic & Monetization (Premium)**
  - *As a premium user, I want to snap a photo of my grocery receipt and have the app automatically extract and categorize every item.*
  - *As a premium user, I want to ask natural-language questions about my data ("Why did my meat inflation spike?") and receive AI answers.*
  - *As a user, I want a smooth paywall experience to upgrade to premium.*
- **Epic 4: Family Sharing (Premium)**
  - *As a family-plan user, I want household members to contribute to a shared basket with per-person contribution views.*

---

## 2. Recommended Tech Stack & Full Package List

- **Core:** Flutter 3.41+, Dart 3.6+
- **State Management:** `flutter_riverpod` & `riverpod_annotation` (v2.5+) - Type-safe, testable, and robust.
- **Routing:** `go_router` - Declarative deep-linking and nested navigation.
- **Local Database:** `drift` & `sqlite3_flutter_libs` - Type-safe SQLite with reactive streams.
- **UI & Visuals:**
  - `fl_chart`: For highly customizable, beautiful line and bar charts.
  - `google_fonts`: Typography.
  - `lucide_icons`: Modern, clean iconography.
- **Device Features:** `camera`, `image_picker`, `image_cropper`.
- **Monetization:** `purchases_flutter` (RevenueCat) - Industry standard for cross-platform subscriptions.
- **Network (AI API):** `dio`, `retrofit` - Type-safe REST client for communicating with Vision APIs.

---

## 3. Database Schema (Drift)

We will use a relational structure to allow complex grouping and historical tracking.

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
}

// purchase_entries.dart
class PurchaseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get storeName => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real()(); // Store exact decimal
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()(); // UnitType.name; null = count
  TextColumn get notes => text().nullable()();
}
```

---

## 4. Project Structure & Architecture

We will strictly adhere to **Feature-First Clean Architecture**:

```text
lib/
 ├── main.dart
 ├── core/
 │    ├── database/       # Drift configuration
 │    ├── theme/          # Material 3 / Cupertino themes
 │    ├── router/         # GoRouter setup
 │    └── utils/          # Calculation helpers, formatting
 ├── features/
 │    ├── dashboard/
 │    │    ├── presentation/ # Charts, DashboardScreen
 │    │    ├── application/  # Providers for inflation calculation
 │    │    └── data/         # Repositories fetching DB streams
 │    ├── entry_management/  # Manual entry forms
 │    ├── ai_scanner/       # Camera, Image Picker, Vision API client
 │    ├── subscription/     # RevenueCat paywall, entitlement state
 │    └── settings/         # Settings and category management
```

---

## 5. Detailed Screen Flow & Navigation Structure

1.  **Splash / Bootstrap (`/`)**: Initializes DB, notifications, and checks RevenueCat entitlement on supported mobile platforms.
2.  **Dashboard (`/home`)**:
    - Tab 1: **Overview** (Overall Inflation Index, Top Inflators/Deflators, Line Chart, selectable CPI/M2 macro overlay).
    - Tab 2: **History** (List of past entries, filterable by date and category).
    - Tab 3: **Categories** (Cross-category bar charts).
    - Tab 4: **Settings** (Premium status, Manage Categories).
3.  **Add Entry Modal (`/home/add`)**:
    - Manual Entry form.
    - "Save as Template" shortcut for recurring purchases.
    - "Scan Receipt (Premium)" button.
4.  **Scan Flow (`/scanner`)**:
    - Camera/Gallery -> Loading (AI Processing) -> Review Screen -> Save.
5.  **Paywall (`/paywall`)**: Shown if Free mobile user taps "Scan Receipt"; desktop/web show a graceful mobile-only subscriptions message.
6.  **Settings (`/settings`)**:
    - Subscription status.
    - Manage Categories.
    - Category Weights.
    - Recurring Purchase Templates.
    - Price Alerts.
    - Export Data (CSV).
7.  **Category Management (`/settings/categories`)**:
    - Add/Delete custom categories.
8.  **Price Alerts (`/settings/price-alerts`)**:
    - Per-product threshold configuration.
    - Enable/disable alerts for tracked products.

---

## 6. Inflation Calculation Logic

**1. Item-Level Inflation (Unit-Normalised):**

All prices are normalised to a canonical base unit before comparison:
- Mass: CHF/g (g, kg, oz, lb all convert to g)
- Volume: CHF/ml (ml, l, fl oz all convert to ml)
- Count: CHF/item

`normalizedUnitPrice = price / (quantity × toBaseMultiplier)`

Inflation is then: `((currentNormPrice - baseNormPrice) / baseNormPrice) × 100`

This means shrinkflation (e.g. 500g → 450g at the same sticker price) shows up
as an effective price increase of ~11.1%, just as it should.

Cross-unit comparisons are allowed when both entries measure the same dimension
(e.g. g↔kg, ml↔l, oz↔lb, g↔oz). Entries with incompatible units (e.g. kg vs l)
are skipped — the newer entry becomes a new baseline.

**2. Category-Level Inflation:**
Weighted average. Sum of `(Item_Inflation × Item_Total_Spend)` / `Total_Category_Spend`.

**3. Basket-Level Inflation (Modified Laspeyres Index):**
Compare the cost of the *exact same basket of goods* over time.
$Index_t = \frac{\sum (Price_{t} \times Quantity_{base})}{\sum (Price_{base} \times Quantity_{base})} \times 100$
If the index moves from 100 to 105, the user's personal inflation is 5%.

Base-basket quantities are stored in base units (g/ml), so a 500g → 450g
repackaging is correctly reflected in the index without any manual adjustment.

---

## 7. Exact AI Receipt Prompt Template

*Target: Google Gemini 3.1 Flash Lite*

```
You are an expert receipt parser. Analyze the provided receipt image.
Extract ONLY actual purchased product items - exclude ALL non-product lines.

STRICTLY EXCLUDE these categories of entries:
- Tax lines (VAT, sales tax, GST, HST, "tax", "TVA", "MwSt")
- Summary lines ("subtotal", "sub-total", "total", "grand total", "sum", "amount due")
- Discount/coupon lines ("discount", "rabatt", "réduction", "sconto", "coupon", "cashback")
- Payment lines ("cash", "card", "credit", "debit", "payment", "change", "tendered", "rendu")
- Store metadata (addresses, phone numbers, website, return policies, store numbers)
- Promotional text (buy one get one, "free", "bonus", "points")
- Blank or meaningless lines

INCLUDE ONLY:
- Individual product/line items that have both a product name AND a price
- Each distinct purchased item should appear only ONCE
- For quantities > 1, include both unit price and total price

For each valid item, provide a "suggestedCategory" strictly chosen from this list: [Food & Groceries, Dairy, Meat, Beverages, Household, Personal Care, Electronics, Fuel/Transportation, Dining Out] plus any user-created custom categories currently stored in the app. If none fit perfectly, deduce the closest match from the provided list.
Return a valid JSON object matching this schema, without markdown formatting:

{
  "storeName": "string",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "productName": "string",
      "price": number,
      "quantity": number,
      "total": number,
      "suggestedCategory": "string",
      "confidence": number (0.0 to 1.0)
    }
  ]
}
```

Note: The prompt also includes client-side post-processing validation that:
- Filters out items with empty/whitespace names
- Filters out items with zero/negative prices
- Filters out items matching tax/total/discount/payment patterns
- Deduplicates by productName (case-insensitive)

---

## 8. Subscription Strategy (RevenueCat)

1.  **Setup:** Configure Apple App Store and Google Play Console products. Connect to RevenueCat.
2.  **Entitlement:** Create an entitlement called `premium`.
3.  **Enforcement:**
Create a Riverpod provider `subscriptionControllerProvider`.
```dart
final isPremiumProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider).valueOrNull;
  return customerInfo?.entitlements.all['premium']?.isActive ?? false;
});
```
4.  **Platform Gating:** Only initialize RevenueCat on Android/iOS. Desktop and web stay on a safe free-tier path and surface mobile-only messaging instead of throwing plugin errors.
5.  **UX:** If `!isPremium`, show "Scan Receipt (Premium)" button that navigates to Paywall on supported mobile platforms.

---

## 9. Implementation Status (As of March 2026)

### ✅ Completed Features

**Phase 1: MVP**
- [x] Project setup, Drift schema, Riverpod architecture.
- [x] Manual entry UI (`/home/add`).
- [x] Basic list view (`History` tab).
- [x] SQLite CRUD operations via `EntryRepository`.
- [x] **Category Seeding:** Default categories (Food & Groceries, Restaurants & Dining Out, Beverages, Transportation, Fuel & Energy, Housing & Rent, Utilities, Healthcare & Medical, Personal Care & Hygiene, Household Supplies, Clothing & Apparel, Electronics & Tech) are automatically created on first launch.
- [x] **Localized Category Display:** Default categories remain stored as canonical English keys in Drift, while the UI localizes them for `en` and `de`. User-created custom categories remain exactly as typed and are never translated.

**Phase 2: Data Visualization & Analytics**
- [x] **Inflation Calculation Engine:**
  - Item-level inflation (Base vs Current price).
  - Category-level weighted inflation.
  - Basket-level Laspeyres Index calculation.
- [x] **fl_chart Integration:**
  - Line chart for Basket Index History (`Overview` tab).
  - Bar chart for Category comparison (`Categories` tab).
- [x] **Top Inflators/Deflators:** Visual lists showing biggest price increases and decreases.
- [x] **History Filtering:**
  - Date range filter (Last 30 days, Last 6 months, All time).
  - Category filter.
  - Implemented via bottom sheet modal.
- [x] **Macro Comparison Overlay:** Overview chart can compare the user's basket against official CPI or central-bank / public-data money-supply series, depending on the selected currency.
- [x] **Macro Series Reliability:** External CPI and M2 series are cached locally for offline fallback and transient API / certificate-failure recovery.

**Phase 3: AI Scanner & Monetization**
- [x] RevenueCat integration (SubscriptionController, OfferingsProvider) with Android/iOS-only initialization and graceful desktop/web fallback.
- [x] Paywall UI (`/paywall`) with Upgrade/Restore buttons on mobile and a safe unsupported-platform state on desktop/web.
- [x] Camera implementation (`ScannerScreen` using `image_picker`).
- [x] Vision API Client (`VisionClient` using `dio` to connect to OpenAI/GPT-4o).
- [x] Review & Edit Screen for AI-extracted items.

**Phase 4: Settings & Polish**
- [x] **Settings Tab:** Added to bottom navigation.
- [x] **Premium Status:** Shows active status in Settings.
- [x] **Category Management UI:** Add/Delete custom categories (`/settings/categories`).
- [x] **Export Data:** Settings → Export Data (CSV) implemented via `ExportService`.
- [x] **Recurring Purchase Templates:** Settings → Templates plus direct "Save as Template" from Add Entry.
- [x] **Price Alerts Settings UI:** Settings → Price Alerts (`/settings/price-alerts`) for per-product threshold configuration.
- [x] Dark/Light mode support via Material 3.
- [x] Desktop (Linux) support enabled.

**Sprint 2: Bug Fixes & Polish**
- [x] **Category Dropdown:** Replaced free-text category input in Add Entry with a `DropdownButtonFormField` sourced from the database via `categoriesProvider`. Ensures data consistency for inflation calculations.
- [x] **Error Feedback:** `Add Entry` screen now shows a `SnackBar` when `submitEntry` throws, surfacing errors to the user instead of failing silently.
- [x] **FocusNode Fix:** `AsyncAutocompleteField` converted to `StatefulWidget`; `FocusNode` now created in `initState` and disposed in `dispose`, eliminating the per-build leak.
- [x] **Notes Field:** Added optional `notes` field to Add Entry form and the database column is now surfaced in the History list tile (italic, muted, collapsed to 1 line).
- [x] **Receipt Date Parsing:** AI Scanner now parses the `date` field returned by the Vision API and uses it for all saved entries, instead of always using `DateTime.now()`.
- [x] **Scanner Bulk Transaction:** Items from receipt scanning are now saved in a single `database.transaction()` with full rollback if any item fails.
- [x] **Per-Item Receipt Review:** Replaced the "Save All or Cancel" scanner dialog with a full stateful `_ReceiptReviewDialog`: per-item checkboxes to deselect, inline product name editing, category dropdown, unit selector, and price field (for correcting AI-extraction errors or unit mismatches) per item. A "Select All / Deselect All" toggle and item count on the Save button are included.
- [x] **Dynamic Version:** Settings screen now reads the app version from `pubspec.yaml` via `package_info_plus` instead of using a hardcoded `'1.0.0'` string.

**Sprint 4A: Launch Readiness & Desktop Scanner UX**
- [x] **Desktop Receipt Drag & Drop:** `ScannerScreen` now supports dragging and dropping receipt images on Linux/macOS/Windows via `desktop_drop`, with a desktop-specific drop zone and file-type validation.
- [x] **Debug Premium Override:** Premium-gated flows now unlock automatically in `kDebugMode`, enabling local testing of receipt scanning, duplicate detection, and price-alert notifications without an active RevenueCat entitlement.
- [x] **Polished Empty/Loading States:** Added reusable `StateMessageCard` UX for scanner processing, history empty states, templates, price alerts, and paywall loading/error/unsupported states.
- [x] **Macro Overlay Source Notes:** Overview now exposes an info sheet describing the current CPI/M2 source by currency and improves overlay loading feedback.

**Sprint 4B: Full UI Localization**
- [x] **Zero hardcoded English strings in UI:** All 13 screens now route every user-facing string through `AppLocalizations`. No literal English text remains in any presentation layer file.
- [x] **Screens fully localized:** `DashboardScreen`, `HistoryTab`, `CategoriesTab`, `OverviewTab`, `AddEntryScreen`, `DuplicateDialog`, `ScannerScreen`, `SettingsScreen`, `TemplatesScreen`, `PriceAlertsScreen`, `CategoryManagementScreen`, `WeightEditorScreen`, `PaywallScreen`.
- [x] **Category display fix in WeightEditorScreen:** `_WeightSliderTile` now receives the localized display name via `CategoryLocalization.displayNameForContext()` rather than the raw canonical DB key.
- [x] **DuplicateDialog simplified:** Removed `_NameRow` helper widget; duplicate prompt now uses the `duplicateDetectionMessage(newName, existingName)` interpolated ARB key for clean localized output.
- [x] **Helper method refactors for l10n:** `_showFilterSheet` (HistoryTab), `_buildBarChart`/`_buildCategoryList` (CategoriesTab), `_showOverlaySourceInfo`/`_overlaySourceDescription` (OverviewTab), and `_save` (ScannerScreen) were updated to accept `AppLocalizations` as a parameter where needed.

**Sprint 5: Reliability & Polish**
- [x] **AI Scanner Fallback Model:** VisionClient now catches `GenerativeAIException` with 503/UNAVAILABLE errors and automatically retries with `gemini-3-flash-preview` fallback model. Logs fallback attempts for debugging.
- [x] **JSON Truncation Recovery:** VisionClient now handles truncated/incomplete JSON responses from the AI by attempting to recover valid JSON. Uses bracket-balancing algorithm to find the last complete object and parse it. Falls back to extracting just the items array if needed. If recovery fails, throws the original error.

### Sprint 6: iOS Launch Bug Fixes

**Bugs Fixed:**
1. **Manual Entry Date Restriction** ✅ — Limit manual item adding to maximum 5 years back from current date.
2. **Premium Testing Bypass** ✅ — Extended beyond `kDebugMode` to support `--dart-define=FORCE_PREMIUM=true` for TestFlight/App Store testing. Updated `codemagic.yaml` to include this flag in iOS builds.
3. **Barcode Scanner Crash** ✅ — Fixed crash when clicking barcode scanner on iOS:
   - Added error handling in `barcode_scan_dialog.dart`: try/catch around controller initialization, `_onDetect` callback, and controller start/stop operations.
   - Added iOS permissions template (`ios_config/Info.plist.template`) with `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.
   - Updated `codemagic.yaml` to copy Info.plist template after iOS project generation.
4. **Dark Mode SNB Curve Color** ✅ — Fixed legend color to match chart: updated `_buildChartLegend` to accept `isLuxeMode` parameter and use `isLuxeMode ? AppColors.textSecondary : Colors.orange` for the overlay curve dot, matching the chart's color logic.
5. **Curve Baseline Alignment** ✅ — Both inflation curves now start at 100% baseline: overlay data is rebased to the first data point of the filtered basket history.
6. **Chart Hover Tooltip Positioning** ✅ — Added `fitInsideHorizontally: true` to `LineTouchTooltipData` in overview_tab.dart to prevent tooltips from extending beyond chart edges.
7. **Overview Chart X-Ticks Clipping** ✅ — Increased chart height from 250 to 280 and added `reservedSize: 32` to bottom axis titles in overview_tab.dart to prevent xticks from being cut off when there are large price increases.

**Bugs to Fix:**
7. **Reduce Text in Settings** ✅ — Removed section headers and subtitles; shortened premium/free subtitles; reduced spacing from 24px to 12px.
8. **App Icon** — Add app icon.
9. **Dynamic X-Axis Time Ticks** ✅ — Overview graph x-axis ticks currently only show month (e.g., "Mar") without year. Make ticks dynamic depending on date range:
    - Short ranges (≤6 months): Show month + day (e.g., "Mar 15")
    - Medium ranges (6mo - 2y): Show month + year (e.g., "Mar '24")
    - Long ranges (>2y): Show year only or year + month (e.g., "2024")
    - Implementation in `overview_tab.dart`: Modify `_buildLineChart` to calculate tick count based on available width and apply date format based on `ChartTimeRange` selection.
10. **Remove Location Field** ✅ — Removed location (City/Branch) field from items as it's not important for inflation tracking. Removed from database schema (v6), Add Entry form, History display, CSV export, and localization strings.

**New Features:**
14. **FAB Swipe-Up Selection** ✅ — When clicking the FAB, show a swipe-up modal bottom sheet with options to "Scan Receipt" (camera), "Select from Photos", or "Add Manually". These three choices should be named/labeled consistently as "scanning", "selecting from photos", and "manual" throughout the app. This allows non-premium users to access manual entry without hitting the paywall.
    - Implemented via `AddEntryBottomSheet` widget in `lib/core/widgets/add_entry_bottom_sheet.dart`
    - Scanner options auto-open camera or gallery when navigating to `/scanner` with `initialSource` parameter
    - Premium-gated items show "Premium feature" badge for non-premium users
    - Desktop shows "Not available on desktop" message for scan receipt option
15. **Monthly Aggregated Comparison Data** — Instead of discrete item data points, sample and compare inflation data at monthly intervals. Store items with month+year granularity and sample the inflation curve accordingly for smoother comparisons.
16. **Core Inflation Comparison Bars** — In the Categories tab, if categorized core inflation data is available (e.g., from CPI sources), display a comparison bar next to each category's actual inflation bar. Show the difference between user's category inflation and official core inflation for that category.
17. **Factory Reset** ✅ — Added option in Settings to revert to factory settings. Shows confirmation dialog with warning before deletion. Clears all SQLite tables (purchase entries, products, templates, alerts, weights, external series cache, categories), re-seeds default categories, and clears all SharedPreferences. Sets `hasCompletedOnboardingKey` to `false` to support future onboarding feature. Navigates to home screen after reset.

### Timeline Selector Feature (Overview & Categories)

**Goal:** Allow users to filter chart data by time range (YTD, 1y, 2y, 3y, 5y, 10y, All) or custom date range. Both Overview and Categories tabs share the same filter state.

**UI Implementation:**
1. `SegmentedButton` in the Overview tab header (next to the overlay selector)
2. Options: `YTD`, `1y`, `2y`, `3y`, `5y`, `10y`, `All` (or custom date picker)
3. Dynamically shows only options where data exists (e.g., if only 8 months of data, shows YTD, 1y, All)
4. Styled consistently with existing overlay selector
5. **Categories Tab** applies the selected time filter to category inflation calculations via `filteredEntriesWithDetailsProvider`

**Data Model:**
1. `ChartTimeRange` enum in `entry_providers.dart`:
   ```dart
   enum ChartTimeRange {
     ytd,      // Year to Date
     oneYear,  // Last 12 months
     twoYears, // Last 24 months
     threeYears, // Last 36 months
     fiveYears,// Last 60 months
     tenYears, // Last 120 months
     allTime,  // All available data
     custom,   // User-selected date range
   }
   ```
2. `customStartDate` and `customEndDate` fields for custom range

**Monthly Aggregation:**
- Inflation calculations aggregate data by month (year-month) rather than individual item entries
- When calculating category and basket inflation, entries are grouped by year-month and compute average prices per product for that period
- Chart data points represent monthly samples for smoother curve visualization
- Dates stored with day-of-month normalized (e.g., always 1st of month) for consistent grouping

**State Management:**
1. `ChartTimeFilterController` Riverpod provider (persisted in SharedPreferences)
2. `filteredBasketIndexHistoryProvider` wraps `basketIndexHistoryProvider` and filters by selected time range
3. `filteredEntriesWithDetailsProvider` filters entry data for category inflation calculations
4. `comparisonOverlayDataProvider` respects the time filter

**Key Files Modified:**
- `lib/features/entry_management/application/entry_providers.dart` — `ChartTimeRange` enum and `ChartTimeFilterController`
- `lib/features/dashboard/presentation/overview_tab.dart` — Timeline selector UI
- `lib/features/dashboard/presentation/categories_tab.dart` — Timeline selector with time filter applied to category inflation
- `lib/features/dashboard/application/inflation_providers.dart` — Added `filteredEntriesWithDetailsProvider` and `filteredBasketIndexHistoryProvider`
- `lib/core/api/cpi_provider.dart` — Overlay data fetching respects time filter

### 📝 Production Configuration (Not Code)
- Replace `'appl_apiKey'` / `'goog_apiKey'` placeholders in `subscription_providers.dart` with real RevenueCat keys before store submission.
- Replace `'YOUR_API_KEY'` in `vision_client.dart`; ideally move to a backend proxy rather than bundling the key in the binary.
- Keep RevenueCat purchase flows mobile-only unless/until desktop support is added upstream.

---

## 10. Phased Implementation Roadmap

- **Phase 1: MVP (Weeks 1-2)** ✅ COMPLETE
  - Project setup, Drift schema, Riverpod architecture.
  - Manual entry UI, basic list view, standard SQLite CRUD operations.
- **Phase 2: Data Visualization (Weeks 3-4)** ✅ COMPLETE
  - Implement math/calculation layer.
  - Integrate `fl_chart` for Dashboard line charts and category bar charts.
- **Phase 3: AI Scanner & Monetization (Weeks 5-6)** ✅ COMPLETE
  - RevenueCat integration and Paywall UI.
  - Camera implementation, API client setup for Grok/GPT-4o.
  - Review/Edit screen for parsed receipt data.
- **Phase 4: Polish & Launch (Weeks 7-8)** ✅ COMPLETE
  - Settings, Category Management.
  - Dark/light mode, bottom navigation polish.
  - Beta testing (TestFlight / Play Console Internal).

---

## 11. Potential Challenges & Mitigations

- **Challenge:** AI Hallucinations / Bad JSON.
  - *Mitigation:* Use strict JSON mode APIs if available. Wrap the API call in a robust `try/catch` with fallback parsing. Allow users to manually edit the extracted data before saving to Drift.
- **Challenge:** Changing Product Names (e.g., "Kroger Milk 1 Gal" vs "Whole Milk 1G").
  - *Mitigation:* Implement a simple fuzzy string matching or allow the user to link a receipt item to an existing product in their DB during the review phase.
- **Challenge:** Cross-Platform UI consistency.
  - *Mitigation:* Stick to Material 3 widgets with adaptive constructors (`Switch.adaptive()`, `Slider.adaptive()`) to automatically render Cupertino styles on iOS.

---

## 13. Future Roadmap

### Sprint 1 – Quick Wins ✅ COMPLETE

1. **Edit/Delete History Entries** ✅ — Swipe-to-delete and explicit edit button (pencil icon) in the History tab. Long-press to edit was unreliable on Linux desktop due to a known Flutter gesture limitation with Dismissible widgets.
2. **Autocomplete for Manual Entry** ✅ — TypeAhead dropdown on Product and Store fields.
3. **CSV Export** ✅ — Settings → Export Data, implemented via `ExportService` using `CsvEncoder` + `share_plus`.
4. **Default Currency & Units** ✅ — CHF default with metric/imperial toggle, persisted via `SharedPreferences`.
5. **CSV Import (Free)** — Settings → "Import Data". Drag-and-drop on desktop or file picker on mobile. Column mapper preview, duplicate detection (same LLM heuristic), progress bar, and rollback transaction. Same format as export for seamless round-trip.
6. **History Search & Advanced Filters (Free)** — Add a persistent search bar (product name, store, notes) using Drift's CustomExpression full-text search. Combine with existing date/category filters. Live results via Riverpod stream.
7. **Batch Operations in History (Free)** — Long-press → multi-select mode (checkboxes + "Select All"). Bulk delete, re-categorize, or add notes. Confirmation dialog with count. Undo via SnackBar + local cache.
8. **Auto-detect Similar Product** — Implement functionality to auto-detect similar product names during entry creation to prevent duplicates and improve data consistency.

### Sprint 2 – Bug Fixes & Polish ✅ COMPLETE

5. **Category Dropdown** ✅ — DB-sourced `DropdownButtonFormField` in Add Entry (replaces free-text input).
6. **Add Entry Error Feedback** ✅ — SnackBar shown on `submitEntry` failure.
7. **FocusNode Fix** ✅ — `AsyncAutocompleteField` converted to `StatefulWidget` to prevent per-build FocusNode leak.
8. **Notes Field** ✅ — Optional notes in Add Entry form; displayed in History tile.
9. **Receipt Date Parsing** ✅ — AI scanner uses the date from the receipt JSON response, not `DateTime.now()`.
10. **Scanner Bulk Transaction** ✅ — `bulkAddFromReceipt()` wraps all inserts in a single `database.transaction()`.
11. **Per-Item Receipt Review** ✅ — Stateful review dialog with per-item checkboxes, editable names, category dropdowns, unit selectors, price fields, and Select All toggle.
12. **Dynamic App Version** ✅ — Version read from `pubspec.yaml` via `package_info_plus`.

---

### Sprint 3 – v2.0 Core Intelligence ✅ COMPLETE

5. **LLM Duplicate Detection (Premium)** ✅ — On product name submission, a normalised LCS-similarity heuristic checks the category's existing product names. If a close match (>70%) is found, a `DuplicateDialog` prompts "Link to Existing" or "Create New". Full semantic LLM call deferred (VisionClient is image-only; a dedicated chat endpoint is a future iteration).
6. **Price Anomaly Detection (Premium)** ✅ — When saving a new entry, compare the submitted unit price against the existing product's historical average. If the new price deviates significantly (>3x or <0.33x the historical average), prompt the user with a `PriceAnomalyDialog`: "This price seems different from your last entry of [Product] at [Price] ([Date]). Is the unit correct?" Options: "Save Anyway", "Edit Price", "Edit Unit". This catches common errors like confusing kg vs g, l vs ml, or 6-pack vs single unit.
6. **Product Normalization** ✅ — Already fully implemented in Sprint 1 via `unit.dart` (`UnitType` enum, `normalizedPricePerUnit`) and `inflation_providers.dart` (`normalizePricePerUnit` helper). No changes required.
7. **Custom Basket Weighting** ✅ — `WeightEditorScreen` (`/settings/weights`) presents one `Slider` per category. Values validate to 100%. `CategoryWeightsController` persists fractions to the `category_weights` DB table (schema v3). `basketInflation()` uses custom weights when set; otherwise falls back to spend-weighted averaging.
8. **Official CPI + Money Supply Comparison** ✅ — `CpiClient` now uses Eurostat SDMX 3.0 monthly HICP index feeds with bounded history windows for supported CPI currencies: CHF → Switzerland (`M.I15.CP00.CH`), EUR → EU27 aggregate (`M.I15.CP00.EU27_2020`). `MoneySupplyClient` fetches currency-specific broad-money data with time-range filtering: CHF → SNB M2, EUR → ECB M2 stocks, USD → FRED M2, GBP → Bank of England M2. `OverviewTab` lets users switch the overlay between CPI and M2 when available, rebasing external series to the same 100-index baseline for visual comparison. External macro series are cached in Drift for offline fallback and transient TLS/network/API failures; if refresh fails, the app falls back to the latest cached series before degrading to an empty overlay.
9. **Localization (i18n)** ✅ — `flutter_localizations` + `gen_l10n` ARB pipeline with 2 locales: `en`, `de`. Unsupported device locales fall back to English. `l10n.yaml` uses `synthetic-package: false`; import path is `package:inflabasket/l10n/app_localizations.dart`. The Settings screen now includes a manual language selector.
10. **Barcode Scanner** ✅ — `mobile_scanner` (replaces unused `camera`) powers `BarcodeScanDialog` (modal bottom sheet with live preview). `OpenFoodFactsClient` calls the OFF API and maps PNNS categories → InflaBasket categories. Barcode `IconButton.filledTonal` added next to the Product Name field in `AddEntryScreen`.
    - **Premium default** — When adding a new entry, premium users are taken directly to the receipt scanner from the FAB; non-premium users continue to the manual entry form.
11. **Recurring Purchase Templates** ✅ — `TemplatesScreen` (`/settings/templates`) lists `watchTemplatesWithDetails()` stream. Swipe-to-delete with confirmation. "Use" button opens `AddEntryScreen` pre-filled via a synthetic `EntryWithDetails`. `AddEntryScreen` also exposes a direct "Save as Template" action backed by `AddTemplateController.addTemplateFromForm()`.
12. **Price Change Alerts (Premium)** ✅ — `flutter_local_notifications` wrapper (`NotificationService`) is initialised in `main()`. `PriceAlertService.checkAndNotify()` compares new purchases against the prior logged price and fires a local notification when the configured threshold is crossed (Premium only). Alert config is persisted in the `price_alerts` DB table (schema v3), and users can manage thresholds from `PriceAlertsScreen` (`/settings/price-alerts`).

**Schema changes (v3/v4):**
- **v3:** Added 3 tables in a single migration: `category_weights` (PK: categoryId), `entry_templates` (autoincrement id), `price_alerts` (PK: productId).
- **v4:** Added `external_series_cache` (composite PK: `source + currency + metric + month`) to persist cached CPI and M2 observations plus fetch timestamps.

**Bug fixes in this sprint:**
- `appDatabaseProvider` changed to `@Riverpod(keepAlive: true)` with `ref.onDispose(db.close)`.
- `HistoryFilter.copyWith` null-sentinel bug fixed: `categoryId: null` now correctly clears the filter.
- `DashboardScreen` tabs wrapped in `IndexedStack` to preserve scroll state on tab switch.
- RevenueCat plugin calls are now platform-gated so desktop/web no longer throw expected `MissingPluginException`s during startup or paywall flows.
- CPI fetch failures are now logged by error type and degrade safely without breaking the dashboard chart experience.
- Added parser/regression tests for Eurostat SDMX, ECB SDMX, FRED CSV, Bank of England CSV, SNB M2 extraction, request-window sizing, rebasing, and cache freshness behavior.

---

### Sprint 4 – UI Design Iteration

A complete visual overhaul to modernize the app with contemporary design patterns, smoother animations, and improved usability. **The overarching design theme should draw inspiration from the Fiat vs. Bitcoin Standard dichotomy** — the UI should visually contrast traditional finance (gold/blue tones, classic typography, established iconography) with the Bitcoin ecosystem (orange accents, modern geometric shapes, futuristic elements), creating a cohesive visual language that reinforces the app's core purpose of comparing fiat inflation against Bitcoin purchasing power.

27. **Dark Mode Support** ✅ — Complete. Implemented via Material 3 `ThemeMode` (light/dark/system). Theme preference persisted via `SharedPreferences`. Toggle available in Settings.

28. **Glassmorphism & Neumorphism Updates** — Replace flat Material 3 surfaces with subtle glassmorphism effects (frosted glass cards, blur overlays) in key areas like the dashboard header, scanner modal, and paywall. Use soft shadows and rounded corners (20-24px radius) for a tactile feel.

29. **Receipt Review Price Editing** ✅ — Complete. The Per-Item Receipt Review dialog (`_ReceiptReviewDialog`) already includes editable product name, category, unit, quantity, and price fields, plus checkboxes for selecting/deselecting items.

30. **Animated Charts** — Enhance `fl_chart` visualizations with entry animations (chart draws in on load), touch-responsive highlights, and smooth data transitions when filters change. Add haptic feedback on category bar taps.

31. **Custom Bottom Navigation** ✅ — Replaced standard `NavigationBar` with custom animated FAB-style nav: floating pill-shaped indicator with smooth slide transitions (300ms easeOutCubic), icon morphing between outline/filled states via AnimatedSwitcher, glassmorphism blur effect (BackdropFilter + ImageFilter), and theme-aware colors that react to Fiat ↔ Bitcoin toggle (Emerald #10B981 ↔ Gold #F59E0B).

32. **Skeleton Loaders** — Replace circular progress indicators with skeleton shimmer placeholders throughout the app (History list, Dashboard cards, Scanner loading) for a more polished loading experience.
    - **Current partial implementation** — key screens now use richer empty/loading/error state cards (`StateMessageCard`) for scanner, paywall, templates, price alerts, and filtered history. Full shimmer/skeleton treatment is still pending.

33. **Swipe Gestures** ✅ — Implemented swipe-to-reveal actions in History list (swipe left: delete with confirmation, swipe right: edit). Spring physics and haptic feedback deferred for future enhancement.

34. **Contextual Floating Action Button** — Add an expandable Speed Dial FAB on the Dashboard that expands into multiple actions (Add Entry, Scan Receipt, Add Template) with staggered animations.

35. **Theme Customization** — Expand beyond Dark/Light mode with a full theme builder: accent color picker, rounded/sharp corner toggle, font size scaling (accessibility), and compact/comfortable density options. Persist via `SharedPreferences`.

36. **Empty State Illustrations** — Add friendly, animated empty state illustrations (using Lottie or Rive) for: No entries yet, No categories, No templates, No price alerts configured. Replace generic "No data" text.

37. **Onboarding Flow** — New 3-screen onboarding flow with animated illustrations explaining: (1) Track purchases, (2) See your inflation, (3) Scan receipts (Premium). Skip/Next with smooth page transitions and progress indicator. Onboarding shown on first launch after fresh install; persisted flag in `SharedPreferences` controls visibility. Routes to Dashboard on completion.

38. **Expand Macro Comparison Sources** — Build on the shipped CPI/M2 overlay system with additional benchmark series and deeper controls.
    - **Current implementation** — CPI uses Eurostat SDMX 3.0 HICP for CHF/EUR; M2 uses SNB (CHF), ECB (EUR), FRED (USD), and Bank of England (GBP), with request windows sized to the visible basket-history range.
    - **Current UX enhancement** — the Overview chart now includes source-info messaging so users can inspect which CPI/M2 feed is backing the selected overlay.
    - **Additional Central Bank Inflation Metrics** — Extend beyond current CPI coverage with direct official sources such as US BLS, UK ONS, and Bank of Japan for users with multi-currency tracking.
    - **More Monetary Benchmarks** — Add alternatives such as M3, central-bank balance sheet growth, or policy-rate overlays where available.
    - **Advanced Overlay Controls** — Support multiple simultaneous overlays, rebasing modes, and source notes/tooltips so users can compare their basket against both reported inflation and money-supply expansion.

---

### Sprint 5 – Code Refactor & Cleanup

A focused effort to improve code maintainability, reduce technical debt, and prepare the codebase for future growth.

1. **Modular File Splitting** — Split any file exceeding 250 lines into smaller, focused modules:
    - Extract reusable UI widgets into separate files in `lib/core/widgets/`
    - Extract helper functions and utilities into `lib/core/utils/`
    - Extract formatters and validators into dedicated files
    - Keep screens focused on orchestration; delegate logic to providers/controllers

2. **Remove Unused Code** — Run static analysis to identify and remove:
    - Unused imports (run `flutter analyze` and address `unused_import` warnings)
    - Unused variables and parameters
    - Dead code branches (if statements that always evaluate the same)
    - Unused private methods and constants

3. **Eliminate Redundancies** — Identify and consolidate:
    - Duplicate logic across screens (e.g., date pickers, category dropdowns, form validation)
    - Repeated widget trees that could be extracted into reusable components
    - Similar data transformation code that could be unified in providers
    - Conflicting or overlapping state management patterns

4. **Clean Up Technical Debt** — Address:
    - TODO/FIXME comments older than 30 days
    - Magic numbers/strings → extract to named constants
    - Hardcoded values that should be configurable
    - Deprecated API usage (check analyzer for deprecation warnings)
    - Inconsistent naming conventions

5. **Documentation Cleanup** — Remove or update:
    - Outdated comments that no longer match the code
    - Commented-out code blocks that are no longer needed
    - Missing or incomplete doc comments on public APIs

6. **Dependency Audit** — Review `pubspec.yaml` for:
    - Unused packages that can be removed
    - Outdated package versions with potential security/bug issues
    - Overlapping functionality between packages

---

### Long-term features that expand the product into a platform.

13. **AI Weekly Insights (Premium)** — Gemini Flash text-analysis generates a weekly summary: "Your grocery spend is up 8% vs last month, driven by Dairy." Delivered as an in-app card or push notification.
14. **Forecasts & Trends (Premium)** — ML-based price forecasting for tracked products using historical entry data. Shows projected cost of basket in 3/6 months.
15. **Home-Screen Widgets** — iOS and Android home-screen widgets showing the current basket inflation index at a glance.
16. **Family / Multi-User Sharing (Premium)** — Share a basket with household members. Each member logs purchases; data is merged into a single household inflation view. Monetized as a family plan tier.
17. **Cloud Backup & Sync** — iCloud (iOS) and Google Drive (Android) backup for purchase history. Enables device migration and restores.
18. **User Authentication & Cross-Device Sync (Premium)** — Sign up / Sign in via email+password or OAuth (Google, Apple) using Firebase Auth or Supabase Auth. Authenticated users get cloud sync: purchase history, categories, templates, and settings automatically sync across all their devices in real-time. Enables seamless migration between devices and household sharing workflows.
18. **Voice Entry (Premium)** — Dictate a purchase ("Milk, 2.50, Migros") using on-device speech recognition. Parsed and pre-filled into the Add Entry form.
19. **Loyalty Card Scanner** — Scan Migros Cumulus or Coop Supercard barcodes to auto-populate the store name field and potentially link to loyalty program history via partner APIs.
20. **Seasonal & Location Insights (Premium)** — Detect seasonal price patterns (e.g., "Tomatoes are typically 30% cheaper in August") and regional price differences across logged store locations.

---

### Bitcoin Standard Mode

A toggle to view all inflation data denominated in Bitcoin (satoshis) instead of fiat currency. This feature appeals to Bitcoin users who want to track their purchasing power in BTC terms.

**Implementation Status (v1.1.1):**
- [x] **Bitcoin Price API** — CoinGecko API integration for historical BTC/fiat rates (`bitcoin_price_client.dart`)
- [x] **Bitcoin Mode Toggle** — Added `isBitcoinMode` bool in `AppSettings`, persisted via SharedPreferences
- [x] **Sats Converter Utility** — `SatsConverter` class with fiat-to-sats conversion and formatting (`sats_converter.dart`)
- [x] **Bitcoin Inflation Providers** — `itemInflationListSatsProvider` and `basketInflationSatsProvider` for sats-based inflation calculations
- [x] **Localization** — Added Bitcoin mode strings to EN/DE ARB files
- [x] **Sats Storage as Integers** — Changed `priceSats` column from REAL to INTEGER in database schema (v8) for precision

**To Complete:**
- [ ] **Sats UI Display** — Show sats values in Overview, Categories, and History tabs when Bitcoin mode is active
- [ ] **Chart Updates** — Display sats-denominated basket index in charts
- [ ] **Price Fetch on Demand** — Fetch BTC prices when viewing entries in Bitcoin mode

---

21. **Fiat/Bitcoin Toggle** — A prominent toggle in the Settings and/or Dashboard header to switch between "Fiat Standard" and "Bitcoin Standard". Persisted via `SharedPreferences`.

22. **Bitcoin-Theme UI** — When Bitcoin Standard is active, the app's color scheme switches to an orange palette (Bitcoin orange: #F7931A) throughout the UI:
    - Primary color changes from default blue/green to Bitcoin orange.
    - Accent elements, icons, and chart colors adapt to the orange theme.
    - Toggle switch itself uses orange when active.
    - Smooth animated transition between fiat (default theme) and Bitcoin (orange theme) modes.

23. **Bitcoin Price Data** — Integrate a Bitcoin price API (e.g., CoinGecko or similar free tier) to fetch historical BTC/fiat exchange rates. Store historical rates alongside purchase entries or fetch on-demand for calculations.

23. **Sats Conversion** — When Bitcoin Standard is active:
    - All purchase amounts are converted to satoshis (1 BTC = 100,000,000 sats) using the exchange rate at the time of purchase.
    - Display values in sats (or mBTC/BTC for larger amounts) throughout the UI.

24. **Bitcoin Inflation Calculation** — In Bitcoin Standard mode:
    - **Item-Level Sats Inflation:** Calculate how many more/fewer sats are required to purchase the same product now vs. in the past.
    - Formula: `((CurrentSatsPrice - BaseSatsPrice) / BaseSatsPrice) * 100`
    - This captures both fiat price inflation AND Bitcoin exchange rate changes.
    - If BTC appreciates against fiat faster than product prices rise, sats inflation may be negative (purchasing power in BTC increases).

25. **Dual-Mode Dashboard** — When Bitcoin Standard is active:
    - Show all inflation charts, category breakdowns, and totals in sats.
    - Include a secondary "Fiat Equivalent" indicator for context.
    - Line charts show sats-denominated basket index over time.

26. **Historical Rate Handling** — For each purchase entry, optionally store the BTC/fiat rate at time of purchase. If not stored, fetch historical rates from the API based on the purchase date. Cache rates locally to minimize API calls.

---

## 12. Next-Step Starter Commands

Run these in your terminal to initialize the project:

```bash
# 1. Create the project
flutter create --org com.yourdomain inflabasket --platforms ios,android

# 2. Navigate to directory
cd inflabasket

# 3. Add Core Dependencies
flutter pub add flutter_riverpod riverpod_annotation go_router drift sqlite3_flutter_libs path_provider path fl_chart google_fonts dio purchases_flutter camera image_picker

# 4. Add Dev Dependencies (Code Generation)
flutter pub add -d build_runner drift_dev riverpod_generator custom_lint riverpod_lint

# 5. Generate initial build runner files
dart run build_runner build -d
```
