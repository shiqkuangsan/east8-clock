#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

app_path="$project_dir/outputs/East8 Clock.app"
resources_path="$app_path/Contents/Resources"
target_arch="$(/usr/bin/uname -m)"

/bin/rm -rf "$resources_path"
/bin/mkdir -p "$app_path/Contents/MacOS" "$resources_path"
/usr/bin/xcrun swiftc -O -parse-as-library -module-name East8Clock \
    -target "${target_arch}-apple-macosx13.0" \
    -o "$app_path/Contents/MacOS/East8Clock" Sources/East8Clock/*.swift
/usr/bin/install -m 644 Resources/Info.plist "$app_path/Contents/Info.plist"
# With Xcode, compile the Liquid Glass icon (Assets.car plus an .icns fallback) so macOS 26 and
# later show it without the gray legacy-icon frame. Command Line Tools lack actool, so use the .icns.
if /usr/bin/xcrun --find actool >/dev/null 2>&1; then
    partial_plist="$(/usr/bin/mktemp -t east8-icon)"
    /usr/bin/xcrun actool Resources/AppIcon.icon --compile "$resources_path" \
        --platform macosx --minimum-deployment-target 13.0 --app-icon AppIcon \
        --output-partial-info-plist "$partial_plist" --errors --warnings >/dev/null
    /bin/rm -f "$partial_plist"
else
    /usr/bin/install -m 644 Resources/AppIcon.icns "$resources_path/AppIcon.icns"
fi
/usr/bin/codesign --force --sign - "$app_path"
/usr/bin/codesign --verify --strict "$app_path"

printf '%s\n' "$app_path"
