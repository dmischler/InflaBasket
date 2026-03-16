# Task Plan

- [x] Review the regenerated Android scaffold and confirm the missing release-build requirements.
- [x] Harden Android Gradle and manifest config for Android Studio builds and scheduled notifications.
- [x] Add Android release ProGuard rules for notification support.
- [x] Update project docs and bump the patch version.
- [ ] Run verification commands, review the diff, and commit the Android build prep.

# Review

- Raised Android `minSdk` to 24 and enabled desugaring plus multidex so the checked-in plugin set builds cleanly from Android Studio.
- Added the notification scheduling receivers, reboot reschedule support, and camera capability declarations required for reliable Android runtime behavior.
- Added `proguard-rules.pro` for `flutter_local_notifications` and updated the Android permission flow to also request exact-alarm access when needed.
- Documented the Android hardening work in `docs/project_outline.md` and prepared the patch version bump for this release.
