# Task Plan

- [ ] Remove the stray nested Flutter project files from `ios/`.
- [ ] Regenerate the real root `android/` and missing iOS scaffold files from the workspace root.
- [ ] Verify the iOS `AppIcon.appiconset` remains wired into the Runner target after cleanup.
- [ ] Update project docs, capture the lesson learned, and bump the patch version.
- [ ] Run verification commands, review the diff, and commit if the platform fix is in place.

# Review

- Removed an accidental nested Flutter project from `ios/` that had polluted the platform folder with unrelated Android/Linux/macOS/Web/Windows files.
- Regenerated the missing root `android/` scaffold and the missing iOS `Flutter/*.xcconfig` files from the real workspace root.
- Verified the existing custom iOS `AppIcon.appiconset` stayed intact and is still referenced by the Runner target as `AppIcon`.
- Fixed CI so `codemagic.yaml` no longer deletes and recreates `ios/`, which would otherwise drop the checked-in iOS icon assets during remote builds.
- Realigned regenerated Android/iOS identifiers to `com.inflabasket.inflabasket`, captured the lesson, and bumped the app version to `1.13.7`.
