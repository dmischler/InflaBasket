# InflaBasket Developer Guide

Guidelines and commands for agents operating on this codebase.

---

## 1. Build, Lint & Test Commands

### Running the App
```bash
flutter run                    # Run on connected device/emulator
flutter run -d linux           # Run on specific platform
flutter run --debug            # Debug mode (faster iteration)
flutter run --release          # Release mode
```

### Code Generation (Required)
This project uses Riverpod and Drift with code generation:
```bash
dart run build_runner build -d   # Generate .g.dart files after provider/db changes
```
Always run this after modifying:
- Any file with `@riverpod` annotations
- Any file with `@Riverpod` annotations  
- Database schema in `lib/core/database/database.dart`
- Generated `.g.dart` or `.drift.dart` files

### Linting & Analysis
```bash
flutter analyze                  # Run Flutter analyzer
flutter analyze --fix            # Run with fix suggestions
```

### Testing
```bash
flutter test                          # Run all tests
flutter test test/widget_test.dart    # Run single test file
flutter test --name "pattern"         # Run tests matching pattern
flutter test --coverage               # Run with coverage report
flutter test --debug                  # Run in debug mode (faster)
```

Note: No test files currently exist in `test/`.

---

## 2. Code Style Guidelines

### Formatting
- 2 spaces for indentation (Flutter default)
- Max line length: 80 chars (soft), 120 for complex expressions
- Run `flutter format .` to format all files

### Imports (order alphabetically within groups)
1. Dart SDK imports
2. Flutter/Riverpod imports
3. Package imports (external)
4. Relative imports (`package:inflabasket/...`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
```

### Naming Conventions
| Element | Convention | Example |
|---------|------------|---------|
| Files | snake_case | `entry_providers.dart` |
| Classes | PascalCase | `class InflaBasketApp` |
| Enums/Values | PascalCase | `enum HistoryDateRange { last30Days }` |
| Functions/Variables | camelCase | `void submitEntry()` |
| Constants | camelCase | `const maxItems = 10` |
| Private members | prefix `_` | `_database` |

### Types
- Prefer `final` over `var`
- Use `const` wherever possible
- Avoid `dynamic` — use specific types or `Object?`
- Use nullable `Type?` explicitly
- Typed collections: `List<String>`, `Map<String, int>`

---

## 3. Architecture Patterns

### Riverpod
```dart
@riverpod
Stream<List<PurchaseEntry>> purchaseEntries(PurchaseEntriesRef ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchEntries();
}

@riverpod
class AddEntryController extends _$AddEntryController {
  @override
  FutureOr<void> build() {}

  Future<void> submitEntry(...) async {
    await AsyncValue.guard(() async { /* ... */ });
  }
}
```
- Always include `part 'filename.g.dart';`
- Run `dart run build_runner build -d` after changes
- NEVER edit `.g.dart` files
- Use `ref.watch()` for reactive data, `ref.read()` for one-time
- Use `AsyncValue.guard()` for async providers (NEVER manually set loading state)

### Database (Drift)
Return streams for reactivity:
```dart
Stream<List<PurchaseEntry>> watchEntries() {
  return (select(purchaseEntries)
    ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)])).watch();
}
```

Use transactions for multi-step operations:
```dart
await transaction(() async {
  await repo.insertProduct(product);
  await repo.insertEntry(entry);
});
```

### Navigation (go_router)
Pass objects via `state.extra`, not constructor parameters:
```dart
context.push('/edit', extra: entryWithDetails);
// In destination screen:
final entry = state.extra as EntryWithDetails;
```

---

## 4. Common Pitfalls

1. **Code generation** — Always run build_runner after modifying providers/database
2. **Nullable state** — Use `state = value`, not `state!.value = x`
3. **Deprecated APIs** — Watch for deprecation warnings (e.g., `DropdownButtonFormField.value`)
4. **Desktop plugins** — Some plugins don't work on Linux; wrap in try/catch with fallback
5. **CSV package** — Use `CsvEncoder` instead of deprecated `ListToCsvConverter` (v7.2.0+)
6. **SharedPreferences** — Initialize in main() before runApp()

---

## 5. File Locations

| Purpose | Path |
|---------|------|
| Main entry | `lib/main.dart` |
| Database | `lib/core/database/database.dart` |
| Router | `lib/core/router/app_router.dart` |
| Providers | `lib/features/*/application/*.dart` |
| UI Screens | `lib/features/*/presentation/*.dart` |
| Repositories | `lib/features/*/data/*.dart` |

---

## 6. Key Dependencies

- `flutter_riverpod` / `riverpod_annotation` — State management
- `drift` — SQLite database
- `go_router` — Navigation
- `fl_chart` — Charts
- `purchases_flutter` — Subscriptions
- `intl` — Number/currency formatting
- `shared_preferences` — Local settings
- `csv` / `share_plus` — Data export

## 7. Context Management

Context is your most important resource. Proactively use subagents to keep exploration, research, and verbose operations out of the main conversation.

### Use Subagents (Task tool) for:
- **Codebase exploration** — reading 3+ files to answer a question
- **Research tasks** — web searches, doc lookups, investigating how something works
- **Code review or analysis** — tasks that produce verbose output
- **Any investigation** where only the summary matters

### Stay in Main Context for:
- Direct file edits the user requested
- Short targeted reads (1-2 files)
- Conversations requiring back-and-forth
- Tasks where the user needs immediate steps

## 8. Documentation

- **Always update `docs/project_outline.md`** when adding a new feature or changing the implementation strategy. This includes:
  - Adding new features to the implementation status section
  - Updating the database schema section if tables/columns change
  - Updating the inflation calculation logic if the math changes
  - Updating the AI prompt template if receipt parsing changes
  - Adding new roadmap items to the Future Roadmap section

---

Last updated: March 2026
