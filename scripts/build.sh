#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
OUT="$ROOT/build"
APP="$OUT/Screen Awake.app"
CLI_ONLY=false
if [[ $# -eq 1 && "${1:-}" == "--cli-only" ]]; then
  CLI_ONLY=true
elif [[ $# -ne 0 ]]; then
  print -u2 'Usage: zsh scripts/build.sh [--cli-only]'
  exit 64
fi
mkdir -p "$OUT"
STAGE="$(mktemp -d "$OUT/.build-XXXXXX")"
trap 'rm -rf -- "$STAGE"' EXIT
SDK="$(xcrun --sdk macosx --show-sdk-path)"
for arch in arm64 x86_64; do
  xcrun swiftc -swift-version 6 -default-isolation MainActor -O -whole-module-optimization \
    -parse-as-library -target "${arch}-apple-macos14.0" -sdk "$SDK" \
    -framework AppKit -framework IOKit "$ROOT"/Sources/*.swift \
    -o "$STAGE/ScreenAwake-$arch"
done
lipo -create "$STAGE/ScreenAwake-arm64" "$STAGE/ScreenAwake-x86_64" -output "$STAGE/ScreenAwake"
ARCHS="$(lipo -archs "$STAGE/ScreenAwake")"
[[ "$ARCHS" == "x86_64 arm64" || "$ARCHS" == "arm64 x86_64" ]]
codesign --force --sign - "$STAGE/ScreenAwake"
codesign --verify --strict "$STAGE/ScreenAwake"
if [[ "$CLI_ONLY" == true ]]; then
  mv -f "$STAGE/ScreenAwake" "$OUT/ScreenAwake"
  file "$OUT/ScreenAwake"
  echo "$OUT/ScreenAwake"
  exit 0
fi
STAGED_APP="$STAGE/Screen Awake.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
cp "$STAGE/ScreenAwake" "$STAGED_APP/Contents/MacOS/ScreenAwake"
cp "$ROOT/Resources/Info.plist" "$STAGED_APP/Contents/Info.plist"
cp -R "$ROOT/Resources/en.lproj" "$ROOT/Resources/zh-Hant.lproj" "$STAGED_APP/Contents/Resources/"
xcrun swift "$ROOT/scripts/make-icon.swift" "$STAGE/AppIcon.png"
ICONSET="$STAGE/AppIcon.iconset"
mkdir -p "$ICONSET"
for pixels in 16 32 128 256 512; do
  sips -z "$pixels" "$pixels" "$STAGE/AppIcon.png" --out "$ICONSET/icon_${pixels}x${pixels}.png" >/dev/null
  doubled=$((pixels * 2))
  sips -z "$doubled" "$doubled" "$STAGE/AppIcon.png" --out "$ICONSET/icon_${pixels}x${pixels}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$STAGED_APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$STAGED_APP"
codesign --verify --strict "$STAGED_APP"
plutil -lint "$STAGED_APP/Contents/Info.plist"
# Replace only after the entire build and validation succeed.
rm -rf -- "$APP"
mv "$STAGED_APP" "$APP"
cp "$STAGE/ScreenAwake" "$OUT/ScreenAwake"
file "$APP/Contents/MacOS/ScreenAwake"
echo "$APP"
