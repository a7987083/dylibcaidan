#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
mkdir -p "$OUT"
xcrun --sdk iphoneos clang++ \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=13.0 \
  -fobjc-arc \
  -fvisibility=hidden \
  -std=c++17 \
  -dynamiclib \
  -Wl,-install_name,@rpath/DylibCaidan.dylib \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  "$ROOT/Sources/Entry.mm" "$ROOT/Sources/ZNOverlay.mm" "$ROOT/Sources/ZNMenuViewController.mm" \
  -o "$OUT/DylibCaidan.dylib"
file "$OUT/DylibCaidan.dylib"
otool -hv "$OUT/DylibCaidan.dylib"
otool -L "$OUT/DylibCaidan.dylib"
echo "Built: $OUT/DylibCaidan.dylib"
