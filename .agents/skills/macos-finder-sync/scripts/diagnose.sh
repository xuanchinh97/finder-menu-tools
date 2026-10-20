#!/usr/bin/env bash
set -euo pipefail

APP_PATH="/Applications/FinderMenuTools.app"
EXT_PATH="$APP_PATH/Contents/PlugIns/FinderSyncExt.appex"
EXT_ID="com.chinh.FinderMenuTools.FinderSyncExt"

echo "=== 1. Checking Installed Bundle ==="
if [ -d "$APP_PATH" ]; then
  echo "[OK] Found $APP_PATH"
  codesign -dv --verbose=2 "$APP_PATH" 2>&1 | grep -E "Identifier|Format|Signature|Authority" || true
else
  echo "[MISSING] $APP_PATH is not installed yet."
fi

echo ""
echo "=== 2. Checking Embedded Finder Sync Extension ==="
if [ -d "$EXT_PATH" ]; then
  echo "[OK] Found $EXT_PATH"
  codesign -dv --verbose=2 "$EXT_PATH" 2>&1 | grep -E "Identifier|Format|Signature|Authority" || true
else
  echo "[MISSING] $EXT_PATH is not found."
fi

echo ""
echo "=== 3. Checking pluginkit Registration ==="
pluginkit -m -v -i "$EXT_ID" || echo "[INFO] Extension not registered in pluginkit yet."

echo ""
echo "=== 4. Checking iTerm2 Availability ==="
if [ -d "/Applications/iTerm.app" ]; then
  echo "[OK] iTerm2 found at /Applications/iTerm.app"
else
  echo "[WARN] /Applications/iTerm.app not found in /Applications"
fi
