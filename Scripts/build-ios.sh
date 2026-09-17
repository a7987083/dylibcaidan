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
  -Wl,-install_name,@rpath/NeonModifier.dylib \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  "$ROOT/Sources/Entry.mm" \
  "$ROOT/Sources/ZNOverlay.mm" \
  "$ROOT/Sources/ZNMemoryEngine.mm" \
  "$ROOT/Sources/ZNThemeCatalog.mm" \
  "$ROOT/Sources/ZNMenuViewController.mm" \
  -o "$OUT/NeonModifier.dylib"

file "$OUT/NeonModifier.dylib"
otool -hv "$OUT/NeonModifier.dylib"
otool -L "$OUT/NeonModifier.dylib"
shasum -a 256 "$OUT/NeonModifier.dylib" | tee "$OUT/SHA256.txt"
echo "Built: $OUT/NeonModifier.dylib"
