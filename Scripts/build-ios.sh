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
  "$ROOT/Sources/NodeVideoGitHubDownloader.m" \
  -o "$OUT/NodeVideoGitHubDownloader.dylib"

codesign --force --sign - "$OUT/NodeVideoGitHubDownloader.dylib"
file "$OUT/NodeVideoGitHubDownloader.dylib"
otool -hv "$OUT/NodeVideoGitHubDownloader.dylib"
otool -L "$OUT/NodeVideoGitHubDownloader.dylib"
nm -gU "$OUT/NodeVideoGitHubDownloader.dylib" | grep 'NVGitHubDownloader'
shasum -a 256 "$OUT/NodeVideoGitHubDownloader.dylib" | tee "$OUT/SHA256.txt"