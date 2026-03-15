# InflaBasket Project Documentation

Personal inflation tracking app that compares user's custom basket against official CPI metrics and monetary expansion benchmarks.

---

## 1. Tech Stack

- **Framework:** Flutter 3.41+, Dart 3.6+
- **State Management:** `flutter_riverpod` & `riverpod_annotation` (v2.5+)
- **Routing:** `go_router`
- **Database:** `drift` & `sqlite3_flutter_libs` (type-safe SQLite)
- **Charts:** `fl_chart`
- **Icons/Fonts:** `lucide_icons`, `google_fonts`
- **Device Features:** `camera`, `image_picker`, `image_cropper`, `mobile_scanner`
- **Subscriptions:** `purchases_flutter` (RevenueCat)
- **Network:** `dio`, `retrofit`, `openfoodfacts` (official package)

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
| `/scanner` | Scanner | Camera/Gallery → AI processing → Review |
| `/paywall` | Paywall | Premium upgrade (mobile only) |
| `/settings` | Settings | Subscription, categories, templates, alerts, export |
| `/settings/categories` | Category Management | Add/Delete custom categories |
| `/settings/price-alerts` | Price Alerts | Per-product thresholds |
| `/settings/weights` | Weight Editor | Category weights for basket |

---

## 5. Inflation Calculation

**Current Method: Product-Level Personal Inflation (Unweighted Mean)**

- Inflation is defined as the **simple average of individual active product price changes**.
- No basket-cost index, no quantity weighting in inflation math.
- Each product uses sparse/irregular updates with **latest known price <= target date**.

`normalizedUnitPrice = price / (quantity × toBaseMultiplier)`

`productChangePct = ((price_at_end - price_at_start) / price_at_start) × 100`

`overallInflationPct = mean(productChangePct for all active products with valid data)`

### Chart Semantics

- Baseline point is always forced to **0.0%**.
- Series is generated from **real update dates only** (plus baseline and end date).
- No interpolation and no synthetic monthly points.
- New products only affect inflation from their first available price onward.

### Bitcoin Mode

- Same unweighted product-change algorithm.
- Prices are converted to sats at each product update date using cached BTC prices.

---

## 6. AI Receipt Prompt (Gemini 3.1 Flash Lite)

```
You are an expert receipt parser. Analyze the provided receipt image.
Extract ONLY actual purchased product items - exclude ALL non-product lines.

STRICTLY EXCLUDE:
- Tax lines (VAT, sales tax, GST)
- Summary lines (subtotal, total, grand total)
- Discount/coupon lines
- Payment lines (cash, card, change)
- Store metadata
- Promotional text

INCLUDE ONLY:
- Individual product items with name AND price

Return JSON:
{
  "storeName": "string",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "productName": "string",
      "price": number,
      "quantity": number,
      "suggestedCategory": "string",
      "confidence": number (0.0 to 1.0)
    }
  ]
}
```

Categories: `[Food & Groceries, Dairy, Meat, Beverages, Household, Personal Care, Electronics, Fuel/Transportation, Dining Out]` + custom categories.

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
- Push notifications when products need price updates
- Toggle moved to left side of header
- Notification bell icon positioned on right side

**v1.10.10 iOS App Icon Fix**
- Added missing Contents.json to AppIcon.appiconset

**Bitcoin Standard Mode (v1.2.1)**
- CoinGecko BTC price API
- Sats converter utility
- Bitcoin inflation providers
- Sats storage as integers
- Unified Fiat/Bitcoin toggle in Dashboard
- Auto-fetch historical BTC prices
- Provider invalidation on mode switch

---

### 🔄 In Progress / Partially Complete

- **Sats UI Display** — Overview shows sats when Bitcoin mode active (partially complete)
- **Chart Skeleton Loaders** — Partial (StateMessageCard exists, full shimmer pending)

---

### 🐛 Known Issues

*None currently*

---

## 9. Future Roadmap

### Near-Term (Planned)

**Sprint 4 – UI Design**
- Glassmorphism cards and blur overlays
- Animated charts with touch highlights
- Speed dial FAB expansion
- Theme customization (accent color, density)
- Empty state illustrations (Lottie/Rive)
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
| Auto-detect Similar Product | Planned | Free |

---

## 10. Production Checklist

- [ ] Replace RevenueCat API key placeholder in `subscription_providers.dart`
- [ ] Replace Vision API key in `vision_client.dart` (move to backend proxy recommended)
- [ ] Configure iOS Info.plist permissions (camera, photo library)
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
