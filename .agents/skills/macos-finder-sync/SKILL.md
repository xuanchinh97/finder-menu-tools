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
- **App Sandbox & Root Monitoring**: Monitoring `/` requires either disabling App Sandbox (`com.apple.security.app-sandbox = false`) for local signed builds or granting full read access. For personal developer tools installed in `/Applications`, disabling App Sandbox with ad-hoc signing (`CODE_SIGN_IDENTITY="-"`) allows unrestricted monitoring of `/` and `/Volumes` as well as launching external applications like `iTerm.app`.
- **Extension Registration (`pluginkit`)**:
  - Register extension: `pluginkit -a /Applications/FinderMenuTools.app/Contents/PlugIns/FinderSyncExt.appex`
  - Enable extension: `pluginkit -e use -i com.chinh.FinderMenuTools.FinderSyncExt`
  - Verify status: `pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt` (Look for `+` prefix indicating enabled).
- **Reloading Finder**: If context menu changes do not appear immediately after reinstalling, restart the extension process and Finder:
  ```bash
  killall FinderSyncExt 2>/dev/null || true
  killall Finder
  ```
