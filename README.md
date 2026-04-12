# InflaBasket

A cross-platform Flutter mobile app (iOS + Android + Linux desktop) that lets users track personal inflation of their own custom "basket" of everyday items by logging purchases over time and visualizing price changes with category-level insights.

---

## Requirements

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| **Flutter SDK** | 3.41+ | [Install via flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.6+ | Comes with Flutter |
| **Git** | Any recent | For version control |

### Platform-Specific Requirements

#### Linux Desktop
```bash
# Ubuntu/Debian
sudo apt install cmake ninja-build clang pkg-config libgtk-3-dev lld binutils

# Fedora
sudo dnf install cmake ninja-build clang pkgconfig gtk3-devel lld binutils

# Arch Linux
sudo pacman -S cmake ninja clang pkgconfig gtk3 lld binutils
```

#### macOS
- Xcode Command Line Tools: `xcode-select --install`
- CocoaPods: `sudo gem install cocoapods`

#### Windows
- Visual Studio Build Tools with C++ support
- Windows 10 SDK

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd InflaBasket
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Generate Code (Required)

This project uses code generation for Riverpod and Drift:

```bash
dart run build_runner build -d
```

> **Note:** This generates `.g.dart` files. These are committed to the repository since they depend on the exact SDK version.

### 4. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d linux
flutter run -d android
flutter run -d ios

# Run in debug mode (faster iteration)
flutter run --debug

# Run in release mode (production)
flutter run --release
```

---

## Building for Production

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK (unsigned)
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app.apk`

### iOS

```bash
# For simulator (no signing required)
flutter build ios --simulator --no-codesign

# For device (requires Apple Developer account)
flutter build ios --release
```

### Linux Desktop

```bash
# Debug build
flutter build linux --debug

# Release build
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/inflabasket`

---

## Project Architecture

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── database/database.dart         # Drift SQLite database
│   └── router/app_router.dart        # GoRouter navigation
└── features/
    ├── dashboard/                     # Main dashboard tabs
    │   ├── application/               # Riverpod providers
    │   └── presentation/               # UI screens
    ├── entry_management/              # Purchase entry CRUD
    ├── ai_scanner/                   # Receipt scanning (user API key)
    └── settings/                     # App settings
```

### Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `drift` | Local SQLite database |
| `go_router` | Declarative routing |
| `fl_chart` | Charts and graphs |
| `google_generative_ai` / `dart_openai` | AI receipt parsing (user-provided API keys) |
| `dio` | HTTP client for AI APIs |
| `image_picker` | Camera/gallery access |

---

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## Common Issues

### Linux Desktop: Missing GTK3
```
Error: GTK3 not found
```
**Fix:** Install GTK3 development libraries (see Platform-Specific Requirements above)

### Build Runner Errors
```
Error: Generator ... was not found
```
**Fix:** Run `flutter pub get` then `dart run build_runner build -d`

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Drift (SQLite) Docs](https://drift.so/)

---

## License

MIT License
