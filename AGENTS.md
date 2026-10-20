# Project Rules: FinderMenuTools (macOS Native Swift / AppKit)

This repository is a **native macOS utility** written in **Swift 6+** using **AppKit** and **FinderSync (`FIFinderSync`)**. These project-level rules override default web/frontend stack assumptions when working inside this repository.

## 1. Tech Stack & Architecture
- **Language**: Swift 6+ (Strict concurrency, modern Foundation `URL` APIs).
- **Frameworks**: `Cocoa` (`AppKit`), `FinderSync`.
- **Targets**:
  1. `FinderMenuTools` (Host macOS Application `.app`).
  2. `FinderSyncExt` (Finder Sync Extension `.appex` embedded inside `PlugIns/` of the Host App).
- **Minimum Deployment Target**: macOS 14.0+ (arm64 / Universal).

## 2. Coding & Implementation Standards
- Keep implementations atomic, explicit, and dependency-free (zero external CocoaPods/SPM packages unless explicitly requested).
- Use `URL.path(percentEncoded: false)` when converting file URLs to POSIX paths so spaces and Vietnamese/Unicode characters are never percent-encoded.
- Handle both `selectedItemURLs()` (direct right-click on items) and `targetedURL()` (right-click on folder background).
- When opening `iTerm2` on a selected file, automatically resolve its parent directory (`.deletingLastPathComponent()`); when selected item is a directory, open it directly.

## 3. Documentation & Tracking Discipline (`docs/`)
Every code change, architectural decision, or build/deployment step **MUST** be reflected in `docs/`:
- `docs/architecture.md`: Technical design, target structure, entitlements, and extension lifecycle.
- `docs/usage-and-setup.md`: Build, installation, activation, and troubleshooting guide.
- `docs/tracking-log.md`: Chronological engineering log recording every milestone, technical decision, verification result, and Git commit reference.

## 4. Version Control (Git) Workflow
- Maintain a clean Git working tree (`main` branch).
- Use Conventional Commits (`chore:`, `docs:`, `feat:`, `fix:`, `refactor:`).
- Never commit build outputs (`build/`, `DerivedData/`, `*.app`, `.DS_Store`).
