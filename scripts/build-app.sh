#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

app_path="$project_dir/outputs/East8 Clock.app"
target_arch="$(/usr/bin/uname -m)"

/bin/mkdir -p "$app_path/Contents/MacOS"
/usr/bin/xcrun swiftc -O -parse-as-library -module-name East8Clock \
    -target "${target_arch}-apple-macosx13.0" \
    -o "$app_path/Contents/MacOS/East8Clock" Sources/East8Clock/*.swift
/usr/bin/install -m 644 Resources/Info.plist "$app_path/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$app_path"
/usr/bin/codesign --verify --strict "$app_path"

printf '%s\n' "$app_path"
