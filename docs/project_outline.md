# InflaBasket Flutter Cross-Platform Development Plan – Ready to Build

Here is the complete, production-grade development roadmap for **InflaBasket**, designed to deliver a high-performance, beautiful, and highly functional mobile application using the latest Flutter and Dart advancements.

---

## 1. App Overview & Prioritized User Stories

**Overview:** InflaBasket empowers users to track their personal inflation rate by logging everyday purchases. By comparing their custom "basket" against official CPI metrics, users gain actionable insights into their spending power and category-level price trends.

**Prioritized User Stories (Agile Epics):**
- **Epic 1: Core Tracking (Free)**
  - *As a user, I want to manually log a purchase (product, price, store, date) so I can track it.*
  - *As a user, I want to categorize my items so I can see which areas of my life are getting more expensive.*
- **Epic 2: Analytics & Dashboard (Free)**
  - *As a user, I want to see a line chart of my overall basket inflation over the last 3, 6, and 12 months.*
  - *As a user, I want to see a side-by-side comparison of inflation by category.*
- **Epic 3: AI Magic & Monetization (Premium)**
  - *As a premium user, I want to snap a photo of my grocery receipt and have the app automatically extract and categorize every item.*
  - *As a user, I want a smooth paywall experience to upgrade to premium.*

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
  TextColumn get location => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real()(); // Store exact decimal
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
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

1.  **Splash / Bootstrap (`/`)**: Initializes DB, checks RevenueCat entitlement.
2.  **Dashboard (`/home`)**:
    - Tab 1: **Overview** (Overall Inflation Index, Top Inflators/Deflators, Line Chart).
    - Tab 2: **History** (List of past entries, filterable by date and category).
    - Tab 3: **Categories** (Cross-category bar charts).
    - Tab 4: **Settings** (Premium status, Manage Categories).
3.  **Add Entry Modal (`/home/add`)**:
    - Manual Entry form.
    - "Scan Receipt (Premium)" button.
4.  **Scan Flow (`/scanner`)**:
    - Camera/Gallery -> Loading (AI Processing) -> Review Screen -> Save.
5.  **Paywall (`/paywall`)**: Shown if Free user taps "Scan Receipt".
6.  **Settings (`/settings`)**:
    - Subscription status.
    - Manage Categories.
    - Export Data (Placeholder).
7.  **Category Management (`/settings/categories`)**:
    - Add/Delete custom categories.

---

## 6. Inflation Calculation Logic

**1. Item-Level Inflation:**
`((CurrentPrice - BasePrice) / BasePrice) * 100`
*(BasePrice is the first recorded price of the product, or the average price from a specific past window).*

**2. Category-Level Inflation:**
Weighted average. Sum of `(Item_Inflation * Item_Total_Spend)` / `Total_Category_Spend`.

**3. Basket-Level Inflation (Modified Laspeyres Index):**
Compare the cost of the *exact same basket of goods* over time.
$Index_t = \frac{\sum (Price_{t} \times Quantity_{base})}{\sum (Price_{base} \times Quantity_{base})} \times 100$
If the index moves from 100 to 105, the user's personal inflation is 5%.

---

## 7. Exact AI Receipt Prompt Template

*Target: xAI Grok Vision / GPT-4o*

