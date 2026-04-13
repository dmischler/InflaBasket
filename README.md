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

### iOS (Sideloading with Sideloadly)

Sideloadly lets you install apps on iPhone/iPad without a paid Apple Developer account ($99/year). It uses your free Apple ID for code signing.

#### Prerequisites

- [Sideloadly](https://sideloadly.fun/) installed on macOS or Windows
- iPhone/iPad running iOS 13 or later
- USB cable to connect iPhone to computer
- Free Apple ID

#### Build Steps

1. **Build the iOS app:**
   ```bash
   flutter build ios --release --no-codesign
   ```

2. **Export to .ipa:**
   ```bash
   xcodebuild -exportArchive -archive_path build/ios/archive/Runner.xcarchive \
     -exportOptionsPlist ios/ExportOptions.plist \
     -exportPath build/ios/release
   ```
   Or use Flutter's built-in export:
   ```bash
   flutter build ios --release
   # The .ipa will be in build/ios/iphoneos/Runner.ipa
   ```

3. **Sideload with Sideloadly:**
   - Connect your iPhone via USB
   - Open Sideloadly on your computer
   - Select the exported `.ipa` file
   - Enter your Apple ID email and password
   - Click **Start** to install the app

4. **Trust the app on your iPhone:**
   - Go to **Settings → General → VPN & Device Management**
   - Find your Apple ID under "Developer App"
   - Tap it and select **Trust**

#### Certificate Renewal

The free Apple ID signing certificate expires after **7 days**. To continue using the app:
1. Reconnect your iPhone to your computer
2. Open Sideloadly with the same .ipa
3. Click Start again - the app will be re-signed automatically

#### Limitations

- No push notifications
- Certificate expires every 7 days (requires re-sideloading)
- One app per Apple ID at a time (use different Apple IDs for multiple apps)

#### Resources

- [Sideloadly Download](https://sideloadly.fun/)
- [Official Sideloadly Usage Guide](https://sideloadly.fun/#how-to-use)

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
