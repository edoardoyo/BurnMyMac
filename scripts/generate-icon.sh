#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${1:-$ROOT/Resources/app-icon-source.png}"
SQUARE="$ROOT/Resources/app-icon-square.png"
ICONSET="$ROOT/Resources/AppIcon.iconset"
ICNS="$ROOT/Resources/AppIcon.icns"

if [[ ! -f "$SOURCE" ]]; then
  echo "Icon source not found: $SOURCE" >&2
  exit 1
fi

cp "$SOURCE" "$SQUARE"
sips -c 1024 1024 "$SQUARE" >/dev/null

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

declare -a SIZES=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)

for entry in "${SIZES[@]}"; do
  size="${entry%%:*}"
  name="${entry##*:}"
  sips -z "$size" "$size" "$SQUARE" --out "$ICONSET/$name" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$ICNS"
echo "Generated: $ICNS"
