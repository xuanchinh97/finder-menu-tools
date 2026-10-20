#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="FinderMenuTools.app"
INSTALL_PATH="/Applications/$APP_NAME"
EXT_PATH="$INSTALL_PATH/Contents/PlugIns/FinderSyncExt.appex"
EXT_BUNDLE_ID="com.chinh.FinderMenuTools.FinderSyncExt"

echo "==> [1/4] Building FinderMenuTools (Release)..."
xcodebuild \
  -project "$PROJECT_DIR/FinderMenuTools.xcodeproj" \
  -target FinderMenuTools \
  -configuration Release \
  SYMROOT="$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  clean build

BUILT_APP="$BUILD_DIR/Release/$APP_NAME"
if [ ! -d "$BUILT_APP" ]; then
  echo "Error: Built application not found at $BUILT_APP"
  exit 1
fi

echo "==> [2/4] Installing to $INSTALL_PATH..."
killall FinderMenuTools 2>/dev/null || true
killall FinderSyncExt 2>/dev/null || true
rm -rf "$INSTALL_PATH"
cp -R "$BUILT_APP" "$INSTALL_PATH"

# Re-sign extension first, then host app (without --deep on host app so extension entitlements are preserved)
codesign --force --sign - --entitlements "$PROJECT_DIR/FinderSyncExt/FinderSyncExt.entitlements" "$EXT_PATH"
codesign --force --sign - --entitlements "$PROJECT_DIR/FinderMenuTools/FinderMenuTools.entitlements" "$INSTALL_PATH"

echo "==> [3/4] Registering and enabling Finder Sync Extension ($EXT_BUNDLE_ID)..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted "$INSTALL_PATH"
pluginkit -a "$EXT_PATH" || true
pluginkit -e use -i "$EXT_BUNDLE_ID" || true

echo "==> [4/4] Restarting Finder to reload extensions..."
killall Finder 2>/dev/null || true

echo "==> Done! Current extension status:"
pluginkit -m -v -i "$EXT_BUNDLE_ID" || true
