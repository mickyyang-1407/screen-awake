#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
mkdir -p "$ROOT/build"
xcrun swiftc -swift-version 6 -default-isolation MainActor -parse-as-library \
  -framework IOKit "$ROOT/Sources/DisplayCommand.swift" "$ROOT/Tests/DisplayCommandChecks.swift" \
  -o "$ROOT/build/DisplayCommandChecks"
"$ROOT/build/DisplayCommandChecks"

xcrun swiftc -swift-version 6 -default-isolation MainActor -parse-as-library \
  -framework AppKit "$ROOT/Sources/AppText.swift" "$ROOT/Sources/ScheduleModel.swift" \
  "$ROOT/Sources/ScheduleController.swift" "$ROOT/Sources/ScheduleText.swift" \
  "$ROOT/Sources/ScheduleView.swift" "$ROOT/Tests/ScheduleChecks.swift" -o "$ROOT/build/ScheduleChecks"
"$ROOT/build/ScheduleChecks"
