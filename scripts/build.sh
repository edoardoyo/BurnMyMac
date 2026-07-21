#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="BurnMyMac"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SOURCES_DIR="$ROOT/Sources/$APP_NAME"
RESOURCES_DIR="$ROOT/Resources"

MIN_MACOS="13.0"
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  TARGET="arm64-apple-macos$MIN_MACOS"
else
  TARGET="x86_64-apple-macos$MIN_MACOS"
fi

echo "Building $APP_NAME for $TARGET ..."

if [[ ! -f "$RESOURCES_DIR/AppIcon.icns" ]]; then
  echo "Generating AppIcon.icns ..."
  "$ROOT/scripts/generate-icon.sh"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
  -O \
  -whole-module-optimization \
  -target "$TARGET" \
  -parse-as-library \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  "$SOURCES_DIR"/*.swift \
  -framework AppKit \
  -framework IOKit \
  -framework Combine

cp "$RESOURCES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [[ -f "$RESOURCES_DIR/AppIcon.icns" ]]; then
  cp "$RESOURCES_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
  echo "Warning: AppIcon.icns not found. Run ./scripts/generate-icon.sh first." >&2
fi

echo "Built: $APP_BUNDLE"
echo "Run: open \"$APP_BUNDLE\""
