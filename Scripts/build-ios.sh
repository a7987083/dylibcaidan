#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build"
VENDOR="$ROOT/vendor"
DOBBY="$VENDOR/Dobby"
DOBBY_COMMIT="5dfc8546954ce3b3198132ab13fddb89ee92cdd7"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
mkdir -p "$OUT" "$VENDOR"

rm -rf "$DOBBY"
git clone https://github.com/jmpews/Dobby.git "$DOBBY"
git -C "$DOBBY" checkout "$DOBBY_COMMIT"
python3 "$DOBBY/scripts/platform_builder.py" --platform=iphoneos --arch=arm64
DOBBY_A="$DOBBY/build/iphoneos/arm64/libdobby.a"
test -f "$DOBBY_A"

xcrun --sdk iphoneos clang \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=12.0 \
  -Oz -fPIC -fvisibility=hidden \
  -Wall -Wextra -Werror \
  -c "$ROOT/Sources/NodeVideoGitHubDownloader.c" \
  -o "$OUT/NodeVideoGitHubDownloader.o"

xcrun --sdk iphoneos clang++ \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=12.0 \
  -dynamiclib \
  -Wl,-install_name,@rpath/NodeVideoGitHubDownloader.dylib \
  "$OUT/NodeVideoGitHubDownloader.o" "$DOBBY_A" \
  -framework Foundation \
  -lobjc -lc++ \
  -o "$OUT/DylibCaidan.dylib"

codesign --force --sign - "$OUT/DylibCaidan.dylib"
file "$OUT/DylibCaidan.dylib"
otool -hv "$OUT/DylibCaidan.dylib"
otool -L "$OUT/DylibCaidan.dylib"
nm -gU "$OUT/DylibCaidan.dylib" | grep -E 'NVGitHubDownloader|DobbyHook|DobbyDestroy'
shasum -a 256 "$OUT/DylibCaidan.dylib" | tee "$OUT/SHA256.txt"