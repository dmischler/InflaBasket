---
name: update-project-outline-and-bump-version
description: Refreshes docs/project_outline.md based on current codebase structure, performs a semantic version bump (default: patch), and commits the changes with a conventional commit message.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: release documentation
---

# Update Project Outline + Semantic Version Bump

**Purpose**: Keep your living documentation in sync with the codebase and maintain proper semantic versioning in one clean, repeatable operation.

## When to use this skill
- You want to update `docs/project_outline.md` after structural changes
- You're preparing a release or tagging a new version
- After a feature, refactor, or cleanup that affects the project architecture
- Whenever you say "update the outline and bump version"

## Execution Steps (follow precisely)

### 1. Planning Phase (always do this first)
1. Read the existing `docs/project_outline.md` (create a high-quality starter version if the file doesn't exist).
2. Locate the version definition by checking common locations **in this order**:
   - `pyproject.toml` (`version = "..."`)
   - `package.json`
   - `Cargo.toml`
   - `setup.py` / `setup.cfg`
   - Any file containing `__version__ =` or `VERSION =`
3. Parse the current version and propose the bump:
   - Default: **patch** (e.g. 1.2.3 → 1.2.4)
   - Respect explicit requests like "bump minor" or "bump major"
4. Present a clear plan to the user:
   - Current version → Proposed new version
   - Summary of outline changes
   - Files that will be modified

**Rule**: Do **not** edit anything until the user approves the plan.

### 2. Update Version
- Use precise editing (never broad file replacements).
- Update **all** version occurrences consistently.
- Handle different file formats correctly (TOML, JSON, Python, etc.).

### 3. Update `docs/project_outline.md`
Refresh or create the following sections (as appropriate):
- **Project Overview** / summary
- **Directory Structure** (use `list_dir` / tree on `src/`, `app/`, `packages/`, etc.)
- **Core Modules & Components** with responsibilities
- **Key Technologies & Patterns**
- **Recent Changes** (based on `git log` of the last few commits)
- Any architecture notes or diagrams

**Best practices for the outline**:
- Clean Markdown hierarchy
- Concise but informative
- Professional tone
- Up-to-date and useful as living documentation

### 4. Commit the Changes
1. Stage **only** these files:
   - `docs/project_outline.md`
   - The version file(s)
2. Create a conventional commit:
   - chore(release): bump version to vX.Y.Z
   - Updated project_outline.md to reflect current codebase structure

3. Commit cleanly using git tools.

## Rules & Constraints
- Always prefer precision (targeted edits) over broad changes.
- Never bump a **major** version without explicit user confirmation.
- If `docs/project_outline.md` is missing, create a solid starter version.
- After the commit, report the new version and commit hash.
- Keep everything professional and consistent.

## Recommended Tools
- File operations: `read_file`, `list_dir`, edit/replace tools
- Git: status, diff, commit
- Bash when needed for parsing versions or running `git log`

Follow this workflow exactly and you'll produce clean, consistent, professional releases every time.