# Product Overview - Add Price Entry Feature

## Progress

- [x] **Phase 1: Database Schema Changes** - COMPLETE
- [ ] Phase 2: Store Autocomplete Service
- [ ] Phase 3: Repository Updates
- [ ] Phase 4: Product Detail Provider
- [ ] Phase 5: Product Detail Screen UI
- [ ] Phase 6: Add Entry Screen Enhancement
- [ ] Phase 7: Router Updates
- [ ] Phase 8: Additional Files to Check
- [ ] Phase 9: Testing & Cleanup

## Overview

Add the ability to quickly add a new price entry from the product detail screen with all constant attributes (product name, category, store) pre-filled — user only updates price, quantity, unit, and date.

## Background

In the current database architecture:
- `Products` table stores: name, categoryId, barcode, brand
- `PurchaseEntries` table stores: productId, storeName, purchaseDate, price, quantity, unit, notes

The constraint: **store is always attached to the product** — meaning store should be a constant attribute per product, not variable per entry.

## Implementation Plan

### Phase 1: Database Schema Changes ✅ COMPLETE

**File: `lib/core/database/database.dart`**

1. Add `storeName` column to `Products` table:
   ```dart
   TextColumn get storeName => text().nullable()();
   ```

2. Bump schema version from 11 to 12

3. Add migration (v11 → v12):
   - Copy storeName from each product's latest entry to the new product.storeName field
   - This ensures backward compatibility for existing users

4. Run `dart run build_runner build -d` to regenerate drift files

**Important: Keep storeName in PurchaseEntries for v13**
- Historical entries will retain their storeName for now
- This serves as a safety net until v13 when we can clean up
- Document this in code comments

---

### Phase 2: Store Autocomplete Service

**File: `lib/features/entry_management/data/entry_repository.dart`**

Add method to get all unique store names for autocomplete:
```dart
Future<List<String>> getAllStores() async {
  final query = selectOnly(products)..addColumns([products.storeName]);
  final stores = await query.map((row) => row.read(products.storeName)).get();
  return stores.whereType<String>().toSet().toList()..sort();
}
```

---

### Phase 3: Repository Updates

**File: `lib/features/entry_management/data/entry_repository.dart`**

1. **Keep storeName in PurchaseEntries for backward compatibility** — do NOT remove it yet

2. **Add product storeName update method**:
   ```dart
   Future<void> updateProductStore(int productId, String storeName) async {
     await (update(products)..where((t) => t.id.equals(productId)))
         .write(ProductsCompanion(storeName: Value(storeName)));
   }
   ```

3. **When inserting new entries**, if `prefilledProduct?.storeName` is present, pass it as `storeName: Value(prefilledProduct.storeName)` (keep the column for backward compatibility). This makes the quick-add flow use the new default without any override UI confusion.

4. **Add getAllStores() provider**: Expose as `FutureProvider` or `AsyncValue` so UI doesn't call repository directly:
   ```dart
   @riverpod
   Future<List<String>> allStores(AllStoresRef ref) async {
     final repo = ref.watch(entryRepositoryProvider);
     return repo.getAllStores();
   }
   ```

---

### Phase 4: Product Detail Provider

**File: `lib/features/dashboard/application/product_detail_provider.dart`**

1. Update `ProductWithDetails` to include store from product (not computed from latest entry)

2. Expose `storeName` as a direct field on the product

3. Include `getAllStores()` for autocomplete suggestions

---

### Phase 5: Product Detail Screen UI

**File: `lib/features/dashboard/presentation/product_detail_screen.dart`**

1. **Add inline editable store field** (similar to category):
   - Use TypeAhead dropdown with store name autocomplete
   - Get suggestions from `getAllStores()` provider
   - When store is changed:
     - Show confirmation dialog: "Changing the store will update this product's default store. All future entries will use the new store. Historical entries keep their original data. Continue?"
     - If confirmed, update the product's storeName in database
   - Show store in the header section alongside product name and category
   - Handle NULL case: "No store set — tap to choose"

2. **Add "Add Price" button**:
   - Use header button (more discoverable than FAB)
   - Action: Navigate to AddEntryScreen with product context pre-filled

---

### Phase 6: Add Entry Screen Enhancement

**File: `lib/features/entry_management/presentation/add_entry_screen.dart`**

1. Add new parameter:
   ```dart
   final Product? prefilledProduct;
   ```

2. When `prefilledProduct` is provided:
   - Pre-fill product name, category, store (from product)
   - **Lock these fields** (non-editable, display only)
   - Lock product name field explicitly
   - Allow editing: price, quantity, unit, date, notes

3. Update UI to show locked fields as read-only (disabled TextFields or display-only chips)

---

### Phase 7: Router Updates

**File: `lib/core/router/app_router.dart`**

1. Update `/home/add` route to accept optional productId parameter

2. Pass product context to AddEntryScreen via state.extra

---

### Phase 8: Additional Files to Check

Review and update these files that may reference storeName:

- Product creation flows (if any)
- Any SELECT queries that join purchase_entries.storeName
- Price-history / statistics / reports that group by store
- Entry list views (if they display store)

---

### Phase 9: Testing & Cleanup

1. Run `flutter analyze` and fix any issues

2. Verify:
   - Existing products without storeName work (show "No store set — tap to choose")
   - New entries use product's storeName as default
   - Product detail shows store inline with edit capability
   - Quick-add flow works correctly with locked fields
   - Confirmation dialog appears when changing store

3. After first launch with migration:
   - Show one-time SnackBar: "Products now have a fixed store — quick-add enabled!"

4. Bump version: `flutter pub version --minor`

---

## Future v13 Cleanup

In v13: drop storeName from PurchaseEntries, make Products.storeName non-nullable, and run a final cleanup migration.

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/core/database/database.dart` | Add storeName to Products, schema v12, migration |
| `lib/features/entry_management/data/entry_repository.dart` | Add getAllStores(), add updateProductStore() |
| `lib/features/dashboard/application/product_detail_provider.dart` | Expose store from product, add stores provider |
| `lib/features/dashboard/presentation/product_detail_screen.dart` | Inline editable store with confirmation dialog, add price button |
| `lib/features/entry_management/presentation/add_entry_screen.dart` | Add prefilledProduct param, lock fields |
| `lib/core/router/app_router.dart` | Pass product context to AddEntryScreen |

### Additional Files to Review

- Any product creation screens/providers
- Analytics/statistics providers that group by store
- Entry list views that display store

---

## Migration SQL (Reference)

```sql
-- Copy storeName from latest entry for each product
UPDATE products
SET storeName = (
  SELECT pe.storeName
  FROM purchase_entries pe
  WHERE pe.product_id = products.id
  ORDER BY pe.purchase_date DESC, pe.id DESC
  LIMIT 1
)
WHERE EXISTS (
  SELECT 1 FROM purchase_entries pe
  WHERE pe.product_id = products.id
);
```

---

## Drift Migration Snippet (Reference)

```dart
// Correct (inside the migration list)
migrationSteps.add(
  MigrationStep(11, 12, (m) async {
    // 1. Drift auto-adds the column via schema
    // 2. Backfill storeName from latest entry
    await m.customStatement('''
      UPDATE products
      SET storeName = (
        SELECT pe.storeName
        FROM purchase_entries pe
        WHERE pe.product_id = products.id
        ORDER BY pe.purchase_date DESC, pe.id DESC
        LIMIT 1
      )
      WHERE EXISTS (
        SELECT 1 FROM purchase_entries pe
        WHERE pe.product_id = products.id
      );
    ''');
  })
);
```
