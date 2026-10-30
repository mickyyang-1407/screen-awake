#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
OUT="$ROOT/build"
mkdir -p "$OUT"
xcrun swiftc -swift-version 6 -default-isolation MainActor -O -parse-as-library \
  -framework AppKit "$ROOT/Sources/AppText.swift" "$ROOT/Sources/ScheduleModel.swift" "$ROOT/Sources/ScheduleText.swift" "$ROOT/Sources/ScheduleView.swift" "$ROOT/Sources/AwakePanelView.swift" "$ROOT/Sources/SetupGuideView.swift" \
  "$ROOT/scripts/render-previews.swift" -o "$OUT/RenderPreviews"
"$OUT/RenderPreviews" "$OUT/previews"
