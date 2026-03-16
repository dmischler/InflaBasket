# Task Plan

- [x] Re-analyze duplicate detection flow and confirm required behavior (same store, exact price, 30-day window).
- [x] Implement exact duplicate auto-discard for manual and barcode-based entry paths.
- [x] Extend receipt bulk import to skip exact duplicates and report skipped counts.
- [x] Add localization messages for duplicate discard and skipped receipt duplicates.
- [x] Update project documentation with the duplicate detection strategy change.
- [x] Run generation/verification commands, bump patch version, and commit.

# Review

- Fixed duplicate detection logic so exact matches are no longer skipped; exact duplicates now resolve by prioritized checks: barcode first, then existing product identity, then normalized name.
- Applied required duplicate criteria: same store + same price (exact to 2 decimals) + within last 30 days.
- Updated add-entry flow to surface exact duplicates as an intentional non-error outcome and notify the user that the new entry was discarded.
- Updated receipt bulk save to skip duplicates both against existing data and within the same scanned batch, then report saved/skipped counts in localized feedback.
- Documented the behavior change in `docs/project_outline.md` under v1.13.9.
