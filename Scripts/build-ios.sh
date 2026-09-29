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

DOBBY_BUILD="$DOBBY/build-ios-arm64"
cmake -S "$DOBBY" -B "$DOBBY_BUILD"   -DCMAKE_BUILD_TYPE=Release   -DCMAKE_SYSTEM_NAME=iOS   -DCMAKE_OSX_ARCHITECTURES=arm64   -DCMAKE_SYSTEM_PROCESSOR=arm64   -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0   -DCMAKE_OSX_SYSROOT="$SDK"   -DPlugin.SymbolResolver=OFF   -DPlugin.ImportTableReplace=OFF   -DDOBBY_BUILD_EXAMPLE=OFF   -DDOBBY_BUILD_TEST=OFF
cmake --build "$DOBBY_BUILD" --target dobby_static -- -j8
DOBBY_A="$DOBBY_BUILD/libdobby.a"
test -f "$DOBBY_A"

xcrun --sdk iphoneos clang   -arch arm64   -isysroot "$SDK"   -miphoneos-version-min=12.0   -Oz -fPIC -fvisibility=hidden   -Wall -Wextra -Werror   -c "$ROOT/Sources/NodeVideoGitHubDownloader.c"   -o "$OUT/NodeVideoGitHubDownloader.o"

xcrun --sdk iphoneos clang++   -arch arm64   -isysroot "$SDK"   -miphoneos-version-min=12.0   -dynamiclib   -Wl,-install_name,@rpath/NodeVideoGitHubDownloader.dylib   "$OUT/NodeVideoGitHubDownloader.o" "$DOBBY_A"   -framework Foundation   -lobjc -lc++   -o "$OUT/DylibCaidan.dylib"

codesign --force --sign - "$OUT/DylibCaidan.dylib"
file "$OUT/DylibCaidan.dylib"
otool -hv "$OUT/DylibCaidan.dylib"
otool -L "$OUT/DylibCaidan.dylib"
nm -gU "$OUT/DylibCaidan.dylib" | grep -E 'NVGitHubDownloader|DobbyHook|DobbyDestroy'
shasum -a 256 "$OUT/DylibCaidan.dylib" | tee "$OUT/SHA256.txt"
