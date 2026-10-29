#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
OUT="$ROOT/build"
APP="$OUT/Screen Awake.app"
trap 'build_exit_code=$?; trap - ZERR; rm -rf -- "$APP"; exit "$build_exit_code"' ZERR
rm -rf "$APP"
mkdir -p "$OUT" "$APP/Contents/MacOS" "$APP/Contents/Resources"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
for arch in arm64 x86_64; do
  xcrun swiftc -swift-version 6 -default-isolation MainActor -O -whole-module-optimization \
    -parse-as-library -target "${arch}-apple-macos14.0" -sdk "$SDK" \
    -framework AppKit -framework IOKit "$ROOT"/Sources/*.swift \
    -o "$OUT/ScreenAwake-$arch"
done
lipo -create "$OUT/ScreenAwake-arm64" "$OUT/ScreenAwake-x86_64" -output "$APP/Contents/MacOS/ScreenAwake"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp -R "$ROOT/Resources/en.lproj" "$ROOT/Resources/zh-Hant.lproj" "$APP/Contents/Resources/"
xcrun swift "$ROOT/scripts/make-icon.swift" "$OUT/AppIcon.png"
ICONSET="$OUT/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for pixels in 16 32 128 256 512; do
  sips -z "$pixels" "$pixels" "$OUT/AppIcon.png" --out "$ICONSET/icon_${pixels}x${pixels}.png" >/dev/null
done
for pixels in 16 32 128 256 512; do
  doubled=$((pixels * 2))
  sips -z "$doubled" "$doubled" "$OUT/AppIcon.png" --out "$ICONSET/icon_${pixels}x${pixels}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
plutil -lint "$APP/Contents/Info.plist"
file "$APP/Contents/MacOS/ScreenAwake"
ARCHS="$(lipo -archs "$APP/Contents/MacOS/ScreenAwake")"
[[ "$ARCHS" == "x86_64 arm64" || "$ARCHS" == "arm64 x86_64" ]]
echo "$APP"
