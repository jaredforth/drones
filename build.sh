#!/bin/sh
# Builds build/Drones.app; run with `open build/Drones.app`.
set -e
cd "$(dirname "$0")"
app=build/Drones.app
rm -rf "$app" && mkdir -p "$app/Contents/MacOS"
swiftc -O -parse-as-library Drones/Drones.swift -o "$app/Contents/MacOS/Drones"
cat > "$app/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Drones</string>
<key>CFBundleIdentifier</key><string>dev.jaredforth.drones</string>
<key>CFBundleExecutable</key><string>Drones</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
P