```
You are an expert receipt parser. Analyze the provided receipt image.
Extract the store name, date, and all individual line items.
For each item, provide a "suggestedCategory" strictly chosen from this list: [Groceries, Dairy, Meat, Beverages, Household, Personal Care, Electronics, Transportation, Dining Out]. If none fit perfectly, deduce the closest match.
Return ONLY a valid JSON object matching this schema, without markdown formatting:

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
4.  **UX:** If `!isPremium`, show "Scan Receipt (Premium)" button that navigates to Paywall.

---

## 9. Implementation Status (As of March 2026)

### ✅ Completed Features

**Phase 1: MVP**
- [x] Project setup, Drift schema, Riverpod architecture.
- [x] Manual entry UI (`/home/add`).
- [x] Basic list view (`History` tab).
- [x] SQLite CRUD operations via `EntryRepository`.
- [x] **Category Seeding:** Default categories (Food & Groceries, Dairy, Meat, Beverages, Household, Personal Care, Electronics, Fuel/Transportation, Dining Out) are automatically created on first launch.

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

**Phase 3: AI Scanner & Monetization**
- [x] RevenueCat integration (SubscriptionController, OfferingsProvider).
- [x] Paywall UI (`/paywall`) with Upgrade/Restore buttons.
- [x] Camera implementation (`ScannerScreen` using `image_picker`).
- [x] Vision API Client (`VisionClient` using `dio` to connect to OpenAI/GPT-4o).
- [x] Review & Edit Screen for AI-extracted items.

**Phase 4: Settings & Polish**
- [x] **Settings Tab:** Added to bottom navigation.
- [x] **Premium Status:** Shows active status in Settings.
- [x] **Category Management UI:** Add/Delete custom categories (`/settings/categories`).
- [x] **Location Tracking:** Added "Location (City/Branch)" field to manual entry and history view.
- [x] Dark/Light mode support via Material 3.
- [x] Desktop (Linux) support enabled.

**Sprint 2: Bug Fixes & Polish**
- [x] **Category Dropdown:** Replaced free-text category input in Add Entry with a `DropdownButtonFormField` sourced from the database via `categoriesProvider`. Ensures data consistency for inflation calculations.
- [x] **Error Feedback:** `Add Entry` screen now shows a `SnackBar` when `submitEntry` throws, surfacing errors to the user instead of failing silently.
- [x] **FocusNode Fix:** `AsyncAutocompleteField` converted to `StatefulWidget`; `FocusNode` now created in `initState` and disposed in `dispose`, eliminating the per-build leak.
- [x] **Notes Field:** Added optional `notes` field to Add Entry form and the database column is now surfaced in the History list tile (italic, muted, collapsed to 1 line).
- [x] **Receipt Date Parsing:** AI Scanner now parses the `date` field returned by the Vision API and uses it for all saved entries, instead of always using `DateTime.now()`.
- [x] **Scanner Bulk Transaction:** Items from receipt scanning are now saved in a single `database.transaction()` with full rollback if any item fails.
- [x] **Per-Item Receipt Review:** Replaced the "Save All or Cancel" scanner dialog with a full stateful `_ReceiptReviewDialog`: per-item checkboxes to deselect, inline product name editing, and category dropdown per item. A "Select All / Deselect All" toggle and item count on the Save button are included.
- [x] **Dynamic Version:** Settings screen now reads the app version from `pubspec.yaml` via `package_info_plus` instead of using a hardcoded `'1.0.0'` string.

### 📝 Production Configuration (Not Code)
- Replace `'appl_apiKey'` / `'goog_apiKey'` placeholders in `subscription_providers.dart` with real RevenueCat keys before store submission.
- Replace `'YOUR_API_KEY'` in `vision_client.dart`; ideally move to a backend proxy rather than bundling the key in the binary.

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
  - Settings, Category Management, Location Tracking.
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

1. **Edit/Delete History Entries** ✅ — Swipe-to-delete and long-press to edit in the History tab.
2. **Autocomplete for Manual Entry** ✅ — TypeAhead dropdown on Product, Store, and Location fields.
3. **CSV Export** ✅ — Settings → Export Data, implemented via `ExportService` using `CsvEncoder` + `share_plus`.
4. **Default Currency & Units** ✅ — CHF default with metric/imperial toggle, persisted via `SharedPreferences`.

### Sprint 2 – Bug Fixes & Polish ✅ COMPLETE

5. **Category Dropdown** ✅ — DB-sourced `DropdownButtonFormField` in Add Entry (replaces free-text input).
6. **Add Entry Error Feedback** ✅ — SnackBar shown on `submitEntry` failure.
7. **FocusNode Fix** ✅ — `AsyncAutocompleteField` converted to `StatefulWidget` to prevent per-build FocusNode leak.
8. **Notes Field** ✅ — Optional notes in Add Entry form; displayed in History tile.
9. **Receipt Date Parsing** ✅ — AI scanner uses the date from the receipt JSON response, not `DateTime.now()`.
10. **Scanner Bulk Transaction** ✅ — `bulkAddFromReceipt()` wraps all inserts in a single `database.transaction()`.
11. **Per-Item Receipt Review** ✅ — Stateful review dialog with per-item checkboxes, editable names, category dropdowns, and Select All toggle.
12. **Dynamic App Version** ✅ — Version read from `pubspec.yaml` via `package_info_plus`.

---

### v2.0 – Core Intelligence

These features add meaningful analytical depth and require moderate implementation effort.

5. **LLM Duplicate Detection (Premium)** — When adding a new entry, call Gemini Flash to check if the product name is semantically similar to an existing product in the DB (e.g., "Whole Milk 1L" vs "Bio Vollmilch"). Prompt the user to link to the existing product or create a new one. Improves basket accuracy.
6. **Product Normalization** — Normalize prices to a per-unit basis (e.g., CHF/kg, CHF/L) regardless of pack size. Makes price comparisons meaningful across different package sizes.
7. **Custom Basket Weighting** — Allow users to assign percentage weights to categories (e.g., 40% Food, 20% Transport) to compute a truly personalized inflation index.
8. **Official CPI Comparison** — Fetch Swiss BFS CPI or Eurostat data via public API. Display a chart overlay: "Your Inflation vs. National Average." Validates user data against macroeconomic reality.
9. **Localization (i18n)** — Full German (de), French (fr), Italian (it), and English (en) support using `flutter_localizations` + `intl` ARB files. Critical for Swiss market.
10. **Barcode Scanner** — Scan a product barcode using the device camera. Auto-fill product name and suggested category via the Open Food Facts public API. Speeds up manual entry significantly.
11. **Recurring Purchase Templates** — Save entries as templates for weekly/bi-weekly staples (e.g., "Weekly grocery run"). One-tap re-entry with pre-filled fields.
12. **Price Change Alerts (Premium)** — Local push notifications when a tracked product's latest price exceeds a configurable threshold (e.g., +10% vs last entry).

---

### v3.0 – Premium Intelligence & Ecosystem

Long-term features that expand the product into a platform.

13. **AI Weekly Insights (Premium)** — Gemini Flash text-analysis generates a weekly summary: "Your grocery spend is up 8% vs last month, driven by Dairy." Delivered as an in-app card or push notification.
14. **Forecasts & Trends (Premium)** — ML-based price forecasting for tracked products using historical entry data. Shows projected cost of basket in 3/6 months.
15. **Home-Screen Widgets** — iOS and Android home-screen widgets showing the current basket inflation index at a glance.
16. **Family / Multi-User Sharing (Premium)** — Share a basket with household members. Each member logs purchases; data is merged into a single household inflation view. Monetized as a family plan tier.
17. **Cloud Backup & Sync** — iCloud (iOS) and Google Drive (Android) backup for purchase history. Enables device migration and restores.
18. **Voice Entry (Premium)** — Dictate a purchase ("Milk, 2.50, Migros") using on-device speech recognition. Parsed and pre-filled into the Add Entry form.
19. **Loyalty Card Scanner** — Scan Migros Cumulus or Coop Supercard barcodes to auto-populate the store name field and potentially link to loyalty program history via partner APIs.
20. **Seasonal & Location Insights (Premium)** — Detect seasonal price patterns (e.g., "Tomatoes are typically 30% cheaper in August") and regional price differences across logged store locations.

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
