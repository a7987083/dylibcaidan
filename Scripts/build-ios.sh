#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
mkdir -p "$OUT"

xcrun --sdk iphoneos clang \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=12.0 \
  -Oz -fPIC -fvisibility=hidden \
  -Wall -Wextra -Werror \
  -dynamiclib \
  -Wl,-install_name,@rpath/NodeVideoGitHubDownloader.dylib \
  -framework Foundation \
  -lobjc \
  "$ROOT/Sources/NodeVideoGitHubDownloader.c" \
  -o "$OUT/DylibCaidan.dylib"

codesign --force --sign - "$OUT/DylibCaidan.dylib"
file "$OUT/DylibCaidan.dylib"
otool -hv "$OUT/DylibCaidan.dylib"
otool -L "$OUT/DylibCaidan.dylib"
nm -gU "$OUT/DylibCaidan.dylib" | grep 'NVGitHubDownloader'
shasum -a 256 "$OUT/DylibCaidan.dylib" | tee "$OUT/SHA256.txt"