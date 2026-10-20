---
name: macos-finder-sync
description: >-
  Workflow and diagnostic runbook for building, code-signing, installing, registering
  (via pluginkit), and debugging macOS Finder Sync Extensions (.appex) and Host Apps.
  Activate whenever building, installing, or troubleshooting FinderMenuTools.
---

# macOS Finder Sync Extension Runbook

Use this skill when building, installing, reloading, or troubleshooting the `FinderMenuTools` application and its `FinderSyncExt.appex` extension.

## 1. Key Identifiers
- **Host App Bundle ID**: `com.chinh.FinderMenuTools`
- **Extension Bundle ID**: `com.chinh.FinderMenuTools.FinderSyncExt`
- **Install Location**: `/Applications/FinderMenuTools.app`
- **Embedded Extension Path**: `/Applications/FinderMenuTools.app/Contents/PlugIns/FinderSyncExt.appex`

## 2. Standard Build & Install Procedure
1. Build and install using the project script:
   ```bash
   ./scripts/install.sh
   ```
2. Or run the diagnostic script to inspect registration and code signature status:
   ```bash
   ./.agents/skills/macos-finder-sync/scripts/diagnose.sh
   ```

## 3. Crucial macOS `FinderSync` Nuances
- **App Sandbox & Root Monitoring**: `pluginkit` (`pkd`) strictly requires `com.apple.security.app-sandbox = true` on `.appex` bundles; setting it to `false` causes `pluginkit` to silently ignore the extension (`(no matches)`). To monitor `/` and `/Volumes` and launch `iTerm.app` inside the sandbox, `FinderSyncExt.entitlements` combines `com.apple.security.app-sandbox = true` with `com.apple.security.temporary-exception.files.all.read-write = true`.
- **Code Signing Order**: Always sign `FinderSyncExt.appex` with its own entitlements first, then sign `FinderMenuTools.app` **without `--deep`** so the host app's entitlements do not overwrite the extension's entitlements.
- **Extension Registration (`pluginkit`)**:
  - Register extension: `pluginkit -a /Applications/FinderMenuTools.app/Contents/PlugIns/FinderSyncExt.appex`
  - Enable extension: `pluginkit -e use -i com.chinh.FinderMenuTools.FinderSyncExt`
  - Verify status: `pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt` (Look for `+` prefix indicating enabled).
- **Reloading Finder**: If context menu changes do not appear immediately after reinstalling, restart the extension process and Finder:
  ```bash
  killall FinderSyncExt 2>/dev/null || true
  killall Finder
  ```
